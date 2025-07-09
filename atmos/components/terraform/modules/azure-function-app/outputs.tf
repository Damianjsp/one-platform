output "function_app_id" {
  description = "The ID of the Function App"
  value       = var.enabled ? (var.os_type == "Linux" ? azurerm_linux_function_app.this[0].id : azurerm_windows_function_app.this[0].id) : null
}

output "function_app_name" {
  description = "The name of the Function App"
  value       = var.enabled ? (var.os_type == "Linux" ? azurerm_linux_function_app.this[0].name : azurerm_windows_function_app.this[0].name) : null
}

output "function_app_default_hostname" {
  description = "The default hostname associated with the Function App"
  value       = var.enabled ? (var.os_type == "Linux" ? azurerm_linux_function_app.this[0].default_hostname : azurerm_windows_function_app.this[0].default_hostname) : null
}

output "function_app_outbound_ip_addresses" {
  description = "A comma separated list of outbound IP addresses"
  value       = var.enabled ? (var.os_type == "Linux" ? azurerm_linux_function_app.this[0].outbound_ip_addresses : azurerm_windows_function_app.this[0].outbound_ip_addresses) : null
}

output "function_app_possible_outbound_ip_addresses" {
  description = "A comma separated list of outbound IP addresses - not all of which are necessarily in use"
  value       = var.enabled ? (var.os_type == "Linux" ? azurerm_linux_function_app.this[0].possible_outbound_ip_addresses : azurerm_windows_function_app.this[0].possible_outbound_ip_addresses) : null
}

output "function_app_site_credential" {
  description = "A site_credential block containing the deployment credentials for the Function App"
  value       = var.enabled ? (var.os_type == "Linux" ? azurerm_linux_function_app.this[0].site_credential : azurerm_windows_function_app.this[0].site_credential) : null
  sensitive   = true
}

output "function_app_identity" {
  description = "An identity block containing the managed identity information for the Function App"
  value       = var.enabled ? (var.os_type == "Linux" ? azurerm_linux_function_app.this[0].identity : azurerm_windows_function_app.this[0].identity) : null
}

output "function_app_custom_domain_verification_id" {
  description = "The identifier used by App Service to perform domain ownership verification via DNS TXT record"
  value       = var.enabled ? (var.os_type == "Linux" ? azurerm_linux_function_app.this[0].custom_domain_verification_id : azurerm_windows_function_app.this[0].custom_domain_verification_id) : null
}

output "function_app_kind" {
  description = "The kind of the Function App"
  value       = var.enabled ? (var.os_type == "Linux" ? azurerm_linux_function_app.this[0].kind : azurerm_windows_function_app.this[0].kind) : null
}

output "tags" {
  description = "The tags applied to the Function App"
  value       = module.label.tags
}

output "context" {
  description = "Exported context for use by other modules"
  value       = module.label.context
}