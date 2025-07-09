# Azure App Service Plan Component

This component creates an Azure App Service Plan using the standardized Atmos component pattern.

## Usage

```yaml
components:
  terraform:
    azure-app-service-plan:
      vars:
        name: "webapp"
        location: "East US"
        resource_group_name: "my-resource-group"
        os_type: "Linux"
        sku_name: "B1"
        worker_count: 1
```

## Examples

### Basic Linux App Service Plan

```yaml
azure-app-service-plan-web:
  metadata:
    component: azure-app-service-plan
  vars:
    name: "webapp"
    location: "eastus"
    resource_group_name: !terraform.output azure-resource-group ".resource_group_name"
    os_type: "Linux"
    sku_name: "B1"
    worker_count: 1
```

### Production Windows App Service Plan

```yaml
azure-app-service-plan-prod:
  metadata:
    component: azure-app-service-plan
  vars:
    name: "prodapp"
    location: "eastus"
    resource_group_name: !terraform.output azure-resource-group ".resource_group_name"
    os_type: "Windows"
    sku_name: "P1v3"
    worker_count: 2
    per_site_scaling_enabled: true
    zone_balancing_enabled: true
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| enabled | Set to false to prevent the module from creating any resources | `bool` | `true` | no |
| location | The Azure Region where the App Service Plan should be created | `string` | n/a | yes |
| resource_group_name | The name of the resource group in which to create the App Service Plan | `string` | n/a | yes |
| app_service_plan_name | Custom name for the App Service Plan. If not specified, the module will use the ID from the label module | `string` | `null` | no |
| os_type | The O/S type for the App Service Plan. Possible values are Linux and Windows | `string` | `"Linux"` | no |
| sku_name | The SKU for the App Service Plan | `string` | `"B1"` | no |
| worker_count | The number of Workers (instances) to be allocated | `number` | `1` | no |
| per_site_scaling_enabled | Should Per Site Scaling be enabled | `bool` | `false` | no |
| zone_balancing_enabled | Should the Service Plan balance across Availability Zones in the region | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| app_service_plan_id | The ID of the App Service Plan |
| app_service_plan_name | The name of the App Service Plan |
| app_service_plan_kind | The kind of the App Service Plan |
| app_service_plan_os_type | The OS type for the App Service Plan |
| app_service_plan_sku_name | The SKU name of the App Service Plan |
| app_service_plan_worker_count | The number of workers for the App Service Plan |
| tags | The tags applied to the App Service Plan |
| context | Exported context for use by other modules |

## SKU Options

### Free Tier
- **F1**: 60 CPU minutes/day, 1GB storage

### Shared Tier
- **D1**: 240 CPU minutes/day, 1GB storage

### Basic Tier
- **B1, B2, B3**: Dedicated compute, no auto-scaling

### Standard Tier
- **S1, S2, S3**: Dedicated compute, auto-scaling available

### Premium Tier
- **P1v2, P2v2, P3v2**: Premium v2 instances
- **P1v3, P2v3, P3v3**: Premium v3 instances
- **P1mv3, P2mv3, P3mv3, P4mv3, P5mv3**: Memory optimized v3 instances

### Isolated Tier
- **I1, I2, I3**: Isolated instances
- **I1v2, I2v2, I3v2**: Isolated v2 instances

## Dependencies

This component depends on:
- Azure Resource Group (for deployment)

## Component Dependencies

Other components that can use this App Service Plan:
- Azure App Service (Web Apps)
- Azure Function Apps
- Azure Logic Apps

## Label Configuration

This component uses the cloudposse/label/null module with the following default configuration:
- `label_order`: ["namespace", "environment", "stage", "name"]
- `delimiter`: "" (no delimiter for Azure naming compatibility)
- `regex_replace_chars`: "/[^a-zA-Z0-9-]/" (Azure-compatible characters only)

## References

- [Azure App Service Plan Documentation](https://docs.microsoft.com/en-us/azure/app-service/overview-hosting-plans)
- [Terraform azurerm_service_plan Resource](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/service_plan)