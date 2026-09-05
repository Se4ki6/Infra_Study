// ==============================================================================
// Azureルートモジュール
// ==============================================================================
// モジュール構成:
//   entra_app     … OIDCトークンの宛先（aud）になるEntra IDアプリ登録
//   function_app  … Function App一式（ストレージ／プラン／監視／マネージドID）
//
// AWS側の値（aws_web_identity_role_arn）は初回は空のままでよい。
// terraform/aws を apply した後に埋めて再applyする（../../README.md 参照）。
// ==============================================================================

data "azurerm_client_config" "current" {}
data "azuread_client_config" "current" {}

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
    Project     = "S3_OIDC_AzureFunction"
    Environment = var.environment
    ManagedBy   = "Terraform"
  })

  // ----------------------------------------------------------------------------
  // Function Appに渡すアプリケーション設定
  // ----------------------------------------------------------------------------
  aws_app_settings = {
    AWS_REGION                       = var.aws_region
    AWS_S3_BUCKET                    = var.aws_s3_bucket
    AWS_S3_PREFIX                    = var.aws_s3_prefix
    AWS_WEB_IDENTITY_ROLE_ARN        = var.aws_web_identity_role_arn
    AWS_STS_SESSION_DURATION_SECONDS = tostring(var.aws_sts_session_duration_seconds)
    AZURE_TOKEN_SCOPE                = module.entra_app.token_scope
  }
}

resource "azurerm_resource_group" "main" {
  name     = "rg-${var.name_prefix}-${var.environment}"
  location = var.location
  tags     = local.common_tags
}

// ------------------------------------------------------------------------------
// OIDCトークンの宛先になるEntra IDアプリ
// ------------------------------------------------------------------------------
module "entra_app" {
  source = "../modules/azure/entra_app"

  display_name                   = var.entra_app_display_name
  requested_access_token_version = var.entra_requested_token_version
  owner_object_ids               = [data.azuread_client_config.current.object_id]
}

// ------------------------------------------------------------------------------
// Function App一式
// ------------------------------------------------------------------------------
module "function_app" {
  source = "../modules/azure/function_app"

  name_prefix         = var.name_prefix
  name_suffix         = random_string.suffix.result
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  sku_name       = var.function_app_sku_name
  python_version = var.python_version
  app_settings   = local.aws_app_settings
  tags           = local.common_tags
}
