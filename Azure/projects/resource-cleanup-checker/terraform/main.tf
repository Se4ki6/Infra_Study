// ==============================================================================
// resource-cleanup-checker
// ==============================================================================
// HTML(静的サイト)のボタン押下 → HTTP Function がStorage Queueにjobを積む
//   → Queue Trigger FunctionがAzure Resource Graphでサブスクリプション内の
//     全リソースを確認し、結果をTable Storageに書く
//   → HTMLは別のHTTP Functionをポーリングして結果を表示する
//
// Queue Triggerはブラウザに直接レスポンスを返せないため、状態の受け渡しに
// Table Storageを使う（job_id起点でポーリング）。
//
// モジュール構成:
//   modules/storage      … Storage Account（Functionsランタイム／Queue／Table／静的サイト）
//   modules/function_app … Function App一式（プラン／監視／マネージドID／Readerロール）
// ==============================================================================

data "azurerm_client_config" "current" {}

// Storage Accountなどグローバル一意が必要なリソース向けのサフィックス
resource "random_string" "suffix" {
  length  = 6
  lower   = true
  upper   = false
  numeric = true
  special = false
}

locals {
  common_tags = merge(var.tags, {
    Project     = "resource-cleanup-checker"
    Environment = var.environment
    ManagedBy   = "Terraform"
  })

  storage_account_name = "st${var.name_prefix}${random_string.suffix.result}"
}

resource "azurerm_resource_group" "main" {
  name     = "rg-${var.name_prefix}-${var.environment}"
  location = var.location
  tags     = local.common_tags
}

module "storage" {
  source = "./modules/storage"

  storage_account_name = local.storage_account_name
  resource_group_name  = azurerm_resource_group.main.name
  location             = azurerm_resource_group.main.location
  tags                 = local.common_tags
}

module "function_app" {
  source = "./modules/function_app"

  name_prefix         = var.name_prefix
  environment         = var.environment
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  sku_name              = var.function_app_sku_name
  python_version        = var.python_version
  log_retention_in_days = var.log_retention_in_days

  storage_account_name       = module.storage.name
  storage_account_access_key = module.storage.primary_access_key
  // 静的サイト($webコンテナ)からのfetchのみ許可
  cors_allowed_origin = trimsuffix(module.storage.primary_web_endpoint, "/")

  subscription_id = data.azurerm_client_config.current.subscription_id

  tags = local.common_tags
}
