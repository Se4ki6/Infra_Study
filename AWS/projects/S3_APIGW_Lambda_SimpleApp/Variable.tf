variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-1"
}

variable "project_name" {
  description = "Project name prefix"
  type        = string
  default     = "serverless-demo"
}
variable "aws_profile" {
  description = "AWS SSO Profile"
  type        = string
  default     = "AdministratorAccess-339126664118"
}
