output "storage_account_id" {
  description = "Resource ID of the Storage Account."
  value       = azurerm_storage_account.this.id
}

output "storage_account_name" {
  description = "Name of the Storage Account."
  value       = azurerm_storage_account.this.name
}

output "container_name" {
  description = "Name of the private Blob container."
  value       = azurerm_storage_container.this.name
}

output "blob_connection_string" {
  description = "Primary connection string for the Storage Account."
  value       = azurerm_storage_account.this.primary_connection_string
  sensitive   = true
}
