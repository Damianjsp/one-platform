module "label" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  namespace   = var.namespace
  tenant      = var.tenant
  environment = var.environment
  stage       = var.stage
  name        = var.name
  attributes  = var.attributes
  delimiter   = var.delimiter
  tags        = var.tags

  regex_replace_chars = var.regex_replace_chars
  label_order         = var.label_order
  label_key_case      = var.label_key_case
  label_value_case    = var.label_value_case
  id_length_limit     = var.id_length_limit
}

# Get current client configuration
data "azurerm_client_config" "current" {}

# Get current user principal for initial access policy
# Note: This may fail if the service principal doesn't have Azure AD read permissions
# In that case, set add_current_user_access to false and manage access policies explicitly
data "azuread_user" "current" {
  count     = var.enabled && var.add_current_user_access ? 1 : 0
  object_id = data.azurerm_client_config.current.object_id
}

# Azure Key Vault
resource "azurerm_key_vault" "this" {
  count = var.enabled ? 1 : 0

  name                = module.label.id
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = data.azurerm_client_config.current.tenant_id

  # SKU configuration
  sku_name = var.sku_name

  # Security configurations
  enabled_for_deployment          = var.enabled_for_deployment
  enabled_for_disk_encryption     = var.enabled_for_disk_encryption
  enabled_for_template_deployment = var.enabled_for_template_deployment
  enable_rbac_authorization       = var.enable_rbac_authorization
  purge_protection_enabled        = var.purge_protection_enabled
  soft_delete_retention_days      = var.soft_delete_retention_days
  public_network_access_enabled   = var.public_network_access_enabled

  # Network ACLs
  dynamic "network_acls" {
    for_each = var.network_acls != null ? [var.network_acls] : []
    content {
      default_action             = network_acls.value.default_action
      bypass                     = network_acls.value.bypass
      ip_rules                   = network_acls.value.ip_rules
      virtual_network_subnet_ids = network_acls.value.virtual_network_subnet_ids
    }
  }

  # Contact information for certificate management
  dynamic "contact" {
    for_each = var.certificate_contacts
    content {
      email = contact.value.email
      name  = contact.value.name
      phone = contact.value.phone
    }
  }


  tags = module.label.tags

  lifecycle {
    ignore_changes = [
      access_policy, # Manage access policies separately to avoid conflicts
    ]
  }
}

# Current user access policy (if enabled)
resource "azurerm_key_vault_access_policy" "current_user" {
  count = var.enabled && var.add_current_user_access && !var.enable_rbac_authorization ? 1 : 0

  key_vault_id = azurerm_key_vault.this[0].id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  key_permissions = [
    "Get", "List", "Update", "Create", "Import", "Delete", "Recover", "Backup", "Restore",
    "Decrypt", "Encrypt", "UnwrapKey", "WrapKey", "Verify", "Sign", "Purge"
  ]

  secret_permissions = [
    "Get", "List", "Set", "Delete", "Recover", "Backup", "Restore", "Purge"
  ]

  certificate_permissions = [
    "Get", "List", "Update", "Create", "Import", "Delete", "Recover", "Backup", "Restore",
    "ManageContacts", "ManageIssuers", "GetIssuers", "ListIssuers", "SetIssuers", "DeleteIssuers", "Purge"
  ]
}

# Additional access policies
resource "azurerm_key_vault_access_policy" "additional" {
  for_each = var.enabled && !var.enable_rbac_authorization ? var.access_policies : {}

  key_vault_id = azurerm_key_vault.this[0].id
  tenant_id    = each.value.tenant_id != null ? each.value.tenant_id : data.azurerm_client_config.current.tenant_id
  object_id    = each.value.object_id

  key_permissions         = each.value.key_permissions
  secret_permissions      = each.value.secret_permissions
  certificate_permissions = each.value.certificate_permissions
  storage_permissions     = each.value.storage_permissions
}

