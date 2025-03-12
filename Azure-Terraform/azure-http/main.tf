

resource "azurerm_resource_group" "saniya_rg" {
  name     = "saniya-http-rg"
  location = "East US"
}

resource "azurerm_virtual_network" "saniya_vnet" {
  name                = "saniya-vnet"
  resource_group_name = azurerm_resource_group.saniya_rg.name
  location            = azurerm_resource_group.saniya_rg.location
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "saniya_subnet" {
  name                 = "saniya-subnet"
  resource_group_name  = azurerm_resource_group.saniya_rg.name
  virtual_network_name = azurerm_virtual_network.saniya_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "saniya_public_ip" {
  name                = "saniya-public-ip"
  resource_group_name = azurerm_resource_group.saniya_rg.name
  location            = azurerm_resource_group.saniya_rg.location
  allocation_method   = "Static"
}

resource "azurerm_application_gateway" "saniya_app_gateway" {
  name                = "saniya-app-gateway"
  resource_group_name = azurerm_resource_group.saniya_rg.name
  location            = azurerm_resource_group.saniya_rg.location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "saniya-gateway-ip-config"
    subnet_id = azurerm_subnet.saniya_subnet.id
  }

  frontend_ip_configuration {
    name                 = "saniya-frontend-ip"
    public_ip_address_id = azurerm_public_ip.saniya_public_ip.id
  }

  frontend_port {
    name = "saniya-frontend-port"
    port = 80
  }

  backend_address_pool {
    name = "saniya-backend-pool"
  }

  backend_http_settings {
    name                  = "saniya-backend-http"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 20
  }

  http_listener {
    name                           = "saniya-http-listener"
    frontend_ip_configuration_name = "saniya-frontend-ip"
    frontend_port_name             = "saniya-frontend-port"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                        = "saniya-routing-rule"
    rule_type                   = "Basic"
    http_listener_name          = "saniya-http-listener"
    backend_address_pool_name   = "saniya-backend-pool"
    backend_http_settings_name  = "saniya-backend-http"
    priority                    = 1
  }
}

resource "azurerm_log_analytics_workspace" "saniya_logs" {
  name                = "saniya-logs"
  location            = azurerm_resource_group.saniya_rg.location
  resource_group_name = azurerm_resource_group.saniya_rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_monitor_action_group" "saniya_action_group" {
  name                = "saniya-action-group"
  resource_group_name = azurerm_resource_group.saniya_rg.name
  short_name          = "saniyaAG"

  email_receiver {
    name          = "send-email"
    email_address = "saniya.i@ampityinfotech.com"
  }
}

resource "azurerm_monitor_metric_alert" "saniya_http_alert" {
  name                = "saniya-http-alert"
  resource_group_name = azurerm_resource_group.saniya_rg.name
  scopes              = [azurerm_application_gateway.saniya_app_gateway.id]

  criteria {
    metric_namespace = "Microsoft.Network/applicationGateways"
    metric_name      = "TotalRequests"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = 100
  }

  action {
    action_group_id = azurerm_monitor_action_group.saniya_action_group.id
  }
}

provider "azurerm" {
   subscription_id = "eb42806a-9a76-49bd-8024-373de52d371d"
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}
