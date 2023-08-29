resource "azurerm_role_assignment" "containerapp" {
  scope                = lower("/subscriptions/bb87627c-ce2f-4c01-8257-2e5c1f074a28/resourceGroups/${var.resource_group_name}/providers/Microsoft.ContainerRegistry/registries/${var.registry_name}")
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.acr_reader.principal_id
}

resource "azurerm_user_assigned_identity" "acr_reader" {
  location            = var.location
  name                = "app-acr-reader"
  resource_group_name = var.resource_group_name
}


resource "azurerm_container_app" "app" {
  name = "ca-${var.resource_token}"

  container_app_environment_id = var.containerapp_env_id
  resource_group_name          = var.resource_group_name
  revision_mode                = "Single"
  tags                         = merge(tomap({ "azd-service-name" = "api-tf" }), tomap({ "azd-env-name" : var.environment }))
  depends_on                   = [azurerm_role_assignment.containerapp, azurerm_user_assigned_identity.acr_reader]



  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.acr_reader.id]
  }
  secret {
    name  = "registry-password"
    value = data.azurerm_container_registry.acr.admin_password
  }

  registry {
    server   = data.azurerm_container_registry.acr.login_server
    identity = azurerm_user_assigned_identity.acr_reader.id

  }
  template {
    container {
      name   = "ca-${var.resource_token}"
      image  = var.image_name == "" ? "nginx:latest" : var.image_name
      cpu    = 0.25
      memory = "0.5Gi"
    }
    min_replicas = 1
    max_replicas = 1
  }
  ingress {

    external_enabled = true
    target_port      = 80
    traffic_weight {
      percentage      = 100
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

resource "azuread_application" "container_app_application" {
  depends_on      = [azurerm_container_app.app]
  display_name    = "API AUTH ${var.resource_token}"
  identifier_uris = ["api://${var.resource_token}"]
  web {
    homepage_url  = "https://ca-${var.resource_token}.${var.containerapp_env_url}"
    redirect_uris = ["https://ca-${var.resource_token}.${var.containerapp_env_url}/.auth/login/aad/callback"]

    implicit_grant {
      access_token_issuance_enabled = true
    }
  }
}

resource "azuread_service_principal" "container_app_service_principle" {
  application_id               = azuread_application.container_app_application.application_id
  app_role_assignment_required = true
}



resource "azapi_resource" "containerauth" {
  type      = "Microsoft.App/containerApps/authConfigs@2022-11-01-preview"
  name      = "current"
  parent_id = azurerm_container_app.app.id
  body = jsonencode({
    properties = {
      globalValidation = {
        excludedPaths               = []
        unauthenticatedClientAction = "Return401"
      }
      platform = {
        enabled = true
      }
      httpSettings = {
        requireHttps = true
      }
      identityProviders = {
        azureActiveDirectory = {
          enabled = true

          registration = {
            clientId = azuread_application.container_app_application.application_id
          }
        }

      }
    }
  })
}
