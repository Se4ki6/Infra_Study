variable "name_prefix" {
  description = "リソース名の接頭辞"
  type        = string
}

variable "name_suffix" {
  description = "グローバル一意が必要なリソース（ストレージアカウント等）に付与するサフィックス"
  type        = string
}

variable "resource_group_name" {
  description = "デプロイ先のリソースグループ名"
  type        = string
}

variable "location" {
  description = "デプロイ先のAzureリージョン"
  type        = string
}

variable "sku_name" {
  description = "App Service PlanのSKU（例: Y1 = Consumption, B1 = Basic）"
  type        = string
  default     = "Y1"
}

variable "python_version" {
  description = "Functionランタイムに使うPythonバージョン"
  type        = string
  default     = "3.11"
}

variable "log_retention_in_days" {
  description = "Log Analyticsの保持期間（日）"
  type        = number
  default     = 30
}

variable "app_settings" {
  description = "Function Appに渡すアプリケーション設定（環境変数）"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "リソースに付与するタグ"
  type        = map(string)
  default     = {}
}
