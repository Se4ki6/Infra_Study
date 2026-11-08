output "name" {
  description = "Function App 名 (zip デプロイ先)"
  value       = azurerm_linux_function_app.this.name
}

output "default_hostname" {
  description = "Function App のホスト名"
  value       = azurerm_linux_function_app.this.default_hostname
}

output "base_url" {
  description = "エンドポイントのベース URL"
  value       = "https://${azurerm_linux_function_app.this.default_hostname}/api"
}

output "principal_id" {
  description = "システム割り当てマネージドID の principal id (トークンの sub クレームと一致)"
  value       = azurerm_linux_function_app.this.identity[0].principal_id
}

output "application_insights_name" {
  description = "Application Insights のリソース名 (ログ照会に使う)"
  value       = azurerm_application_insights.this.name
}

output "storage_account_name" {
  description = "Functions ランタイム用ストレージアカウント名"
  value       = azurerm_storage_account.this.name
}
