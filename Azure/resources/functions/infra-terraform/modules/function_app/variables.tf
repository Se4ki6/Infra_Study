variable "function_app_name" {
  description = "作成する Function App 名です。"
  type        = string
}

variable "service_plan_name" {
  description = "作成する Flex Consumption Plan 名です。"
  type        = string
}

variable "resource_group_name" {
  description = "Function App を配置する Resource Group 名です。"
  type        = string
}

variable "location" {
  description = "Function App のリージョンです。"
  type        = string
}

variable "storage_container_endpoint" {
  description = "配置パッケージを置く Blob Container のエンドポイントです。"
  type        = string
}

variable "storage_access_key" {
  description = "Storage Account の access key です。"
  type        = string
  sensitive   = true
}

variable "runtime_name" {
  description = "Function App のランタイム名です。"
  type        = string
}

variable "runtime_version" {
  description = "Function App のランタイムバージョンです。"
  type        = string
}

variable "maximum_instance_count" {
  description = "Flex Consumption の最大インスタンス数です。"
  type        = number
}

variable "instance_memory_in_mb" {
  description = "Flex Consumption のメモリサイズです。"
  type        = number
}

variable "tags" {
  description = "Function App に付けるタグです。"
  type        = map(string)
  default     = {}
}
