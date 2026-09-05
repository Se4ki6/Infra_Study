output "client_id" {
  description = "アプリケーション（クライアント）ID"
  value       = azuread_application.this.client_id
}

output "identifier_uri" {
  description = "アプリケーションID URI（例: api://<client-id>）。v1トークンのaudはこの値になる"
  value       = azuread_application_identifier_uri.this.identifier_uri
}

output "token_scope" {
  description = "ManagedIdentityCredential.get_token() に渡すスコープ（v1トークンをリクエストする）"
  value       = "${azuread_application_identifier_uri.this.identifier_uri}/.default"
}

output "service_principal_object_id" {
  description = "作成したサービスプリンシパルのオブジェクトID"
  value       = azuread_service_principal.this.object_id
}
