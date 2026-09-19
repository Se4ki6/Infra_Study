// ==============================================================================
// module: storage
// ==============================================================================
// Functionsランタイム用ストレージ・Queue・Table・HTML配信用の静的サイトを
// 1つのStorage Accountに集約する。
// ==============================================================================

resource "azurerm_storage_account" "this" {
  name                     = var.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  static_website {
    index_document = "index.html"
  }

  tags = var.tags
}

resource "azurerm_storage_queue" "resource_check_jobs" {
  name                 = var.queue_name
  storage_account_name = azurerm_storage_account.this.name
}

resource "azurerm_storage_table" "job_status" {
  name                 = var.table_name
  storage_account_name = azurerm_storage_account.this.name
}
