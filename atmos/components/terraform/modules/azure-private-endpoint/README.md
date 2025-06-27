# Azure Private Endpoint Module

This module creates an Azure Private Endpoint that enables secure connectivity to Azure services over a private network connection.

## Features

- Creates Azure Private Endpoint with customizable configuration
- Supports private DNS zone groups for automatic DNS resolution
- Configurable IP addressing and subresource targeting
- Follows standardized naming conventions using cloudposse/label
- Supports manual and automatic connection approval

## Usage

### Basic Private Endpoint for Storage Account

```yaml
components:
  terraform:
    azure-private-endpoint-storage:
      metadata:
        component: azure-private-endpoint
      vars:
        name: "storage"
        location: "East US"
        resource_group_name: "my-resource-group"
        subnet_id: "/subscriptions/{id}/resourceGroups/{rg}/providers/Microsoft.Network/virtualNetworks/{vnet}/subnets/{subnet}"
        private_connection_resource_id: "/subscriptions/{id}/resourceGroups/{rg}/providers/Microsoft.Storage/storageAccounts/mystorageaccount"
        subresource_names: ["blob"]
        private_dns_zone_group:
          name: "storage-dns-zone-group"
          private_dns_zone_ids: ["/subscriptions/{id}/resourceGroups/{rg}/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net"]
```

### Private Endpoint for Key Vault

```yaml
components:
  terraform:
    azure-private-endpoint-keyvault:
      metadata:
        component: azure-private-endpoint
      vars:
        name: "keyvault"
        location: "East US"
        resource_group_name: "my-resource-group"
        subnet_id: "/subscriptions/{id}/resourceGroups/{rg}/providers/Microsoft.Network/virtualNetworks/{vnet}/subnets/{subnet}"
        private_connection_resource_id: "/subscriptions/{id}/resourceGroups/{rg}/providers/Microsoft.KeyVault/vaults/mykeyvault"
        subresource_names: ["vault"]
        private_dns_zone_group:
          name: "keyvault-dns-zone-group"
          private_dns_zone_ids: ["/subscriptions/{id}/resourceGroups/{rg}/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net"]
```

## Common Subresource Names

- **Storage Account**: `blob`, `file`, `queue`, `table`, `web`, `dfs`
- **Key Vault**: `vault`
- **SQL Server**: `sqlServer`
- **Cosmos DB**: `sql`, `mongodb`, `cassandra`, `gremlin`, `table`
- **Event Hub**: `namespace`
- **Service Bus**: `namespace`

## Private DNS Zones

Common private DNS zones for Azure services:
- Storage: `privatelink.blob.core.windows.net`
- Key Vault: `privatelink.vaultcore.azure.net`
- SQL Server: `privatelink.database.windows.net`
- Event Hub: `privatelink.servicebus.windows.net`

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.0 |
| azurerm | = 4.23.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| enabled | Set to false to prevent the module from creating any resources | `bool` | `true` | no |
| location | The Azure Region where the private endpoint should be created | `string` | n/a | yes |
| resource_group_name | The name of the resource group | `string` | n/a | yes |
| subnet_id | The ID of the subnet from which the private IP will be allocated | `string` | n/a | yes |
| private_connection_resource_id | The ID of the private link enabled remote resource | `string` | n/a | yes |
| subresource_names | A list of subresource names which the private endpoint is able to connect to | `list(string)` | `[]` | no |
| private_dns_zone_group | A private DNS zone group configuration | `object({...})` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| private_endpoint_id | The ID of the private endpoint |
| private_endpoint_name | The name of the private endpoint |
| network_interface | A network_interface block |
| private_service_connection | A private_service_connection block |
| custom_dns_configs | A custom_dns_configs block |
| private_dns_zone_configs | A private_dns_zone_configs block |