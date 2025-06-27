# Azure Subnet Module

This module creates an Azure Subnet within a Virtual Network with standardized naming conventions, flexible configuration options, and support for service endpoints, delegations, and private endpoint network policies.

## Features

- **Standardized Naming**: Uses cloudposse/label for consistent resource naming
- **Private Endpoint Support**: Configurable network policies for private endpoints
- **Service Endpoints**: Enable service endpoints for Azure services (Storage, SQL, etc.)
- **Subnet Delegation**: Support for delegating subnets to Azure services
- **Service Endpoint Policies**: Fine-grained control over service endpoint traffic
- **Conditional Creation**: Enable/disable with `var.enabled` flag
- **Flexible Address Space**: Support for multiple address prefixes

## Usage

### Basic Subnet
```yaml
components:
  terraform:
    azure-subnet:
      vars:
        name: "web"
        resource_group_name: "eusdevserviceslazylabs"
        virtual_network_name: "eusdevnetworklazylabs"
        address_prefixes: ["10.0.1.0/24"]
```

### Subnet with Service Endpoints
```yaml
components:
  terraform:
    azure-subnet:
      vars:
        name: "data"
        resource_group_name: "eusdevserviceslazylabs"
        virtual_network_name: "eusdevnetworklazylabs"
        address_prefixes: ["10.0.2.0/24"]
        service_endpoints:
          - "Microsoft.Storage"
          - "Microsoft.Sql"
          - "Microsoft.KeyVault"
```

### Subnet with Delegation (for Azure Container Instances)
```yaml
components:
  terraform:
    azure-subnet:
      vars:
        name: "containers"
        resource_group_name: "eusdevserviceslazylabs"
        virtual_network_name: "eusdevnetworklazylabs"
        address_prefixes: ["10.0.3.0/24"]
        delegations:
          - name: "aci-delegation"
            service_delegation:
              name: "Microsoft.ContainerInstance/containerGroups"
              actions:
                - "Microsoft.Network/virtualNetworks/subnets/action"
```

### Private Endpoint Subnet
```yaml
components:
  terraform:
    azure-subnet:
      vars:
        name: "private-endpoints"
        resource_group_name: "eusdevserviceslazylabs"
        virtual_network_name: "eusdevnetworklazylabs"
        address_prefixes: ["10.0.4.0/24"]
        private_endpoint_network_policies: "Disabled"
```

## Naming Convention

Subnets follow the pattern: `{environment}{stage}{name}{namespace}`

### Examples
| Environment | Stage | Name | Namespace | Result |
|-------------|-------|------|-----------|--------|
| eus | dev | web | lazylabs | eusdevweblazylabs |
| eus | prod | data | lazylabs | eusproddatalazylabs |
| wus | dev | private-endpoints | lazylabs | wusdevprivateendpointslazylabs |

## Multiple Instance Patterns

### Multi-Tier Application Subnets
```yaml
components:
  terraform:
    # Web tier subnet
    azure-subnet-web:
      metadata:
        component: azure-subnet
      vars:
        name: "web"
        resource_group_name: "${var.environment}${var.stage}${components.terraform.azure-resource-group.vars.name}${var.namespace}"
        virtual_network_name: "${var.environment}${var.stage}${components.terraform.azure-vnet.vars.name}${var.namespace}"
        address_prefixes: ["10.0.1.0/24"]
        service_endpoints: ["Microsoft.Storage"]

    # Application tier subnet
    azure-subnet-app:
      metadata:
        component: azure-subnet
      vars:
        name: "app"
        resource_group_name: "${var.environment}${var.stage}${components.terraform.azure-resource-group.vars.name}${var.namespace}"
        virtual_network_name: "${var.environment}${var.stage}${components.terraform.azure-vnet.vars.name}${var.namespace}"
        address_prefixes: ["10.0.2.0/24"]
        service_endpoints: ["Microsoft.Sql", "Microsoft.KeyVault"]

    # Data tier subnet
    azure-subnet-data:
      metadata:
        component: azure-subnet
      vars:
        name: "data"
        resource_group_name: "${var.environment}${var.stage}${components.terraform.azure-resource-group.vars.name}${var.namespace}"
        virtual_network_name: "${var.environment}${var.stage}${components.terraform.azure-vnet.vars.name}${var.namespace}"
        address_prefixes: ["10.0.3.0/24"]
        private_endpoint_network_policies: "Disabled"
```

