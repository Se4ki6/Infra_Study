output "bucket_id" {
  description = "バケット名（= バケットID）"
  value       = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = "バケットARN"
  value       = aws_s3_bucket.this.arn
}
