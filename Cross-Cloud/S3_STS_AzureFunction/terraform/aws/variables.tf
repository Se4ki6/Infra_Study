// ==============================================================================
// 共通設定
// ==============================================================================

variable "aws_region" {
  description = "リソースを作成するリージョン"
  type        = string
  default     = "ap-southeast-2"
}

variable "aws_profile" {
  description = "使用する AWS CLI プロファイル (SSO)"
  type        = string
  default     = "AdministratorAccess-339126664118"
}

variable "environment" {
  description = "環境名 (dev, staging, prod など)"
  type        = string
  default     = "dev"
}

variable "name_prefix" {
  description = "IAM ロール・ポリシー名の接頭辞"
  type        = string
  default     = "s3-sts-azure"
}

// ==============================================================================
// S3 バケット設定
// ==============================================================================

variable "bucket_name" {
  description = "S3 バケット名 (AWS 全体でグローバルに一意である必要がある)"
  type        = string
}

variable "allowed_prefix" {
  description = <<-EOT
    STS ロールに読み取りを許可する S3 プレフィックス。
    空文字にするとバケット全体が対象になる。最小権限の練習として既定ではプレフィックスを絞る。
  EOT
  type        = string
  default     = "shared"
}

variable "sample_files_folder" {
  description = "サンプルとして allowed_prefix 配下にアップロードするローカルフォルダ (空文字でアップロードしない)"
  type        = string
  default     = "../../sample_files"
}

// ------------------------------------------------------------------------------
// バケットロックダウン (この構成の中核)
// ------------------------------------------------------------------------------
variable "enable_bucket_lockdown" {
  description = <<-EOT
    true にすると「STS で Assume したロール」と「Terraform 実行者/ルート」以外の
    全 principal を S3 バケットポリシーの Deny で締め出す。
    これが「外部からのアクセスは STS 経由のみ」を実際に強制している部分。

    【重要】Deny はアカウント内の IAM ポリシーより優先されるため、設定を誤ると
    自分自身もバケットを操作できなくなる。復旧はルートユーザーでバケットポリシーを
    削除する (ルートはバケットポリシーの Deny を受けても DeleteBucketPolicy が可能)。
    詳細は README.md の「ロックアウトからの復旧」を参照。
  EOT
  type        = bool
  default     = true
}

variable "additional_allowed_user_ids" {
  description = <<-EOT
    ロックダウンの例外に追加したい aws:userId のリスト。
    形式: IAM ユーザーは "AIDA...", Assume ロールは "AROA...:*", ルートは "<アカウントID>"。
    確認コマンド: aws sts get-caller-identity --query UserId --output text
  EOT
  type        = list(string)
  default     = []
}

variable "session_duration_seconds" {
  description = "STS 一時クレデンシャルの最大有効期間 (秒)。ロールの max_session_duration に設定される"
  type        = number
  default     = 3600

  validation {
    condition     = var.session_duration_seconds >= 900 && var.session_duration_seconds <= 43200
    error_message = "session_duration_seconds は 900〜43200 の範囲で指定してください。"
  }
}

// ==============================================================================
// 方式A: アクセスキー + sts:AssumeRole
// ==============================================================================

variable "enable_access_key_flow" {
  description = "方式A (IAM ユーザーのアクセスキー → AssumeRole) を作成するかどうか"
  type        = bool
  default     = true
}

variable "external_id" {
  description = <<-EOT
    方式A の AssumeRole に要求する ExternalId。
    「混乱した代理人 (confused deputy) 問題」対策で、ロールARNを知っているだけでは
    Assume できないようにするための合言葉。推測されにくいランダム文字列を設定する。
    生成例: openssl rand -hex 16
  EOT
  type        = string
  default     = ""
  sensitive   = true
}

// ==============================================================================
// 方式B: OIDC フェデレーション + sts:AssumeRoleWithWebIdentity
// ==============================================================================

variable "enable_oidc_flow" {
  description = "方式B (Entra ID の OIDC トークン → AssumeRoleWithWebIdentity) を作成するかどうか"
  type        = bool
  default     = true
}

variable "azure_tenant_id" {
  description = "Entra ID (Azure AD) のテナントID。terraform/azure の出力 azure_tenant_id をそのまま渡す"
  type        = string
  default     = ""

  validation {
    condition     = !var.enable_oidc_flow || var.azure_tenant_id != ""
    error_message = "enable_oidc_flow = true の場合は azure_tenant_id が必須です。先に terraform/azure を apply して出力値を取得してください。"
  }
}

variable "azure_token_version" {
  description = <<-EOT
    Azure が発行するアクセストークンのバージョン。信頼する issuer (OIDC プロバイダ URL) が変わる。
      v1 -> https://sts.windows.net/<tenant-id>            (マネージドID が発行するトークンは通常こちら)
      v2 -> https://login.microsoftonline.com/<tenant-id>/v2.0

    【必ず実測して合わせること】
    Function App の GET /api/token-claims を叩くと、実際に発行されたトークンの
    iss / aud / sub が返る。その iss に一致する方を選ぶ。
  EOT
  type        = string
  default     = "v1"

  validation {
    condition     = contains(["v1", "v2"], var.azure_token_version)
    error_message = "azure_token_version は \"v1\" または \"v2\" を指定してください。"
  }
}

variable "azure_oidc_audience" {
  description = <<-EOT
    信頼するトークンの aud クレーム。terraform/azure の出力 aws_oidc_audience_v1 / _v2 を渡す。
      v1 トークン -> アプリケーションID URI (例: api://s3-sts-azure-aws-access)
      v2 トークン -> アプリケーションの client id (GUID)
    ここも /api/token-claims の実測値に合わせる。
  EOT
  type        = string
  default     = ""

  validation {
    condition     = !var.enable_oidc_flow || var.azure_oidc_audience != ""
    error_message = "enable_oidc_flow = true の場合は azure_oidc_audience が必須です。terraform/azure の出力 aws_oidc_audience を渡してください。"
  }
}

variable "azure_function_principal_id" {
  description = <<-EOT
    Function App のシステム割り当てマネージドID の principal id (オブジェクトID)。
    トークンの sub クレームと一致し、ロールの信頼ポリシーで「この Function だけ」に絞るために使う。
    空文字にすると sub 条件を付けない (aud のみで判定 = テナント内の他のIDでも Assume できてしまうので非推奨)。
  EOT
  type        = string
  default     = ""
}
