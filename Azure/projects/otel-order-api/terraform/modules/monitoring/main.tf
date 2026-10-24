resource "azurerm_log_analytics_workspace" "this" {
  name                = "law-otel-order-api-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days
  daily_quota_gb      = var.daily_data_cap_gb
  tags                = var.tags
}

resource "azurerm_application_insights" "this" {
  name                                 = "appi-otel-order-api-${var.environment}"
  location                             = var.location
  resource_group_name                  = var.resource_group_name
  application_type                     = "web"
  workspace_id                         = azurerm_log_analytics_workspace.this.id
  daily_data_cap_in_gb                 = var.daily_data_cap_gb
  daily_data_cap_notifications_enabled = true
  tags                                 = var.tags
}
