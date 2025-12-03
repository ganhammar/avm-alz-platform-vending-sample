provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

provider "azapi" {
}

data "external" "get_access_token" {
  program = ["az", "account", "get-access-token", "--resource", "api://${var.ipam_api_id}", "--query", "{accessToken:accessToken}"]
}

provider "azureipam" {
  api_url = var.ipam_engine_url
  token   = data.external.get_access_token.result.accessToken
}
