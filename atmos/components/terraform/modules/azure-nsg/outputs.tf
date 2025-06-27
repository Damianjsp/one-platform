output "id" {
  description = "The ID of the Network Security Group"
  value       = var.enabled ? azurerm_network_security_group.this[0].id : null
}

output "name" {
  description = "The name of the Network Security Group"
  value       = var.enabled ? azurerm_network_security_group.this[0].name : null
}

output "location" {
  description = "The location/region where the Network Security Group is located"
  value       = var.enabled ? azurerm_network_security_group.this[0].location : null
}

output "resource_group_name" {
  description = "The name of the resource group in which the Network Security Group is created"
  value       = var.enabled ? azurerm_network_security_group.this[0].resource_group_name : null
}

output "security_rules" {
  description = "Collection of security rules created for this Network Security Group"
  value = var.enabled ? concat(
    [for rule in azurerm_network_security_rule.default_rules : {
      name                         = rule.name
      priority                     = rule.priority
      direction                    = rule.direction
      access                      = rule.access
      protocol                    = rule.protocol
      source_port_range           = rule.source_port_range
      destination_port_range      = rule.destination_port_range
      source_port_ranges          = rule.source_port_ranges
      destination_port_ranges     = rule.destination_port_ranges
      source_address_prefix       = rule.source_address_prefix
      destination_address_prefix  = rule.destination_address_prefix
      source_address_prefixes     = rule.source_address_prefixes
      destination_address_prefixes = rule.destination_address_prefixes
    }],
    [for rule in azurerm_network_security_rule.custom_rules : {
      name                         = rule.name
      priority                     = rule.priority
      direction                    = rule.direction
      access                      = rule.access
      protocol                    = rule.protocol
      source_port_range           = rule.source_port_range
      destination_port_range      = rule.destination_port_range
      source_port_ranges          = rule.source_port_ranges
      destination_port_ranges     = rule.destination_port_ranges
      source_address_prefix       = rule.source_address_prefix
      destination_address_prefix  = rule.destination_address_prefix
      source_address_prefixes     = rule.source_address_prefixes
      destination_address_prefixes = rule.destination_address_prefixes
    }]
  ) : []
}

output "subnet_associations" {
  description = "Map of subnet associations with this Network Security Group"
  value = var.enabled ? {
    for assoc in azurerm_subnet_network_security_group_association.this :
    assoc.subnet_id => assoc.network_security_group_id
  } : {}
}