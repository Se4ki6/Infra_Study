variable "subscription_id" {
  description = "Azure subscription ID used by the AzureRM provider."
  type        = string
  nullable    = false
}

variable "environment" {
  description = "Environment suffix used in resource names and tags."
  type        = string
  default     = "study"

  validation {
    condition     = can(regex("^[a-z0-9]{3,12}$", var.environment))
    error_message = "environment must contain 3 to 12 lowercase letters or digits."
  }
}

variable "name_suffix" {
  description = "Optional lowercase alphanumeric suffix input for regenerating the globally unique storage account name."
  type        = string
  default     = ""

  validation {
    condition     = var.name_suffix == "" || can(regex("^[a-z0-9]+$", var.name_suffix))
    error_message = "name_suffix must be empty or contain only lowercase letters and digits."
  }
}

variable "location" {
  description = "Azure region shared by all resources."
  type        = string
  default     = "japaneast"
}

variable "tags" {
  description = "Additional tags merged with the project, environment, and managed-by tags."
  type        = map(string)
  default     = {}
}

variable "log_retention_days" {
  description = "Log Analytics Workspace retention period in days."
  type        = number
  default     = 30

  validation {
    condition     = var.log_retention_days >= 30 && var.log_retention_days <= 730
    error_message = "log_retention_days must be between 30 and 730."
  }
}

variable "daily_data_cap_gb" {
  description = "Daily ingestion cap in GB applied to the Workspace and Application Insights."
  type        = number
  default     = 1

  validation {
    condition     = var.daily_data_cap_gb > 0
    error_message = "daily_data_cap_gb must be greater than zero."
  }
}

variable "image_tag" {
  description = "Container image tag used when the API Container App is enabled."
  type        = string
  default     = "latest"

  validation {
    condition     = can(regex("^[A-Za-z0-9_][A-Za-z0-9_.-]{0,127}$", var.image_tag))
    error_message = "image_tag must be a valid Docker image tag of at most 128 characters."
  }
}

variable "enable_api" {
  description = "Create the API Container App after its image has been pushed to the registry."
  type        = bool
  default     = false
}
