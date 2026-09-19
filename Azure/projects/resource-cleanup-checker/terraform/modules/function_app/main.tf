// ==============================================================================
// module: function_app
// ==============================================================================
// Python isolated のLinux Function App一式（プラン／監視／マネージドID）。
// Storage Accountはこのモジュールの外（module.storage）で作成し、名前・アクセス
// キーを受け取って使い回す。
//
// マネージドIDにはサブスクリプションスコープのReaderロールのみを付与し、
// Azure Resource Graphへの問い合わせに使う。
// ==============================================================================

resource "azurerm_log_analytics_workspace" "this" {
  name                = "log-${var.name_prefix}-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_in_days

  tags = var.tags
}

resource "azurerm_application_insights" "this" {
  name                = "appi-${var.name_prefix}-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location
  workspace_id        = azurerm_log_analytics_workspace.this.id
  application_type    = "web"

  tags = var.tags
}

resource "azurerm_service_plan" "this" {
  name                = "plan-${var.name_prefix}-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = "Linux"
  sku_name            = var.sku_name

  tags = var.tags
}

resource "azurerm_linux_function_app" "this" {
  name                = "func-${var.name_prefix}-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location
  service_plan_id     = azurerm_service_plan.this.id

  storage_account_name       = var.storage_account_name
  storage_account_access_key = var.storage_account_access_key

  https_only = true

  // Resource Graphへの問い合わせ(Readerロール)に使うマネージドID
  identity {
    type = "SystemAssigned"
  }

  site_config {
    application_insights_connection_string = azurerm_application_insights.this.connection_string
    application_insights_key               = azurerm_application_insights.this.instrumentation_key

    application_stack {
      python_version = var.python_version
    }

    cors {
      allowed_origins = [var.cors_allowed_origin]
    }
  }

  app_settings = merge(
    {
      FUNCTIONS_WORKER_RUNTIME = "python"
      AZURE_SUBSCRIPTION_ID    = var.subscription_id
    },
    var.app_settings,
  )

  tags = var.tags
}

// ------------------------------------------------------------------------------
// サブスクリプション内リソースの参照権限
// ------------------------------------------------------------------------------
resource "azurerm_role_assignment" "reader" {
  scope                = "/subscriptions/${var.subscription_id}"
  role_definition_name = "Reader"
  principal_id         = azurerm_linux_function_app.this.identity[0].principal_id
}
