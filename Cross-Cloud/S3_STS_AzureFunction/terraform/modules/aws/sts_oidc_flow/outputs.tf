output "role_arn" {
  description = "Assume するロールの ARN (Function App の AWS_WEB_IDENTITY_ROLE_ARN に設定)"
  value       = aws_iam_role.this.arn
}

output "role_name" {
  description = "ロール名"
  value       = aws_iam_role.this.name
}

output "role_unique_id" {
  description = "ロールの一意ID (AROA...)。バケットポリシーの aws:userId 条件に使う"
  value       = aws_iam_role.this.unique_id
}

output "oidc_provider_arn" {
  description = "登録した IAM OIDC プロバイダの ARN"
  value       = aws_iam_openid_connect_provider.this.arn
}

output "issuer_url" {
  description = "信頼している issuer。トークンの iss クレームと一致している必要がある"
  value       = local.issuer_url
}
