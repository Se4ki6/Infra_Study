variable "display_name" {
  description = "Entra IDアプリ登録の表示名"
  type        = string
}

variable "owner_object_ids" {
  description = "アプリ／サービスプリンシパルの所有者に設定するオブジェクトIDの一覧（通常はterraform実行者自身）"
  type        = list(string)
}

variable "requested_access_token_version" {
  description = <<-EOT
    このアプリ宛のアクセストークンのバージョン。
      1 -> iss = https://sts.windows.net/<tenant>/, aud = api://<client-id>
      2 -> iss = https://login.microsoftonline.com/<tenant>/v2.0, aud = <client-id>（GUID）
    マネージドIDが取得するトークンは通常v1になる。
  EOT
  type        = number
  default     = 1

  validation {
    condition     = contains([1, 2], var.requested_access_token_version)
    error_message = "requested_access_token_version は 1 または 2 を指定してください。"
  }
}
