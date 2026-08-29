########################################
# RG VARIABLES
########################################

variable "resource_groups" {
  type = map(object({
    name = string
    location = string
    tags = map(string)
  }))
}

########################################
# NETWORK VARIABLES
########################################

variable "vnets" {
  type = map(object({
    name = string
    address_space = list(string)
    rg_key = string
  }))
}

variable "nsgs" {
  type = map(object({
    name = string
    rg_key = string
  }))
}

variable "nsg_associations" {
  type = map(object({
    subnet_key = string
    nsg_key    = string
  }))
}

variable "subnets" {
  type = map(object({
    name               = string
    address_prefixes   = list(string)
    vnet_key           = string
    rg_key             = string

    delegation = optional(object({
      name    = string
      service = string
    }))
  }))
}
########################################
# APP VARIABLES
########################################

variable "app_services" {
  type = map(object({
    app_service_name       = string
    app_service_plan_name  = string
    rg_key                 = string
    subnet_key             = string
    app_settings = optional(map(string), {})
    startup_command = optional(string, "")
  }))
}

variable "app_services_vnet_integration" {
  type = map(object({
    appservice_key = string
    subnet_key  = string
  }))
}

########################################
# DB VARIABLES
########################################

variable "sqlservers" {
  type = map(object({
    name = string
    version = string
    admin_login  = string
    admin_password = string
    rg_key = string
  }))
}

variable "sqldatabases" {
  type = map(object({
    name = string
    sku_name = string
    server_key = string
  }))
}

########################################
# FRONT DOOR VARIABLES
########################################

#variable "fd_profile" {
#  type = map(object({
#    name = string
#    sku = string
#    response_timeout_seconds = number
#    rg_key = string
#  }))
#}

#variable "fd_endpoint" {
#  description = "Name of the Front Door endpoint"
#  type        = string
#}

#variable "fd_og_name" {
#  description = "Name of the Front Door origin group"
#  type        = string
#}

#variable "fd_route" {
#  description = "Name of the Front Door route"
#  type        = string
#}

########################################
# STORAGE ACCOUNT VARIABLES
########################################

variable "storage_accounts" {
  type = map(object({
    name = string
    account_tier = string
    account_replication_type = string
    rg_key = string
  }))
}

########################################
# KEY VAULT VARIABLES
########################################

variable "key_vaults" {
  type = map(object({
    name = string
    enabled_for_disk_encryption = bool
    soft_delete_retention_days = number
    purge_protection_enabled = bool
    sku_name = string
    rbac_authorization_enabled = bool
    rg_key = string
  }))
}

########################################
# APP CONFIG VARIABLES
########################################

variable "app_configs" {
  type = map(object({
    name = string
    sku = string
    local_auth_enabled         = bool
    public_network_access      = string
    purge_protection_enabled   = bool
    rg_key = string
  }))
}

variable "service_bus" {
  type = map(object({
    name = string
    sku = string
    rg_key = string
  }))
}

