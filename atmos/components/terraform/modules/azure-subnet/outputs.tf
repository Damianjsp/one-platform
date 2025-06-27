output "subnet_id" {
  description = "The ID of the subnet"
  value       = var.enabled ? azurerm_subnet.this[0].id : null
}

output "subnet_name" {
  description = "The name of the subnet"
  value       = var.enabled ? azurerm_subnet.this[0].name : null
}

output "subnet_address_prefixes" {
  description = "The address prefixes of the subnet"
  value       = var.enabled ? azurerm_subnet.this[0].address_prefixes : null
}

output "tags" {
  description = "The tags applied to the subnet"
  value       = module.label.tags
}

output "context" {
  description = "Exported context for use by other modules"
  value       = module.label.context
}