# 他の Azure リソースをまとめる器として Resource Group を作成します。
resource "azurerm_resource_group" "this" {
  name     = var.name
  location = var.location
  tags     = var.tags
}
