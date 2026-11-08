terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    // Entra ID の証明書サムプリントを動的に取得するために使用
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}
