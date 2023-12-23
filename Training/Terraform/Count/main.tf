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

resource "azurerm_resource_group" "myrg" {
  name     = "NextOpsVideos"
  location = "eastus"
}

resource "azurerm_virtual_network" "myvnet" {
  name                = var.vnet_name
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.myrg.location
  resource_group_name = azurerm_resource_group.myrg.name
}

resource "azurerm_subnet" "mysubnet" {
  count                = 2
  name                 = "my-subnet-${count.index}"
  address_prefixes     = ["10.0.${count.index}.0/24"]
  virtual_network_name = azurerm_virtual_network.myvnet.name
  resource_group_name  = azurerm_resource_group.myrg.name
}

resource "azurerm_network_interface" "mynic" {
  count               = 2  
  name                = "my-nic-${count.index}"
  location            = azurerm_resource_group.myrg.location
  resource_group_name = azurerm_resource_group.myrg.name

  ip_configuration {
    name                          = "my-ip-config"
    subnet_id                     = azurerm_subnet.mysubnet[count.index].id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_machine" "myvm" {
  count                = 2
  name                 = "my-vm-${count.index}"
  location             = azurerm_resource_group.myrg.location
  resource_group_name  = azurerm_resource_group.myrg.name
  network_interface_ids = [azurerm_network_interface.mynic[count.index].id]
  vm_size               = "Standard_DS1_v2"
 
storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "myosdisk-${count.index}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
   computer_name  = "my-vm-${count.index}"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    environment = "staging"
  }
}

 