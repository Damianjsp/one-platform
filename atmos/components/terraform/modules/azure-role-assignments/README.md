# Azure Role Assignments Component

This component creates multiple Azure Role Assignments following One Platform standards. It supports both individual role assignments and matrix-style configurations for complex scenarios.

## Overview

The role assignment component solves the maintainability challenge of managing multiple role assignments across different Azure services. Instead of creating individual role assignment components, this module allows you to configure multiple assignments in a single, manageable configuration.

## Key Features

- **Multiple Assignments**: Create multiple role assignments with a single component
- **Matrix Support**: Advanced matrix-style configuration for complex scenarios
- **Role Validation**: Built-in validation against approved Azure built-in roles
- **Flexible Identity Types**: Supports both user-assigned and system-assigned managed identities
- **Cross-Service Support**: Handle authentication chains across multiple Azure services
- **Security Compliance**: Custom Checkov checks for security validation

## Usage Patterns

### 1. Basic Role Assignments

```yaml
components:
  terraform:
    azure-role-assignments-example:
      metadata:
        component: azure-role-assignments
      settings:
        depends_on:
          1:
            component: "azure-function-app-api"
          2:
            component: "azure-storage-account-general"
      vars:
        name: "basic"
        role_assignments:
          function-storage-access:
            principal_id: !terraform.output azure-function-app-api ".function_app_identity.0.principal_id"
            principal_type: "system_assigned"
            role_definition_name: "Storage Blob Data Reader"
            scope: !terraform.output azure-storage-account-general ".storage_account_id"
            description: "Function App read access to storage"
```

### 2. Function App Accessing Multiple Services

```yaml
azure-role-assignments-function-services:
  metadata:
    component: azure-role-assignments
  settings:
    depends_on:
      1:
        component: "azure-function-app-api"
      2:
        component: "azure-storage-account-data"
      3:
        component: "azure-keyvault-secrets"
  vars:
    name: "function"
    attributes: ["services"]
    role_assignments:
      # Function App → Storage Access
      funcapp-storage-blob-reader:
        principal_id: !terraform.output azure-function-app-api ".function_app_identity.0.principal_id"
        principal_type: "system_assigned"
        role_definition_name: "Storage Blob Data Reader"
        scope: !terraform.output azure-storage-account-data ".storage_account_id"
        description: "Allow Function App to read from data storage"
      
      # Function App → Key Vault Access
      funcapp-keyvault-secrets:
        principal_id: !terraform.output azure-function-app-api ".function_app_identity.0.principal_id"
        principal_type: "system_assigned"
        role_definition_name: "Key Vault Secrets User"
        scope: !terraform.output azure-keyvault-secrets ".key_vault_id"
        description: "Allow Function App to read secrets from Key Vault"
```

### 3. Matrix-Style Complex Scenarios

```yaml
azure-role-assignments-matrix:
  metadata:
    component: azure-role-assignments
  vars:
    name: "matrix"
    attributes: ["multi"]
    assignment_matrix:
      principals:
        api-function: !terraform.output azure-function-app-api ".function_app_identity.0.principal_id"
        processor-function: !terraform.output azure-function-app-processor ".function_app_identity.0.principal_id"
        data-umi: !terraform.output azure-user-managed-identity-data ".principal_id"
      scopes:
        storage-input: !terraform.output azure-storage-account-input ".storage_account_id"
        storage-output: !terraform.output azure-storage-account-output ".storage_account_id"
        keyvault-config: !terraform.output azure-keyvault-config ".key_vault_id"
      assignments:
        api-function-access:
          principal_key: "api-function"
          scope_key: "storage-input"
          roles: ["Storage Blob Data Reader"]
        processor-function-access:
          principal_key: "processor-function"
          scope_key: "storage-output"
          roles: ["Storage Blob Data Contributor"]
        data-umi-access:
          principal_key: "data-umi"
          scope_key: "keyvault-config"
          roles: ["Key Vault Secrets User"]
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| enabled | Set to false to prevent the module from creating any resources | `bool` | `true` | no |
| role_assignments | Map of role assignments to create | `map(object)` | `{}` | no |
| assignment_matrix | Matrix-style assignment configuration for complex scenarios | `object` | `null` | no |
| approved_roles | List of approved Azure built-in role names for validation | `list(string)` | [comprehensive list] | no |
| skip_service_principal_aad_check | Skip the Azure Active Directory check for the service principal | `bool` | `false` | no |

### Role Assignment Object Structure

```terraform
role_assignment = {
  principal_id         = string           # Principal ID (User/System Managed Identity)
  principal_type       = string           # "user_assigned" or "system_assigned"
  role_definition_name = string           # Azure built-in role name
  scope               = string            # Target resource ID
  description         = string            # Assignment description (optional)
}
```

### Assignment Matrix Object Structure

```terraform
assignment_matrix = {
  principals = map(string)               # name -> principal_id mapping
  scopes     = map(string)               # name -> resource_id mapping
  assignments = map(object({
    principal_key = string               # key from principals map
    scope_key     = string               # key from scopes map
    roles         = list(string)         # list of role names
  }))
}
```

## Outputs

| Name | Description |
|------|-------------|
| role_assignment_ids | Map of role assignment IDs keyed by assignment name |
| role_assignment_details | Complete details of all role assignments created |
| assignment_count | Total number of role assignments created |
| assignments_by_principal | Role assignments grouped by principal ID |
| assignments_by_role | Role assignments grouped by role definition name |
| assignments_by_scope | Role assignments grouped by scope (target resource) |
| validated_role_count | Number of roles that passed validation |
| matrix_assignment_count | Number of assignments created from matrix configuration |

## Approved Azure Roles

The component validates against a comprehensive list of approved Azure built-in roles:

### Storage Roles
- `Storage Blob Data Owner`
- `Storage Blob Data Contributor`
- `Storage Blob Data Reader`
- `Storage Queue Data Contributor`
- `Storage Queue Data Reader`
- `Storage Queue Data Message Processor`
- `Storage Queue Data Message Sender`

### Key Vault Roles
- `Key Vault Administrator`
- `Key Vault Secrets Officer`
- `Key Vault Secrets User`
- `Key Vault Crypto Officer`
- `Key Vault Crypto User`

### Database Roles
- `DocumentDB Account Contributor`
- `SQL DB Contributor`
- `SQL Managed Instance Contributor`
- `SQL Server Contributor`

### General Roles
- `Reader`
- `Contributor`
- `Managed Identity Operator`
- `Managed Identity Contributor`

### Monitoring Roles
- `Log Analytics Contributor`
- `Log Analytics Reader`
- `Monitoring Contributor`
- `Monitoring Reader`

## Security Checks

This component includes custom Checkov security checks:

- **CKV_OP_AZURE_RA_1**: Role Assignment uses label module
- **CKV_OP_AZURE_RA_2**: Role Assignment uses approved built-in roles
- **CKV_OP_AZURE_RA_3**: Role Assignment has valid principal ID
- **CKV_OP_AZURE_RA_4**: Role Assignment has appropriate scope
- **CKV_OP_AZURE_RA_5**: Role Assignment has description for audit
- **CKV_OP_AZURE_RA_6**: Role Assignment follows least privilege principle

## Common Integration Patterns

### 1. Function App Full Stack Access

```yaml
# Function App accessing Storage, Key Vault services
vars:
  role_assignments:
    funcapp-storage-read:
      principal_id: !terraform.output azure-function-app-api ".function_app_identity.0.principal_id"
      principal_type: "system_assigned"
      role_definition_name: "Storage Blob Data Reader"
      scope: !terraform.output azure-storage-account-data ".storage_account_id"
    funcapp-keyvault-secrets:
      principal_id: !terraform.output azure-function-app-api ".function_app_identity.0.principal_id"
      principal_type: "system_assigned"
      role_definition_name: "Key Vault Secrets User"
      scope: !terraform.output azure-keyvault-config ".key_vault_id"
