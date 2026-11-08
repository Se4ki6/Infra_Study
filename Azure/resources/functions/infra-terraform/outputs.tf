output "resource_group_name" {
  description = "作成された Resource Group 名です。"
  value       = module.resource_group.name
}

output "storage_account_name" {
  description = "作成された Storage Account 名です。"
  value       = module.storage_account.name
}

output "deployment_container_endpoint" {
  description = "Function App がコード配置に使う Blob Container のエンドポイントです。"
  value       = module.storage_account.deployment_container_endpoint
}

output "function_app_name" {
  description = "作成された Function App 名です。"
  value       = module.function_app.name
}

output "function_app_default_hostname" {
  description = "Function App の既定ホスト名です。"
  value       = module.function_app.default_hostname
}

output "function_hello_url" {
  description = "Hello World を返す想定の HTTP Trigger URL です。"
  value       = "https://${module.function_app.default_hostname}/api/hello"
}

output "application_insights_connection_string" {
  description = "Application Insights の接続文字列です。"
  value       = module.monitoring.application_insights_connection_string
  sensitive   = true
}
