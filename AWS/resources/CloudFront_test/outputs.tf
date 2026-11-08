# CloudFrontのURL
output "cloudfront_url" {
  description = "CloudFrontディストリビューションのURL"
  value       = "https://${aws_cloudfront_distribution.s3_distribution.domain_name}"
}

# CloudFrontのドメイン名
output "cloudfront_domain_name" {
  description = "CloudFrontのドメイン名"
  value       = aws_cloudfront_distribution.s3_distribution.domain_name
}

# S3バケット名
output "s3_bucket_name" {
  description = "S3バケット名"
  value       = aws_s3_bucket.cloudfront_origin.id
}
