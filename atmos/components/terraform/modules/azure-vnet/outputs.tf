output "vnet_id" {
  description = "The ID of the virtual network"
  value       = var.enabled ? azurerm_virtual_network.this[0].id : null
}

output "vnet_name" {
  description = "The name of the virtual network"
  value       = var.enabled ? azurerm_virtual_network.this[0].name : null
}

output "vnet_address_space" {
  description = "The address space of the virtual network"
  value       = var.enabled ? azurerm_virtual_network.this[0].address_space : null
}

output "tags" {
  description = "The tags applied to the virtual network"
  value       = module.label.tags
}

output "context" {
  description = "Exported context for use by other modules"
  value       = module.label.context
}
