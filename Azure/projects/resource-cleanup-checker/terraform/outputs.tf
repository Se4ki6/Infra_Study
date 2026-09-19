output "function_app_name" {
  description = "Function App名（デプロイ・キー取得に使う）"
  value       = module.function_app.function_app_name
}

output "function_app_default_hostname" {
  description = "Function AppのデフォルトホストURL"
  value       = module.function_app.function_app_default_hostname
}

output "static_website_url" {
  description = "HTML配信用の静的サイトURL（$webコンテナ）"
  value       = module.storage.primary_web_endpoint
}

output "storage_account_name" {
  description = "Storage Account名（静的サイトへのアップロード先）"
  value       = module.storage.name
}
