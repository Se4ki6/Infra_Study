variable "log_analytics_workspace_name" {
  description = "Log Analytics Workspace 名です。"
  type        = string
}

variable "application_insights_name" {
  description = "Application Insights 名です。"
  type        = string
}

variable "resource_group_name" {
  description = "監視リソースを配置する Resource Group 名です。"
  type        = string
}

variable "location" {
  description = "監視リソースのリージョンです。"
  type        = string
}

variable "tags" {
  description = "監視リソースに付けるタグです。"
  type        = map(string)
  default     = {}
}
