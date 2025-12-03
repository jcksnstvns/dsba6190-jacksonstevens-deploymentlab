// ---------------------------------------
// Tags
// ---------------------------------------
locals {
  tags = {
    class      = var.tag_class
    instructor = var.tag_instructor
    semester   = var.tag_semester
  }
}

// ------------------------------
// Random Suffix
// ------------------------------
resource "random_integer" "deployment_id_suffix" {
  min = 10
  max = 99
}

// ------------------------------
// Resource Group
// ------------------------------
resource "azurerm_resource_group" "rg" {
  name     = "rg-${var.class_name}-${var.student_name}-${var.environment}-${var.location}-${random_integer.deployment_id_suffix.result}"
  location = var.location

  tags = local.tags
}

// ------------------------------
// Virtual Network
// ------------------------------
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${var.class_name}-${var.student_name}-${var.environment}-${var.location}-${random_integer.deployment_id_suffix.result}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = [var.address_space]

  tags = local.tags
}

// ------------------------------
// Subnet
// ------------------------------
resource "azurerm_subnet" "subnet" {
  name                 = "subnet-app-${random_integer.deployment_id_suffix.result}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet_prefix]

  service_endpoints = [
    "Microsoft.Sql",
    "Microsoft.Storage"
  ]
}

// ------------------------------
// Storage Account
// ------------------------------
resource "azurerm_storage_account" "storage" {
  name                     = "sto${var.class_name}${var.student_name}${var.environment}${random_integer.deployment_id_suffix.result}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  is_hns_enabled           = true

  network_rules {
    default_action             = "Deny"
    virtual_network_subnet_ids = [azurerm_subnet.subnet.id]
  }

  tags = local.tags
}

// ------------------------------
// SQL Server
// ------------------------------
resource "azurerm_mssql_server" "sqlserver" {
  name                         = "sql-${var.class_name}-${var.student_name}-${var.environment}-${random_integer.deployment_id_suffix.result}"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = var.location
  version                      = "12.0"
  administrator_login          = "sqladminuser"
  administrator_login_password = "Password123!123!"

  tags = local.tags
}

// ------------------------------
// SQL Database
// ------------------------------
resource "azurerm_mssql_database" "sqldb" {
  name      = "db-${var.class_name}-${var.student_name}-${var.environment}-${random_integer.deployment_id_suffix.result}"
  server_id = azurerm_mssql_server.sqlserver.id
  sku_name  = "Basic"

  tags = local.tags
}

// ------------------------------
// SQL VNET Rule
// ------------------------------
resource "azurerm_mssql_virtual_network_rule" "sqlvnet" {
  name      = "sql-vnet-rule"
  server_id = azurerm_mssql_server.sqlserver.id
  subnet_id = azurerm_subnet.subnet.id
}