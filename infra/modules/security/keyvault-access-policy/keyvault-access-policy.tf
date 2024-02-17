
resource "azurerm_role_assignment" "rbac_role" {
  scope              = var.key_vault_id
  role_definition_name =var.role_name  //"/subscriptions/${data.azurerm_client_config.current.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/${var.role_name}"
  principal_id       = var.principal_id
}