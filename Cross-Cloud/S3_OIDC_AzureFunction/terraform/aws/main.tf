// ==============================================================================
// AWSルートモジュール
// ==============================================================================
// モジュール構成と依存関係:
//
//   s3_secure_bucket ──bucket_arn──▶ s3_read_policy ──policy_arn──▶ sts_oidc_flow
//
// デプロイ順序（../../README.md も参照）:
//   1. terraform/azure を apply（aws_web_identity_role_arn は空のままでよい）
//      → entra_app_identifier_uri / function_app_principal_id を控える
//   2. このモジュール（terraform/aws）を、控えた値を使って apply
//      → web_identity_role_arn が出力される
//   3. terraform/azure を、web_identity_role_arn を渡して再apply
// ==============================================================================

locals {
  common_tags = merge(var.tags, {
    Project     = "S3_OIDC_AzureFunction"
    Environment = var.environment
    ManagedBy   = "Terraform"
  })

  // filesetは実行時のカレントディレクトリ基準で解決されるため、
  // path.rootからの絶対パスに直しておく（terraform -chdirでもズレないように）
  sample_files_folder = var.sample_files_folder == "" ? "" : abspath("${path.root}/${var.sample_files_folder}")
}

// ------------------------------------------------------------------------------
// S3バケット本体
// ------------------------------------------------------------------------------
module "s3_bucket" {
  source = "../modules/aws/s3_secure_bucket"

  bucket_name         = var.bucket_name
  key_prefix          = var.allowed_prefix
  sample_files_folder = local.sample_files_folder
  tags                = local.common_tags
}

// ------------------------------------------------------------------------------
// Assume後に使える権限
// ------------------------------------------------------------------------------
module "s3_read_policy" {
  source = "../modules/aws/s3_read_policy"

  policy_name    = "${var.name_prefix}-s3-read"
  bucket_arn     = module.s3_bucket.bucket_arn
  allowed_prefix = var.allowed_prefix
  tags           = local.common_tags
}

// ------------------------------------------------------------------------------
// OIDC + sts:AssumeRoleWithWebIdentity
// ------------------------------------------------------------------------------
module "sts_oidc_flow" {
  source = "../modules/aws/sts_oidc_flow"

  name_prefix                 = var.name_prefix
  s3_read_policy_arn          = module.s3_read_policy.policy_arn
  azure_tenant_id             = var.azure_tenant_id
  azure_token_version         = var.azure_token_version
  azure_oidc_audience         = var.azure_oidc_audience
  azure_function_principal_id = var.azure_function_principal_id
  max_session_duration        = var.session_duration_seconds
  tags                        = local.common_tags
}
