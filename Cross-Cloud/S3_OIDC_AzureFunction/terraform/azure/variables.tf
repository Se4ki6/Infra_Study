variable "name_prefix" {
  description = "リソース名の接頭辞"
  type        = string
  default     = "s3oidc"
}

variable "environment" {
  description = "環境名（タグ付け用）"
  type        = string
  default     = "study"
}

variable "location" {
  description = "デプロイ先のAzureリージョン"
  type        = string
  default     = "japaneast"
}

variable "entra_app_display_name" {
  description = "OIDCトークンの宛先になるEntra IDアプリの表示名"
  type        = string
  default     = "s3-oidc-azurefunction"
}

variable "entra_requested_token_version" {
  description = "Entra IDアプリが発行するトークンのバージョン（1 or 2）"
  type        = number
  default     = 1
}

variable "function_app_sku_name" {
  description = "App Service PlanのSKU（Y1 = Consumption）"
  type        = string
  default     = "Y1"
}

variable "python_version" {
  description = "Functionランタイムに使うPythonバージョン"
  type        = string
  default     = "3.11"
}

// ---- AWS側と接続するための値 ----

variable "aws_region" {
  description = "S3バケットがあるAWSリージョン"
  type        = string
}

variable "aws_s3_bucket" {
  description = "ダウンロード対象のS3バケット名"
  type        = string
}

variable "aws_s3_prefix" {
  description = "ダウンロード対象のキー プレフィックス"
  type        = string
  default     = ""
}

variable "aws_web_identity_role_arn" {
  description = <<-EOT
    AssumeRoleWithWebIdentityで引き受けるロールのARN。
    初回applyでは terraform/aws をまだ適用していないため空文字にしておき、
    terraform/aws apply後に得られる web_identity_role_arn を渡して再applyする。
  EOT
  type        = string
  default     = ""
}

variable "aws_sts_session_duration_seconds" {
  description = "AssumeRoleWithWebIdentityでリクエストする一時クレデンシャルの有効期間（秒）"
  type        = number
  default     = 3600
}

variable "tags" {
  description = "全リソース共通で付与する追加タグ"
  type        = map(string)
  default     = {}
}
