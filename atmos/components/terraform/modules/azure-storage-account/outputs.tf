output "storage_account_id" {
  description = "The ID of the storage account"
  value       = var.enabled ? azurerm_storage_account.this[0].id : null
}

output "storage_account_name" {
  description = "The name of the storage account"
  value       = var.enabled ? azurerm_storage_account.this[0].name : null
}

output "storage_account_primary_location" {
  description = "The primary location of the storage account"
  value       = var.enabled ? azurerm_storage_account.this[0].primary_location : null
}

output "storage_account_secondary_location" {
  description = "The secondary location of the storage account"
  value       = var.enabled ? azurerm_storage_account.this[0].secondary_location : null
}

output "storage_account_kind" {
  description = "The kind of the storage account"
  value       = var.enabled ? azurerm_storage_account.this[0].account_kind : null
}

output "storage_account_tier" {
  description = "The tier of the storage account"
  value       = var.enabled ? azurerm_storage_account.this[0].account_tier : null
}

output "storage_account_replication_type" {
  description = "The replication type of the storage account"
  value       = var.enabled ? azurerm_storage_account.this[0].account_replication_type : null
}

output "is_hns_enabled" {
  description = "Is Hierarchical Namespace enabled? (Data Lake Gen2)"
  value       = var.enabled ? azurerm_storage_account.this[0].is_hns_enabled : null
}

# Access Keys
output "storage_account_primary_access_key" {
  description = "The primary access key for the storage account"
  value       = var.enabled ? azurerm_storage_account.this[0].primary_access_key : null
  sensitive   = true
}

output "storage_account_secondary_access_key" {
  description = "The secondary access key for the storage account"
  value       = var.enabled ? azurerm_storage_account.this[0].secondary_access_key : null
  sensitive   = true
}

# Connection Strings
output "storage_account_primary_connection_string" {
  description = "The connection string associated with the primary location"
  value       = var.enabled ? azurerm_storage_account.this[0].primary_connection_string : null
  sensitive   = true
}

output "storage_account_secondary_connection_string" {
  description = "The connection string associated with the secondary location"
  value       = var.enabled ? azurerm_storage_account.this[0].secondary_connection_string : null
  sensitive   = true
}

# Service Endpoints
output "primary_blob_endpoint" {
  description = "The endpoint URL for blob storage in the primary location"
  value       = var.enabled ? azurerm_storage_account.this[0].primary_blob_endpoint : null
}

output "secondary_blob_endpoint" {
  description = "The endpoint URL for blob storage in the secondary location"
  value       = var.enabled ? azurerm_storage_account.this[0].secondary_blob_endpoint : null
}

output "primary_queue_endpoint" {
  description = "The endpoint URL for queue storage in the primary location"
  value       = var.enabled && contains(var.enabled_services, "queue") ? azurerm_storage_account.this[0].primary_queue_endpoint : null
}

output "secondary_queue_endpoint" {
  description = "The endpoint URL for queue storage in the secondary location"
  value       = var.enabled && contains(var.enabled_services, "queue") ? azurerm_storage_account.this[0].secondary_queue_endpoint : null
}

output "primary_table_endpoint" {
  description = "The endpoint URL for table storage in the primary location"
  value       = var.enabled && contains(var.enabled_services, "table") ? azurerm_storage_account.this[0].primary_table_endpoint : null
}

output "secondary_table_endpoint" {
  description = "The endpoint URL for table storage in the secondary location"
  value       = var.enabled && contains(var.enabled_services, "table") ? azurerm_storage_account.this[0].secondary_table_endpoint : null
}

output "primary_file_endpoint" {
  description = "The endpoint URL for file storage in the primary location"
  value       = var.enabled && contains(var.enabled_services, "file") ? azurerm_storage_account.this[0].primary_file_endpoint : null
}

output "secondary_file_endpoint" {
  description = "The endpoint URL for file storage in the secondary location"
  value       = var.enabled && contains(var.enabled_services, "file") ? azurerm_storage_account.this[0].secondary_file_endpoint : null
}

# Data Lake Gen2 endpoints
output "primary_dfs_endpoint" {
  description = "The endpoint URL for DFS storage in the primary location (Data Lake Gen2)"
  value       = var.enabled && var.is_hns_enabled ? azurerm_storage_account.this[0].primary_dfs_endpoint : null
}

output "secondary_dfs_endpoint" {
  description = "The endpoint URL for DFS storage in the secondary location (Data Lake Gen2)"
  value       = var.enabled && var.is_hns_enabled ? azurerm_storage_account.this[0].secondary_dfs_endpoint : null
}

# Private Endpoint Outputs
output "private_endpoint_blob" {
  description = "Private endpoint configuration for blob service"
  value = var.enabled && var.create_private_endpoints && contains(var.private_endpoint_services, "blob") ? {
    id   = module.private_endpoint_blob[0].private_endpoint_id
    name = module.private_endpoint_blob[0].private_endpoint_name
    network_interface = module.private_endpoint_blob[0].network_interface
  } : null
}

output "private_endpoint_file" {
  description = "Private endpoint configuration for file service"
  value = var.enabled && var.create_private_endpoints && contains(var.private_endpoint_services, "file") ? {
    id   = module.private_endpoint_file[0].private_endpoint_id
    name = module.private_endpoint_file[0].private_endpoint_name
    network_interface = module.private_endpoint_file[0].network_interface
  } : null
}

output "private_endpoint_queue" {
  description = "Private endpoint configuration for queue service"
  value = var.enabled && var.create_private_endpoints && contains(var.private_endpoint_services, "queue") ? {
    id   = module.private_endpoint_queue[0].private_endpoint_id
    name = module.private_endpoint_queue[0].private_endpoint_name
    network_interface = module.private_endpoint_queue[0].network_interface
  } : null
}

output "private_endpoint_table" {
  description = "Private endpoint configuration for table service"
  value = var.enabled && var.create_private_endpoints && contains(var.private_endpoint_services, "table") ? {
    id   = module.private_endpoint_table[0].private_endpoint_id
    name = module.private_endpoint_table[0].private_endpoint_name
    network_interface = module.private_endpoint_table[0].network_interface
  } : null
}

output "private_endpoint_dfs" {
  description = "Private endpoint configuration for dfs service (Data Lake Gen2)"
  value = var.enabled && var.create_private_endpoints && contains(var.private_endpoint_services, "dfs") ? {
    id   = module.private_endpoint_dfs[0].private_endpoint_id
    name = module.private_endpoint_dfs[0].private_endpoint_name
    network_interface = module.private_endpoint_dfs[0].network_interface
  } : null
}

# Service Configuration
output "enabled_services" {
  description = "List of enabled storage services"
  value       = var.enabled_services
}

# Labels and Tags
output "tags" {
  description = "The tags applied to the storage account"
  value       = module.label.tags
}

output "context" {
  description = "Exported context for use by other modules"
  value       = module.label.context
}