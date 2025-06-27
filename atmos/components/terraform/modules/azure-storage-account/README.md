# Azure Storage Account Module

This module creates an Azure Storage Account with comprehensive configuration options, including support for different storage types, Data Lake Gen2, multiple storage services, and integrated private endpoint creation.

## Features

- **Multiple Storage Types**: Support for StorageV2, Data Lake Gen2, Premium Block Blob, and File Storage
- **Flexible Service Configuration**: Enable/disable specific storage services (blob, file, queue, table)
- **Integrated Private Endpoints**: Automatic private endpoint creation for all enabled services
- **Data Lake Gen2 Support**: Hierarchical namespace for big data analytics
- **Advanced Configuration**: Blob properties, queue metrics, file share settings
- **Security Features**: Network rules, HTTPS enforcement, OAuth authentication
- **Global Uniqueness**: Optional random suffix for storage account names

## Storage Account Types

### 1. Standard V2 (General Purpose)
```yaml
azure-storage-account-general:
  vars:
    account_kind: "StorageV2"
    account_tier: "Standard"
    account_replication_type: "LRS"
    enabled_services: ["blob", "file", "queue", "table"]
```

### 2. Data Lake Gen2
```yaml
azure-storage-account-datalake:
  vars:
    account_kind: "StorageV2"
    is_hns_enabled: true  # Enable hierarchical namespace
    enabled_services: ["blob"]
    private_endpoint_services: ["blob", "dfs"]
```

### 3. Premium Block Blob Storage
```yaml
azure-storage-account-premium:
  vars:
    account_kind: "BlockBlobStorage"
    account_tier: "Premium"
    account_replication_type: "LRS"
    enabled_services: ["blob"]
```

### 4. Premium File Storage
```yaml
azure-storage-account-files:
  vars:
    account_kind: "FileStorage"
    account_tier: "Premium"
    account_replication_type: "LRS"
    enabled_services: ["file"]
```

## Private Endpoint Integration

The module automatically creates private endpoints for enabled storage services:

### Supported Services and Subresources
- **Blob**: `blob` subresource
- **File**: `file` subresource  
- **Queue**: `queue` subresource
- **Table**: `table` subresource
- **Data Lake**: `dfs` subresource (when `is_hns_enabled = true`)

### Private DNS Zones
Each service requires its own private DNS zone:
- **Blob**: `privatelink.blob.core.windows.net`
- **File**: `privatelink.file.core.windows.net`
- **Queue**: `privatelink.queue.core.windows.net`
- **Table**: `privatelink.table.core.windows.net`
- **Data Lake**: `privatelink.dfs.core.windows.net`

### Example with Private Endpoints
```yaml
azure-storage-account:
  vars:
    name: "myapp"
    enabled_services: ["blob", "file"]
    create_private_endpoints: true
    private_endpoint_services: ["blob", "file"]
    private_endpoint_subnet_id: "/subscriptions/.../subnets/storage-subnet"
    
    private_endpoint_dns_zone_group_blob:
      name: "blob-dns-group"
      private_dns_zone_ids: ["/subscriptions/.../privateDnsZones/privatelink.blob.core.windows.net"]
    
    private_endpoint_dns_zone_group_file:
      name: "file-dns-group"
      private_dns_zone_ids: ["/subscriptions/.../privateDnsZones/privatelink.file.core.windows.net"]
```

## Advanced Configuration

### Blob Properties
```yaml
blob_properties:
  versioning_enabled: true
  change_feed_enabled: true
  change_feed_retention_in_days: 365
  last_access_time_enabled: true
  delete_retention_policy:
    days: 30
  container_delete_retention_policy:
    days: 30
```

### Queue Properties
```yaml
queue_properties:
  logging:
    delete: true
    read: true
    write: true
    version: "1.0"
    retention_policy_days: 10
  minute_metrics:
    enabled: true
    version: "1.0"
    include_apis: true
    retention_policy_days: 7
```

### File Share Properties
```yaml
share_properties:
  retention_policy:
    days: 30
  smb:
    versions: ["SMB3.0", "SMB3.1.1"]
    authentication_types: ["NTLMv2", "Kerberos"]
    kerberos_ticket_encryption_type: ["RC4-HMAC", "AES-256"]
    channel_encryption_type: ["AES-128-CCM", "AES-256-GCM"]
```

### Network Rules
```yaml
network_rules:
  default_action: "Deny"
  bypass: ["AzureServices"]
  ip_rules: ["203.0.113.0/24"]
  virtual_network_subnet_ids: ["/subscriptions/.../subnets/app-subnet"]
```

## Multiple Instance Examples

