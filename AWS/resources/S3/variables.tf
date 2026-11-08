// S3バケット名の変数定義
// バケット名はAWS全体でグローバルに一意である必要がある
variable "bucket_name" {
  // コンソール上での説明表示用
  description = "S3バケットの名前"
  type        = string // 文字列型
  // デフォルト値なし = 必須パラメータ
}

// 環境名の変数定義
// リソースの用途や環境を識別するために使用
variable "environment" {
  description = "環境名 (dev, staging, prod など)"
  type        = string // 文字列型
  default     = "dev"  // デフォルト値は "dev" (開発環境)
}

// S3にアップロードするファイルが格納されているローカルフォルダのパス
// このフォルダ内の全ファイルが自動的にS3にアップロードされる
variable "upload_folder" {
  description = "アップロードするファイルが格納されているフォルダのパス"
  type        = string
  default     = "upload_file"
}

// S3にアップロードする際のプレフィックス (フォルダパス)
// 空文字列の場合はバケットのルートにアップロードされる
variable "s3_prefix" {
  description = "S3内でのファイルのプレフィックス (フォルダパス)"
  type        = string
  default     = "" // デフォルトはルート
}

// 静的ウェブサイトホスティングを有効にするかどうか
variable "enable_website_hosting" {
  description = "静的ウェブサイトホスティングを有効にするかどうか"
  type        = bool
  default     = false
}

// IAMユーザーを作成するかどうか（ローカル開発用）
variable "create_iam_user" {
  description = "IAMユーザーを作成するかどうか（ローカル開発用）"
  type        = bool
  default     = true
}

// IAMロールを作成するかどうか（Lambda/EC2用）
variable "create_iam_role" {
  description = "IAMロールを作成するかどうか（Lambda/EC2用）"
  type        = bool
  default     = false
}

// IAMロールのサービスプリンシパル
variable "iam_role_service" {
  description = "IAMロールの使用サービス（lambda.amazonaws.com or ec2.amazonaws.com）"
  type        = string
  default     = "lambda.amazonaws.com"
}

// ==============================================================================
// 画像専用プレフィックス設定 (ステップ2)
// ==============================================================================

// 画像ファイル専用のS3プレフィックス
variable "images_prefix" {
  description = "画像ファイルをアップロードするS3プレフィックス（フォルダパス）"
  type        = string
  default     = "images"
}

// 画像ファイルが格納されているローカルフォルダ
variable "images_upload_folder" {
  description = "画像ファイルが格納されているローカルフォルダのパス"
  type        = string
  default     = "upload_file/images"
}

// 画像アップロードを有効にするかどうか
variable "enable_images_upload" {
  description = "画像専用フォルダからのアップロードを有効にするかどうか"
  type        = bool
  default     = true
}
