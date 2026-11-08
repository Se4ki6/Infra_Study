# Flex Consumption の serverless 実行基盤を作る Service Plan です。
resource "azurerm_service_plan" "this" {
  name                = var.service_plan_name
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = "Linux"
  sku_name            = "FC1"
  tags                = var.tags
}

# HTTP Trigger を載せる最小の Function App を作成します。
resource "azurerm_function_app_flex_consumption" "this" {
  name                        = var.function_app_name
  resource_group_name         = var.resource_group_name
  location                    = var.location
  service_plan_id             = azurerm_service_plan.this.id
  storage_container_type      = "blobContainer"
  storage_container_endpoint  = var.storage_container_endpoint
  storage_authentication_type = "StorageAccountConnectionString"
  storage_access_key          = var.storage_access_key
  runtime_name                = var.runtime_name
  runtime_version             = var.runtime_version
  maximum_instance_count      = var.maximum_instance_count
  instance_memory_in_mb       = var.instance_memory_in_mb
  site_config {}
  tags = var.tags
}
