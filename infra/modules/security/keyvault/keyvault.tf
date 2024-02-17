resource "azurerm_key_vault" "key_vault" {
  name                        = "ky-${var.resource_token}"
  location                    = var.location
  resource_group_name         = var.resource_group_name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false
  enable_rbac_authorization   = true
  sku_name                    = "standard"
}

module "key_vault_access" {
  source = "../keyvault-access-policy"
  key_vault_id = azurerm_key_vault.key_vault.id
  principal_id = data.azurerm_client_config.current.object_id
  role_name = "Key Vault Administrator"
}