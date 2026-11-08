variable "bucket_id" {
  description = "ポリシーを適用する S3 バケット名"
  type        = string
}

variable "bucket_arn" {
  description = "ポリシーを適用する S3 バケットの ARN"
  type        = string
}

variable "enable_lockdown" {
  description = <<-EOT
    true にすると allowed_user_ids 以外の全 principal を明示的 Deny で締め出す。
    false でも HTTPS 強制の Deny は残る。

    【重要】明示的 Deny はアカウント内の IAM ポリシー (AdministratorAccess を含む) より
    優先されるため、allowed_user_ids の指定を誤ると自分自身も操作できなくなる。
  EOT
  type        = bool
  default     = true
}

variable "allowed_user_ids" {
  description = <<-EOT
    Deny の例外にする aws:userId のリスト (StringNotLike で評価するのでワイルドカード可)。
      IAM ユーザー      : "AIDA..."
      Assume したロール : "AROA...:*"
      ルートユーザー    : "<AWS アカウントID>"
  EOT
  type        = list(string)
}
