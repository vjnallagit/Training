terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {

  features {}

  subscription_id = "1a969a93-6700-4065-8df6-c63ab4cd3352"
  client_id = "97869bb7-15ca-4806-ae6d-229e8c9919e1"
  tenant_id = "d60722e7-35f8-42e3-a83d-ed9a27cf4a9b"
  client_secret = "G7U8Q~Ovnk1QDddvEcoC7MNqScvQcTbHL_7Geds1"

}

data "azurerm_resource_group" "Infra-RG" {
  name     = "Infra-WestUS-RG"
  }

data "azurerm_network_security_group" "Sec-gp1" {
  name                = "Sec-Gp-WestUS"
  resource_group_name = data.azurerm_resource_group.Infra-RG.name
  }

data "azurerm_virtual_network" "vnet1" {
  name                = "vnet-uswest"
  resource_group_name = data.azurerm_resource_group.Infra-RG.name
}
data "azurerm_subnet" "subnet1" {
 name = "Prod-Snet"
 virtual_network_name = data.azurerm_virtual_network.vnet1.name
 resource_group_name = data.azurerm_resource_group.Infra-RG.name
}
resource "azurerm_network_interface" "nic1" {
  name                = "nic1-${var.vmname}"
  location = data.azurerm_resource_group.Infra-RG.location
  resource_group_name = data.azurerm_resource_group.Infra-RG.name

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = data.azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "vm1" {
  name                = "${var.vmname}"
  resource_group_name = data.azurerm_resource_group.Infra-RG.name
  location            = data.azurerm_resource_group.Infra-RG.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  admin_password      = "P@$$w0rd1234!"
  network_interface_ids = [
  azurerm_network_interface.nic1.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
}


