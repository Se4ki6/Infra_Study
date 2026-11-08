variable "name" {
  description = "作成する Storage Account 名です。"
  type        = string
}

variable "resource_group_name" {
  description = "Storage Account を配置する Resource Group 名です。"
  type        = string
}

variable "location" {
  description = "Storage Account のリージョンです。"
  type        = string
}

variable "deployment_container_name" {
  description = "Function App の配置パッケージを置く Blob Container 名です。"
  type        = string
}

variable "tags" {
  description = "Storage Account に付けるタグです。"
  type        = map(string)
  default     = {}
}
