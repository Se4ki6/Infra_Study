# 一意なリソース名を作るための短い suffix です。
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
  numeric = true
}

locals {
  normalized_prefix = substr(lower(var.name_prefix), 0, 10)
  normalized_env    = substr(lower(var.environment), 0, 4)
  suffix            = random_string.suffix.result

  resource_group_name          = "rg-${local.normalized_prefix}-${local.normalized_env}"
  storage_account_name         = substr("${local.normalized_prefix}${local.normalized_env}${local.suffix}", 0, 24)
  deployment_container_name    = "app-package"
  log_analytics_workspace_name = "log-${local.normalized_prefix}-${local.normalized_env}"
  application_insights_name    = "appi-${local.normalized_prefix}-${local.normalized_env}"
  service_plan_name            = "plan-${local.normalized_prefix}-${local.normalized_env}"
  function_app_name            = substr("func-${local.normalized_prefix}-${local.normalized_env}-${local.suffix}", 0, 60)

  common_tags = merge(var.tags, {
    environment = local.normalized_env
  })
}

# Resource Group を他の module の土台として先に作成します。
module "resource_group" {
  source = "./modules/resource_group"

  name     = local.resource_group_name
  location = var.location
  tags     = local.common_tags
}

# Function App が利用するストレージとデプロイ用コンテナを作成します。
module "storage_account" {
  source = "./modules/storage_account"

  name                      = local.storage_account_name
  location                  = module.resource_group.location
  resource_group_name       = module.resource_group.name
  deployment_container_name = local.deployment_container_name
  tags                      = local.common_tags
}

# 最小監視構成として Log Analytics と Application Insights を作成します。
module "monitoring" {
  source = "./modules/monitoring"

  log_analytics_workspace_name = local.log_analytics_workspace_name
  application_insights_name    = local.application_insights_name
  location                     = module.resource_group.location
  resource_group_name          = module.resource_group.name
  tags                         = local.common_tags
}

# Function App と Flex Consumption Plan をまとめて作成します。
module "function_app" {
  source = "./modules/function_app"

  function_app_name          = local.function_app_name
  service_plan_name          = local.service_plan_name
  location                   = module.resource_group.location
  resource_group_name        = module.resource_group.name
  runtime_name               = var.runtime_name
  runtime_version            = var.runtime_version
  storage_container_endpoint = module.storage_account.deployment_container_endpoint
  storage_access_key         = module.storage_account.primary_access_key
  maximum_instance_count     = var.maximum_instance_count
  instance_memory_in_mb      = var.instance_memory_in_mb
  tags                       = local.common_tags
}
