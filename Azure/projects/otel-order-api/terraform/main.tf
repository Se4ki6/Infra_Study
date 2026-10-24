locals {
  common_tags = merge(var.tags, {
    Project     = "otel-order-api"
    Environment = var.environment
    ManagedBy   = "Terraform"
  })

  storage_account_name = format(
    "otelorder%s",
    substr(sha1(join("-", [var.subscription_id, var.environment, var.name_suffix])), 0, 8)
  )

  container_registry_name = format(
    "otelacr%s",
    substr(sha1(join("-", [var.subscription_id, var.environment, var.name_suffix])), 0, 8)
  )
}

resource "azurerm_resource_group" "this" {
  name     = "rg-otel-order-api-${var.environment}"
  location = var.location
  tags     = local.common_tags
}

module "monitoring" {
  source = "./modules/monitoring"

  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  environment         = var.environment
  log_retention_days  = var.log_retention_days
  daily_data_cap_gb   = var.daily_data_cap_gb
  tags                = local.common_tags
}

module "storage" {
  source = "./modules/storage"

  resource_group_name  = azurerm_resource_group.this.name
  location             = azurerm_resource_group.this.location
  storage_account_name = local.storage_account_name
  container_name       = "orders"
  tags                 = local.common_tags
}

module "api_hosting" {
  source = "./modules/api_hosting"

  resource_group_name                    = azurerm_resource_group.this.name
  location                               = azurerm_resource_group.this.location
  environment                            = var.environment
  container_registry_name                = local.container_registry_name
  log_analytics_workspace_id             = module.monitoring.workspace_id
  application_insights_connection_string = module.monitoring.application_insights_connection_string
  blob_connection_string                 = module.storage.blob_connection_string
  blob_container_name                    = module.storage.container_name
  image_tag                              = var.image_tag
  enable_api                             = var.enable_api
  tags                                   = local.common_tags
}
