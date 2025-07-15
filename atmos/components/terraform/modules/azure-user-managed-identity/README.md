# Azure User Managed Identity Component

This component creates an Azure User Assigned Identity following One Platform standards.

## Usage

```yaml
components:
  terraform:
    azure-user-managed-identity-example:
      metadata:
        component: azure-user-managed-identity
      settings:
        depends_on:
          1:
            component: "azure-resource-group"
      vars:
        name: "functions"
        location: "eastus"
        resource_group_name: !terraform.output azure-resource-group ".resource_group_name"
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| enabled | Set to false to prevent the module from creating any resources | `bool` | `true` | no |
| user_assigned_identity_name | Custom name for the user assigned identity. If not specified, the module will use the ID from the label module | `string` | `null` | no |
| resource_group_name | The name of the resource group in which to create the user assigned identity | `string` | n/a | yes |
| location | The Azure region where the user assigned identity should exist | `string` | n/a | yes |

Additional label module variables are available for consistent naming and tagging.

## Outputs

| Name | Description |
|------|-------------|
| user_assigned_identity_id | The ID of the user assigned identity |
| user_assigned_identity_name | The name of the user assigned identity |
| principal_id | The principal ID (object ID) of the user assigned identity |
| client_id | The client ID (application ID) of the user assigned identity |
| tenant_id | The tenant ID of the user assigned identity |
| tags | The tags applied to the user assigned identity |
| context | Exported context for use by other modules |

## Security Checks

This component includes custom Checkov security checks:

- **CKV_OP_AZURE_UMI_1**: Ensures User Managed Identity uses cloudposse/label module
- **CKV_OP_AZURE_UMI_2**: Ensures User Managed Identity uses conditional creation pattern
- **CKV_OP_AZURE_UMI_3**: Ensures User Managed Identity properly references resource group
- **CKV_OP_AZURE_UMI_4**: Ensures User Managed Identity uses approved Azure regions
- **CKV_OP_AZURE_UMI_5**: Ensures User Managed Identity follows naming conventions

## Common Use Cases

### Function App Identity
```yaml
azure-user-managed-identity-functions:
  metadata:
    component: azure-user-managed-identity
  vars:
    name: "functions"
    location: "eastus"
    resource_group_name: !terraform.output azure-resource-group ".resource_group_name"
```

### Data Access Identity
```yaml
azure-user-managed-identity-data:
  metadata:
    component: azure-user-managed-identity
  vars:
    name: "data"
    attributes: ["access"]
    location: "eastus"
    resource_group_name: !terraform.output azure-resource-group ".resource_group_name"
```

## Dependencies

- Resource Group (for placement)
- Properly configured label module variables

## Notes

- User Managed Identities are regional resources that must be in the same region as the resources that will use them
- The identity can be assigned to multiple Azure resources for shared access scenarios
- Principal ID output is used for role assignments and access policies
- Client ID output is used in application configurations