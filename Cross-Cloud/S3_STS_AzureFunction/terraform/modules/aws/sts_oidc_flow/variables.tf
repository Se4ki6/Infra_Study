variable "name_prefix" {
  description = "IAM ロール名の接頭辞"
  type        = string
}

variable "s3_read_policy_arn" {
  description = "Assume 後のロールにアタッチする S3 読み取りポリシーの ARN"
  type        = string
}

variable "azure_tenant_id" {
  description = "Entra ID (Azure AD) のテナントID"
  type        = string
}

variable "azure_token_version" {
  description = <<-EOT
    Azure が発行するアクセストークンのバージョン。信頼する issuer が変わる。
      v1 -> https://sts.windows.net/<tenant-id>             (マネージドID は通常こちら)
      v2 -> https://login.microsoftonline.com/<tenant-id>/v2.0

    【必ず実測して合わせること】Function App の GET /api/token-claims が
    実際のトークンの iss / aud / sub を返すので、その iss に一致する方を選ぶ。
  EOT
  type        = string
  default     = "v1"

  validation {
    condition     = contains(["v1", "v2"], var.azure_token_version)
    error_message = "azure_token_version は \"v1\" または \"v2\" を指定してください。"
  }
}

variable "azure_oidc_audience" {
  description = <<-EOT
    信頼するトークンの aud クレーム。
      v1 トークン -> アプリケーションID URI (例: api://<client-id>)
      v2 トークン -> アプリケーションの client id (GUID)
  EOT
  type        = string
}

variable "azure_function_principal_id" {
  description = <<-EOT
    Function App のマネージドID の principal id (オブジェクトID)。トークンの sub と一致する。
    空文字にすると sub 条件を付けない (テナント内の他のIDでも Assume できてしまうので非推奨)。
  EOT
  type        = string
  default     = ""
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
