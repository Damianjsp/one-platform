output "private_endpoint_id" {
  description = "The ID of the private endpoint"
  value       = var.enabled ? azurerm_private_endpoint.this[0].id : null
}

output "private_endpoint_name" {
  description = "The name of the private endpoint"
  value       = var.enabled ? azurerm_private_endpoint.this[0].name : null
}

output "network_interface" {
  description = "A network_interface block"
  value       = var.enabled ? azurerm_private_endpoint.this[0].network_interface : null
}

output "private_service_connection" {
  description = "A private_service_connection block"
  value       = var.enabled ? azurerm_private_endpoint.this[0].private_service_connection : null
}

output "custom_dns_configs" {
  description = "A custom_dns_configs block"
  value       = var.enabled ? azurerm_private_endpoint.this[0].custom_dns_configs : null
}

output "private_dns_zone_configs" {
  description = "A private_dns_zone_configs block"
  value       = var.enabled ? azurerm_private_endpoint.this[0].private_dns_zone_configs : null
}

output "tags" {
  description = "The tags applied to the private endpoint"
  value       = module.label.tags
}

output "context" {
  description = "Exported context for use by other modules"
  value       = module.label.context
}