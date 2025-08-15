terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "4.16.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "316f0ed4-2796-4561-a734-24b156826ae5"
}

terraform {
  backend "azurerm" {
    resource_group_name  = "RG5"
    storage_account_name = "jenkinsstatemcg2697"
    container_name       = "terraform-state"
    key                  = "terraform.tfstate"
  }
}
#
resource "azurerm_resource_group" "example" {
  name     = "RG6"
  location = "westeurope"
}