### Different Storage Types
```yaml
# General purpose storage
azure-storage-account-general:
  vars:
    name: "general"
    account_kind: "StorageV2"
    enabled_services: ["blob", "file", "queue", "table"]

# Data Lake for analytics
azure-storage-account-datalake:
  vars:
    name: "datalake"
    account_kind: "StorageV2"
    is_hns_enabled: true
    enabled_services: ["blob"]
    private_endpoint_services: ["blob", "dfs"]

# Premium for high performance
azure-storage-account-premium:
  vars:
    name: "premium"
    account_kind: "BlockBlobStorage"
    account_tier: "Premium"
    enabled_services: ["blob"]
```

### Environment-Specific Configurations
```yaml
# Development
azure-storage-account-dev:
  vars:
    name: "dev"
    account_replication_type: "LRS"
    create_private_endpoints: false

# Production
azure-storage-account-prod:
  vars:
    name: "prod"
    account_replication_type: "GRS"
    create_private_endpoints: true
    private_endpoint_services: ["blob", "file", "queue", "table"]
```

## Security Best Practices

### Default Security Settings
- `https_traffic_only_enabled: true`
- `min_tls_version: "TLS1_2"`
- `allow_nested_items_to_be_public: false`
- `public_network_access_enabled: false`
- `default_to_oauth_authentication: true`

### Network Isolation
```yaml
network_rules:
  default_action: "Deny"
  bypass: ["AzureServices"]
  virtual_network_subnet_ids: ["/subscriptions/.../subnets/app-subnet"]
```

### Private Connectivity
```yaml
create_private_endpoints: true
private_endpoint_services: ["blob", "file", "queue", "table"]
private_endpoint_manual_connection: false
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.0 |
| azurerm | = 4.23.0 |
| random | ~> 3.1 |

## Providers

| Name | Version |
|------|---------|
| azurerm | = 4.23.0 |
| random | ~> 3.1 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| enabled | Set to false to prevent the module from creating any resources | `bool` | `true` | no |
| location | The Azure Region where the storage account should be created | `string` | n/a | yes |
| resource_group_name | The name of the resource group | `string` | n/a | yes |
| account_kind | Kind of account (BlobStorage, BlockBlobStorage, FileStorage, Storage, StorageV2) | `string` | `"StorageV2"` | no |
| account_tier | Tier to use (Standard, Premium) | `string` | `"Standard"` | no |
| account_replication_type | Replication type (LRS, GRS, RAGRS, ZRS, GZRS, RAGZRS) | `string` | `"LRS"` | no |
| is_hns_enabled | Enable Hierarchical Namespace for Data Lake Gen2 | `bool` | `false` | no |
| enabled_services | List of storage services to enable | `list(string)` | `["blob"]` | no |
| create_private_endpoints | Whether to create private endpoints | `bool` | `false` | no |
| private_endpoint_services | Services to create private endpoints for | `list(string)` | `["blob"]` | no |
| private_endpoint_subnet_id | Subnet ID for private endpoints | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| storage_account_id | The ID of the storage account |
| storage_account_name | The name of the storage account |
| primary_blob_endpoint | The endpoint URL for blob storage |
| primary_dfs_endpoint | The endpoint URL for DFS storage (Data Lake Gen2) |
| private_endpoint_blob | Private endpoint details for blob service |
| private_endpoint_dfs | Private endpoint details for DFS service |
| storage_account_primary_access_key | The primary access key (sensitive) |

## Data Lake Gen2 Features

When `is_hns_enabled = true`, the storage account becomes a Data Lake Gen2 with:

- **Hierarchical File System**: Organize data in directories and subdirectories
- **POSIX Permissions**: Fine-grained access control
- **DFS Endpoint**: Direct file system access via `dfs.core.windows.net`
- **Analytics Integration**: Optimized for big data analytics workloads
- **Azure Data Lake Analytics**: Compatible with Azure Synapse, Databricks, HDInsight

### Data Lake Example
```yaml
azure-storage-account-analytics:
  vars:
    name: "analytics"
    account_kind: "StorageV2"
    is_hns_enabled: true
    account_replication_type: "GRS"
    
    # Enable both blob and DFS endpoints
    enabled_services: ["blob"]
    create_private_endpoints: true
    private_endpoint_services: ["blob", "dfs"]
    
    # Advanced blob properties for analytics
    blob_properties:
      change_feed_enabled: true
      change_feed_retention_in_days: 365
      last_access_time_enabled: true
```

## Troubleshooting

### Common Issues

1. **Storage Account Name Already Exists**
   - Set `use_random_suffix: true` to add random suffix
   - Use specific `storage_account_name` if needed

2. **Private Endpoint DNS Resolution**
   - Ensure private DNS zones are configured
   - Verify DNS zone groups are properly set

3. **Service Not Available**
   - Check `enabled_services` configuration
   - Verify account kind supports the service

4. **Network Access Issues**
   - Review `network_rules` configuration
   - Check `public_network_access_enabled` setting

### Validation
```bash
# Validate the storage account component
./scripts/validate-component.sh azure-storage-account core-eus-dev
```