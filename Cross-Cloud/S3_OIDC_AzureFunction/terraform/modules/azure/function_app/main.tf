// ==============================================================================
// module: function_app
// ==============================================================================
// Python isolated のLinux Function App一式（ストレージ／プラン／監視を含む）。
//
// AWS固有の設定値はapp_settings変数として呼び出し側から渡す。
// このモジュール自体はAWSのことを知らない汎用モジュールにしてある。
// ==============================================================================

// Functionsランタイムが必ず要求するストレージアカウント
resource "azurerm_storage_account" "this" {
  name                     = "st${var.name_prefix}${var.name_suffix}"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  tags = var.tags
}

// ------------------------------------------------------------------------------
// 監視
// ------------------------------------------------------------------------------
// STSの呼び出しが失敗したときの原因（AccessDenied / InvalidIdentityTokenなど）は
// ここのログでしか分からない。この構成では実質必須。
resource "azurerm_log_analytics_workspace" "this" {
  name                = "log-${var.name_prefix}-${var.name_suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_in_days

  tags = var.tags
}

resource "azurerm_application_insights" "this" {
  name                = "appi-${var.name_prefix}-${var.name_suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  workspace_id        = azurerm_log_analytics_workspace.this.id
  application_type    = "web"

  tags = var.tags
}

// ------------------------------------------------------------------------------
// App Service Plan
// ------------------------------------------------------------------------------
resource "azurerm_service_plan" "this" {
  name                = "plan-${var.name_prefix}-${var.name_suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = "Linux"
  sku_name            = var.sku_name

  tags = var.tags
}

// ------------------------------------------------------------------------------
// Function App
// ------------------------------------------------------------------------------
resource "azurerm_linux_function_app" "this" {
  name                = "func-${var.name_prefix}-${var.name_suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  service_plan_id     = azurerm_service_plan.this.id

  storage_account_name       = azurerm_storage_account.this.name
  storage_account_access_key = azurerm_storage_account.this.primary_access_key

  https_only = true

  // OIDCフェデレーションの要。このFunction自身のEntra ID上の身元になる。
  // 発行されるトークンのsubクレーム = このマネージドIDのprincipal_id
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
      allowed_origins = ["https://portal.azure.com"]
    }
  }

  app_settings = merge(
    { FUNCTIONS_WORKER_RUNTIME = "python" },
    var.app_settings,
  )

  tags = var.tags
}
