########################################
# RESOURCE GROUP
########################################

resource_groups = {
  customerapp = {
    name = "p-auea-customerapp-rg"
    location  = "Australia East"
    tags = {
    environment = "prod"
    owner       = "cloud-team"
    deployment  = "terraform"
    }
  }  
}
########################################
# APP SERVICE
########################################

app_services = {
  frontend = {
    app_service_plan_name = "p-auea-customerapp-asp"
    app_service_name      = "p-auea-customerapp-frontend"
    rg_key                = "customerapp"
    subnet_key            = "app_service_integration_subnet"
  }

  api = {
    app_service_plan_name = "p-auea-customerapp-asp"
    app_service_name      = "p-auea-customerapp-api"
    rg_key                = "customerapp"
    subnet_key            = "app_service_integration_subnet"
  }
}

app_services_vnet_integration = {
  frontend = {
    appservice_key = "frontend"
    subnet_key  = "app_service_integration_subnet"
  }

  api = {
    appservice_key = "api"
    subnet_key     = "app_service_integration_subnet"
  }
}

########################################
# VNET
########################################

vnets = {
    customerapp = {
    name = "p-auea-customerapp-vnet"
    address_space = ["10.0.0.0/16"]
    rg_key = "customerapp"
  }
}

nsgs = {
 app_service_integration_nsg = {
   name   = "p-auea-customerapp-nsg-appsvc"
   rg_key = "customerapp"
 }

  pep_subnet_nsg = {
    name   = "p-auea-customerapp-nsg-pep"
    rg_key = "customerapp"
  }
}

nsg_associations = {
  app_service_integration = {
    subnet_key = "app_service_integration_subnet"
    nsg_key    = "app_service_integration_nsg"
  }

  pep = {
    subnet_key = "pep_subnet"
    nsg_key    = "pep_subnet_nsg"
  }
}

subnets = {
  app_service_integration_subnet = {
    name = "p-auea-customerapp-snet-appsvc"
    address_prefixes = ["10.0.0.0/24"]
    vnet_key = "customerapp"
    rg_key = "customerapp"

    delegation = {
     name    = "webapp"
     service = "Microsoft.Web/serverFarms"
    }
  }
  
  pep_subnet = {
    name = "p-auea-customerapp-snet-pep"
    address_prefixes = ["10.0.1.0/24"]
    vnet_key = "customerapp"
    rg_key = "customerapp"
  }
}

########################################
# DATABASE
########################################

sqlservers = {
  sqlserver_customerapp = {
    name = "p-auea-customerapp-sql"
    version = "12.0"
    admin_login= "sqladmin"
    admin_password = "ReplaceWithSecurePassword123"
    rg_key = "customerapp"
  }
}

sqldatabases = {
  db_customerapp = {
    name = "p-auea-customerapp-db"
    sku_name = "basic"
    server_key = "sqlserver_customerapp"
  }
}

########################################
# FRONT DOOR
########################################

#fd_profile = {
#  fd_profile_flaskapp = {
#    name = "fd-prod-aue-01"
#    sku = "Standard_AzureFrontDoor"
#    response_timeout_seconds = 120
#    rg_key = "flask_app"
#  }
#}

#fd_endpoint = "fde-prod-aue-01"
#fd_og_name  = "fdog-prod-aue-01"
#fd_route    = "fdroute-prod-aue-01"

########################################
# STORAGE ACCOUNT
########################################

storage_accounts = {
  customerapp = {
    name = "paueacustomerappsa"
    account_tier = "Standard"
    account_replication_type = "LRS"
    rg_key = "customerapp"
  }
}

########################################
# KEY VAULT
########################################

key_vaults = {
  kv_customerapp = {
    name = "p-auea-customerapp-kv"
    enabled_for_disk_encryption = true
    soft_delete_retention_days = 7
    purge_protection_enabled = false
    sku_name = "standard"
    rbac_authorization_enabled = true
    rg_key = "customerapp"
  }
}

########################################
# APP CONFIG
########################################

app_configs = {
  customerapp = {
    name = "p-auea-customerapp-ac"
    sku = "free"
    local_auth_enabled = false
    public_network_access = "enabled"
    purge_protection_enabled = false
    rg_key = "customerapp"
  }
}

service_bus = {
  customerapp = {
    name = "p-auea-customerapp-servicebus"
    sku = "Basic"
    rg_key = "customerapp"
  }
}
