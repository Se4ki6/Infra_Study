output "api_fqdn" {
  description = "Public FQDN of the API Container App, or null while the app is disabled."
  value       = var.enable_api ? azurerm_container_app.this[0].latest_revision_fqdn : null
}

output "container_registry_name" {
  description = "Name of the Container Registry."
  value       = azurerm_container_registry.this.name
}

output "container_registry_login_server" {
  description = "Login server of the Container Registry."
  value       = azurerm_container_registry.this.login_server
}
