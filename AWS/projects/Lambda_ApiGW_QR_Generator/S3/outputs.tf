# ============================================================
# Outputs
# ============================================================

output "environment" {
  description = "Current Environment"
  value       = var.environment
}

output "bucket_name" {
  description = "S3 Bucket Name"
  value       = aws_s3_bucket.website.id
}

output "bucket_arn" {
  description = "S3 Bucket ARN"
  value       = aws_s3_bucket.website.arn
}

output "website_endpoint" {
  description = "S3 Static Website Endpoint"
  value       = aws_s3_bucket_website_configuration.website.website_endpoint
}

output "website_url" {
  description = "Website URL (HTTP)"
  value       = "http://${aws_s3_bucket_website_configuration.website.website_endpoint}"
}

output "bucket_regional_domain" {
  description = "S3 Bucket Regional Domain Name"
  value       = aws_s3_bucket.website.bucket_regional_domain_name
}

# 使い方の説明
output "usage_instructions" {
  description = "How to use the QR Generator"
  value       = <<-EOT

    =============================================
    QRコード生成ツールの使い方
    =============================================

    1. 以下のURLにアクセス:
       http://${aws_s3_bucket_website_configuration.website.website_endpoint}

    2. 「API設定」を開いて、Lambda API GatewayのエンドポイントURLを入力
       例: https://xxxxxxxx.execute-api.ap-northeast-1.amazonaws.com

    3. 変換したいURLを入力して「QRコードを生成」ボタンをクリック

    =============================================
  EOT
}
