variable "name_prefix" {
  description = "リソース名の接頭辞"
  type        = string
}

variable "environment" {
  description = "環境名（タグ付け用）"
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
  description = "App Service PlanのSKU（例: Y1 = Consumption）"
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

variable "storage_account_name" {
  description = "Functionsランタイム・Queue・Tableで使い回すStorage Account名"
  type        = string
}

variable "storage_account_access_key" {
  description = "上記Storage Accountのアクセスキー"
  type        = string
  sensitive   = true
}

variable "cors_allowed_origin" {
  description = "CORSで許可するオリジン（静的サイトのURL）"
  type        = string
}

variable "subscription_id" {
  description = "Resource Graphで確認する対象・Readerロールの付与先サブスクリプションID"
  type        = string
}

variable "app_settings" {
  description = "Function Appに渡す追加のアプリケーション設定（環境変数）"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "リソースに付与するタグ"
  type        = map(string)
  default     = {}
}
