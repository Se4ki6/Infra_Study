output "id" {
  description = "Function App の ID です。"
  value       = azurerm_function_app_flex_consumption.this.id
}

output "name" {
  description = "Function App 名です。"
  value       = azurerm_function_app_flex_consumption.this.name
}

output "default_hostname" {
  description = "Function App の既定ホスト名です。"
  value       = azurerm_function_app_flex_consumption.this.default_hostname
}

output "service_plan_id" {
  description = "作成された Service Plan の ID です。"
  value       = azurerm_service_plan.this.id
}
