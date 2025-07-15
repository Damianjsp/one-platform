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

# Generate a random suffix for globally unique storage account names
resource "random_string" "storage_suffix" {
  count   = var.enabled && var.use_random_suffix ? 1 : 0
  length  = 4
  special = false
  upper   = false
}

locals {
  # Storage account name with optional random suffix for global uniqueness
  storage_account_name = var.enabled ? coalesce(
    var.storage_account_name,
    var.use_random_suffix ? "${module.label.id}${random_string.storage_suffix[0].result}" : module.label.id
  ) : null

  # Determine if hierarchical namespace should be enabled (Data Lake Gen2)
  is_data_lake = var.account_kind == "StorageV2" && var.is_hns_enabled

  # Calculate which private endpoints to create based on configuration
  private_endpoints_to_create = var.enabled && var.create_private_endpoints ? {
    for service in var.private_endpoint_services :
    service => {
      subresource = service
      enabled     = contains(var.enabled_services, service) || service == "dfs" && local.is_data_lake
    }
    } : {
    blob  = { subresource = "blob", enabled = false }
    file  = { subresource = "file", enabled = false }
    queue = { subresource = "queue", enabled = false }
    table = { subresource = "table", enabled = false }
    dfs   = { subresource = "dfs", enabled = false }
  }
}

# Primary Storage Account
resource "azurerm_storage_account" "this" {
  count = var.enabled ? 1 : 0

  name                = local.storage_account_name
  resource_group_name = var.resource_group_name
  location            = var.location

  account_tier                    = var.account_tier
  account_replication_type        = var.account_replication_type
  account_kind                    = var.account_kind
  access_tier                     = var.access_tier
  https_traffic_only_enabled      = var.https_traffic_only_enabled
  min_tls_version                 = var.min_tls_version
  allow_nested_items_to_be_public = var.allow_nested_items_to_be_public
  shared_access_key_enabled       = var.shared_access_key_enabled
  public_network_access_enabled   = var.public_network_access_enabled
  default_to_oauth_authentication = var.default_to_oauth_authentication

  # Data Lake Gen2 support
  is_hns_enabled = var.is_hns_enabled

  # Managed Identity - Always enable system-assigned identity
  identity {
    type = "SystemAssigned"
  }

  # Network rules
  dynamic "network_rules" {
    for_each = var.network_rules != null ? [var.network_rules] : []
    content {
      default_action             = network_rules.value.default_action
      bypass                     = network_rules.value.bypass
      ip_rules                   = network_rules.value.ip_rules
      virtual_network_subnet_ids = network_rules.value.virtual_network_subnet_ids
    }
  }

  # Blob properties
  dynamic "blob_properties" {
    for_each = var.blob_properties != null ? [var.blob_properties] : []
    content {
      versioning_enabled            = blob_properties.value.versioning_enabled
      change_feed_enabled           = blob_properties.value.change_feed_enabled
      change_feed_retention_in_days = blob_properties.value.change_feed_retention_in_days
      default_service_version       = blob_properties.value.default_service_version
      last_access_time_enabled      = blob_properties.value.last_access_time_enabled

      dynamic "cors_rule" {
        for_each = blob_properties.value.cors_rules != null ? blob_properties.value.cors_rules : []
        content {
          allowed_origins    = cors_rule.value.allowed_origins
          allowed_methods    = cors_rule.value.allowed_methods
          allowed_headers    = cors_rule.value.allowed_headers
          exposed_headers    = cors_rule.value.exposed_headers
          max_age_in_seconds = cors_rule.value.max_age_in_seconds
        }
      }

      dynamic "delete_retention_policy" {
        for_each = blob_properties.value.delete_retention_policy != null ? [blob_properties.value.delete_retention_policy] : []
        content {
          days = delete_retention_policy.value.days
        }
      }

      dynamic "container_delete_retention_policy" {
        for_each = blob_properties.value.container_delete_retention_policy != null ? [blob_properties.value.container_delete_retention_policy] : []
        content {
          days = container_delete_retention_policy.value.days
        }
      }
    }
  }

  # Queue properties
  dynamic "queue_properties" {
    for_each = var.queue_properties != null && contains(var.enabled_services, "queue") ? [var.queue_properties] : []
    content {
      dynamic "cors_rule" {
        for_each = queue_properties.value.cors_rules != null ? queue_properties.value.cors_rules : []
        content {
          allowed_origins    = cors_rule.value.allowed_origins
          allowed_methods    = cors_rule.value.allowed_methods
          allowed_headers    = cors_rule.value.allowed_headers
          exposed_headers    = cors_rule.value.exposed_headers
          max_age_in_seconds = cors_rule.value.max_age_in_seconds
        }
      }

      dynamic "logging" {
        for_each = queue_properties.value.logging != null ? [queue_properties.value.logging] : []
        content {
          delete                = logging.value.delete
          read                  = logging.value.read
          write                 = logging.value.write
          version               = logging.value.version
          retention_policy_days = logging.value.retention_policy_days
        }
      }

      dynamic "minute_metrics" {
        for_each = queue_properties.value.minute_metrics != null ? [queue_properties.value.minute_metrics] : []
        content {
          enabled               = minute_metrics.value.enabled
          version               = minute_metrics.value.version
          include_apis          = minute_metrics.value.include_apis
          retention_policy_days = minute_metrics.value.retention_policy_days
        }
      }

      dynamic "hour_metrics" {
        for_each = queue_properties.value.hour_metrics != null ? [queue_properties.value.hour_metrics] : []
        content {
          enabled               = hour_metrics.value.enabled
          version               = hour_metrics.value.version
          include_apis          = hour_metrics.value.include_apis
          retention_policy_days = hour_metrics.value.retention_policy_days
        }
      }
    }
  }

  # Share properties (File service)
  dynamic "share_properties" {
    for_each = var.share_properties != null && contains(var.enabled_services, "file") ? [var.share_properties] : []
    content {
      dynamic "cors_rule" {
        for_each = share_properties.value.cors_rules != null ? share_properties.value.cors_rules : []
        content {
          allowed_origins    = cors_rule.value.allowed_origins
          allowed_methods    = cors_rule.value.allowed_methods
          allowed_headers    = cors_rule.value.allowed_headers
          exposed_headers    = cors_rule.value.exposed_headers
          max_age_in_seconds = cors_rule.value.max_age_in_seconds
        }
      }

      dynamic "retention_policy" {
        for_each = share_properties.value.retention_policy != null ? [share_properties.value.retention_policy] : []
        content {
          days = retention_policy.value.days
        }
      }

      dynamic "smb" {
        for_each = share_properties.value.smb != null ? [share_properties.value.smb] : []
        content {
          versions                        = smb.value.versions
          authentication_types            = smb.value.authentication_types
          kerberos_ticket_encryption_type = smb.value.kerberos_ticket_encryption_type
          channel_encryption_type         = smb.value.channel_encryption_type
        }
      }
    }
  }

  tags = module.label.tags

  lifecycle {
    ignore_changes = [
      customer_managed_key # Prevent drift from external key management
    ]
  }
}

