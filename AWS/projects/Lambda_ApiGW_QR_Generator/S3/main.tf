# ============================================================
# QR Generator Frontend - S3 Static Website Hosting
# ============================================================
#
# このTerraformコードは、QRコード生成ツールのフロントエンド
# (index.html) をS3でホスティングするためのリソースを作成します。
#
# 使用方法:
#   terraform init
#   terraform plan -var-file="dev.tfvars"
#   terraform apply -var-file="dev.tfvars"
#
# ============================================================

terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = var.profile

  default_tags {
    tags = {
      Project     = "qr-generator"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

# ============================================================
# Random Suffix for Dev Environment
# ============================================================

resource "random_string" "bucket_suffix" {
  count   = var.bucket_name_suffix == "" ? 1 : 0
  length  = 8
  special = false
  upper   = false
}

locals {
  bucket_suffix = var.bucket_name_suffix != "" ? var.bucket_name_suffix : random_string.bucket_suffix[0].result
}
