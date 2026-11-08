output "log_analytics_workspace_id" {
  description = "Log Analytics Workspace の ID です。"
  value       = azurerm_log_analytics_workspace.this.id
}

output "application_insights_id" {
  description = "Application Insights の ID です。"
  value       = azurerm_application_insights.this.id
}

output "application_insights_connection_string" {
  description = "Application Insights の connection string です。"
  value       = azurerm_application_insights.this.connection_string
  sensitive   = true
}

output "application_insights_instrumentation_key" {
  description = "Application Insights の instrumentation key です。"
  value       = azurerm_application_insights.this.instrumentation_key
  sensitive   = true
}
