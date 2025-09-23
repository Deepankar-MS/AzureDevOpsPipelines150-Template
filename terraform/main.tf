provider "azurerm" {
  # The "feature" block is required for AzureRM provider 2.x. 
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "${var.resource-group-name}-${var.environment}"
  location = var.location
  
  tags = {
    environment = var.environment
  }
}
