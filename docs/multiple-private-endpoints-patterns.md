# Multiple Private Endpoints Patterns

This document demonstrates how to create multiple private endpoint instances using the azure-private-endpoint component with different configurations.

## Key Concepts

### Component Instance Naming
Each private endpoint instance must have a **unique component name** in the stack:
- `azure-private-endpoint-storage-blob`
- `azure-private-endpoint-storage-file`
- `azure-private-endpoint-keyvault`
- `azure-private-endpoint-sql`

### Naming Differentiation
Use the `name` and `attributes` variables to create unique resource names:
```yaml
vars:
  name: "stgblob"
  attributes: ["blob"]  # Results in: eusdevstgbloblazylabs
```

## Supported Multiple Instance Scenarios

### 1. Same Service, Different Subresources
Create multiple endpoints for the same Azure service targeting different subresources:

```yaml
# Storage Account - Blob Service
azure-private-endpoint-storage-blob:
  metadata:
    component: azure-private-endpoint
  vars:
    name: "stgblob"
    subresource_names: ["blob"]

# Storage Account - File Service (Same storage account)
azure-private-endpoint-storage-file:
  metadata:
    component: azure-private-endpoint
  vars:
    name: "stgfile"
    subresource_names: ["file"]
```

### 2. Different Services
Create endpoints for completely different Azure services:

```yaml
# Key Vault
azure-private-endpoint-keyvault:
  metadata:
    component: azure-private-endpoint
  vars:
    name: "keyvault"
    subresource_names: ["vault"]

# SQL Database
azure-private-endpoint-sql:
  metadata:
    component: azure-private-endpoint
  vars:
    name: "sqldb"
    subresource_names: ["sqlServer"]
```

### 3. Different Configuration Requirements
Create endpoints with different connection and DNS settings:

```yaml
# Automatic Connection
azure-private-endpoint-storage:
  metadata:
    component: azure-private-endpoint
  vars:
    name: "storage"
    is_manual_connection: false

# Manual Approval Required
azure-private-endpoint-sql:
  metadata:
    component: azure-private-endpoint
  vars:
    name: "sqldb"
    is_manual_connection: true
    request_message: "Please approve connection for dev environment"
```

### 4. Custom IP Configurations
Create endpoints with specific IP addressing:

```yaml
# Standard Dynamic IP
azure-private-endpoint-keyvault:
  metadata:
    component: azure-private-endpoint
  vars:
    name: "keyvault"
    ip_configurations: []

# Custom Static IP
azure-private-endpoint-cosmos:
  metadata:
    component: azure-private-endpoint
  vars:
    name: "cosmos"
    ip_configurations:
      - name: "cosmos-ip-config"
        private_ip_address: "10.0.1.100"
        subresource_name: "sql"
```

## Resource Naming Results

With the naming convention `{environment}{stage}{name}{namespace}`:

| Component Instance | Name Variable | Attributes | Final Resource Name |
|-------------------|---------------|------------|-------------------|
| azure-private-endpoint-storage-blob | "stgblob" | ["blob"] | eusdevstgbloblazylabs |
| azure-private-endpoint-storage-file | "stgfile" | ["file"] | eusdevstgfilelazylabs |
| azure-private-endpoint-keyvault | "keyvault" | [] | eusdevkeyvaultlazylabs |
| azure-private-endpoint-sql | "sqldb" | [] | eusdevsqldblazylabs |

## DNS Zone Considerations

Each service type typically requires its own private DNS zone:

| Service Type | Private DNS Zone |
|-------------|------------------|
| Storage Blob | privatelink.blob.core.windows.net |
| Storage File | privatelink.file.core.windows.net |
| Key Vault | privatelink.vaultcore.azure.net |
| SQL Database | privatelink.database.windows.net |
| Cosmos DB | privatelink.documents.azure.com |

## Best Practices

1. **Unique Component Names**: Always use descriptive, unique component names
2. **Meaningful Name Variables**: Use clear `name` values that indicate the service and purpose
3. **Consistent Attributes**: Use `attributes` to further differentiate similar services
4. **Service-Specific DNS**: Configure appropriate private DNS zones for each service type
5. **Connection Types**: Choose manual vs automatic connection based on security requirements
6. **IP Planning**: Use custom IP configurations when network design requires specific addressing

## Complete Example Stack

```yaml
components:
  terraform:
    # Multiple private endpoints for different services
    azure-private-endpoint-storage-blob:
      metadata:
        component: azure-private-endpoint
      vars:
        name: "stgblob"
        attributes: ["blob"]
        subresource_names: ["blob"]
        # ... other configuration

    azure-private-endpoint-storage-file:
      metadata:
        component: azure-private-endpoint
      vars:
        name: "stgfile"
        attributes: ["file"]
        subresource_names: ["file"]
        # ... other configuration

    azure-private-endpoint-keyvault:
      metadata:
        component: azure-private-endpoint
      vars:
        name: "keyvault"
        subresource_names: ["vault"]
        is_manual_connection: true
        # ... other configuration
```

This approach allows unlimited private endpoint instances with complete configuration flexibility while maintaining consistent naming and resource management.