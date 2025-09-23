provider "azurerm" {
  # The "feature" block is required for AzureRM provider 2.x. 
  features {}
  
  # Use service principal authentication via environment variables
  # These will be set by the Azure CLI task in the pipeline
  use_cli = false
}

resource "azurerm_resource_group" "rg" {
  name     = "${var.resource-group-name}-${var.environment}"
  location = var.location
  
  tags = {
    environment = var.environment
  }
}
