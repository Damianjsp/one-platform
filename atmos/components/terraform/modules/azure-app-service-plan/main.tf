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

resource "azurerm_service_plan" "this" {
  count = var.enabled ? 1 : 0

  name                = coalesce(var.app_service_plan_name, module.label.id)
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = var.os_type
  sku_name            = var.sku_name

  worker_count             = var.worker_count
  per_site_scaling_enabled = var.per_site_scaling_enabled
  zone_balancing_enabled   = var.zone_balancing_enabled

  tags = module.label.tags
}