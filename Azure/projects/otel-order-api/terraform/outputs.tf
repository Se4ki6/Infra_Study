output "resource_group_name" {
  description = "Name of the resource group containing the exercise resources."
  value       = azurerm_resource_group.this.name
}

output "workspace_id" {
  description = "Resource ID of the Log Analytics Workspace."
  value       = module.monitoring.workspace_id
}

output "application_insights_id" {
  description = "Resource ID of the Application Insights component."
  value       = module.monitoring.application_insights_id
}

output "storage_account_name" {
  description = "Name of the order JSON Storage Account."
  value       = module.storage.storage_account_name
}

output "container_name" {
  description = "Name of the private order Blob container."
  value       = module.storage.container_name
}

output "application_insights_connection_string" {
  description = "Connection string for sending telemetry to Application Insights."
  value       = module.monitoring.application_insights_connection_string
  sensitive   = true
}

output "blob_connection_string" {
  description = "Storage Account connection string for the local API."
  value       = module.storage.blob_connection_string
  sensitive   = true
}

output "api_fqdn" {
  description = "Public FQDN of the API Container App, or null while the app is disabled."
  value       = module.api_hosting.api_fqdn
}

output "api_container_registry_name" {
  description = "Name of the Container Registry used to publish the API image."
  value       = module.api_hosting.container_registry_name
}

output "api_container_registry_login_server" {
  description = "Login server of the Container Registry used to publish the API image."
  value       = module.api_hosting.container_registry_login_server
}
