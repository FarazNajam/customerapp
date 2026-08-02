########################################
# RESOURCE GROUP
########################################

resource_groups = {
  infraguardian = {
    name = "p-auea-infragai-rg"
    location  = "Australia East"
    tags = {
    environment = "prod"
    owner       = "cloud-team"
    deployment  = "terraform"
    }
  }

    hubnetwork = {
    name = "p-auea-hubnetwork-rg"
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
    app_service_plan_name = "p-auea-infraguardian-asp"
    app_service_name  = "frontend"
    rg_key = "infraguardian"
    subnet_key = "frontend_infraguardian"
  }
}

app_services_vnet_integration = {
  frontend = {
    appservice_key = "frontend"
    subnet_key  = "frontend_infraguardian"
  }
}

########################################
# VNET
########################################

vnets = {
  hub = {
    name = "p-auea-hub-vn"
    address_space = ["10.0.0.0/16"]
    dns_servers = ["10.0.0.4","10.0.0.5"]
    rg_key = "hubnetwork"
  }

    infraguardian = {
    name = "p-auea-infraguardian-vn"
    address_space = ["10.1.0.0/16"]
    dns_servers = ["10.0.0.4","10.0.0.5"]
    rg_key = "infraguardian"
  }
}

nsgs = {
  frontend_infraguardian = {
    name = "p-auea-infraguardian-fe_nsg"
    rg_key = "infraguardian"
  }
}

subnets = {
  firewall_hub = {
    name = "p-auea-infraguardian-fw_sn"
    address_prefixes = ["10.0.1.0/24"]
    vnet_key = "hub"
    rg_key = "hubnetwork"
  }

  frontend_infraguardian = {
    name = "p-auea-infraguardian-fe_sb"
    address_prefixes = ["10.0.2.0/24"]
    vnet_key = "infraguardian"
    rg_key = "infraguardian"
  }
}

########################################
# DATABASE
########################################

sqlservers = {
  infraguardian = {
    name = "p-auea-infraguardian-sqlserver"
    version = "12.0"
    admin_login= "sqladmin"
    admin_password = "ReplaceWithSecurePassword123"
    rg_key = "infraguardian"
  }
}

sqldatabases = {
  infraguardian = {
    name = "p-auea-infraguardian-sqldatabase01"
    sku_name = "basic"
    server_key = "infraguardian"
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
  infraguardian = {
    name = "paueainfraguardianst"
    account_tier = "Standard"
    account_replication_type = "LRS"
    rg_key = "infraguardian"
  }
}

########################################
# KEY VAULT
########################################

key_vaults = {
  infraguardian = {
    name = "p-auea-infraguardian-kv"
    enabled_for_disk_encryption = true
    soft_delete_retention_days = 7
    purge_protection_enabled = false
    sku_name = "standard"
    rbac_authorization_enabled = true
    rg_key = "infraguardian"
  }
}

########################################
# KEY VAULT SECRETS
########################################

key_vault_secrets = {
  sqlserver_id = {
    name          = "sqlserverid"
    sqlserver_key = "infraguardian"
    key_vault_key = "infraguardian"
  }

    sqlserver_fqdn = {
    name          = "sqlserverfqdn"
    sqlserver_key = "infraguardian"
    key_vault_key = "infraguardian"
  }

    database_id= {
    name          = "databaseid"
    sqlserver_key = "infraguardian"
    key_vault_key = "infraguardian"
  }

    database_name = {
    name          = "databasename"
    sqlserver_key = "infraguardian"
    key_vault_key = "infraguardian"
  }
}

########################################
# APP CONFIG
########################################

app_configs = {
  infraguardian = {
    name = "p-auea-infraguardian-ac"
    sku = "standard"
    local_auth_enabled = false
    public_network_access = "enabled"
    purge_protection_enabled = false
    soft_delete_retention_days = 1
    rg_key = "infraguardian"
  }
}

########################################
# VIRTUAL MACHINES
########################################

nics= {
  vm01_infraguardian = {
    network_interface_name = "p-auea-infraguardian-nic_vm01"
    ip_configuration = {
      name = "internal"
      subnet_key = "frontend_infraguardian"
      private_ip_address_allocation = "Dynamic"
    }
    rg_key = "infraguardian"
  }
}

vms = {}

#vms= {
#  vm01 = {
#    name = "p-auea-flaskapp-vm01"
#    nic_key = "nic01_vm01"
#    subnet_key = "subnet_app"
#    rg_key = "flask_app"
#    vm_size = "Standard_B2s"
#    computer_name = "vm01"
#    admin_username = "admin01"
#    admin_password = "Faraznajam1985!"
#  }
#}

private_endpoints= {
  kv_infraguardian = {
    name = "p-auea-infraguardian-kv-pep"
    private_service_connection = {
      name = "internal"
      is_manual_connection = false
    }
    rg_key = "infraguardian"
    subnet_key = "frontend_infraguardian"
    resource_key = "infraguardian"
  }
}

service_bus = {
  infraguardian = {
    name = "p-auea-infraguardian-servicebus"
    sku = "Basic"
    rg_key = "infraguardian"
  }
}
