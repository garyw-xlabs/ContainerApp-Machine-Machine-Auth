
resource "azurerm_role_assignment" "othercontainerapp" {
  scope                = lower("/subscriptions/bb87627c-ce2f-4c01-8257-2e5c1f074a28/resourceGroups/${var.resource_group_name}/providers/Microsoft.ContainerRegistry/registries/${var.registry_name}")
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.other-acr_reader.principal_id
}

resource "azurerm_user_assigned_identity" "other-acr_reader" {
  location            = var.location
  name                = "otherapp-acr-reader"
  resource_group_name = var.resource_group_name
}

resource "azuread_app_role_assignment" "example" {
  app_role_id         = "00000000-0000-0000-0000-000000000000"
  principal_object_id = azurerm_user_assigned_identity.other-acr_reader.principal_id
  resource_object_id  = var.api_sp_id
}

resource "azurerm_container_app" "otherapp" {
  name = "ca-other-${var.resource_token}"

  container_app_environment_id = var.containerapp_env_id
  resource_group_name          = var.resource_group_name
  revision_mode                = "Single"
  tags                         = merge(tomap({ "azd-service-name" = "otherapi-tf" }), tomap({ "azd-env-name" : var.environment }))
  depends_on = [ azurerm_role_assignment.othercontainerapp, azurerm_user_assigned_identity.other-acr_reader ]



  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.other-acr_reader.id]
  }
  secret {
    name = "registry-password"
    value = data.azurerm_container_registry.acr.admin_password
  }

  secret {
    name = "azure-client-id"
    value = azurerm_user_assigned_identity.other-acr_reader.client_id
  }

  secret {
    name = "api-authid"
    value = var.api_sp_client_id
  }

  registry {
    server   = data.azurerm_container_registry.acr.login_server
    identity = azurerm_user_assigned_identity.other-acr_reader.id
  
  }
 template {
      container {
      name   = "ca-other-${var.resource_token}"
      image  = var.image_name == "" ? "nginx:latest" : var.image_name
      cpu    = 0.25
      memory = "0.5Gi"
      
      env{
        name = "AZURE_CLIENT_ID"
        secret_name = "azure-client-id"
      }
      env{
        name = "Api__uri"
        value = var.api_uri
      }
      env{
        name = "Api__AuthId"
        secret_name = "api-authid"
      }
    }
     min_replicas = 1
    max_replicas = 1
  }
  ingress {

    external_enabled = true
    target_port      = 80
    traffic_weight {
      percentage = 100
      latest_revision = true
    }
  }
lifecycle {
    ignore_changes = [
      secret,
      template.0.container.0.env,
      template.0.container.0.image
    ]
  } 
}

