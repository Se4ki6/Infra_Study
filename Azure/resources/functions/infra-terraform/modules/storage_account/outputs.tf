output "id" {
  description = "Storage Account の ID です。"
  value       = azurerm_storage_account.this.id
}

output "name" {
  description = "Storage Account 名です。"
  value       = azurerm_storage_account.this.name
}

output "primary_access_key" {
  description = "Storage Account の primary access key です。"
  value       = azurerm_storage_account.this.primary_access_key
  sensitive   = true
}

output "primary_blob_endpoint" {
  description = "Blob サービスのベースエンドポイントです。"
  value       = azurerm_storage_account.this.primary_blob_endpoint
}

output "deployment_container_name" {
  description = "デプロイ用 Blob Container 名です。"
  value       = azurerm_storage_container.deployment.name
}

output "deployment_container_endpoint" {
  description = "Flex Consumption がコード配置先として使うコンテナエンドポイントです。"
  value       = "${azurerm_storage_account.this.primary_blob_endpoint}${azurerm_storage_container.deployment.name}"
}
