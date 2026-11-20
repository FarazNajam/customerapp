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

  virtual_network_subnet_id = module.network.subnet_id["outbound_subnet"]

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

  virtual_network_subnet_id = module.network.subnet_id["outbound_subnet"]

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