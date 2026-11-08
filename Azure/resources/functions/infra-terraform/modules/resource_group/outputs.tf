output "id" {
  description = "Resource Group の ID です。"
  value       = azurerm_resource_group.this.id
}

output "name" {
  description = "Resource Group 名です。"
  value       = azurerm_resource_group.this.name
}

output "location" {
  description = "Resource Group のリージョンです。"
  value       = azurerm_resource_group.this.location
}
