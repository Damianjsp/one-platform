# Azure Virtual Network Module

This module creates an Azure Virtual Network with standardized naming conventions, consistent tagging, and flexible configuration options. It provides the network foundation for all other Azure resources in the One Platform architecture.

## Features

- **Standardized Naming**: Uses cloudposse/label for consistent resource naming
- **Flexible Address Space**: Support for multiple address ranges and CIDR blocks
- **DNS Configuration**: Custom DNS servers or Azure default DNS
- **DDoS Protection**: Optional DDoS protection plan integration
- **BGP Community**: Border Gateway Protocol community attributes
- **Conditional Creation**: Enable/disable with `var.enabled` flag
- **Network Foundation**: Serves as base for subnets and other network resources

## Usage

### Basic Virtual Network
```yaml
components:
  terraform:
    azure-vnet:
      vars:
        name: "network"
        location: "East US"
        resource_group_name: "eusdevserviceslazylabs"
        address_space: ["10.0.0.0/16"]
        dns_servers: ["168.63.129.16"]  # Azure default DNS
```

### Multiple Address Spaces
```yaml
components:
  terraform:
    azure-vnet:
      vars:
        name: "network"
        location: "East US"
        resource_group_name: "eusdevserviceslazylabs"
        address_space: 
          - "10.0.0.0/16"    # Primary address space
          - "10.1.0.0/16"    # Secondary address space
        dns_servers: ["10.0.0.4", "10.0.0.5"]  # Custom DNS servers
```

### Enterprise Network with DDoS Protection
```yaml
components:
  terraform:
    azure-vnet:
      vars:
        name: "enterprise"
        location: "East US"
        resource_group_name: "eusdevserviceslazylabs"
        address_space: ["10.0.0.0/8"]
        bgp_community: "65001:1001"
        ddos_protection_plan:
          id: "/subscriptions/{subscription-id}/resourceGroups/{rg}/providers/Microsoft.Network/ddosProtectionPlans/{plan-name}"
          enable: true
```

## Naming Convention

Virtual networks follow the pattern: `{environment}{stage}{name}{namespace}`

### Examples
| Environment | Stage | Name | Namespace | Result |
|-------------|-------|------|-----------|--------|
| eus | dev | network | lazylabs | eusdevnetworklazylabs |
| wus | prod | enterprise | lazylabs | wusprodenterpriselazylabs |
| eus | dev | spoke1 | lazylabs | eusdevspoke1lazylabs |

## Multiple Instance Patterns

### Hub-Spoke Network Architecture
```yaml
components:
  terraform:
    # Hub network
    azure-vnet-hub:
      metadata:
        component: azure-vnet
      vars:
        name: "hub"
        address_space: ["10.0.0.0/16"]
        dns_servers: ["10.0.0.4", "10.0.0.5"]

    # Spoke network 1 (Applications)
    azure-vnet-spoke-app:
      metadata:
        component: azure-vnet
      vars:
        name: "spoke"
        attributes: ["app"]
        address_space: ["10.1.0.0/16"]
        dns_servers: ["10.0.0.4", "10.0.0.5"]

    # Spoke network 2 (Data)
    azure-vnet-spoke-data:
      metadata:
        component: azure-vnet
      vars:
        name: "spoke"
        attributes: ["data"]
        address_space: ["10.2.0.0/16"]
        dns_servers: ["10.0.0.4", "10.0.0.5"]
```

### Environment-Specific Networks
```yaml
components:
  terraform:
    # Development network
    azure-vnet-dev:
      metadata:
        component: azure-vnet
      vars:
        name: "development"
        address_space: ["10.10.0.0/16"]

    # Production network
    azure-vnet-prod:
      metadata:
        component: azure-vnet
      vars:
        name: "production"
        address_space: ["10.20.0.0/16"]
        ddos_protection_plan:
          id: "/subscriptions/{id}/resourceGroups/{rg}/providers/Microsoft.Network/ddosProtectionPlans/{plan}"
          enable: true
```

## Integration with Other Components

Virtual networks are referenced by subnets and other network components:

```yaml
# Subnet references the VNet
azure-subnet:
  vars:
    virtual_network_name: "${var.environment}${var.stage}${components.terraform.azure-vnet.vars.name}${var.namespace}"

# Private endpoint references VNet through subnet
azure-private-endpoint:
  vars:
    subnet_id: "/subscriptions/{id}/resourceGroups/{rg}/providers/Microsoft.Network/virtualNetworks/${var.environment}${var.stage}${components.terraform.azure-vnet.vars.name}${var.namespace}/subnets/{subnet-name}"
```

## Address Space Planning

### Common Address Space Patterns
```yaml
# Development environments (smaller ranges)
address_space: ["10.10.0.0/16"]  # 65,534 addresses

# Production environments (larger ranges)
address_space: ["10.0.0.0/8"]    # 16,777,214 addresses

# Multi-region with reserved ranges
# East US: 10.1.0.0/16
# West US: 10.2.0.0/16
# Central US: 10.3.0.0/16
```

### Subnet Planning Within VNet
```yaml
# VNet: 10.0.0.0/16 (65,534 addresses)
# Subnet planning:
# - Web tier: 10.0.1.0/24 (254 addresses)
# - App tier: 10.0.2.0/24 (254 addresses)  
# - Data tier: 10.0.3.0/24 (254 addresses)
# - Management: 10.0.4.0/24 (254 addresses)
```

