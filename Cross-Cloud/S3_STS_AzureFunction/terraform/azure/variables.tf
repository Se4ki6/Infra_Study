variable "azure_subscription_id" {
  description = "デプロイ先サブスクリプションID (空なら az login の既定サブスクリプション)"
  type        = string
  default     = ""
}

variable "azure_tenant_id" {
  description = "Entra ID テナントID (空なら az login のテナント)"
  type        = string
  default     = ""
}

variable "location" {
  description = "Azure リージョン"
  type        = string
  default     = "japaneast"
}

variable "environment" {
  description = "環境名"
  type        = string
  default     = "dev"
}

variable "name_prefix" {
  description = "リソース名の接頭辞 (英小文字と数字のみ推奨)"
  type        = string
  default     = "s3sts"
}

variable "function_app_sku_name" {
  description = <<-EOT
    App Service Plan の SKU。
      Y1 -> Linux Consumption (従量課金・無料枠あり)。ただしサブスクリプションによっては
            "Total VMs" クォータが 0 で作成できないことがある (新規 PayAsYouGo 等)。
      B1 -> Basic (常時課金・目安 月 $13 程度)。Y1 のクォータで詰まった場合の代替。
    Y1 で作成できない場合、Azure Portal の「使用状況とクォータ」からセルフサービスで
    増枠申請するのが本来の直し方。B1 はそれまでのつなぎとして使う。
  EOT
  type        = string
  default     = "Y1"
}

// ==============================================================================
// Entra ID アプリ登録 (方式B の OIDC トークンの宛先)
// ==============================================================================

variable "entra_app_display_name" {
  description = "AWS からトークンの宛先 (aud) として信頼させる Entra ID アプリの表示名"
  type        = string
  default     = "AWS S3 STS Access"
}

variable "entra_requested_token_version" {
  description = <<-EOT
    このアプリ向けに発行されるアクセストークンのバージョン (1 or 2)。
    AWS 側の azure_token_version と対応させる。
      1 -> iss: https://sts.windows.net/<tenant>/         aud: api://<client-id>
      2 -> iss: https://login.microsoftonline.com/<t>/v2.0 aud: <client-id>

    マネージドID が実際にどちらを返すかは環境依存なので、デプロイ後に
    GET /api/token-claims で実測して AWS 側の設定を合わせること。
  EOT
  type        = number
  default     = 1

  validation {
    condition     = contains([1, 2], var.entra_requested_token_version)
    error_message = "entra_requested_token_version は 1 または 2 を指定してください。"
  }
}

// ==============================================================================
// AWS 側の値 (terraform/aws の出力をここに渡す)
// ==============================================================================
// 初回はすべて空のまま apply してよい (Function App だけ先に作られる)。
// terraform/aws を apply したあと、出力値を埋めて再度 apply する。

variable "aws_region" {
  description = "S3 バケットのリージョン"
  type        = string
  default     = "ap-southeast-2"
}

variable "aws_s3_bucket" {
  description = "terraform/aws の出力 bucket_name"
  type        = string
  default     = ""
}

variable "aws_s3_prefix" {
  description = "terraform/aws の出力 allowed_prefix"
  type        = string
  default     = "shared"
}

variable "default_credential_mode" {
  description = "Function の既定の認証方式 (accesskey | oidc)。リクエストの ?mode= で上書きできる"
  type        = string
  default     = "oidc"

  validation {
    condition     = contains(["accesskey", "oidc"], var.default_credential_mode)
    error_message = "default_credential_mode は \"accesskey\" または \"oidc\" を指定してください。"
  }
}

variable "aws_sts_session_duration_seconds" {
  description = "STS で要求する一時クレデンシャルの有効期間 (秒)"
  type        = number
  default     = 900
}

// ------------------------------------------------------------------------------
// 方式A の値
// ------------------------------------------------------------------------------

variable "aws_assume_role_arn" {
  description = "terraform/aws の出力 assume_role_arn"
  type        = string
  default     = ""
}

variable "aws_bootstrap_access_key_id" {
  description = "terraform/aws の出力 bootstrap_access_key_id"
  type        = string
  default     = ""
  sensitive   = true
}

variable "aws_bootstrap_secret_access_key" {
  description = "terraform/aws の出力 bootstrap_secret_access_key"
  type        = string
  default     = ""
  sensitive   = true
}

variable "aws_external_id" {
  description = "terraform/aws に設定した external_id と同じ値"
  type        = string
  default     = ""
  sensitive   = true
}

// ------------------------------------------------------------------------------
// 方式B の値
// ------------------------------------------------------------------------------

variable "aws_web_identity_role_arn" {
  description = "terraform/aws の出力 web_identity_role_arn"
  type        = string
  default     = ""
}