### Service-Specific Subnets
```yaml
components:
  terraform:
    # Application Gateway subnet
    azure-subnet-appgw:
      metadata:
        component: azure-subnet
      vars:
        name: "appgw"
        address_prefixes: ["10.0.10.0/24"]
        delegations:
          - name: "appgw-delegation"
            service_delegation:
              name: "Microsoft.Network/applicationGateways"
              actions: ["Microsoft.Network/virtualNetworks/subnets/action"]

    # Azure Kubernetes Service subnet
    azure-subnet-aks:
      metadata:
        component: azure-subnet
      vars:
        name: "aks"
        address_prefixes: ["10.0.20.0/22"]  # Larger range for pods
        service_endpoints: ["Microsoft.Storage", "Microsoft.ContainerRegistry"]

    # Azure Functions subnet
    azure-subnet-functions:
      metadata:
        component: azure-subnet
      vars:
        name: "functions"
        address_prefixes: ["10.0.30.0/24"]
        delegations:
          - name: "functions-delegation"
            service_delegation:
              name: "Microsoft.Web/serverFarms"
              actions: ["Microsoft.Network/virtualNetworks/subnets/action"]
```

## Integration with Other Components

### Referenced by Private Endpoints
```yaml
azure-private-endpoint:
  vars:
    subnet_id: "${module.azure-subnet.subnet_id}"
```

### Referenced by Network Security Groups
```yaml
azure-network-security-group:
  vars:
    subnet_id: "${module.azure-subnet.subnet_id}"
```

### Complete Network Stack
```yaml
components:
  terraform:
    # Virtual Network
    azure-vnet:
      vars:
        name: "network"
        address_space: ["10.0.0.0/16"]

    # Subnet within VNet
    azure-subnet:
      vars:
        name: "web"
        virtual_network_name: "${var.environment}${var.stage}${components.terraform.azure-vnet.vars.name}${var.namespace}"
        address_prefixes: ["10.0.1.0/24"]
```

## Service Endpoints

### Supported Services
- **Microsoft.Storage**: Azure Storage (Blob, File, Queue, Table)
- **Microsoft.Sql**: Azure SQL Database and Data Warehouse
- **Microsoft.KeyVault**: Azure Key Vault
- **Microsoft.ContainerRegistry**: Azure Container Registry
- **Microsoft.ServiceBus**: Azure Service Bus
- **Microsoft.CognitiveServices**: Azure Cognitive Services
- **Microsoft.EventHub**: Azure Event Hubs

### Service Endpoint Configuration
```yaml
service_endpoints:
  - "Microsoft.Storage"
  - "Microsoft.Sql"
  - "Microsoft.KeyVault"

# Optional: Service endpoint policies for fine-grained control
service_endpoint_policy_ids:
  - "/subscriptions/{id}/resourceGroups/{rg}/providers/Microsoft.Network/serviceEndpointPolicies/{policy-name}"
```

## Subnet Delegations

### Common Delegation Examples
```yaml
# Azure Container Instances
delegations:
  - name: "aci-delegation"
    service_delegation:
      name: "Microsoft.ContainerInstance/containerGroups"
      actions: ["Microsoft.Network/virtualNetworks/subnets/action"]

# Azure Functions (Premium Plan)
delegations:
  - name: "functions-delegation"
    service_delegation:
      name: "Microsoft.Web/serverFarms"
      actions: ["Microsoft.Network/virtualNetworks/subnets/action"]

# Azure NetApp Files
delegations:
  - name: "netapp-delegation"
    service_delegation:
      name: "Microsoft.NetApp/volumes"
      actions: ["Microsoft.Network/networkinterfaces/*", "Microsoft.Network/virtualNetworks/subnets/join/action"]
```

