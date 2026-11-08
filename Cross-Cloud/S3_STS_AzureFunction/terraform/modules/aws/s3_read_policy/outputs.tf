output "policy_arn" {
  description = "作成した IAM ポリシーの ARN"
  value       = aws_iam_policy.this.arn
}

output "policy_json" {
  description = "生成されたポリシードキュメント (確認用)"
  value       = data.aws_iam_policy_document.this.json
}

output "object_arn_pattern" {
  description = "読み取りを許可しているオブジェクト ARN パターン"
  value       = local.object_arn_pattern
}
