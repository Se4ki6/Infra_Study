variable "resource_group_name" {
  description = "Resource group that contains the Storage Account."
  type        = string
}

variable "location" {
  description = "Azure region for the Storage Account."
  type        = string
}

variable "storage_account_name" {
  description = "Globally unique, lowercase Storage Account name."
  type        = string
}

variable "container_name" {
  description = "Private Blob container for order JSON documents."
  type        = string
}

variable "tags" {
  description = "Tags applied to storage resources."
  type        = map(string)
}