# Diagnostic settings
resource "azurerm_monitor_diagnostic_setting" "this" {
  count = var.enabled && var.diagnostic_settings != null ? 1 : 0

  name                       = "${module.label.id}-diagnostics"
  target_resource_id         = azurerm_key_vault.this[0].id
  log_analytics_workspace_id = var.diagnostic_settings.log_analytics_workspace_id
  storage_account_id         = var.diagnostic_settings.storage_account_id

  dynamic "enabled_log" {
    for_each = var.diagnostic_settings.log_categories
    content {
      category = enabled_log.value
    }
  }

  dynamic "metric" {
    for_each = var.diagnostic_settings.metric_categories
    content {
      category = metric.value
      enabled  = true
    }
  }
}

# Key Vault Secrets (optional)
resource "azurerm_key_vault_secret" "secrets" {
  for_each = var.enabled ? var.secrets : {}

  name         = each.key
  value        = each.value.value
  key_vault_id = azurerm_key_vault.this[0].id

  content_type    = each.value.content_type
  not_before_date = each.value.not_before_date
  expiration_date = each.value.expiration_date

  tags = merge(module.label.tags, each.value.tags)

  depends_on = [
    azurerm_key_vault_access_policy.current_user,
    azurerm_key_vault_access_policy.additional
  ]
}

# Key Vault Keys (optional)
resource "azurerm_key_vault_key" "keys" {
  for_each = var.enabled ? var.keys : {}

  name         = each.key
  key_vault_id = azurerm_key_vault.this[0].id
  key_type     = each.value.key_type
  key_size     = each.value.key_size
  curve        = each.value.curve
  key_opts     = each.value.key_opts

  not_before_date = each.value.not_before_date
  expiration_date = each.value.expiration_date

  dynamic "rotation_policy" {
    for_each = each.value.rotation_policy != null ? [each.value.rotation_policy] : []
    content {
      automatic {
        time_after_creation = rotation_policy.value.automatic.time_after_creation
        time_before_expiry  = rotation_policy.value.automatic.time_before_expiry
      }
      expire_after         = rotation_policy.value.expire_after
      notify_before_expiry = rotation_policy.value.notify_before_expiry
    }
  }

  tags = merge(module.label.tags, each.value.tags)

  depends_on = [
    azurerm_key_vault_access_policy.current_user,
    azurerm_key_vault_access_policy.additional
  ]
}

# Key Vault Certificates (optional)
resource "azurerm_key_vault_certificate" "certificates" {
  for_each = var.enabled ? var.certificates : {}

  name         = each.key
  key_vault_id = azurerm_key_vault.this[0].id

  dynamic "certificate_policy" {
    for_each = [each.value.certificate_policy]
    content {
      issuer_parameters {
        name = certificate_policy.value.issuer_parameters.name
      }

      key_properties {
        exportable = certificate_policy.value.key_properties.exportable
        key_size   = certificate_policy.value.key_properties.key_size
        key_type   = certificate_policy.value.key_properties.key_type
        reuse_key  = certificate_policy.value.key_properties.reuse_key
      }

      lifetime_action {
        action {
          action_type = certificate_policy.value.lifetime_action.action.action_type
        }

        trigger {
          days_before_expiry  = certificate_policy.value.lifetime_action.trigger.days_before_expiry
          lifetime_percentage = certificate_policy.value.lifetime_action.trigger.lifetime_percentage
        }
      }

      secret_properties {
        content_type = certificate_policy.value.secret_properties.content_type
      }

      dynamic "x509_certificate_properties" {
        for_each = certificate_policy.value.x509_certificate_properties != null ? [certificate_policy.value.x509_certificate_properties] : []
        content {
          key_usage          = x509_certificate_properties.value.key_usage
          subject            = x509_certificate_properties.value.subject
          validity_in_months = x509_certificate_properties.value.validity_in_months

          dynamic "subject_alternative_names" {
            for_each = x509_certificate_properties.value.subject_alternative_names != null ? [x509_certificate_properties.value.subject_alternative_names] : []
            content {
              dns_names = subject_alternative_names.value.dns_names
              emails    = subject_alternative_names.value.emails
              upns      = subject_alternative_names.value.upns
            }
          }
        }
      }
    }
  }

  certificate {
    contents = each.value.certificate_contents
    password = each.value.certificate_password
  }

  tags = merge(module.label.tags, each.value.tags)

  depends_on = [
    azurerm_key_vault_access_policy.current_user,
    azurerm_key_vault_access_policy.additional
  ]
}