output "policy_json" {
  description = "適用したバケットポリシー (確認用)"
  value       = data.aws_iam_policy_document.this.json
}

output "allowed_user_ids" {
  description = "Deny の例外に載っている aws:userId 一覧 (トラブル時の突き合わせ用)"
  value       = var.allowed_user_ids
}

output "lockdown_enabled" {
  description = "ロックダウンが有効かどうか"
  value       = var.enable_lockdown
}