# Private Endpoints for Storage Services - Temporarily disabled due to module compatibility issues
# TODO: Fix private endpoint modules to work with count/for_each by removing provider configurations
# module "private_endpoint_blob" {
#   count  = local.private_endpoints_to_create["blob"].enabled ? 1 : 0
#   source = "../azure-private-endpoint"
#
#   enabled                        = true
#   name                          = "${var.name}blob"
#   attributes                    = concat(var.attributes, ["blob"])
#   location                      = var.location
#   resource_group_name           = var.resource_group_name
#   subnet_id                     = var.private_endpoint_subnet_id
#   private_connection_resource_id = azurerm_storage_account.this[0].id
#   subresource_names             = ["blob"]
#   is_manual_connection          = var.private_endpoint_manual_connection
#   private_dns_zone_group        = var.private_endpoint_dns_zone_group_blob
#
#   # Inherit label configuration
#   namespace               = var.namespace
#   tenant                 = var.tenant
#   environment            = var.environment
#   stage                  = var.stage
#   delimiter              = var.delimiter
#   tags                   = var.tags
#   regex_replace_chars    = var.regex_replace_chars
#   label_order            = var.label_order
#   label_key_case         = var.label_key_case
#   label_value_case       = var.label_value_case
#   id_length_limit        = var.id_length_limit
# }

