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

resource "azurerm_network_security_group" "this" {
  count = var.enabled ? 1 : 0

  name                = coalesce(var.nsg_name, module.label.id)
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = module.label.tags
}

resource "azurerm_network_security_rule" "default_rules" {
  for_each = var.enabled ? var.default_security_rules : {}

  name                        = each.key
  priority                    = each.value.priority
  direction                   = each.value.direction
  access                      = each.value.access
  protocol                    = each.value.protocol
  source_port_range           = each.value.source_port_range
  destination_port_range      = each.value.destination_port_range
  source_port_ranges          = each.value.source_port_ranges
  destination_port_ranges     = each.value.destination_port_ranges
  source_address_prefix       = each.value.source_address_prefix
  destination_address_prefix  = each.value.destination_address_prefix
  source_address_prefixes     = each.value.source_address_prefixes
  destination_address_prefixes = each.value.destination_address_prefixes
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.this[0].name
}

resource "azurerm_network_security_rule" "custom_rules" {
  for_each = var.enabled ? var.custom_security_rules : {}

  name                        = each.key
  priority                    = each.value.priority
  direction                   = each.value.direction
  access                      = each.value.access
  protocol                    = each.value.protocol
  source_port_range           = each.value.source_port_range
  destination_port_range      = each.value.destination_port_range
  source_port_ranges          = each.value.source_port_ranges
  destination_port_ranges     = each.value.destination_port_ranges
  source_address_prefix       = each.value.source_address_prefix
  destination_address_prefix  = each.value.destination_address_prefix
  source_address_prefixes     = each.value.source_address_prefixes
  destination_address_prefixes = each.value.destination_address_prefixes
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.this[0].name
}

resource "azurerm_subnet_network_security_group_association" "this" {
  for_each = var.enabled ? toset(var.subnet_ids) : toset([])

  subnet_id                 = each.value
  network_security_group_id = azurerm_network_security_group.this[0].id
}