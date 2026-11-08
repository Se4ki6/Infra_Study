variable "name_prefix" {
  description = "IAM ロール・ユーザー名の接頭辞"
  type        = string
}

variable "s3_read_policy_arn" {
  description = "Assume 後のロールにアタッチする S3 読み取りポリシーの ARN"
  type        = string
}

variable "external_id" {
  description = <<-EOT
    AssumeRole に要求する ExternalId (混乱した代理人問題への対策)。
    空文字にすると条件なしになるが、学習用途でも設定を推奨。
  EOT
  type        = string
  default     = ""
  sensitive   = true
}

variable "max_session_duration" {
  description = "一時クレデンシャルの最大有効期間 (秒)"
  type        = number
  default     = 3600
}

variable "tags" {
  description = "リソースに付与するタグ"
  type        = map(string)
  default     = {}
}
