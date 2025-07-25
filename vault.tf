module "vault" {
  source                      = "git@github.com:hmcts/cnp-module-key-vault?ref=master"
  name                        = "${var.product}-${var.env}"
  product                     = var.product
  env                         = var.env
  tenant_id                   = var.tenant_id
  object_id                   = var.jenkins_AAD_objectId
  resource_group_name         = azurerm_resource_group.rg.name
  product_group_object_id     = "70de400b-4f47-4f25-a4f0-45e1ee4e4ae3"
  common_tags                 = var.common_tags
  managed_identity_object_ids = [var.managed_identity_cft_api_mgmt]
  create_managed_identity     = true
}

output "vaultName" {
  value = module.vault.key_vault_name
}
