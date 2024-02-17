resource "azurerm_role_assignment" "containerapp" {
  scope                = lower("/subscriptions/bb87627c-ce2f-4c01-8257-2e5c1f074a28/resourceGroups/${var.resource_group_name}/providers/Microsoft.ContainerRegistry/registries/${var.registry_name}")
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.acr_reader.principal_id
}

resource "azurerm_user_assigned_identity" "acr_reader" {
  location            = var.location
  name                = "id-ca-${var.resource_token}"
  resource_group_name = var.resource_group_name
}

resource "azurerm_container_app" "app" {
  name = "ca-${var.resource_token}"

  container_app_environment_id = var.containerapp_env_id
  resource_group_name          = var.resource_group_name
  revision_mode                = "Multiple"
  tags = merge(tomap({ "azd-service-name" = var.service_name }),
    tomap({ "azd-env-name" : var.environment }),
    tomap({ "blueCommitId" = var.blue_commit_id }),
    tomap({ "greenCommitId" = var.green_commit_id }),
    tomap({ "latestCommitId" = local.current_commit_id }),
  tomap({ "productionLabel" = var.production_label }))
  depends_on = [azurerm_role_assignment.containerapp, azurerm_user_assigned_identity.acr_reader]

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.acr_reader.id]
  }

  registry {
    server   = data.azurerm_container_registry.acr.login_server
    identity = azurerm_user_assigned_identity.acr_reader.id
  }
  template {
    revision_suffix = var.latest_commit_id
    container {
      name   = "ca-${var.resource_token}"
      image  = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
      cpu    = 0.25
      memory = "0.5Gi"

      env {
        name  = "AZURE_CLIENT_ID"
        value = azurerm_user_assigned_identity.acr_reader.client_id
      }
      env {
        name  = "REVISION_COMMIT_ID"
        value = var.latest_commit_id
      }
    }
    min_replicas = 1
    max_replicas = 1
  }
  ingress {
    external_enabled = true
    target_port      = 80

    dynamic "traffic_weight" {
      for_each = var.green_commit_id == var.blue_commit_id ? [1] : []
      content {
        latest_revision = true
        label           = "blue"
        percentage      = var.production_label == "blue" ? 100 : 0
      }
    }
    dynamic "traffic_weight" {
      for_each = var.green_commit_id != var.blue_commit_id ? [1] : []
      content {
        revision_suffix = var.blue_commit_id
        label           = "blue"
        percentage      = var.production_label == "blue" ? 100 : 0
      }
    }

    dynamic "traffic_weight" {
      for_each = var.green_commit_id != var.blue_commit_id ? [1] : []
      content {
        revision_suffix = var.green_commit_id
        label           = "green"
        percentage      = var.production_label == "green" ? 100 : 0
      }
    }
  }
}
