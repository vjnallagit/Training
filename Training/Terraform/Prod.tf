terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}
module "module_prod"{
source = "./modules"
rglocation = "West US"
rgname = "Infra-WestUS-RG"
}
