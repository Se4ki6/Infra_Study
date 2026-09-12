output "role_arn" {
  description = "AssumeRoleWithWebIdentity で引き受けるロールのARN"
  value       = aws_iam_role.this.arn
}

output "role_name" {
  description = "作成したIAMロール名"
  value       = aws_iam_role.this.name
}

output "oidc_provider_arn" {
  description = "作成したIAM OIDCプロバイダのARN"
  value       = aws_iam_openid_connect_provider.this.arn
}
