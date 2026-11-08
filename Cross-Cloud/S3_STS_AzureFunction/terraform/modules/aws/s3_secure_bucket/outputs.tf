output "bucket_id" {
  description = "S3 バケット名"
  value       = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = "S3 バケットの ARN"
  value       = aws_s3_bucket.this.arn
}

output "bucket_domain_name" {
  description = "S3 バケットのドメイン名"
  value       = aws_s3_bucket.this.bucket_domain_name
}

output "uploaded_keys" {
  description = "アップロードしたサンプルファイルのキー一覧"
  value       = [for object in aws_s3_object.samples : object.key]
}
