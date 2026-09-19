output "name" {
  description = "Storage Account名"
  value       = azurerm_storage_account.this.name
}

output "primary_access_key" {
  description = "Storage Accountのプライマリアクセスキー"
  value       = azurerm_storage_account.this.primary_access_key
  sensitive   = true
}

output "primary_web_endpoint" {
  description = "静的サイト($webコンテナ)のURL"
  value       = azurerm_storage_account.this.primary_web_endpoint
}

output "queue_name" {
  description = "ジョブ投入用Storage Queueの名前"
  value       = azurerm_storage_queue.resource_check_jobs.name
}

output "table_name" {
  description = "ジョブ状態を保存するTable Storageの名前"
  value       = azurerm_storage_table.job_status.name
}
