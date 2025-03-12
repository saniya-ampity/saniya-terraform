provider "azurerm" {
  features {}

  subscription_id = "eb42806a-9a76-49bd-8024-373de52d371d"
}

resource "azurerm_resource_group" "saniya_rg" {
  name     = "saniya-lb-rg"
  location = "East US"
}

resource "azurerm_virtual_network" "saniya_vnet" {
  name                = "saniya-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.saniya_rg.location
  resource_group_name = azurerm_resource_group.saniya_rg.name
}

resource "azurerm_subnet" "saniya_private_subnet" {
  name                 = "saniya-private-subnet"
  resource_group_name  = azurerm_resource_group.saniya_rg.name
  virtual_network_name = azurerm_virtual_network.saniya_vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_subnet" "saniya_public_subnet" {
  name                 = "saniya-public-subnet"
  resource_group_name  = azurerm_resource_group.saniya_rg.name
  virtual_network_name = azurerm_virtual_network.saniya_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_interface" "saniya_nic" {
  count               = 2
  name                = "saniya-nic-${count.index}"
  location            = azurerm_resource_group.saniya_rg.location
  resource_group_name = azurerm_resource_group.saniya_rg.name

  ip_configuration {
    name                          = "saniya-ip-config-${count.index}"
    subnet_id                     = azurerm_subnet.saniya_private_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "saniya_vm" {
  count                 = 2
  name                  = "saniya-vm-${count.index}"
  resource_group_name   = azurerm_resource_group.saniya_rg.name
  location              = azurerm_resource_group.saniya_rg.location
  size                  = "Standard_B1s"
  admin_username        = "azureuser"

  network_interface_ids = [azurerm_network_interface.saniya_nic[count.index].id]

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("C:/Users/Dell/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

resource "azurerm_public_ip" "saniya_bastion_ip" {
  name                = "saniya-bastion-ip"
  location            = azurerm_resource_group.saniya_rg.location
  resource_group_name = azurerm_resource_group.saniya_rg.name
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "saniya_bastion_nic" {
  name                = "saniya-bastion-nic"
  location            = azurerm_resource_group.saniya_rg.location
  resource_group_name = azurerm_resource_group.saniya_rg.name

  ip_configuration {
    name                          = "saniya-bastion-ip-config"
    subnet_id                     = azurerm_subnet.saniya_public_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.saniya_bastion_ip.id
  }
}

resource "azurerm_linux_virtual_machine" "saniya_bastion" {
  name                  = "saniya-bastion"
  resource_group_name   = azurerm_resource_group.saniya_rg.name
  location              = azurerm_resource_group.saniya_rg.location
  size                  = "Standard_B1s"
  admin_username        = "azureuser"

  network_interface_ids = [azurerm_network_interface.saniya_bastion_nic.id]

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("C:/Users/Dell/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

resource "azurerm_lb" "saniya_lb" {
  name                = "saniya-load-balancer"
  location            = azurerm_resource_group.saniya_rg.location
  resource_group_name = azurerm_resource_group.saniya_rg.name

  frontend_ip_configuration {
    name                          = "saniya-frontend-ip"
    subnet_id                     = azurerm_subnet.saniya_private_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_lb_backend_address_pool" "saniya_backend_pool" {
  loadbalancer_id = azurerm_lb.saniya_lb.id
  name            = "saniya-backend-pool"
}

resource "azurerm_network_interface_backend_address_pool_association" "saniya_nic_association" {
  count                   = 2
  network_interface_id    = azurerm_network_interface.saniya_nic[count.index].id
  ip_configuration_name   = "saniya-ip-config-${count.index}"
  backend_address_pool_id = azurerm_lb_backend_address_pool.saniya_backend_pool.id
}

resource "azurerm_lb_probe" "saniya_health_probe" {
  loadbalancer_id = azurerm_lb.saniya_lb.id
  name            = "saniya-health-probe"
  port            = 80
  protocol        = "Tcp"
}

resource "azurerm_lb_rule" "saniya_lb_rule" {
  loadbalancer_id                = azurerm_lb.saniya_lb.id
  name                           = "saniya-lb-rule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = azurerm_lb.saniya_lb.frontend_ip_configuration[0].name
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.saniya_backend_pool.id]
  probe_id                       = azurerm_lb_probe.saniya_health_probe.id
}
