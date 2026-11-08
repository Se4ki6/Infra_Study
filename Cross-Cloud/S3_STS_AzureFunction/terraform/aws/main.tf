// ==============================================================================
// AWS ルートモジュール
// ==============================================================================
// モジュール構成と依存関係:
//
//   s3_secure_bucket ──bucket_arn──▶ s3_read_policy ──policy_arn──┬─▶ sts_access_key_flow
//          │                                                       └─▶ sts_oidc_flow
//          │                                                                │
//          └──bucket_id / bucket_arn──▶ s3_bucket_lockdown ◀──role_unique_id─┘
//
// バケット本体とバケットポリシー (ロックダウン) を別モジュールにしているのは、
// 同居させると「バケット → ロール → バケット」でモジュール間が循環するため。
//
// 適用順序については ../../README.md の「デプロイ手順」を参照。
// Azure 側の値が必要なので azure → aws → azure の 3 段階で流す。
// ==============================================================================

// 現在 Terraform を実行している principal。
// ロックダウン時に「自分自身を締め出さない」ために使う
data "aws_caller_identity" "current" {}

locals {
  common_tags = {
    Project     = "S3_STS_AzureFunction"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  // ----------------------------------------------------------------------------
  // ロックダウンの Deny 例外に載せる aws:userId
  // ----------------------------------------------------------------------------
  // aws:userId は principal の種類で形式が違う:
  //   IAM ユーザー      : "AIDAXXXXXXXXXXXX"
  //   Assume したロール : "AROAXXXXXXXXXXXX:<セッション名>"
  //   ルートユーザー    : "<AWS アカウントID>"
  // Terraform 実行者が SSO ロールの場合はセッション名が変わりうるので、
  // "AROAXXXX:*" という前方一致パターンも併せて許可しておく。
  caller_user_id = data.aws_caller_identity.current.user_id

  caller_allowed_user_ids = distinct(compact([
    local.caller_user_id,                        // IAM ユーザーそのまま / 現セッション
    "${split(":", local.caller_user_id)[0]}:*",  // SSO・Assume ロールのセッション全般
    data.aws_caller_identity.current.account_id, // ルートユーザー (最後の逃げ道)
  ]))

  // fileset は実行時のカレントディレクトリ基準で解決されるため、
  // path.root からの絶対パスに直しておく (terraform -chdir でもズレないように)
  sample_files_folder = var.sample_files_folder == "" ? "" : abspath("${path.root}/${var.sample_files_folder}")

  // 有効になっている STS ロールの unique_id (AROA...) を集める
  sts_role_unique_ids = concat(
    module.sts_access_key_flow[*].role_unique_id,
    module.sts_oidc_flow[*].role_unique_id,
  )

  bucket_allowed_user_ids = distinct(concat(
    local.caller_allowed_user_ids,
    [for id in local.sts_role_unique_ids : "${id}:*"],
    var.additional_allowed_user_ids,
  ))
}

// ------------------------------------------------------------------------------
// S3 バケット本体
// ------------------------------------------------------------------------------
module "s3_bucket" {
  source = "../modules/aws/s3_secure_bucket"

  bucket_name         = var.bucket_name
  key_prefix          = var.allowed_prefix
  sample_files_folder = local.sample_files_folder
  tags                = local.common_tags
}

// ------------------------------------------------------------------------------
// Assume 後に使える権限 (方式A・方式B で共通)
// ------------------------------------------------------------------------------
module "s3_read_policy" {
  source = "../modules/aws/s3_read_policy"

  policy_name    = "${var.name_prefix}-s3-read"
  bucket_arn     = module.s3_bucket.bucket_arn
  allowed_prefix = var.allowed_prefix
  tags           = local.common_tags
}

// ------------------------------------------------------------------------------
// 方式A: アクセスキー + sts:AssumeRole
// ------------------------------------------------------------------------------
module "sts_access_key_flow" {
  source = "../modules/aws/sts_access_key_flow"
  count  = var.enable_access_key_flow ? 1 : 0

  name_prefix          = var.name_prefix
  s3_read_policy_arn   = module.s3_read_policy.policy_arn
  external_id          = var.external_id
  max_session_duration = var.session_duration_seconds
  tags                 = local.common_tags
}

// ------------------------------------------------------------------------------
// 方式B: OIDC + sts:AssumeRoleWithWebIdentity
// ------------------------------------------------------------------------------
module "sts_oidc_flow" {
  source = "../modules/aws/sts_oidc_flow"
  count  = var.enable_oidc_flow ? 1 : 0

  name_prefix                 = var.name_prefix
  s3_read_policy_arn          = module.s3_read_policy.policy_arn
  azure_tenant_id             = var.azure_tenant_id
  azure_token_version         = var.azure_token_version
  azure_oidc_audience         = var.azure_oidc_audience
  azure_function_principal_id = var.azure_function_principal_id
  max_session_duration        = var.session_duration_seconds
  tags                        = local.common_tags
}

// ------------------------------------------------------------------------------
// バケットロックダウン (この構成の中核)
// ------------------------------------------------------------------------------
module "s3_bucket_lockdown" {
  source = "../modules/aws/s3_bucket_lockdown"

  bucket_id        = module.s3_bucket.bucket_id
  bucket_arn       = module.s3_bucket.bucket_arn
  enable_lockdown  = var.enable_bucket_lockdown
  allowed_user_ids = local.bucket_allowed_user_ids

  // サンプルファイルを置き終えてからロックダウンする
  depends_on = [module.s3_bucket]
}
