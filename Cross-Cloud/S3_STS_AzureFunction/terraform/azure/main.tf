// ==============================================================================
// Azure ルートモジュール
// ==============================================================================
// 「別 AWS アカウントからのアクセス」の代役として Azure Function を使う。
// AWS から見れば完全な外部であり、この構成が成立すれば
// 「S3 へは STS 経由でしか入れない」ことの実証になる。
//
// モジュール構成:
//   entra_app     … 方式B の OIDC トークンの宛先 (aud) になる Entra ID アプリ登録
//   function_app  … Function App 一式 (ストレージ / プラン / 監視 / マネージドID)
//
// AWS 側の値は初回は空のままでよい。terraform/aws を apply した後に埋めて再 apply する。
// ==============================================================================

data "azurerm_client_config" "current" {}
data "azuread_client_config" "current" {}

// Storage Account などグローバル一意が必要なリソース向けのサフィックス
resource "random_string" "suffix" {
  length  = 6
  lower   = true
  upper   = false
  numeric = true
  special = false
}

locals {
  common_tags = {
    Project     = "S3_STS_AzureFunction"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  // ----------------------------------------------------------------------------
  // Function App に渡すアプリケーション設定
  // ----------------------------------------------------------------------------
  aws_app_settings = {
    // --- S3 の場所 ---
    AWS_REGION    = var.aws_region
    AWS_S3_BUCKET = var.aws_s3_bucket
    AWS_S3_PREFIX = var.aws_s3_prefix

    // --- 認証方式の切り替え ---
    CREDENTIAL_MODE                  = var.default_credential_mode
    AWS_STS_SESSION_DURATION_SECONDS = tostring(var.aws_sts_session_duration_seconds)

    // --- 方式A: アクセスキー + AssumeRole ---
    // 変数名にわざと BOOTSTRAP_ を付けている。AWS_ACCESS_KEY_ID という名前にすると
    // AWS SDK の既定クレデンシャルチェーンが勝手に拾ってしまい、
    // 「STS を経由していないのに動く」状態になって検証にならないため。
    AWS_ASSUME_ROLE_ARN             = var.aws_assume_role_arn
    BOOTSTRAP_AWS_ACCESS_KEY_ID     = var.aws_bootstrap_access_key_id
    BOOTSTRAP_AWS_SECRET_ACCESS_KEY = var.aws_bootstrap_secret_access_key
    AWS_EXTERNAL_ID                 = var.aws_external_id

    // --- 方式B: OIDC + AssumeRoleWithWebIdentity ---
    AWS_WEB_IDENTITY_ROLE_ARN = var.aws_web_identity_role_arn
    AZURE_TOKEN_SCOPE         = module.entra_app.token_scope
  }
}

resource "azurerm_resource_group" "main" {
  name     = "rg-${var.name_prefix}-${var.environment}"
  location = var.location
  tags     = local.common_tags
}

// ------------------------------------------------------------------------------
// 方式B の OIDC トークンの宛先になる Entra ID アプリ
// ------------------------------------------------------------------------------
module "entra_app" {
  source = "../modules/azure/entra_app"

  display_name                   = var.entra_app_display_name
  requested_access_token_version = var.entra_requested_token_version
  owner_object_ids               = [data.azuread_client_config.current.object_id]
}

// ------------------------------------------------------------------------------
// Function App 一式
// ------------------------------------------------------------------------------
module "function_app" {
  source = "../modules/azure/function_app"

  name_prefix         = var.name_prefix
  name_suffix         = random_string.suffix.result
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  sku_name     = var.function_app_sku_name
  app_settings = local.aws_app_settings
  tags         = local.common_tags
}
