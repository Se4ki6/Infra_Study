# ============================================================
# Variables
# ============================================================

variable "profile" {
  description = "AWS Profile"
  type        = string
}

variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "ap-northeast-1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "qr-generator"
}

variable "bucket_name_suffix" {
  description = "Suffix for S3 bucket name (must be globally unique). Empty string will generate random suffix."
  type        = string
  default     = ""
}
