# Azure Resource Group Module

This module creates an Azure Resource Group with standardized naming conventions and consistent tagging. It serves as the foundation component for all other Azure resources in the One Platform architecture.

## Features

- **Standardized Naming**: Uses cloudposse/label for consistent resource naming
- **Conditional Creation**: Enable/disable with `var.enabled` flag
- **Consistent Tagging**: Automatic tag application based on label configuration
- **Foundation Component**: No dependencies, serves as base for other components
- **Custom Naming**: Optional custom resource group name override
- **Location Flexibility**: Deploy to any Azure region

## Usage

### Basic Resource Group
```yaml
components:
  terraform:
    azure-resource-group:
      vars:
        name: "services"
        location: "East US"
        attributes: ["shared"]
```

### Multiple Resource Groups
```yaml
components:
  terraform:
    # Application resource group
    azure-resource-group-app:
      metadata:
        component: azure-resource-group
      vars:
        name: "application"
        location: "East US"
        attributes: ["web"]
    
    # Data resource group
    azure-resource-group-data:
      metadata:
        component: azure-resource-group
      vars:
        name: "data"
        location: "East US"
        attributes: ["storage"]
```

### Custom Resource Group Name
```yaml
components:
  terraform:
    azure-resource-group:
      vars:
        name: "services"
        location: "East US"
        resource_group_name: "my-custom-rg-name"  # Override generated name
```

## Naming Convention

Resource groups follow the pattern: `{environment}{stage}{name}{namespace}`

### Examples
| Environment | Stage | Name | Namespace | Result |
|-------------|-------|------|-----------|--------|
| eus | dev | services | lazylabs | eusdevserviceslazylabs |
| eus | prod | application | lazylabs | eusprodapplicationlazylabs |
| wus | dev | data | lazylabs | wusdevdatalazylabs |

## Multiple Instance Patterns

### Environment-Specific Resource Groups
```yaml
# Development resource group
azure-resource-group-dev:
  metadata:
    component: azure-resource-group
  vars:
    name: "development"
    location: "East US"

# Production resource group  
azure-resource-group-prod:
  metadata:
    component: azure-resource-group
  vars:
    name: "production"
    location: "East US"
```

### Function-Specific Resource Groups
```yaml
# Networking resources
azure-resource-group-network:
  metadata:
    component: azure-resource-group
  vars:
    name: "network"
    attributes: ["infra"]

# Application resources
azure-resource-group-app:
  metadata:
    component: azure-resource-group
  vars:
    name: "application"
    attributes: ["web"]

# Data resources
azure-resource-group-data:
  metadata:
    component: azure-resource-group
  vars:
    name: "data"
    attributes: ["storage"]
```

## Integration with Other Components

Resource groups are referenced by other components using Atmos interpolation:

```yaml
# VNet references resource group
azure-vnet:
  vars:
    resource_group_name: "${var.environment}${var.stage}${components.terraform.azure-resource-group.vars.name}${var.namespace}"

# Storage account references resource group
azure-storage-account:
  vars:
    resource_group_name: "${var.environment}${var.stage}${components.terraform.azure-resource-group.vars.name}${var.namespace}"
```

## Security Best Practices

### Tagging Strategy
```yaml
vars:
  tags:
    Environment: "production"
    CostCenter: "engineering"
    Owner: "platform-team"
    Purpose: "application-hosting"
```

### Location Considerations
- Use regions close to users for better performance
- Consider data residency requirements
- Plan for disaster recovery with secondary regions

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.0 |
| azurerm | = 4.23.0 |

## Providers

| Name | Version |
|------|---------|
| azurerm | = 4.23.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| enabled | Set to false to prevent the module from creating any resources | `bool` | `true` | no |
| location | The Azure Region where the resource group should be created | `string` | n/a | yes |
| resource_group_name | Custom name for the resource group. If not specified, uses label module ID | `string` | `null` | no |
| namespace | ID element. Usually an abbreviation of your organization name | `string` | `null` | no |
| environment | ID element. Usually used for region (e.g. 'eus', 'wus') | `string` | `null` | no |
| stage | ID element. Usually used to indicate role (e.g. 'prod', 'dev') | `string` | `null` | no |
| name | ID element. Usually the component or solution name | `string` | `null` | no |
| attributes | ID element. Additional attributes to add to ID | `list(string)` | `[]` | no |
| tags | Additional tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| resource_group_id | The ID of the resource group |
| resource_group_name | The name of the resource group |
| resource_group_location | The location of the resource group |
| tags | The tags applied to the resource group |
| context | Exported context for use by other modules |

## Examples

### Complete Stack Integration
```yaml
components:
  terraform:
    # Foundation resource group
    azure-resource-group:
      vars:
        name: "services"
        location: "East US"
        attributes: ["shared"]

    # Network components using the resource group
    azure-vnet:
      vars:
        name: "network"
        resource_group_name: "${var.environment}${var.stage}${components.terraform.azure-resource-group.vars.name}${var.namespace}"

    # Storage using the same resource group
    azure-storage-account:
      vars:
        name: "storage"
        resource_group_name: "${var.environment}${var.stage}${components.terraform.azure-resource-group.vars.name}${var.namespace}"
```

### Multi-Region Deployment
```yaml
components:
  terraform:
    # Primary region resource group
    azure-resource-group-primary:
      metadata:
        component: azure-resource-group
      vars:
        name: "primary"
        location: "East US"
        attributes: ["main"]

    # Secondary region resource group
    azure-resource-group-secondary:
      metadata:
        component: azure-resource-group
      vars:
        name: "secondary"
        location: "West US"
        attributes: ["backup"]
```

## Troubleshooting

### Common Issues

1. **Resource Group Already Exists**
   - Check for existing resource groups with the same name
   - Use different `name` or `attributes` values
   - Consider using `resource_group_name` override

2. **Location Not Available**
   - Verify the Azure region name is correct
   - Check if services are available in the target region
   - Use standard Azure region names (e.g., "East US", not "eastus")

3. **Permission Issues**
   - Ensure service principal has Contributor access
   - Verify subscription permissions
   - Check Azure RBAC settings

### Validation
```bash
# Validate the resource group component
./scripts/validate-component.sh azure-resource-group core-eus-dev

# Check resource group in Azure
az group show --name eusdevserviceslazylabs
```

## Best Practices

### Naming Strategy
- Use descriptive names that indicate purpose
- Include environment and stage information
- Consider resource lifecycle and ownership
- Plan for multiple resource groups per environment

### Organization
- Separate resource groups by function (network, compute, data)
- Consider cost management and billing requirements
- Plan for role-based access control (RBAC)
- Group resources with similar lifecycles

### Tagging
- Implement consistent tagging strategy
- Include cost center, owner, and environment tags
- Use tags for automation and cost allocation
- Follow organizational tagging policies