variable "name_prefix" {
  description = "IAM リソース名の接頭辞"
  type        = string
}

variable "s3_read_policy_arn" {
  description = "Assume後のロールにアタッチするS3読み取りポリシーのARN"
  type        = string
}

variable "azure_tenant_id" {
  description = "Entra ID（Azure AD）のテナントID"
  type        = string
}

variable "azure_token_version" {
  description = <<-EOT
    Azureが発行するアクセストークンのバージョン。信頼するissuerが変わる。
      v1 -> https://sts.windows.net/<tenant-id>             （マネージドIDは通常こちら）
      v2 -> https://login.microsoftonline.com/<tenant-id>/v2.0

    【必ず実測して合わせること】Function App の GET /api/token-claims が
    実際のトークンの iss / aud / sub を返すので、そのissに一致する方を選ぶ。
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
    信頼するトークンのaudクレーム。
      v1トークン -> アプリケーションID URI（例: api://<client-id>）
      v2トークン -> アプリケーションのclient id（GUID）
  EOT
  type        = string
}

variable "azure_function_principal_id" {
  description = <<-EOT
    Function Appのマネージド ID の principal id（オブジェクトID）。トークンのsubと一致する。
    空文字にするとsub条件を付けない（テナント内の他のIDでもAssumeできてしまうので非推奨）。
  EOT
  type        = string
  default     = ""
}

variable "max_session_duration" {
  description = "一時クレデンシャルの最大有効期間（秒）"
  type        = number
  default     = 3600
}

variable "tags" {
  description = "リソースに付与するタグ"
  type        = map(string)
  default     = {}
}
