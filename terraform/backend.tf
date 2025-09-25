#Set the terraform backend
terraform {
  # Backend variables are initialized by Azure DevOps
  backend "azurerm" {
    # Use OIDC authentication instead of storage account keys
    use_oidc = true
  }
}
