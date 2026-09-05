variable "policy_name" {
  description = "IAM ポリシー名"
  type        = string
}

variable "bucket_arn" {
  description = "対象バケットのARN"
  type        = string
}

variable "allowed_prefix" {
  description = "読み取りを許可するキー プレフィックス（空文字ならバケット全体）"
  type        = string
  default     = ""
}

variable "tags" {
  description = "リソースに付与するタグ"
  type        = map(string)
  default     = {}
}
