variable "name" {
  description = "作成する Resource Group 名です。"
  type        = string
}

variable "location" {
  description = "Resource Group のリージョンです。"
  type        = string
}

variable "tags" {
  description = "Resource Group に付けるタグです。"
  type        = map(string)
  default     = {}
}
