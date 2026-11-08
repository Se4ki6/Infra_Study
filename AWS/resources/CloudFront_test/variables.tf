# S3バケット名（グローバルで一意である必要があります）
variable "bucket_name" {
  description = "S3バケットの名前（グローバルで一意）"
  type        = string
}
