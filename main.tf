terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.107.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.sub-id
}

#########################
# Variables (edit these)
#########################
variable "sub-id" {
  type = string
  default = "316f0ed4-2796-4561-a734-24b156826ae5"

}

variable "location" {
  type    = string
  default = "westeurope"
}

variable "name_prefix" {
  type    = string
  default = "demo"
}

variable "admin_username" {
  type    = string
  default = "azureuser"
}

variable "ssh_public_key_path" {
  type    = string
  default = "~/.ssh/azure_automation_rsa.pub"
}

# Set to YOUR public IP /32 (e.g. "203.0.113.4/32")
variable "allowed_ip_cidr" {
  type    = string
  default = "109.147.125.164/32"
}

# VM size (policy-friendly)
variable "vm_size" {
  type    = string
  default = "Standard_B2s"
}

#########################
# Resource Group & Net
#########################
resource "azurerm_resource_group" "rg" {
  name     = "RG2"
  location = var.location
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.name_prefix}-vnet"
  address_space       = ["10.10.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "web"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.10.1.0/24"]
}

#########################
# One NSG for both VMs
#########################
resource "azurerm_network_security_group" "allow_from_me" {
  name                = "${var.name_prefix}-allow-from-me-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  # Allow ALL inbound from *your* IP (smoke-test convenience)
  security_rule {
    name                       = "AllowAllFromMyIP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = var.allowed_ip_cidr
    destination_address_prefix = "*"
  }
}

#########################
# VM1 (Ubuntu, public IP)
#########################
resource "azurerm_public_ip" "vm1_pip" {
  name                = "${var.name_prefix}-vm1-pip"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "vm1_nic" {
  name                = "${var.name_prefix}-vm1-nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipcfg"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm1_pip.id
  }
}

resource "azurerm_network_interface_security_group_association" "vm1_nic_nsg" {
  network_interface_id      = azurerm_network_interface.vm1_nic.id
  network_security_group_id = azurerm_network_security_group.allow_from_me.id
}

resource "azurerm_linux_virtual_machine" "vm1" {
  name                  = "VM1"
  resource_group_name   = azurerm_resource_group.rg.name
  location              = var.location
  size                  = var.vm_size
  admin_username        = var.admin_username
  network_interface_ids = [azurerm_network_interface.vm1_nic.id]

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.ssh_public_key_path)
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  os_disk {
    name                 = "${var.name_prefix}-vm1-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
}

