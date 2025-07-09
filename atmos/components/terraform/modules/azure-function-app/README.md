# Azure Function App Component

This component creates an Azure Function App using the standardized Atmos component pattern. It supports both Linux and Windows Function Apps with comprehensive configuration options.

## Usage

```yaml
components:
  terraform:
    azure-function-app:
      vars:
        name: "myfunction"
        location: "East US"
        resource_group_name: "my-resource-group"
        service_plan_id: "/subscriptions/.../resourceGroups/.../providers/Microsoft.Web/serverfarms/..."
        storage_account_name: "mystorageaccount"
        storage_account_access_key: "storage-account-key"
        os_type: "Linux"
        functions_worker_runtime: "node"
```

## Examples

### Basic Node.js Function App on Linux

```yaml
azure-function-app-api:
  metadata:
    component: azure-function-app
  settings:
    depends_on:
      1:
        component: "azure-resource-group"
      2:
        component: "azure-app-service-plan-web"
      3:
        component: "azure-storage-account-general"
  vars:
    name: "api"
    location: "eastus"
    resource_group_name: !terraform.output azure-resource-group ".resource_group_name"
    service_plan_id: !terraform.output azure-app-service-plan-web ".app_service_plan_id"
    storage_account_name: !terraform.output azure-storage-account-general ".storage_account_name"
    storage_account_access_key: !terraform.output azure-storage-account-general ".storage_account_primary_access_key"
    os_type: "Linux"
    functions_worker_runtime: "node"
    application_stack:
      node_version: "18"
```

### Python Function App with Application Insights

```yaml
azure-function-app-python:
  metadata:
    component: azure-function-app
  settings:
    depends_on:
      1:
        component: "azure-resource-group"
      2:
        component: "azure-app-service-plan-web"
      3:
        component: "azure-storage-account-general"
  vars:
    name: "python"
    attributes: ["ml"]
    location: "eastus"
    resource_group_name: !terraform.output azure-resource-group ".resource_group_name"
    service_plan_id: !terraform.output azure-app-service-plan-web ".app_service_plan_id"
    storage_account_name: !terraform.output azure-storage-account-general ".storage_account_name"
    storage_account_access_key: !terraform.output azure-storage-account-general ".storage_account_primary_access_key"
    os_type: "Linux"
    functions_worker_runtime: "python"
    application_stack:
      python_version: "3.11"
    application_insights_connection_string: "InstrumentationKey=..."
    always_on: true
```

### .NET Function App on Windows

