terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=4.23.0"
    }
  }
}
provider "azurerm" {
  features {}

  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id
}

# grupo de recursos
resource "azurerm_resource_group" "rg" {
  name     = "gr-sisinfo-llamadas-46456464"
  location = "East US"
}
 
resource "azurerm_storage_account" "sa" {
  name                     = "saucbtigodelta4345343"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = true
}
 
resource "azurerm_storage_container" "raw-tigo" {
  name                  = "raw-tigo"
  storage_account_id    = azurerm_storage_account.sa.id
  container_access_type = "blob"
}

resource "azurerm_storage_blob" "llamadascsv" {
  name                   = "llamadas.csv"
  storage_account_name   = azurerm_storage_account.sa.name
  storage_container_name = azurerm_storage_container.raw-tigo.name
  type                   = "Block"
  source                 = "dataset/llamadas-tigo.csv"
}

resource "azurerm_storage_blob" "llamadasxls" {
  name                   = "llamadas.xlsx"
  storage_account_name   = azurerm_storage_account.sa.name
  storage_container_name = azurerm_storage_container.raw-tigo.name
  type                   = "Block"
  source                 = "dataset/llamadas-tigo.xlsx"
}



# base de datos sql
 
 
 
resource "azurerm_mssql_server" "db" {
  name                         = "sql-ucb-sisinfo-tigo-delta-7212836"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = "East US 2"
  version                      = "12.0"
  administrator_login          = "Cristhian"
  administrator_login_password = "4-v3ry-53cr37-p455w0rd"
}

resource "azurerm_mssql_firewall_rule" "rulefirewall" {
  name             = "FirewallRule1"
  server_id        = azurerm_mssql_server.db.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "255.255.255.255"
}


resource "azurerm_mssql_database" "dw-tigo" {
  name         = "dw_tigo"
  server_id    = azurerm_mssql_server.db.id
  collation    = "SQL_Latin1_General_CP1_CI_AS"
  license_type = "LicenseIncluded"
  max_size_gb  = 2
  sku_name     = "S0"
  enclave_type = "VBS"
 
  tags = {
    foo = "bar"
  }
 
  # prevent the possibility of accidental data loss
  lifecycle {
    prevent_destroy = false
  }
}

# agregar  data factory

resource "azurerm_data_factory" "df" {
  name                = "adf-ucb-dw-tigo-4536427"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}
