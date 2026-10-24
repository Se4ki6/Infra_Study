variable "resource_group_name" {
  description = "Resource group that contains the Container Apps and Registry resources."
  type        = string
}

variable "location" {
  description = "Azure region for the hosting resources."
  type        = string
}

variable "environment" {
  description = "Environment suffix used in resource names."
  type        = string
}

variable "container_registry_name" {
  description = "Globally unique lowercase alphanumeric Container Registry name."
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "Workspace receiving Container Apps system and console logs."
  type        = string
}

variable "application_insights_connection_string" {
  description = "Connection string used by the API to send telemetry to Application Insights."
  type        = string
  sensitive   = true
}

variable "blob_connection_string" {
  description = "Connection string used by the API to access Azure Blob Storage."
  type        = string
  sensitive   = true
}

variable "blob_container_name" {
  description = "Blob container used to store order documents."
  type        = string
}

variable "image_tag" {
  description = "Tag of the API image already pushed to the Container Registry."
  type        = string
}

variable "enable_api" {
  description = "Whether to create the Container App after its image is available."
  type        = bool
}

variable "tags" {
  description = "Tags applied to hosting resources."
  type        = map(string)
}
