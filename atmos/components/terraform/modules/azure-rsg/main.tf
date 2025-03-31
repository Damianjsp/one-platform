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

resource "azurerm_resource_group" "this" {
  count = var.enabled ? 1 : 0

  name     = coalesce(var.resource_group_name, module.label.id)
  location = var.location
  tags     = module.label.tags

  lifecycle {
    prevent_destroy = var.prevent_resource_group_deletion
  }
}