```yaml
azure-function-app-dotnet:
  metadata:
    component: azure-function-app
  settings:
    depends_on:
      1:
        component: "azure-resource-group"
      2:
        component: "azure-app-service-plan-api"
      3:
        component: "azure-storage-account-general"
  vars:
    name: "dotnet"
    location: "eastus"
    resource_group_name: !terraform.output azure-resource-group ".resource_group_name"
    service_plan_id: !terraform.output azure-app-service-plan-api ".app_service_plan_id"
    storage_account_name: !terraform.output azure-storage-account-general ".storage_account_name"
    storage_account_access_key: !terraform.output azure-storage-account-general ".storage_account_primary_access_key"
    os_type: "Windows"
    functions_worker_runtime: "dotnet-isolated"
    application_stack:
      dotnet_version: "8.0"
      use_dotnet_isolated_runtime: true
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| enabled | Set to false to prevent the module from creating any resources | `bool` | `true` | no |
| location | The Azure Region where the Function App should be created | `string` | n/a | yes |
| resource_group_name | The name of the resource group in which to create the Function App | `string` | n/a | yes |
| service_plan_id | The ID of the App Service Plan within which to create this Function App | `string` | n/a | yes |
| storage_account_name | The backend storage account name which will be used by this Function App | `string` | n/a | yes |
| storage_account_access_key | The access key which will be used to access the backend storage account | `string` | n/a | yes |
| function_app_name | Custom name for the Function App. If not specified, the module will use the ID from the label module | `string` | `null` | no |
| os_type | The O/S type for the Function App. Possible values are Linux and Windows | `string` | `"Linux"` | no |
| functions_worker_runtime | The runtime stack of the Function App. Possible values are dotnet, dotnet-isolated, java, node, python, powershell, custom | `string` | `"node"` | no |
| always_on | Should the Function App be loaded at all times | `bool` | `false` | no |
| https_only | Should the Function App only be accessible via HTTPS | `bool` | `true` | no |
| public_network_access_enabled | Should the Function App be accessible from the public network | `bool` | `true` | no |
| minimum_tls_version | The minimum supported TLS version for the Function App | `string` | `"1.2"` | no |
| functions_extension_version | The runtime version associated with the Function App | `string` | `"~4"` | no |
| application_stack | Configuration block for the Function App application stack | `object` | `null` | no |
| cors | Configuration block for CORS settings | `object` | `null` | no |
| auth_settings | Configuration block for authentication settings | `object` | `null` | no |
| connection_strings | Map of connection strings | `map(object)` | `{}` | no |
| identity | Configuration block for managed identity | `object` | `null` | no |
| app_settings | A map of key-value pairs for App Settings and custom values | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| function_app_id | The ID of the Function App |
| function_app_name | The name of the Function App |
| function_app_default_hostname | The default hostname associated with the Function App |
| function_app_outbound_ip_addresses | A comma separated list of outbound IP addresses |
| function_app_possible_outbound_ip_addresses | A comma separated list of outbound IP addresses - not all of which are necessarily in use |
| function_app_site_credential | A site_credential block containing the deployment credentials for the Function App |
| function_app_identity | An identity block containing the managed identity information for the Function App |
| function_app_custom_domain_verification_id | The identifier used by App Service to perform domain ownership verification via DNS TXT record |
| function_app_kind | The kind of the Function App |
| tags | The tags applied to the Function App |
| context | Exported context for use by other modules |

## Runtime Support

### Linux Function Apps
- **.NET**: dotnet (6.0, 8.0), dotnet-isolated (6.0, 8.0)
- **Node.js**: node (16, 18, 20)
- **Python**: python (3.8, 3.9, 3.10, 3.11)
- **Java**: java (8, 11, 17)
- **PowerShell**: powershell (7.0, 7.2)
- **Custom**: custom

### Windows Function Apps
- **.NET**: dotnet (6.0, 8.0), dotnet-isolated (6.0, 8.0)
- **Node.js**: node (16, 18, 20)
- **Java**: java (8, 11, 17)
- **PowerShell**: powershell (7.0, 7.2)
- **Custom**: custom

## Dependencies

This component depends on:
- Azure Resource Group (for deployment)
- Azure App Service Plan (for hosting)
- Azure Storage Account (for function app storage)

## Security Features

- **HTTPS Only**: Enforces HTTPS-only access by default
- **TLS 1.2**: Minimum TLS version set to 1.2
- **Authentication**: Supports Azure AD and other authentication providers
- **Client Certificates**: Optional client certificate authentication
- **Network Access**: Configurable public network access
- **Managed Identity**: Support for system and user-assigned managed identities

## Monitoring and Diagnostics

- **Application Insights**: Built-in support for Application Insights integration
- **Logging**: Comprehensive logging configuration
- **Health Checks**: Built-in health monitoring

## Label Configuration

This component uses the cloudposse/label/null module with the following default configuration:
- `label_order`: ["namespace", "environment", "stage", "name"]
- `delimiter`: "" (no delimiter for Azure naming compatibility)
- `regex_replace_chars`: "/[^a-zA-Z0-9-]/" (Azure-compatible characters only)

## References

- [Azure Functions Documentation](https://docs.microsoft.com/en-us/azure/azure-functions/)
- [Terraform azurerm_linux_function_app Resource](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_function_app)
- [Terraform azurerm_windows_function_app Resource](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/windows_function_app)