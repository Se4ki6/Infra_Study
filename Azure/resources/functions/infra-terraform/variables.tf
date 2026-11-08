variable "location" {
  description = "Azure リソースを配置するリージョンです。"
  type        = string
  default     = "Japan East"
}

variable "name_prefix" {
  description = "リソース名の先頭に使う英小文字と数字のプレフィックスです。"
  type        = string
  default     = "learnfunc"

  validation {
    condition     = can(regex("^[a-z0-9]+$", var.name_prefix))
    error_message = "name_prefix には英小文字と数字だけを使ってください。"
  }
}

variable "environment" {
  description = "環境名です。短い英小文字と数字だけを使います。"
  type        = string
  default     = "dev"

  validation {
    condition     = can(regex("^[a-z0-9]+$", var.environment))
    error_message = "environment には英小文字と数字だけを使ってください。"
  }
}

variable "runtime_name" {
  description = "Flex Consumption Function App のランタイム名です。"
  type        = string
  default     = "python"
}

variable "runtime_version" {
  description = "Function App のランタイムバージョンです。"
  type        = string
  default     = "3.10"
}

variable "maximum_instance_count" {
  description = "Flex Consumption での最大インスタンス数です。"
  type        = number
  default     = 50
}

variable "instance_memory_in_mb" {
  description = "Flex Consumption で使うメモリサイズです。"
  type        = number
  default     = 2048
}

variable "tags" {
  description = "全リソースに付ける共通タグです。"
  type        = map(string)
  default = {
    managed_by = "terraform"
    project    = "azure-functions-learning"
  }
}
