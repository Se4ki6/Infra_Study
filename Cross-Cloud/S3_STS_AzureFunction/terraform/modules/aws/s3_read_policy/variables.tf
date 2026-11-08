variable "policy_name" {
  description = "作成する IAM ポリシー名"
  type        = string
}

variable "bucket_arn" {
  description = "対象 S3 バケットの ARN"
  type        = string
}

variable "allowed_prefix" {
  description = "読み取りを許可する S3 プレフィックス (空文字ならバケット全体)"
  type        = string
  default     = ""
}

variable "tags" {
  description = "リソースに付与するタグ"
  type        = map(string)
  default     = {}
}
