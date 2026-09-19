variable "storage_account_name" {
  description = "Storage Account名（グローバル一意）"
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

variable "queue_name" {
  description = "ジョブ投入用Storage Queueの名前"
  type        = string
  default     = "resource-check-jobs"
}

variable "table_name" {
  description = "ジョブ状態を保存するTable Storageの名前"
  type        = string
  default     = "jobstatus"
}

variable "tags" {
  description = "リソースに付与するタグ"
  type        = map(string)
  default     = {}
}