## Private Endpoint Network Policies

### Policy Options
- **Enabled**: Default setting, enables network policies
- **Disabled**: Required for subnets hosting private endpoints
- **NetworkSecurityGroupEnabled**: Enables NSG rules for private endpoints
- **RouteTableEnabled**: Enables custom routes for private endpoints

### Private Endpoint Subnet
```yaml
# Dedicated subnet for private endpoints
azure-subnet-private-endpoints:
  vars:
    name: "private-endpoints"
    address_prefixes: ["10.0.100.0/24"]
    private_endpoint_network_policies: "Disabled"
```

## Address Space Planning

### Standard Subnet Sizes
```yaml
# Small subnet (62 hosts)
address_prefixes: ["10.0.1.0/26"]

# Medium subnet (254 hosts)
address_prefixes: ["10.0.1.0/24"]

# Large subnet (1,022 hosts)
address_prefixes: ["10.0.0.0/22"]

# Extra large subnet (4,094 hosts) - for AKS
address_prefixes: ["10.0.0.0/20"]
```

### Multi-Prefix Subnets
```yaml
# Subnet with multiple address ranges
address_prefixes:
  - "10.0.1.0/24"
  - "10.0.2.0/24"
```

## Security Best Practices

### Network Segmentation
- Create separate subnets for different tiers (web, app, data)
- Use dedicated subnets for management and private endpoints
- Implement least privilege with service endpoints

### Service Endpoint Security
```yaml
# Restrict storage access to specific subnet
service_endpoints: ["Microsoft.Storage"]
service_endpoint_policy_ids: ["/subscriptions/.../serviceEndpointPolicies/storage-policy"]
```

### Private Endpoint Best Practices
- Use dedicated subnets for private endpoints
- Disable network policies on private endpoint subnets
- Implement proper DNS resolution with private DNS zones

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
| resource_group_name | The name of the resource group in which to create the subnet | `string` | n/a | yes |
| virtual_network_name | The name of the virtual network to which to attach the subnet | `string` | n/a | yes |
| address_prefixes | The address prefixes to use for the subnet | `list(string)` | n/a | yes |
| subnet_name | Custom name for the subnet. If not specified, uses label module ID | `string` | `null` | no |
| private_endpoint_network_policies | Network policies for private endpoints (Enabled, Disabled, NetworkSecurityGroupEnabled, RouteTableEnabled) | `string` | `"Enabled"` | no |
| service_endpoints | List of service endpoints to associate with the subnet | `list(string)` | `[]` | no |
| service_endpoint_policy_ids | List of service endpoint policy IDs to associate with the subnet | `list(string)` | `[]` | no |
| delegations | List of subnet delegations | `list(object)` | `[]` | no |
| namespace | ID element. Usually an abbreviation of your organization name | `string` | `null` | no |
| environment | ID element. Usually used for region (e.g. 'eus', 'wus') | `string` | `null` | no |
| stage | ID element. Usually used to indicate role (e.g. 'prod', 'dev') | `string` | `null` | no |
| name | ID element. Usually the component or solution name | `string` | `null` | no |
| attributes | ID element. Additional attributes to add to ID | `list(string)` | `[]` | no |
| tags | Additional tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| subnet_id | The ID of the subnet |
| subnet_name | The name of the subnet |
| subnet_address_prefixes | The address prefixes of the subnet |
| tags | The tags applied to the subnet |
| context | Exported context for use by other modules |

## Examples

