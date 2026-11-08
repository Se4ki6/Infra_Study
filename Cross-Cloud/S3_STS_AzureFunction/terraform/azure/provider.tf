terraform {
  required_version = ">= 1.9.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "azurerm" {
  features {}

  // 空文字の場合は環境変数 ARM_SUBSCRIPTION_ID / az login の既定サブスクリプションを使う
  subscription_id = var.azure_subscription_id == "" ? null : var.azure_subscription_id
}

provider "azuread" {
  tenant_id = var.azure_tenant_id == "" ? null : var.azure_tenant_id
}
