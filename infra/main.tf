locals {
  tags           = { azd-env-name : var.environment_name }
  sha            = base64encode(sha256("${var.environment_name}${var.location}${data.azurerm_client_config.current.subscription_id}"))
  resource_token = substr(replace(lower(local.sha), "[^A-Za-z0-9_]", ""), 0, 13)
  stack          = "playground-tf"
}

resource "azurecaf_name" "rg_name" {
  name          = var.environment_name
  resource_type = "azurerm_resource_group"
  random_length = 0
  clean_input   = true
}

# Deploy resource group
resource "azurerm_resource_group" "rg" {
  name     = azurecaf_name.rg_name.result
  location = var.location
  // Tag the resource group with the azd environment name
  // This should also be applied to all resources created in this module
  tags = local.tags
}

resource "azurerm_log_analytics_workspace" "log" {
  name                = "log-${local.resource_token}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = local.tags
}

resource "azurerm_application_insights" "appinsights" {
  name                = "tf-test-appinsights"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  workspace_id        = azurerm_log_analytics_workspace.log.id
  application_type    = "web"
}

resource "azurerm_container_app_environment" "cae" {
  name                       = "cae-${local.resource_token}"
  location                   = var.location
  resource_group_name        = azurerm_resource_group.rg.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.log.id

  tags = local.tags
}
resource "azurerm_container_registry" "acr" {
  name                = "acr${local.resource_token}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  admin_enabled       = true
  sku                 = "Basic"
}

module "container_app_api" {
  source               = "./modules/containerappapi"
  service_name         = "keyvault-tf"
  environment          = var.environment_name
  resource_group_name  = azurerm_resource_group.rg.name
  containerapp_env_id  = azurerm_container_app_environment.cae.id
  containerapp_env_url = azurerm_container_app_environment.cae.default_domain
  resource_token       = local.resource_token
  registry_name        = azurerm_container_registry.acr.name
  default_tags         = local.tags
  location             = var.location
  image_name           = var.api_image
  latest_commit_id     = var.latest_commit_id
  blue_commit_id       = var.blue_commit_id
  green_commit_id      = var.green_commit_id
  production_label     = local.prod_label
}
