output "function_app_name" {
  description = "Function App名"
  value       = azurerm_linux_function_app.this.name
}

output "function_app_default_hostname" {
  description = "Function AppのデフォルトホストURL"
  value       = azurerm_linux_function_app.this.default_hostname
}

output "principal_id" {
  description = "システム割り当てマネージドIDのprincipal id（オブジェクトID）"
  value       = azurerm_linux_function_app.this.identity[0].principal_id
}
