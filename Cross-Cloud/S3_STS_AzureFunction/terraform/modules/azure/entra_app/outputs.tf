output "client_id" {
  description = "アプリケーション (クライアント) ID"
  value       = azuread_application.this.client_id
}

output "identifier_uri" {
  description = "アプリケーションID URI"
  value       = azuread_application_identifier_uri.this.identifier_uri
}

output "service_principal_object_id" {
  description = "サービスプリンシパルのオブジェクトID"
  value       = azuread_service_principal.this.object_id
}

output "token_scope" {
  description = <<-EOT
    マネージドID にトークンを要求するときのスコープ。
    Azure.Identity は末尾の "/.default" を落としてリソース名として扱う
  EOT
  value       = "api://${azuread_application.this.client_id}/.default"
}

output "aws_oidc_audience" {
  description = "AWS 側の azure_oidc_audience に設定する値 (トークンバージョンに対応)"
  value       = var.requested_access_token_version == 2 ? azuread_application.this.client_id : "api://${azuread_application.this.client_id}"
}

output "aws_oidc_audience_v1" {
  description = "v1 トークンの場合の aud (参考)"
  value       = "api://${azuread_application.this.client_id}"
}

output "aws_oidc_audience_v2" {
  description = "v2 トークンの場合の aud (参考)"
  value       = azuread_application.this.client_id
}
