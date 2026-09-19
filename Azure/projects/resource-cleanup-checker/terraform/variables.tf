variable "name_prefix" {
  description = "リソース名の接頭辞"
  type        = string
  default     = "rescheck"
}

variable "environment" {
  description = "環境名（タグ付け用）"
  type        = string
  default     = "study"
}

variable "location" {
  description = "デプロイ先のAzureリージョン"
  type        = string
  default     = "japaneast"
}

variable "function_app_sku_name" {
  description = "App Service PlanのSKU（Y1 = Consumption）"
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

variable "tags" {
  description = "全リソース共通で付与する追加タグ"
  type        = map(string)
  default     = {}
}