## DNS Configuration

### Azure Default DNS
```yaml
dns_servers: ["168.63.129.16"]  # Azure-provided DNS
```

### Custom DNS Servers
```yaml
dns_servers: 
  - "10.0.0.4"    # Primary DNS server
  - "10.0.0.5"    # Secondary DNS server
```

### Hybrid DNS (On-premises + Azure)
```yaml
dns_servers:
  - "192.168.1.10"   # On-premises DNS
  - "168.63.129.16"  # Azure DNS fallback
```

## Security Best Practices

### Network Segmentation
- Use separate VNets for different environments
- Implement network security groups (NSGs) on subnets
- Consider Azure Firewall for centralized security

### DDoS Protection
```yaml
ddos_protection_plan:
  id: "/subscriptions/{subscription-id}/resourceGroups/{rg}/providers/Microsoft.Network/ddosProtectionPlans/{plan-name}"
  enable: true
```

### Network Monitoring
- Enable Network Watcher in each region
- Configure flow logs for security analysis
- Set up connection monitoring

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
| location | The location/region where the virtual network is created | `string` | n/a | yes |
| resource_group_name | The name of the resource group | `string` | n/a | yes |
| address_space | The address space that is used for the virtual network | `list(string)` | n/a | yes |
| vnet_name | Custom name for the virtual network. If not specified, uses label module ID | `string` | `null` | no |
| dns_servers | List of IP addresses of DNS servers | `list(string)` | `null` | no |
| bgp_community | The BGP community attribute in format `<as-number>:<community-value>` | `string` | `null` | no |
| ddos_protection_plan | A ddos_protection_plan block | `object({id = string, enable = bool})` | `null` | no |
| namespace | ID element. Usually an abbreviation of your organization name | `string` | `null` | no |
| environment | ID element. Usually used for region (e.g. 'eus', 'wus') | `string` | `null` | no |
| stage | ID element. Usually used to indicate role (e.g. 'prod', 'dev') | `string` | `null` | no |
| name | ID element. Usually the component or solution name | `string` | `null` | no |
| attributes | ID element. Additional attributes to add to ID | `list(string)` | `[]` | no |
| tags | Additional tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| vnet_id | The ID of the virtual network |
| vnet_name | The name of the virtual network |
| vnet_address_space | The address space of the virtual network |
| tags | The tags applied to the virtual network |
| context | Exported context for use by other modules |

## Examples

### Complete Network Stack
```yaml
components:
  terraform:
    # Resource group for network resources
    azure-resource-group-network:
      metadata:
        component: azure-resource-group
      vars:
        name: "network"
        location: "East US"

    # Virtual network
    azure-vnet:
      vars:
        name: "network"
        location: "East US"
        resource_group_name: "${var.environment}${var.stage}${components.terraform.azure-resource-group-network.vars.name}${var.namespace}"
        address_space: ["10.0.0.0/16"]
        dns_servers: ["168.63.129.16"]

    # Subnets within the VNet
    azure-subnet-web:
      metadata:
        component: azure-subnet
      vars:
        name: "web"
        resource_group_name: "${var.environment}${var.stage}${components.terraform.azure-resource-group-network.vars.name}${var.namespace}"
        virtual_network_name: "${var.environment}${var.stage}${components.terraform.azure-vnet.vars.name}${var.namespace}"
        address_prefixes: ["10.0.1.0/24"]
```

### Multi-Region Network
```yaml
components:
  terraform:
    # East US network
    azure-vnet-east:
      metadata:
        component: azure-vnet
      vars:
        name: "network"
        attributes: ["east"]
        location: "East US"
        address_space: ["10.1.0.0/16"]

    # West US network
    azure-vnet-west:
      metadata:
        component: azure-vnet
      vars:
        name: "network"
        attributes: ["west"]
        location: "West US"
        address_space: ["10.2.0.0/16"]
```

## Troubleshooting

### Common Issues

1. **Address Space Conflicts**
   - Ensure address spaces don't overlap between VNets
   - Check for conflicts with on-premises networks
   - Use Azure IP address planning tools

2. **DNS Resolution Issues**
   - Verify DNS server accessibility
   - Check NSG rules for DNS traffic (port 53)
   - Validate DNS server configuration

3. **Connectivity Problems**
   - Verify route tables and user-defined routes
   - Check network security group rules
   - Validate network peering configuration

### Validation
```bash
# Validate the VNet component
./scripts/validate-component.sh azure-vnet core-eus-dev

# Check VNet in Azure
az network vnet show --name eusdevnetworklazylabs --resource-group eusdevserviceslazylabs
```

## Best Practices

### Address Space Design
- Plan address spaces before deployment
- Reserve address ranges for future growth
- Avoid overlapping with on-premises networks
- Use standard private IP ranges (10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16)

### Network Architecture
- Implement hub-spoke topology for enterprise scenarios
- Use separate VNets for different environments
- Consider network peering for VNet-to-VNet connectivity
- Plan for hybrid connectivity with ExpressRoute or VPN

### Security
- Enable DDoS protection for production environments
- Implement network segmentation with subnets
- Use Azure Firewall or network virtual appliances
- Monitor network traffic with Network Watcher

### Performance
- Choose regions close to users
- Consider availability zones for high availability
- Plan bandwidth requirements
- Monitor network performance metrics