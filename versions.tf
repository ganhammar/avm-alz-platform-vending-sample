terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.54.0"
    }
    azapi = {
      source  = "Azure/azapi"
      version = "2.7.0"
    }
    azureipam = {
      version = "2.0"
      source  = "xtratuscloud/azureipam"
    }
    alz = {
      source  = "azure/alz"
      version = "0.20.1"
    }
  }
}
