variable "resource_group_name" {
  description = "Resource group for monitoring resources."
  type        = string
}

variable "location" {
  description = "Azure region for monitoring resources."
  type        = string
}

variable "environment" {
  description = "Environment suffix used in resource names."
  type        = string
}

variable "log_retention_days" {
  description = "Log Analytics Workspace retention period in days."
  type        = number
}

variable "daily_data_cap_gb" {
  description = "Daily ingestion cap in GB for the Workspace and Application Insights."
  type        = number
}

variable "tags" {
  description = "Tags applied to monitoring resources."
  type        = map(string)
}
