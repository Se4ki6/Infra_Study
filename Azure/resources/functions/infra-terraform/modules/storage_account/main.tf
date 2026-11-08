# Function App の実行とパッケージ配置に必要な Storage Account を作成します。
resource "azurerm_storage_account" "this" {
  name                            = var.name
  resource_group_name             = var.resource_group_name
  location                        = var.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  account_kind                    = "StorageV2"
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  tags                            = var.tags
}

# Flex Consumption のコード配置先になる Blob Container を作成します。
resource "azurerm_storage_container" "deployment" {
  name                  = var.deployment_container_name
  storage_account_id    = azurerm_storage_account.this.id
  container_access_type = "private"
}
