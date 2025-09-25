provider "azurerm" {
  features {}
  
  # Use OIDC authentication (Workload Identity Federation)
  use_cli  = false
  use_msi  = false
  use_oidc = true
}

resource "azurerm_resource_group" "rg" {
  name     = "${var.resource-group-name}-${var.environment}"
  location = var.location
  
  tags = {
    environment = var.environment
  }
}
