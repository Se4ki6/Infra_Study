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

// アクセスを許可するIPv4アドレスのリスト
variable "allowed_ip_v4" {
  default = ["192.168.11.6"] # ← あなたのIPv4アドレス
}

// アクセスを許可するIPv6アドレスのリスト
variable "allowed_ip_v6" {
  default = ["2401:4d40:22a0:700:3014:4fe2:f522:f037"] # ← あなたのIPv6アドレス
}

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
  default     = "" // デフォルトはルートフィックス

}

// 画像ファイル専用のS3プレフィックス
// 画像専用プレフィックス設定
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

// WAF用のIP制限設定
variable "allowed_ip_addresses" {
  description = "アクセスを許可するIPアドレスのリスト (CIDR形式)"
  type        = list(string)
  default     = []
}
