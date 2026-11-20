
# ============================================================
# PRIVATE DNS ZONES
# ============================================================

resource "azurerm_private_dns_zone" "api" {
  name                = "privatelink.azurewebsites.net"
  resource_group_name = module.rg.rg_name["customerapp"]
}

resource "azurerm_private_dns_zone" "sql" {
  name                = "privatelink.database.windows.net"
  resource_group_name = module.rg.rg_name["customerapp"]
}


# ============================================================
# API APP SERVICE PRIVATE ENDPOINT
# ============================================================

resource "azurerm_private_endpoint" "api_pep" {
  name                = "p-auea-customerapp-api-pep"
  location            = module.rg.location["customerapp"]
  resource_group_name = module.rg.rg_name["customerapp"]
  subnet_id           = module.network.subnet_id["pep_subnet"]

  private_service_connection {
    name                           = "p-auea-customerapp-api-psc"
    private_connection_resource_id = azurerm_linux_web_app.api.id
    subresource_names              = ["sites"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "api-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.api.id]
  }
}


# ============================================================
# API PRIVATE DNS VNET LINK
# ============================================================

resource "azurerm_private_dns_zone_virtual_network_link" "api_vnetl" {
  name                  = "p-auea-customerapp-api-vnetl"
  resource_group_name   = module.rg.rg_name["customerapp"]
  private_dns_zone_name = azurerm_private_dns_zone.api.name
  virtual_network_id    = module.network.vnet_ids["customerapp"]
}


# ============================================================
# AZURE SQL PRIVATE ENDPOINT
# ============================================================

resource "azurerm_private_endpoint" "db_pep" {
  name                = "p-auea-customerapp-db-pep"
  location            = module.rg.location["customerapp"]
  resource_group_name = module.rg.rg_name["customerapp"]
  subnet_id           = module.network.subnet_id["pep_subnet"]

  private_service_connection {
    name                           = "p-auea-customerapp-db-psc"
    private_connection_resource_id = module.db.sqlserver_ids["sqlserver_customerapp"]
    subresource_names              = ["sqlServer"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "sql-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.sql.id]
  }
}


# ============================================================
# SQL PRIVATE DNS VNET LINK
# ============================================================

resource "azurerm_private_dns_zone_virtual_network_link" "sql_vnetl" {
  name                  = "p-auea-customerapp-sql-vnetl"
  resource_group_name   = module.rg.rg_name["customerapp"]
  private_dns_zone_name = azurerm_private_dns_zone.sql.name
  virtual_network_id    = module.network.vnet_ids["customerapp"]
}
