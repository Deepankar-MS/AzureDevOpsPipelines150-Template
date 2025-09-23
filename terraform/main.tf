provider "azurerm" {
  features {}
  
  # Try Service Principal first, fall back to OIDC if no secret available
  use_cli                 = false
  use_msi                 = false
  
  # Note: Azure DevOps may use Workload Identity Federation
  # If ARM_CLIENT_SECRET is not available, this will try OIDC
}

resource "azurerm_resource_group" "rg" {
  name     = "${var.resource-group-name}-${var.environment}"
  location = var.location
  
  tags = {
    environment = var.environment
  }
}
