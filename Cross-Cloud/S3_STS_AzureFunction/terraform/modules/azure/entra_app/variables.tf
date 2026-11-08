variable "display_name" {
  description = "Entra ID アプリの表示名"
  type        = string
}

variable "requested_access_token_version" {
  description = <<-EOT
    このアプリ向けに発行されるアクセストークンのバージョン (1 or 2)。
    AWS 側の azure_token_version と対応させる。
      1 -> iss: https://sts.windows.net/<tenant>/          aud: api://<client-id>
      2 -> iss: https://login.microsoftonline.com/<t>/v2.0  aud: <client-id>
  EOT
  type        = number
  default     = 1

  validation {
    condition     = contains([1, 2], var.requested_access_token_version)
    error_message = "requested_access_token_version は 1 または 2 を指定してください。"
  }
}

variable "owner_object_ids" {
  description = "アプリとサービスプリンシパルの所有者にするオブジェクトID"
  type        = list(string)
  default     = []
}
