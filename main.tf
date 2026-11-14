terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
}

data "azurerm_client_config" "current" {}

module "rg" {
  source          = "../enterprise-azure-terraform-modules/modules/resource_group"
  resource_groups = var.resource_groups
}

module "network" {
  source   = "../enterprise-azure-terraform-modules/modules/network"
  rg_name  = module.rg.rg_name
  location = module.rg.location
  vnets    = var.vnets
  subnets  = var.subnets
}

module "nsg" {
  source           = "../enterprise-azure-terraform-modules/modules/nsg"
  rg_name          = module.rg.rg_name
  location         = module.rg.location
  nsgs             = var.nsgs
  subnet_id        = module.network.subnet_id
  nsg_associations = var.nsg_associations
}

resource "azurerm_service_plan" "customerapp" {
  name                = "p-auea-customerapp-asp"
  resource_group_name = module.rg.rg_name["customerapp"]
  location            = module.rg.location["customerapp"]

  os_type  = "Linux"
  sku_name = "B1"

  tags = {
    application = "customerapp"
    environment = "production"
  }
}

resource "azurerm_linux_web_app" "api" {
  name                = "p-auea-customerapp-api"
  resource_group_name = module.rg.rg_name["customerapp"]
  location            = module.rg.location["customerapp"]
  service_plan_id     = azurerm_service_plan.customerapp.id

  https_only = true

  virtual_network_subnet_id = module.network.subnet_id["app_service_integration_subnet"]

  identity {
    type = "SystemAssigned"
  }

  site_config {
    always_on        = true
    app_command_line = "gunicorn --bind=0.0.0.0 --timeout 600 app:app"

    application_stack {
      python_version = "3.11"
    }
  }

  app_settings = {
    DB_SERVER = "p-auea-customerapp-sqlserver.database.windows.net"
    DB_NAME   = "p-auea-customerapp-db"

    SCM_DO_BUILD_DURING_DEPLOYMENT = "true"
  }

  tags = {
    application = "customerapp"
    environment = "production"
  }
}

resource "azurerm_linux_web_app" "frontend" {
  name                = "p-auea-customerapp-frontend"
  resource_group_name = module.rg.rg_name["customerapp"]
  location            = module.rg.location["customerapp"]
  service_plan_id     = azurerm_service_plan.customerapp.id

  https_only = true

  virtual_network_subnet_id = module.network.subnet_id["app_service_integration_subnet"]

  site_config {
    always_on        = true
    app_command_line = "gunicorn --bind=0.0.0.0 --timeout 600 app:app"

    application_stack {
      python_version = "3.11"
    }
  }

  app_settings = {
    API_URL = "https://p-auea-customerapp-api.azurewebsites.net"

    SCM_DO_BUILD_DURING_DEPLOYMENT = "true"
  }

  tags = {
    application = "customerapp"
    environment = "production"
  }
}

output "api_managed_identity_principal_id" {
  description = "CustomerApp API system-assigned managed identity principal ID"
  value       = azurerm_linux_web_app.api.identity[0].principal_id
}

module "db" {
  source       = "../enterprise-azure-terraform-modules/modules/database"
  rg_name      = module.rg.rg_name
  location     = module.rg.location
  sqlservers   = var.sqlservers
  sqldatabases = var.sqldatabases
  tenant_id    = data.azurerm_client_config.current.tenant_id
}

#module "frontdoor" {
#  source   = "../enterprise-azure-terraform-modules/modules/frontdoor"
#  rg_name  = module.rg.rg_name
#  location = module.rg.location
#  fd_profile       = var.fd_profile
#  fd_endpoint      = var.fd_endpoint
#  app_hostname     = module.app.default_hostnames
#  fd_og_name       = var.fd_og_name
#  fd_route         = var.fd_route
# }

module "storage_account" {
  source           = "../enterprise-azure-terraform-modules/modules/storage_account"
  rg_name          = module.rg.rg_name
  location         = module.rg.location
  storage_accounts = var.storage_accounts
}

module "key_vault" {
  source     = "../enterprise-azure-terraform-modules/modules/key_vault"
  rg_name    = module.rg.rg_name
  location   = module.rg.location
  tenant_id  = data.azurerm_client_config.current.tenant_id
  key_vaults = var.key_vaults
}

module "app_config" {
  source      = "../enterprise-azure-terraform-modules/modules/app_config"
  rg_name     = module.rg.rg_name
  location    = module.rg.location
  app_configs = var.app_configs
}

#resource "azurerm_private_endpoint" "key_vault" {
#  name                = "p-auea-customerapp-kv-pep"
#  location            = module.rg.location["customerapp"]
#  resource_group_name = module.rg.rg_name["customerapp"]
#  subnet_id = module.network.subnet_id["pep_subnet"]

#  private_service_connection {
#    name                           = "internal"
#    private_connection_resource_id = module.key_vault.key_vault_ids["kv_customerapp"]
#    is_manual_connection           = false
#    subresource_names              = ["vault"]
#  }
#}

#resource "azurerm_private_endpoint" "sql_server" {
#  name                = "p-auea-customerapp-db-pep"
#  location            = module.rg.location["customerapp"]
#  resource_group_name = module.rg.rg_name["customerapp"]
#  subnet_id = module.network.subnet_id["pep_subnet"]

#  private_service_connection {
#    name                           = "internal"
#    private_connection_resource_id = module.db.sqlserver_ids["sqlserver_customerapp"]
#    is_manual_connection           = false
#    subresource_names              = ["sqlServer"]
#  }
#}

module "service_bus" {
  source      = "../enterprise-azure-terraform-modules/modules/service_bus"
  rg_name     = module.rg.rg_name
  location    = module.rg.location
  service_bus = var.service_bus
}