terraform {
  required_version = ">= 1.9.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "= 4.23.0"
    }
  }
}

provider "azurerm" {
  features {}
  use_cli  = false
  use_msi  = false
  use_oidc = false
}
