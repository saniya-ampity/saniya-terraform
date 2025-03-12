terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

resource "random_id" "saniya_random" {
  keepers = {
    resource_group = azurerm_resource_group.saniya_rg.name
  }
  byte_length = 2
}

# ✅ Create a Resource Group
resource "azurerm_resource_group" "saniya_rg" {
  name     = "saniya-iam-rg"
  location = "East US"
}

# ✅ Create a Storage Account (like S3)
resource "azurerm_storage_account" "saniya_storage" {
  name                     = "saniya${random_id.saniya_random.hex}store"
  resource_group_name      = azurerm_resource_group.saniya_rg.name
  location                 = azurerm_resource_group.saniya_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# ✅ Create a Blob Container
resource "azurerm_storage_container" "saniya_container" {
  name                  = "saniyablobcontainer"
  storage_account_name  = azurerm_storage_account.saniya_storage.name
  container_access_type = "private"
}

# ✅ Create a Virtual Network
resource "azurerm_virtual_network" "saniya_vnet" {
  name                = "saniya-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.saniya_rg.location
  resource_group_name = azurerm_resource_group.saniya_rg.name
}

# ✅ Create a Subnet
resource "azurerm_subnet" "saniya_subnet" {
  name                 = "saniya-subnet"
  resource_group_name  = azurerm_resource_group.saniya_rg.name
  virtual_network_name = azurerm_virtual_network.saniya_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# ✅ Create a Public IP
resource "azurerm_public_ip" "saniya_public_ip" {
  name                = "saniya-public-ip"
  resource_group_name = azurerm_resource_group.saniya_rg.name
  location            = azurerm_resource_group.saniya_rg.location
  allocation_method   = "Dynamic"
}

# ✅ Create a Network Interface
resource "azurerm_network_interface" "saniya_nic" {
  name                = "saniya-nic"
  location            = azurerm_resource_group.saniya_rg.location
  resource_group_name = azurerm_resource_group.saniya_rg.name

  ip_configuration {
    name                          = "saniya-ip-config"
    subnet_id                      = azurerm_subnet.saniya_subnet.id
    private_ip_address_allocation  = "Dynamic"
    public_ip_address_id           = azurerm_public_ip.saniya_public_ip.id
  }
}

# ✅ Create a Virtual Machine (Without SSH Key)
resource "azurerm_linux_virtual_machine" "saniya_vm" {
  name                  = "saniya-vm"
  resource_group_name   = azurerm_resource_group.saniya_rg.name
  location              = azurerm_resource_group.saniya_rg.location
  size                  = "Standard_DS1_v2"
  admin_username        = "saniyaadmin"
  admin_password        = "Password@1234"
  network_interface_ids = [azurerm_network_interface.saniya_nic.id]

  # ✅ Storage Disk
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 30
  }

  # ✅ Ubuntu Server Image
  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  # ✅ Azure Managed Identity (For IAM Role)
  identity {
    type = "SystemAssigned"
  }

  # ✅ Use Password Based Login (NO SSH KEY REQUIRED)
  disable_password_authentication = false
}

# ✅ Attach IAM Role to Read from Blob Storage
resource "azurerm_role_assignment" "saniya_role" {
  scope                = azurerm_storage_account.saniya_storage.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azurerm_linux_virtual_machine.saniya_vm.identity[0].principal_id
}

# ✅ Output Information
output "storage_account_name" {
  value = azurerm_storage_account.saniya_storage.name
}

output "container_name" {
  value = azurerm_storage_container.saniya_container.name
}

output "vm_public_ip" {
  value = azurerm_public_ip.saniya_public_ip.ip_address
}
