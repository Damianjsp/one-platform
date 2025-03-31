# Azure Resource Group Terraform Module

This Terraform module provisions an Azure Resource Group with consistent naming and tagging using the `null-label` module from Cloud Posse.

## Features

- Creates an Azure Resource Group with standardized naming convention
- Applies consistent tags based on the null-label module
- Option to prevent accidental deletion of the resource group
- Conditional creation with the `enabled` flag
- Compatible with Atmos stack management

## Usage

Basic usage:

```hcl
module "resource_group" {
  source = "path/to/components/terraform/azure-resource-group"

  namespace   = "myorg"
  tenant      = "core"
  environment = "eastus"
  stage       = "dev"
  name        = "app"
  location    = "East US"

  tags = {
    BusinessUnit = "Finance"
    Owner        = "DevOps Team"
  }
}

<!-- BEGIN_TF_DOCS -->

<!-- END_TF_DOCS -->
