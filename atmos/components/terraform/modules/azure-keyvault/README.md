# Azure Key Vault Terraform Module

This module creates and manages Azure Key Vault resources with comprehensive security configurations, access policies, and optional secrets, keys, and certificates management.

## Features

### Security & Compliance
- **Purge Protection**: Enabled by default to prevent accidental permanent deletion
- **Soft Delete**: Configurable retention period (7-90 days, default 90)
- **Network Access Control**: Support for IP rules and VNet integration
- **RBAC Authorization**: Optional Azure RBAC for data plane operations
- **Public Network Access**: Disabled by default for enhanced security

### Access Management
- **Current User Access**: Automatically grants full access to deploying user/service principal
- **Custom Access Policies**: Support for multiple granular access policies
- **RBAC Integration**: Option to use Azure RBAC instead of access policies

### Resource Management
- **Secrets Management**: Create and manage Key Vault secrets with expiration and metadata
- **Key Management**: Support for RSA, EC, and RSA-HSM keys with rotation policies
- **Certificate Management**: Import and manage certificates with custom policies
- **Diagnostic Settings**: Comprehensive logging and monitoring integration

### Enterprise Features
- **Certificate Contacts**: Contact information for certificate lifecycle notifications
- **Template Deployment**: Integration with ARM templates and Azure services
- **Disk Encryption**: Support for Azure Disk Encryption scenarios
- **VM Deployment**: Enable certificate retrieval for Virtual Machines

## Usage Examples

### Basic Key Vault
```yaml
azure-keyvault-basic:
  vars:
    name: "secrets"
    location: "eastus"
    resource_group_name: "my-rg"
    sku_name: "standard"
```

### Production Key Vault with Network Restrictions
```yaml
azure-keyvault-prod:
  vars:
    name: "production"
    location: "eastus"
    resource_group_name: "prod-rg"
    sku_name: "premium"
    purge_protection_enabled: true
    public_network_access_enabled: false
    network_acls:
      default_action: "Deny"
      bypass: "AzureServices"
      virtual_network_subnet_ids: ["/subscriptions/.../subnets/private"]
      ip_rules: ["203.0.113.0/24"]
```

### Key Vault with RBAC Authorization
```yaml
azure-keyvault-rbac:
  vars:
    name: "rbac-vault"
    location: "eastus"
    resource_group_name: "security-rg"
    enable_rbac_authorization: true
    add_current_user_access: false  # RBAC handles permissions
```

### Key Vault with Secrets and Keys
```yaml
azure-keyvault-full:
  vars:
    name: "application"
    location: "eastus"
    resource_group_name: "app-rg"
    secrets:
      database-connection:
        value: "Server=myserver;Database=mydb;..."
        content_type: "connection-string"
        expiration_date: "2025-12-31T23:59:59Z"
      api-key:
        value: "super-secret-api-key"
        content_type: "api-key"
    keys:
      encryption-key:
        key_type: "RSA"
        key_size: 2048
        key_opts: ["encrypt", "decrypt", "sign", "verify"]
        rotation_policy:
          expire_after: "P2Y"  # 2 years
          notify_before_expiry: "P30D"  # 30 days
```

### Key Vault with Custom Access Policies
```yaml
azure-keyvault-access:
  vars:
    name: "shared"
    location: "eastus"
    resource_group_name: "shared-rg"
    access_policies:
      app-service:
        object_id: "00000000-0000-0000-0000-000000000000"
        secret_permissions: ["Get", "List"]
        key_permissions: ["Get", "Decrypt", "Encrypt"]
      admin-group:
        object_id: "11111111-1111-1111-1111-111111111111"
        secret_permissions: ["Get", "List", "Set", "Delete"]
        key_permissions: ["Get", "List", "Create", "Delete", "Update"]
        certificate_permissions: ["Get", "List", "Create", "Delete", "Update"]
```

### Key Vault with Diagnostic Settings
```yaml
azure-keyvault-monitoring:
  vars:
    name: "monitored"
    location: "eastus"
    resource_group_name: "monitoring-rg"
    diagnostic_settings:
      log_analytics_workspace_id: "/subscriptions/.../workspaces/my-workspace"
      log_categories: ["AuditEvent", "AzurePolicyEvaluationDetails"]
      metric_categories: ["AllMetrics"]
```

## Security Considerations

### Default Security Posture
- **Purge Protection**: Enabled by default (cannot be disabled once enabled)
- **Soft Delete**: 90-day retention period
- **Public Access**: Disabled by default
- **HTTPS Only**: All communication encrypted in transit
- **Current User Access**: Automatically granted for initial setup

### Network Security
- Use `network_acls` to restrict access to specific IP ranges or VNets
- Consider disabling public network access for production environments
- Implement Private Endpoints for complete network isolation

### Access Control
- Use RBAC authorization for modern, role-based access control
- Implement least-privilege access policies
- Regular review and rotation of access permissions
- Monitor access through diagnostic logs

### Key and Secret Management
- Use appropriate key types and sizes for your security requirements
- Implement key rotation policies for long-lived keys
- Set expiration dates for secrets and certificates
- Use HSM-backed keys for highest security requirements

## Integration with Other Azure Services

### Azure Services Integration
- **ARM Templates**: Enable `enabled_for_template_deployment`
- **Virtual Machines**: Enable `enabled_for_deployment` for certificate access
- **Disk Encryption**: Enable `enabled_for_disk_encryption` for Azure Disk Encryption

### Monitoring and Compliance
- Integrate with Azure Monitor for comprehensive logging
- Use Azure Policy for compliance enforcement
- Implement Azure Security Center recommendations

## Terraform Configuration

### Provider Requirements
- `azurerm` provider version 4.23.0
- `azuread` provider version ~> 3.0

### Module Dependencies
- Cloud Posse Label module for consistent naming and tagging

## Outputs

The module provides comprehensive outputs including:
- Key Vault metadata (ID, URI, name, location)
- Security configuration details
- Created secrets, keys, and certificates metadata
- Access policy and network ACL information
- Diagnostic settings configuration