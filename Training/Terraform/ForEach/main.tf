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
  for_each = var.resourcedetails

  name     = each.value.rg_name
  location = each.value.location
}

resource "azurerm_virtual_network" "myvnet" {
  for_each = var.resourcedetails
  name                = each.value.vnet_name
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.myrg[each.key].location
  resource_group_name = azurerm_resource_group.myrg[each.key].name
}

resource "azurerm_subnet" "mysubnet" {
  for_each = var.resourcedetails

  name                 = each.value.subnet_name
  address_prefixes     = ["10.0.0.0/24"]
  virtual_network_name = azurerm_virtual_network.myvnet[each.key].name
  resource_group_name  = azurerm_resource_group.myrg[each.key].name
}

resource "azurerm_network_interface" "mynic" {
  for_each = var.resourcedetails

  name                = "my-nic"  
  location            = azurerm_resource_group.myrg[each.key].location
  resource_group_name = azurerm_resource_group.myrg[each.key].name
  ip_configuration {
    name                          = "my-ip-config"
    subnet_id                     = azurerm_subnet.mysubnet[each.key].id
    private_ip_address_allocation = "Dynamic"
  }
}


resource "azurerm_virtual_machine" "vm" {
  for_each = var.resourcedetails

  name                  = each.value.name
  location            = azurerm_resource_group.myrg[each.key].location
  resource_group_name = azurerm_resource_group.myrg[each.key].name
  network_interface_ids = [azurerm_network_interface.mynic[each.key].id]
  vm_size               = each.value.size

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "${each.value.name}-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = each.value.name
    admin_username = "adminuser"
    admin_password = "Password1234!"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

}

resource "azurerm_storage_account" "storeaccount" {
  name                     = "psstoraccount"
  resource_group_name      = "westus-rg"
  location                 = "westus2"
  account_tier             = "Standard"
  account_replication_type = "LRS"

}