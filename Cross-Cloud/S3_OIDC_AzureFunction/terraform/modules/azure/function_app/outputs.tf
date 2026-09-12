output "function_app_name" {
  description = "Function App名"
  value       = azurerm_linux_function_app.this.name
}

output "function_app_id" {
  description = "Function AppのリソースID"
  value       = azurerm_linux_function_app.this.id
}

output "function_app_default_hostname" {
  description = "Function AppのデフォルトホストURL"
  value       = azurerm_linux_function_app.this.default_hostname
}

output "principal_id" {
  description = "システム割り当てマネージドIDのprincipal id（オブジェクトID）。AWS側の信頼ポリシーのsubに使う"
  value       = azurerm_linux_function_app.this.identity[0].principal_id
}
