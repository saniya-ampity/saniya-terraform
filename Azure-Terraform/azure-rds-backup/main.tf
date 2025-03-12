resource "azurerm_resource_group" "saniya_rds_rg" {
  name     = "saniya-rds-rg"
  location = "East US 2"
}

provider "azurerm" {
  features {}
  subscription_id = "eb42806a-9a76-49bd-8024-373de52d371d"
}

resource "azurerm_storage_account" "saniya_storage" {
  name                     = "saniyastoragebackup"
  resource_group_name = azurerm_resource_group.saniya_rds_rg.name
  location                 = azurerm_resource_group.saniya_rds_rg.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
}

resource "azurerm_storage_container" "saniya_container" {
  name                  = "dbbackups"
  storage_account_id  = azurerm_storage_account.saniya_storage.id
  container_access_type = "private"
}

resource "azurerm_mysql_flexible_server" "saniya_db" {
  zone = "1"
  depends_on = [azurerm_storage_account.saniya_storage, azurerm_storage_container.saniya_container]

  
  name                = "saniya-db"
  resource_group_name = azurerm_resource_group.saniya_rds_rg.name
  location            = azurerm_resource_group.saniya_rds_rg.location

  administrator_login    = "adminuser"
  administrator_password = "P@ssw0rd123!"

  sku_name     = "GP_Standard_D2ds_v4"
}
