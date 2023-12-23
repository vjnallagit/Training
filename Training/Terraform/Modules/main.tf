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

resource "azurerm_resource_group" "Infra-RG" {
  name     = "${var.rgname}"
  location = "${var.rglocation}"
}

resource "azurerm_network_security_group" "Sec-gp1" {
  name                = "Sec-Gp-WestUS"
  location            = azurerm_resource_group.Infra-RG.location
  resource_group_name = azurerm_resource_group.Infra-RG.name
}

resource "azurerm_virtual_network" "vnet1" {
  name                = "vnet-uswest"
  location            = azurerm_resource_group.Infra-RG.location
  resource_group_name = azurerm_resource_group.Infra-RG.name
  address_space       = ["10.0.0.0/16"]
  #dns_servers         = ["10.0.0.4", "10.0.0.5"]

  subnet {
    name           = "Prod-Snet"
    address_prefix = "10.0.1.0/24"
    security_group = azurerm_network_security_group.Sec-gp1.id
  }

  subnet {
    name           = "Dev-Snet"
    address_prefix = "10.0.2.0/24"
    security_group = azurerm_network_security_group.Sec-gp1.id
  }

}


resource "azurerm_network_security_rule" "nsg-rule1" {
  name                        = "rdp-rule"
  priority                    = 100
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3389"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.Infra-RG.name
  network_security_group_name = azurerm_network_security_group.Sec-gp1.name
}

data "azurerm_subnet" "subnet1" {
  name                = "Prod-Snet"
  virtual_network_name = azurerm_virtual_network.vnet1.name
  resource_group_name = azurerm_resource_group.Infra-RG.name
  }
data "azurerm_subnet" "subnet2" {
  virtual_network_name = azurerm_virtual_network.vnet1.name
  name                = "Dev-Snet"
   resource_group_name = azurerm_resource_group.Infra-RG.name
  }

resource "azurerm_network_interface" "nic1" {
  name                = "nic1"
  location            = azurerm_resource_group.Infra-RG.location
  resource_group_name = azurerm_resource_group.Infra-RG.name

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = data.azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "vm1" {
  name                = "ABKVM01"
  resource_group_name = azurerm_resource_group.Infra-RG.name
  location            = azurerm_resource_group.Infra-RG.location
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

resource "azurerm_storage_account" "storeacc" {
  name                     = "uswestsa001"
  resource_group_name      = azurerm_resource_group.Infra-RG.name
  location                 = azurerm_resource_group.Infra-RG.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    environment = "staging"
  }
}