```

### 2. User Managed Identity Multi-Service Access

```yaml
# UMI accessing multiple storage services with different permissions
vars:
  role_assignments:
    umi-blob-read:
      principal_id: !terraform.output azure-user-managed-identity-processor ".principal_id"
      principal_type: "user_assigned"
      role_definition_name: "Storage Blob Data Reader"
      scope: !terraform.output azure-storage-account-input ".storage_account_id"
    umi-blob-write:
      principal_id: !terraform.output azure-user-managed-identity-processor ".principal_id"
      principal_type: "user_assigned"
      role_definition_name: "Storage Blob Data Contributor"
      scope: !terraform.output azure-storage-account-output ".storage_account_id"
    umi-queue-full:
      principal_id: !terraform.output azure-user-managed-identity-processor ".principal_id"
      principal_type: "user_assigned"
      role_definition_name: "Storage Queue Data Contributor"
      scope: !terraform.output azure-storage-account-processing ".storage_account_id"
```

### 3. Database Access Pattern

```yaml
# Function App accessing database services
vars:
  assignment_matrix:
    principals:
      api-function: !terraform.output azure-function-app-api ".function_app_identity.0.principal_id"
      worker-function: !terraform.output azure-function-app-worker ".function_app_identity.0.principal_id"
    scopes:
      cosmos-db: !terraform.output azure-cosmosdb-account ".cosmos_account_id"
      sql-database: !terraform.output azure-sql-database ".sql_database_id"
    assignments:
      api-database-access:
        principal_key: "api-function"
        scope_key: "cosmos-db"
        roles: ["DocumentDB Account Contributor"]
      worker-sql-access:
        principal_key: "worker-function"
        scope_key: "sql-database"
        roles: ["SQL DB Contributor"]
```

## Dependencies

- Target Azure resources (Function Apps, Storage Accounts, Key Vaults, etc.)
- Managed identities (user-assigned or system-assigned)
- Properly configured label module variables

## Best Practices

1. **Principle of Least Privilege**: Use the most restrictive role that provides necessary permissions
2. **Clear Descriptions**: Always provide meaningful descriptions for audit purposes
3. **Dependency Management**: Use explicit component dependencies to ensure proper deployment order
4. **Role Validation**: Stick to approved built-in roles for security compliance
5. **Matrix for Scale**: Use matrix configuration for complex scenarios with multiple principals and scopes
6. **Environment Separation**: Use different role assignments for dev/staging/prod environments

## Authentication Flow Example

1. **Azure Service** (Function App, etc.) uses `DefaultAzureCredential` for authentication
2. **Role Assignment** grants appropriate permissions to the service's managed identity
3. **Azure AD** provides token for authentication
4. **No API Keys** needed - managed identity handles authentication
5. **Cross-Service Access** configured with appropriate roles in same component

This approach provides a scalable, maintainable solution for managing complex cross-service authentication in Azure.