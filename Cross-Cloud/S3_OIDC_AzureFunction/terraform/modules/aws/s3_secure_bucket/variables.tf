variable "bucket_name" {
  description = "S3 バケット名（グローバルで一意である必要がある）"
  type        = string
}

variable "key_prefix" {
  description = "サンプルファイルを配置するプレフィックス（空文字ならバケット直下）"
  type        = string
  default     = ""
}

variable "sample_files_folder" {
  description = "アップロードするサンプルファイルが置かれたローカルフォルダ。空文字なら何もアップロードしない"
  type        = string
  default     = ""
}

variable "tags" {
  description = "リソースに付与するタグ"
  type        = map(string)
  default     = {}
}
