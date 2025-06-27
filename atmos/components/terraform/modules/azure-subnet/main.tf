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

resource "azurerm_subnet" "this" {
  count = var.enabled ? 1 : 0

  name                              = coalesce(var.subnet_name, module.label.id)
  resource_group_name               = var.resource_group_name
  virtual_network_name              = var.virtual_network_name
  address_prefixes                  = var.address_prefixes
  private_endpoint_network_policies = var.private_endpoint_network_policies
  service_endpoints                 = var.service_endpoints
  service_endpoint_policy_ids       = var.service_endpoint_policy_ids

  dynamic "delegation" {
    for_each = var.delegations
    content {
      name = delegation.value.name
      service_delegation {
        name    = delegation.value.service_delegation.name
        actions = delegation.value.service_delegation.actions
      }
    }
  }
}