### Complete Application Stack
```yaml
components:
  terraform:
    # Resource Group
    azure-resource-group:
      vars:
        name: "app"
        location: "East US"

    # Virtual Network
    azure-vnet:
      vars:
        name: "network"
        resource_group_name: "${var.environment}${var.stage}${components.terraform.azure-resource-group.vars.name}${var.namespace}"
        address_space: ["10.0.0.0/16"]

    # Web tier subnet
    azure-subnet-web:
      metadata:
        component: azure-subnet
      vars:
        name: "web"
        resource_group_name: "${var.environment}${var.stage}${components.terraform.azure-resource-group.vars.name}${var.namespace}"
        virtual_network_name: "${var.environment}${var.stage}${components.terraform.azure-vnet.vars.name}${var.namespace}"
        address_prefixes: ["10.0.1.0/24"]

    # Private endpoints subnet
    azure-subnet-private-endpoints:
      metadata:
        component: azure-subnet
      vars:
        name: "private-endpoints"
        resource_group_name: "${var.environment}${var.stage}${components.terraform.azure-resource-group.vars.name}${var.namespace}"
        virtual_network_name: "${var.environment}${var.stage}${components.terraform.azure-vnet.vars.name}${var.namespace}"
        address_prefixes: ["10.0.100.0/24"]
        private_endpoint_network_policies: "Disabled"
```

### Microservices Architecture
```yaml
components:
  terraform:
    # API Gateway subnet
    azure-subnet-gateway:
      metadata:
        component: azure-subnet
      vars:
        name: "gateway"
        address_prefixes: ["10.0.10.0/24"]
        service_endpoints: ["Microsoft.KeyVault"]

    # Microservices subnet
    azure-subnet-services:
      metadata:
        component: azure-subnet
      vars:
        name: "services"
        address_prefixes: ["10.0.20.0/22"]
        service_endpoints: ["Microsoft.Storage", "Microsoft.Sql", "Microsoft.ServiceBus"]

    # Cache subnet
    azure-subnet-cache:
      metadata:
        component: azure-subnet
      vars:
        name: "cache"
        address_prefixes: ["10.0.30.0/24"]
        private_endpoint_network_policies: "Disabled"
```

## Troubleshooting

### Common Issues

1. **Address Space Conflicts**
   - Ensure subnet address prefixes don't overlap
   - Verify address prefixes are within VNet address space
   - Check for conflicts with existing subnets

2. **Service Endpoint Failures**
   - Verify service endpoint is supported in the region
   - Check service endpoint policy restrictions
   - Ensure proper firewall rules on target services

3. **Delegation Issues**
   - Verify service supports subnet delegation
   - Check delegation actions are correct for the service
   - Ensure only one delegation per subnet

4. **Private Endpoint Policy Problems**
   - Set `private_endpoint_network_policies = "Disabled"` for private endpoint subnets
   - Verify NSG rules allow private endpoint traffic
   - Check route table configuration

### Validation
```bash
# Validate the subnet component
./scripts/validate-component.sh azure-subnet core-eus-dev

# Check subnet in Azure
az network vnet subnet show --vnet-name eusdevnetworklazylabs --name eusdevweblazylabs --resource-group eusdevserviceslazylabs
```

## Best Practices

### Address Planning
- Plan subnet sizes based on expected resource count
- Reserve address space for future growth
- Use consistent subnet sizing across environments
- Document subnet purpose and ownership

### Security
- Use service endpoints to secure traffic to Azure services
- Implement Network Security Groups for traffic filtering
- Use dedicated subnets for private endpoints
- Apply least privilege access principles

### Organization
- Name subnets based on their purpose (web, app, data, mgmt)
- Use consistent naming conventions across environments
- Group related resources in the same subnet
- Consider network latency and bandwidth requirements

### Performance
- Size subnets appropriately for expected load
- Consider proximity to other Azure services
- Plan for auto-scaling scenarios
- Monitor subnet utilization and adjust as needed