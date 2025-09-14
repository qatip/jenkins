terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.16.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = "RG1"
    storage_account_name = "jenkinsstate6789"
    container_name       = "terraform-state"
    key                  = "terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
  # Do NOT hardcode subscription here. Let Jenkins auth (SP/OIDC) set it via env:
  # ARM_SUBSCRIPTION_ID / ARM_TENANT_ID / ARM_CLIENT_ID / ARM_USE_OIDC= true
}

variable "location"        { 
  type = string
  default = "westeurope" 
}

variable "name_prefix"     {
  type = string
  default = "demo" 
}

variable "admin_username"  {
  type = string
  default = "azureuser" 
}

variable "allowed_ip_cidrs" {
  type = list(string)
}

variable "ssh_public_key"  {
  type = string
  sensitive = false 
} # PUBLIC key content

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

resource "azurerm_network_security_group" "allow_from_me" {
  name                = "${var.name_prefix}-allow-from-me-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "AllowAllFromMyIP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefixes    = var.allowed_ip_cidrs 
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow8080"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix    = "*" 
    destination_address_prefix = "*"
  }



}

data "azurerm_virtual_network" "remote" {
  name                = "demo-vnet"
  resource_group_name = "RG4"
}


# Local -> Remote
resource "azurerm_virtual_network_peering" "local_to_remote" {
  name                      = "rg2-to-rg4"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.vnet.name
  remote_virtual_network_id = data.azurerm_virtual_network.remote.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  use_remote_gateways          = false
  allow_gateway_transit        = false
}

# Remote -> Local
resource "azurerm_virtual_network_peering" "remote_to_local" {
  name                      = "rg4-to-rg2"
  resource_group_name       = "RG4"
  virtual_network_name      = "demo-vnet"
  remote_virtual_network_id = azurerm_virtual_network.vnet.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  use_remote_gateways          = false
  allow_gateway_transit        = false
}




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
  size                  = "Standard_B2s"
  admin_username        = var.admin_username
  network_interface_ids = [azurerm_network_interface.vm1_nic.id]

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
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
