// ==============================================================================
// 共通設定
// ==============================================================================

variable "aws_region" {
  description = "リソースを作成するリージョン"
  type        = string
  default     = "ap-northeast-1"
}

variable "aws_profile" {
  description = "apply に使う AWS CLI プロファイル名"
  type        = string
}

variable "environment" {
  description = "環境名 (dev, staging, prod など)"
  type        = string
  default     = "prod"
}

variable "name_prefix" {
  description = "IAM ロール・ユーザー・ポリシー名の接頭辞"
  type        = string
}

// ==============================================================================
// S3 バケット設定
// ==============================================================================

variable "bucket_name" {
  description = "新規作成する S3 バケット名 (AWS 全体でグローバルに一意である必要がある)"
  type        = string
}

variable "allowed_prefix" {
  description = <<-EOT
    連携先 (バッチ) に読み取りを許可する S3 プレフィックス。
    空文字にするとバケット全体が対象になる (最小権限の観点から、必要な範囲に絞ることを推奨)。
  EOT
  type        = string
}

// ==============================================================================
// バケットロックダウン
// ==============================================================================

variable "enable_bucket_lockdown" {
  description = <<-EOT
    true にすると「STS で AssumeRole したセッション」と「Terraform 実行者/ルート」以外の
    全 principal を S3 バケットポリシーの明示的 Deny で締め出す。
    これが「外部からのアクセスは AssumeRole 経由のみ」を強制している部分。

    【重要】明示的 Deny はアカウント内の IAM ポリシー (AdministratorAccess を含む) より
    優先されるため、設定を誤ると自分自身もバケットを操作できなくなる。
    Terraform 実行者は自動的に例外リストへ入るが、別のプロファイルや CI から触る場合は
    additional_allowed_user_ids に追加すること。
    復旧はルートユーザーでバケットポリシーを削除する (ルートは Deny を受けても
    DeleteBucketPolicy が可能)。
  EOT
  type        = bool
  default     = true
}

variable "additional_allowed_user_ids" {
  description = <<-EOT
    ロックダウンの例外に追加したい aws:userId のリスト。
    形式: IAM ユーザーは "AIDA...", Assume ロールのセッションは "AROA...:*", ルートは "<アカウントID>"。
    確認コマンド: aws sts get-caller-identity --query UserId --output text
  EOT
  type        = list(string)
  default     = []
}

// ==============================================================================
// AssumeRole (アクセスキー方式)
// ==============================================================================

variable "external_id" {
  description = <<-EOT
    AssumeRole に要求する ExternalId。
    「混乱した代理人 (confused deputy) 問題」対策で、ロール ARN とアクセスキーの両方を
    知っていても、この合言葉を知らなければ AssumeRole できないようにするための値。
    連携先 (バッチ側) にはこの値を安全な経路 (Key Vault 等) で共有すること。
    生成例 (PowerShell): -join ((1..32) | % { '{0:x}' -f (Get-Random -Max 16) })
  EOT
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.external_id) >= 16
    error_message = "external_id は推測されないよう 16 文字以上のランダムな値にしてください。"
  }
}

variable "session_duration_seconds" {
  description = "AssumeRole で発行する一時クレデンシャルの最大有効期間 (秒)"
  type        = number
  default     = 3600

  validation {
    condition     = var.session_duration_seconds >= 900 && var.session_duration_seconds <= 43200
    error_message = "session_duration_seconds は 900〜43200 の範囲で指定してください。"
  }
}

variable "tags" {
  description = "リソースに付与する追加タグ"
  type        = map(string)
  default     = {}
}
