terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.65"
    }
  }

  required_version = "= 1.0.3"
}

provider "azurerm" {
  features {}
}

module "demomodule" {
source ="git::https://github.com/zealvora/tmp-repo.git"

}