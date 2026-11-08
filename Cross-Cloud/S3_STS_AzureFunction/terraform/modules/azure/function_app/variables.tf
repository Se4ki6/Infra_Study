variable "name_prefix" {
  description = "リソース名の接頭辞 (英小文字と数字のみ)"
  type        = string
}

variable "name_suffix" {
  description = "グローバル一意性を確保するためのサフィックス"
  type        = string
}

variable "resource_group_name" {
  description = "配置先リソースグループ名"
  type        = string
}

variable "location" {
  description = "Azure リージョン"
  type        = string
}

variable "dotnet_version" {
  description = ".NET isolated ワーカーのバージョン"
  type        = string
  default     = "8.0"
}

variable "sku_name" {
  description = "App Service Plan の SKU (Y1 = 従量課金)"
  type        = string
  default     = "Y1"
}

variable "log_retention_in_days" {
  description = "Log Analytics ワークスペースの保持日数"
  type        = number
  default     = 30
}

variable "app_settings" {
  description = "Function App に設定するアプリケーション設定 (FUNCTIONS_WORKER_RUNTIME は自動で付与)"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "リソースに付与するタグ"
  type        = map(string)
  default     = {}
}
