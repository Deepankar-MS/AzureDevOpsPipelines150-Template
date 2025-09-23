provider "azurerm" {
  features {}
  
  # Explicitly use service principal authentication
  use_cli                 = false
  use_msi                 = false
  use_oidc                = false
  
  # These will be provided via environment variables:
  # ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_TENANT_ID, ARM_SUBSCRIPTION_ID
}

resource "azurerm_resource_group" "rg" {
  name     = "${var.resource-group-name}-${var.environment}"
  location = var.location
  
  tags = {
    environment = var.environment
  }
}
