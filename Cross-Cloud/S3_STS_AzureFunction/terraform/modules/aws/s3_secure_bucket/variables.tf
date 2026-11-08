variable "bucket_name" {
  description = "S3 バケット名 (AWS 全体でグローバルに一意)"
  type        = string
}

variable "key_prefix" {
  description = "サンプルファイルを配置するプレフィックス (空文字ならバケット直下)"
  type        = string
  default     = ""
}

variable "sample_files_folder" {
  description = "アップロードするローカルフォルダのパス (空文字でアップロードしない)"
  type        = string
  default     = ""
}

variable "tags" {
  description = "リソースに付与するタグ"
  type        = map(string)
  default     = {}
}
