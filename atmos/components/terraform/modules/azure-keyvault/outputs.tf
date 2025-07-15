output "key_vault_id" {
  description = "The ID of the Key Vault"
  value       = var.enabled ? azurerm_key_vault.this[0].id : null
}

output "key_vault_name" {
  description = "The name of the Key Vault"
  value       = var.enabled ? azurerm_key_vault.this[0].name : null
}

output "key_vault_uri" {
  description = "The URI of the Key Vault, used for performing operations on keys and secrets"
  value       = var.enabled ? azurerm_key_vault.this[0].vault_uri : null
}

output "key_vault_location" {
  description = "The location of the Key Vault"
  value       = var.enabled ? azurerm_key_vault.this[0].location : null
}

output "key_vault_resource_group_name" {
  description = "The name of the resource group in which the Key Vault was created"
  value       = var.enabled ? azurerm_key_vault.this[0].resource_group_name : null
}

output "key_vault_tenant_id" {
  description = "The Azure Active Directory tenant ID that should be used for authenticating requests to the key vault"
  value       = var.enabled ? azurerm_key_vault.this[0].tenant_id : null
}

output "key_vault_sku_name" {
  description = "The SKU name of the Key Vault"
  value       = var.enabled ? azurerm_key_vault.this[0].sku_name : null
}

output "key_vault_access_policy" {
  description = "The access policy of the Key Vault"
  value       = var.enabled ? azurerm_key_vault.this[0].access_policy : []
}

output "key_vault_network_acls" {
  description = "The network ACLs of the Key Vault"
  value       = var.enabled ? azurerm_key_vault.this[0].network_acls : []
}

# Security and Configuration Outputs
output "purge_protection_enabled" {
  description = "Whether purge protection is enabled"
  value       = var.enabled ? azurerm_key_vault.this[0].purge_protection_enabled : null
}

output "soft_delete_retention_days" {
  description = "The number of days that items should be retained for once soft-deleted"
  value       = var.enabled ? azurerm_key_vault.this[0].soft_delete_retention_days : null
}

output "public_network_access_enabled" {
  description = "Whether public network access is enabled"
  value       = var.enabled ? azurerm_key_vault.this[0].public_network_access_enabled : null
}

output "enable_rbac_authorization" {
  description = "Whether RBAC authorization is enabled"
  value       = var.enabled ? azurerm_key_vault.this[0].enable_rbac_authorization : null
}

# Created Resources Outputs
output "secrets" {
  description = "Map of created secrets and their metadata"
  value = var.enabled ? {
    for k, v in azurerm_key_vault_secret.secrets : k => {
      id             = v.id
      name           = v.name
      version        = v.version
      versionless_id = v.versionless_id
    }
  } : {}
}

output "keys" {
  description = "Map of created keys and their metadata"
  value = var.enabled ? {
    for k, v in azurerm_key_vault_key.keys : k => {
      id             = v.id
      name           = v.name
      version        = v.version
      versionless_id = v.versionless_id
      key_type       = v.key_type
      key_size       = v.key_size
      curve          = v.curve
    }
  } : {}
}

output "certificates" {
  description = "Map of created certificates and their metadata"
  value = var.enabled ? {
    for k, v in azurerm_key_vault_certificate.certificates : k => {
      id               = v.id
      name             = v.name
      version          = v.version
      versionless_id   = v.versionless_id
      secret_id        = v.secret_id
      certificate_data = v.certificate_data
      thumbprint       = v.thumbprint
    }
  } : {}
}

# Diagnostic Settings
output "diagnostic_setting_id" {
  description = "The ID of the diagnostic setting"
  value       = var.enabled && var.diagnostic_settings != null ? azurerm_monitor_diagnostic_setting.this[0].id : null
}

# Labels and Tags
output "tags" {
  description = "The tags applied to the Key Vault"
  value       = module.label.tags
}

output "context" {
  description = "Exported context for use by other modules"
  value       = module.label.context
}

