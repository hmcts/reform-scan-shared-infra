locals {
  stripped_product     = replace(var.product, "-", "")
  account_name         = "${local.stripped_product}${var.env}"
  mgmt_network_name    = "cft-ptl-vnet"
  mgmt_network_rg_name = "cft-ptl-network-rg"
  prod_hostname        = "${local.stripped_product}.${var.external_hostname}"
  nonprod_hostname     = "${local.stripped_product}.${var.env}.${var.external_hostname}"
  external_hostname    = var.env == "prod" ? local.prod_hostname : local.nonprod_hostname
  aks_env              = var.env == "sandbox" ? "sbox" : var.env
  // for each client service two containers are created: one named after the service
  // and another one, named {service_name}-rejected, for storing envelopes rejected by process
  client_containers = ["bulkscanauto", "bulkscan", "cmc", "crime", "divorce", "nfd", "finrem", "pcq", "probate", "sscs", "publiclaw", "privatelaw", "adoption"]

  common_subnets = [
    data.azurerm_subnet.scan_storage_subnet.id,
    data.azurerm_subnet.jenkins_subnet.id,
    data.azurerm_subnet.aks_00_subnet.id,
    data.azurerm_subnet.aks_01_subnet.id,
  ]
  app_aks_network_name    = "cft-${local.aks_env}-vnet"
  app_aks_network_rg_name = "cft-${local.aks_env}-network-rg"

  cft_aks_subnets = var.env == "prod" ? [data.azurerm_subnet.app_aks_00_subnet.id, data.azurerm_subnet.app_aks_01_subnet.id] : []

  vnets_to_allow_access = concat(local.common_subnets, local.cft_aks_subnets)
}

resource "azurerm_storage_account" "storage_account" {
  name                = local.account_name
  resource_group_name = azurerm_resource_group.rg.name

  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = var.storage_account_repl_type

  allow_nested_items_to_be_public = false

  #   custom_domain {
  #     name          = "${local.external_hostname}"
  #     use_subdomain = "false"
  #   }

  network_rules {
    virtual_network_subnet_ids = local.vnets_to_allow_access
    bypass                     = ["Logging", "Metrics", "AzureServices"]
    default_action             = "Deny"
  }

  tags = local.tags
}

resource "azurerm_storage_container" "client_containers" {
  name                 = local.client_containers[count.index]
  storage_account_name = azurerm_storage_account.storage_account.name
  count                = length(local.client_containers)
}

resource "azurerm_storage_container" "client_rejected_containers" {
  name                 = "${local.client_containers[count.index]}-rejected"
  storage_account_name = azurerm_storage_account.storage_account.name
  count                = length(local.client_containers)
}

# store blob storage secrets in key vault
resource "azurerm_key_vault_secret" "storage_account_name" {
  key_vault_id = module.vault.key_vault_id
  name         = "storage-account-name"
  value        = azurerm_storage_account.storage_account.name
}

resource "azurerm_key_vault_secret" "storage_account_primary_key" {
  key_vault_id = module.vault.key_vault_id
  name         = "storage-account-primary-key"
  value        = azurerm_storage_account.storage_account.primary_access_key
}

resource "azurerm_key_vault_secret" "storage_account_secondary_key" {
  key_vault_id = module.vault.key_vault_id
  name         = "storage-account-secondary-key"
  value        = azurerm_storage_account.storage_account.secondary_access_key
}
