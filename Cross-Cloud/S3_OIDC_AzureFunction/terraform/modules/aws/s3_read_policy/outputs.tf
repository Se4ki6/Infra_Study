output "policy_arn" {
  description = "作成した IAM ポリシーのARN"
  value       = aws_iam_policy.this.arn
}
