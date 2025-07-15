output "user_assigned_identity_id" {
  description = "The ID of the user assigned identity"
  value       = var.enabled ? azurerm_user_assigned_identity.this[0].id : ""
}

output "user_assigned_identity_name" {
  description = "The name of the user assigned identity"
  value       = var.enabled ? azurerm_user_assigned_identity.this[0].name : ""
}

output "principal_id" {
  description = "The principal ID (object ID) of the user assigned identity"
  value       = var.enabled ? azurerm_user_assigned_identity.this[0].principal_id : ""
}

output "client_id" {
  description = "The client ID (application ID) of the user assigned identity"
  value       = var.enabled ? azurerm_user_assigned_identity.this[0].client_id : ""
}

output "tenant_id" {
  description = "The tenant ID of the user assigned identity"
  value       = var.enabled ? azurerm_user_assigned_identity.this[0].tenant_id : ""
}

output "tags" {
  description = "The tags applied to the user assigned identity"
  value       = module.label.tags
}

output "context" {
  description = "Exported context for use by other modules"
  value       = module.label.context
}