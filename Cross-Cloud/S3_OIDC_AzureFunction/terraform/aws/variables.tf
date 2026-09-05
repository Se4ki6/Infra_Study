variable "name_prefix" {
  description = "リソース名の接頭辞"
  type        = string
  default     = "s3-oidc"
}

variable "environment" {
  description = "環境名（タグ付け用）"
  type        = string
  default     = "study"
}

variable "aws_region" {
  description = "リソースを作成するAWSリージョン"
  type        = string
  default     = "ap-northeast-1"
}

variable "bucket_name" {
  description = "S3バケット名（グローバルで一意な名前を指定すること）"
  type        = string
}

variable "allowed_prefix" {
  description = "Functionからの読み取りを許可するキー プレフィックス（空文字ならバケット全体）"
  type        = string
  default     = ""
}

variable "sample_files_folder" {
  description = "動作確認用サンプルファイルのローカルフォルダ（terraform/awsからの相対パス）。空文字ならアップロードしない"
  type        = string
  default     = "../../sample_files"
}

variable "session_duration_seconds" {
  description = "AssumeRoleWithWebIdentityで発行する一時クレデンシャルの有効期間（秒）"
  type        = number
  default     = 3600
}

// ---- Azure側の値。1回目は terraform/azure の出力を確認してから埋める ----

variable "azure_tenant_id" {
  description = "Entra ID（Azure AD）のテナントID"
  type        = string
}

variable "azure_token_version" {
  description = "信頼するAzureトークンのバージョン（v1 or v2）。GET /api/token-claims の実測値に合わせる"
  type        = string
  default     = "v1"
}

variable "azure_oidc_audience" {
  description = "信頼するトークンのaud。terraform/azureの出力 entra_app_identifier_uri（v1）または entra_app_client_id（v2）を指定する"
  type        = string
}

variable "azure_function_principal_id" {
  description = "terraform/azureの出力 function_app_principal_id。Assumeを許可するマネージドIDを1つに絞り込む"
  type        = string
}

variable "tags" {
  description = "全リソース共通で付与する追加タグ"
  type        = map(string)
  default     = {}
}
