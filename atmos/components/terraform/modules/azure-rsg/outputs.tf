output "resource_group_name" {
  description = "The name of the resource group"
  value       = var.enabled ? azurerm_resource_group.this[0].name : ""
}

output "resource_group_id" {
  description = "The ID of the resource group"
  value       = var.enabled ? azurerm_resource_group.this[0].id : ""
}

output "resource_group_location" {
  description = "The location of the resource group"
  value       = var.enabled ? azurerm_resource_group.this[0].location : ""
}

output "tags" {
  description = "The tags applied to the resource group"
  value       = module.label.tags
}

output "context" {
  description = "Exported context for use by other modules"
  value       = module.label.context
}
