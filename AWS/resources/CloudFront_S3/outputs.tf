# --------------------------------------------------------------------------------
# 出力値
# Terraform実行後に表示される情報です。
# --------------------------------------------------------------------------------

# S3バケット名
output "bucket_name" {
  description = "S3バケット名"
  value       = aws_s3_bucket.website_bucket.id
}

# S3バケットのARN
output "bucket_arn" {
  description = "S3バケットのARN"
  value       = aws_s3_bucket.website_bucket.arn
}

# CloudFrontディストリビューションのドメイン名
output "cloudfront_domain_name" {
  description = "CloudFrontディストリビューションのドメイン名"
  value       = aws_cloudfront_distribution.s3_distribution.domain_name
}

# CloudFrontディストリビューションのURL
output "cloudfront_url" {
  description = "CloudFrontディストリビューションのURL"
  value       = "https://${aws_cloudfront_distribution.s3_distribution.domain_name}"
}

# CloudFrontディストリビューションのID
output "cloudfront_id" {
  description = "CloudFrontディストリビューションのID"
  value       = aws_cloudfront_distribution.s3_distribution.id
}

# CloudFrontディストリビューションのARN
output "cloudfront_arn" {
  description = "CloudFrontディストリビューションのARN"
  value       = aws_cloudfront_distribution.s3_distribution.arn
}

# WAF WebACL ARN
output "waf_web_acl_arn" {
  description = "WAF WebACLのARN"
  value       = aws_wafv2_web_acl.ip_restriction.arn
}