# module "private_endpoint_file" {
#   count  = local.private_endpoints_to_create["file"].enabled ? 1 : 0
#   source = "../azure-private-endpoint"
#
#   enabled                        = true
#   name                          = "${var.name}file"
#   attributes                    = concat(var.attributes, ["file"])
#   location                      = var.location
#   resource_group_name           = var.resource_group_name
#   subnet_id                     = var.private_endpoint_subnet_id
#   private_connection_resource_id = azurerm_storage_account.this[0].id
#   subresource_names             = ["file"]
#   is_manual_connection          = var.private_endpoint_manual_connection
#   private_dns_zone_group        = var.private_endpoint_dns_zone_group_file
#
#   # Inherit label configuration
#   namespace               = var.namespace
#   tenant                 = var.tenant
#   environment            = var.environment
#   stage                  = var.stage
#   delimiter              = var.delimiter
#   tags                   = var.tags
#   regex_replace_chars    = var.regex_replace_chars
#   label_order            = var.label_order
#   label_key_case         = var.label_key_case
#   label_value_case       = var.label_value_case
#   id_length_limit        = var.id_length_limit
# }

# module "private_endpoint_queue" {
#   count  = local.private_endpoints_to_create["queue"].enabled ? 1 : 0
#   source = "../azure-private-endpoint"
#
#   enabled                        = true
#   name                          = "${var.name}queue"
#   attributes                    = concat(var.attributes, ["queue"])
#   location                      = var.location
#   resource_group_name           = var.resource_group_name
#   subnet_id                     = var.private_endpoint_subnet_id
#   private_connection_resource_id = azurerm_storage_account.this[0].id
#   subresource_names             = ["queue"]
#   is_manual_connection          = var.private_endpoint_manual_connection
#   private_dns_zone_group        = var.private_endpoint_dns_zone_group_queue
#
#   # Inherit label configuration
#   namespace               = var.namespace
#   tenant                 = var.tenant
#   environment            = var.environment
#   stage                  = var.stage
#   delimiter              = var.delimiter
#   tags                   = var.tags
#   regex_replace_chars    = var.regex_replace_chars
#   label_order            = var.label_order
#   label_key_case         = var.label_key_case
#   label_value_case       = var.label_value_case
#   id_length_limit        = var.id_length_limit
# }

# module "private_endpoint_table" {
#   count  = local.private_endpoints_to_create["table"].enabled ? 1 : 0
#   source = "../azure-private-endpoint"
#
#   enabled                        = true
#   name                          = "${var.name}table"
#   attributes                    = concat(var.attributes, ["table"])
#   location                      = var.location
#   resource_group_name           = var.resource_group_name
#   subnet_id                     = var.private_endpoint_subnet_id
#   private_connection_resource_id = azurerm_storage_account.this[0].id
#   subresource_names             = ["table"]
#   is_manual_connection          = var.private_endpoint_manual_connection
#   private_dns_zone_group        = var.private_endpoint_dns_zone_group_table
#
#   # Inherit label configuration
#   namespace               = var.namespace
#   tenant                 = var.tenant
#   environment            = var.environment
#   stage                  = var.stage
#   delimiter              = var.delimiter
#   tags                   = var.tags
#   regex_replace_chars    = var.regex_replace_chars
#   label_order            = var.label_order
#   label_key_case         = var.label_key_case
#   label_value_case       = var.label_value_case
#   id_length_limit        = var.id_length_limit
# }

# module "private_endpoint_dfs" {
#   count  = local.private_endpoints_to_create["dfs"].enabled ? 1 : 0
#   source = "../azure-private-endpoint"
#
#   enabled                        = true
#   name                          = "${var.name}dfs"
#   attributes                    = concat(var.attributes, ["dfs"])
#   location                      = var.location
#   resource_group_name           = var.resource_group_name
#   subnet_id                     = var.private_endpoint_subnet_id
#   private_connection_resource_id = azurerm_storage_account.this[0].id
#   subresource_names             = ["dfs"]
#   is_manual_connection          = var.private_endpoint_manual_connection
#   private_dns_zone_group        = var.private_endpoint_dns_zone_group_dfs
#
#   # Inherit label configuration
#   namespace               = var.namespace
#   tenant                 = var.tenant
#   environment            = var.environment
#   stage                  = var.stage
#   delimiter              = var.delimiter
#   tags                   = var.tags
#   regex_replace_chars    = var.regex_replace_chars
#   label_order            = var.label_order
#   label_key_case         = var.label_key_case
#   label_value_case       = var.label_value_case
#   id_length_limit        = var.id_length_limit
# }