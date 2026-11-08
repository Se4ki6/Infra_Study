output "role_arn" {
  description = "Assume するロールの ARN (Function App の AWS_ASSUME_ROLE_ARN に設定)"
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

output "bootstrap_user_arn" {
  description = "bootstrap IAM ユーザーの ARN"
  value       = aws_iam_user.bootstrap.arn
}

output "access_key_id" {
  description = "bootstrap ユーザーのアクセスキーID"
  value       = aws_iam_access_key.bootstrap.id
  sensitive   = true
}

output "secret_access_key" {
  description = "bootstrap ユーザーのシークレットアクセスキー"
  value       = aws_iam_access_key.bootstrap.secret
  sensitive   = true
}
