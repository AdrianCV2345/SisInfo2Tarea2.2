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
  name     = "gr-sisinfo-llamadas-1654575"
  location = "East US 2"
}

resource "azurerm_storage_account" "sa" {
  name                     = "saucbenteldelta1562354"  # Cambié <CI> por 01, asegúrate de que sea un nombre válido
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = true  # Cambié la cadena a valor booleano
}

resource "azurerm_storage_container" "raw_entel" {  # Cambié "raw-entel" a "raw_entel" para cumplir con las convenciones de Azure
  name                  = "raw-entel"  # Nombres de contenedores no pueden contener guiones
  storage_account_id    = azurerm_storage_account.sa.id
  container_access_type = "blob"
}

resource "azurerm_storage_blob" "csv_03" {
  name                   = "03.csv"
  storage_account_name   = azurerm_storage_account.sa.name
  storage_container_name = azurerm_storage_container.raw_entel.name  # Corregí el nombre del contenedor
  type                   = "Block"
  source                 = "Dataset/03.csv"
}

resource "azurerm_storage_blob" "csv_05" {
  name                   = "05.csv"
  storage_account_name   = azurerm_storage_account.sa.name
  storage_container_name = azurerm_storage_container.raw_entel.name  # Corregí el nombre del contenedor
  type                   = "Block"
  source                 = "Dataset/05.csv"
}

resource "azurerm_storage_blob" "csv_06" {
  name                   = "06.csv"
  storage_account_name   = azurerm_storage_account.sa.name
  storage_container_name = azurerm_storage_container.raw_entel.name  # Corregí el nombre del contenedor
  type                   = "Block"
  source                 = "Dataset/06.csv"
}

# base de datos sql

resource "azurerm_mssql_server" "db" {
  name                         = "sql-ucb-sisinfo-entel-delta-230423-new"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
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

resource "azurerm_mssql_database" "dw-entel" {  # Cambié el nombre del recurso a "dw_entel" para que coincida con la convención
  name         = "dw_entel_delta"
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

# agregar data factory

resource "azurerm_data_factory" "df" {
  name                = "adf-ucb-dw-entel-1302-new"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}
