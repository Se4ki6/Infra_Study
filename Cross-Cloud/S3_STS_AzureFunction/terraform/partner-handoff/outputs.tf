// ==============================================================================
// 連携先 (バッチ側) に安全な経路 (Key Vault 等) で渡す値
// ==============================================================================

output "aws_region" {
  description = "リージョン (連携先の設定にそのまま使う)"
  value       = var.aws_region
}

output "bucket_name" {
  description = "S3 バケット名"
  value       = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = "S3 バケットの ARN"
  value       = aws_s3_bucket.this.arn
}

output "allowed_prefix" {
  description = "AssumeRole 後に読み取りが許可されるプレフィックス"
  value       = var.allowed_prefix
}

output "assume_role_arn" {
  description = "連携先が AssumeRole する対象のロール ARN"
  value       = aws_iam_role.assume_role.arn
}

output "bootstrap_access_key_id" {
  description = "連携先に渡す AccessKeyId (機密度は中: これ単体では S3 に到達できない)"
  value       = aws_iam_access_key.bootstrap.id
  sensitive   = true
}

output "bootstrap_secret_access_key" {
  description = "連携先に渡す SecretAccessKey (最重要機密。Key Vault 等のシークレットストアで管理すること)"
  value       = aws_iam_access_key.bootstrap.secret
  sensitive   = true
}

output "external_id" {
  description = "連携先が AssumeRole 呼び出し時に指定する ExternalId (tfvars に設定した入力値をそのまま出力・確認用)"
  value       = var.external_id
  sensitive   = true
}

output "bucket_lockdown_enabled" {
  description = "バケットロックダウンが有効かどうか"
  value       = var.enable_bucket_lockdown
}

output "bucket_lockdown_allowed_user_ids" {
  description = "バケットポリシーの Deny 例外に載っている aws:userId 一覧 (トラブル時の確認用)"
  value       = local.bucket_allowed_user_ids
}
