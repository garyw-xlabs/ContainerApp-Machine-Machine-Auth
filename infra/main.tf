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
  tags                = local.tags
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
  source              = "./modules/containerappapi"
  environment         = var.environment_name
  resource_group_name = azurerm_resource_group.rg.name
  containerapp_env_id = azurerm_container_app_environment.cae.id
  containerapp_env_url= azurerm_container_app_environment.cae.default_domain
  resource_token      = local.resource_token
  registry_name       = azurerm_container_registry.acr.name
  default_tags        = local.tags
  location            = var.location
  image_name = var.api_image
}

module "container_app_otherapi" {
  source              = "./modules/containerappotherapi"
  environment         = var.environment_name
  resource_group_name = azurerm_resource_group.rg.name
  containerapp_env_id = azurerm_container_app_environment.cae.id
  resource_token      = local.resource_token
  registry_name       = azurerm_container_registry.acr.name
  default_tags        = local.tags
  location            = var.location
  image_name = var.otherapi_image
  api_sp_id = module.container_app_api.API_SERVICE_PRINCIPLE
  api_sp_client_id= module.container_app_api.API_SERVICE_PRINICIPLE_CLIENT_ID
  api_uri = module.container_app_api.API_URL
}
