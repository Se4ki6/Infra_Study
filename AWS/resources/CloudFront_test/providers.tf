# Terraformとプロバイダーの設定
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# AWSプロバイダー
# CloudFrontはグローバルサービスですが、us-east-1リージョンを使用するのが一般的
provider "aws" {
  region  = "us-east-1"
  profile = "AdministratorAccess-339126664118"
}
