output "API_SERVICE_ID" {
  value = azurerm_user_assigned_identity.acr_reader.principal_id
}


output "API_URL" {
  value = azurerm_container_app.app.ingress[0].fqdn
}
