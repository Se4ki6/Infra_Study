// ==============================================================================
// terraform/azure および Function App の設定に渡す値
// ==============================================================================

output "bucket_name" {
  description = "S3 バケット名"
  value       = module.s3_bucket.bucket_id
}

output "bucket_arn" {
  description = "S3 バケットの ARN"
  value       = module.s3_bucket.bucket_arn
}

output "uploaded_keys" {
  description = "アップロードしたサンプルファイルのキー一覧"
  value       = module.s3_bucket.uploaded_keys
}

output "allowed_prefix" {
  description = "STS ロールが読み取れる S3 プレフィックス"
  value       = var.allowed_prefix
}

output "aws_region" {
  description = "リージョン"
  value       = var.aws_region
}

output "bucket_lockdown_allowed_user_ids" {
  description = "バケットポリシーの Deny 例外に載っている aws:userId 一覧 (トラブル時の確認用)"
  value       = module.s3_bucket_lockdown.allowed_user_ids
}

output "bucket_lockdown_enabled" {
  description = "ロックダウンが有効かどうか"
  value       = module.s3_bucket_lockdown.lockdown_enabled
}

// ------------------------------------------------------------------------------
// 方式A: アクセスキー + AssumeRole
// ------------------------------------------------------------------------------

output "assume_role_arn" {
  description = "方式A で Assume するロールの ARN (Function App の AWS_ASSUME_ROLE_ARN に設定)"
  value       = one(module.sts_access_key_flow[*].role_arn)
}

output "bootstrap_access_key_id" {
  description = "方式A の bootstrap ユーザーのアクセスキーID"
  value       = one(module.sts_access_key_flow[*].access_key_id)
  sensitive   = true
}

output "bootstrap_secret_access_key" {
  description = "方式A の bootstrap ユーザーのシークレットアクセスキー"
  value       = one(module.sts_access_key_flow[*].secret_access_key)
  sensitive   = true
}

// ------------------------------------------------------------------------------
// 方式B: OIDC + AssumeRoleWithWebIdentity
// ------------------------------------------------------------------------------

output "web_identity_role_arn" {
  description = "方式B で Assume するロールの ARN (Function App の AWS_WEB_IDENTITY_ROLE_ARN に設定)"
  value       = one(module.sts_oidc_flow[*].role_arn)
}

output "oidc_provider_arn" {
  description = "登録した IAM OIDC プロバイダの ARN"
  value       = one(module.sts_oidc_flow[*].oidc_provider_arn)
}

output "oidc_issuer_url" {
  description = "信頼している issuer。トークンの iss クレームと一致している必要がある"
  value       = one(module.sts_oidc_flow[*].issuer_url)
}
