output "app_service_plan_id" {
  description = "The ID of the App Service Plan"
  value       = var.enabled ? azurerm_service_plan.this[0].id : null
}

output "app_service_plan_name" {
  description = "The name of the App Service Plan"
  value       = var.enabled ? azurerm_service_plan.this[0].name : null
}

output "app_service_plan_kind" {
  description = "The kind of the App Service Plan"
  value       = var.enabled ? azurerm_service_plan.this[0].kind : null
}

output "app_service_plan_os_type" {
  description = "The OS type for the App Service Plan"
  value       = var.enabled ? azurerm_service_plan.this[0].os_type : null
}

output "app_service_plan_sku_name" {
  description = "The SKU name of the App Service Plan"
  value       = var.enabled ? azurerm_service_plan.this[0].sku_name : null
}

output "app_service_plan_worker_count" {
  description = "The number of workers for the App Service Plan"
  value       = var.enabled ? azurerm_service_plan.this[0].worker_count : null
}

output "tags" {
  description = "The tags applied to the App Service Plan"
  value       = module.label.tags
}

output "context" {
  description = "Exported context for use by other modules"
  value       = module.label.context
}