# ==============================================================================
# S3バケット（CloudFrontのオリジンとして使用）
# ==============================================================================

# S3バケット本体
resource "aws_s3_bucket" "cloudfront_origin" {
  bucket = var.bucket_name

  tags = {
    Name      = var.bucket_name
    ManagedBy = "Terraform"
  }
}

# S3バケットのパブリックアクセスをブロック
# CloudFront経由のみでアクセスさせるため、直接のパブリックアクセスは禁止
resource "aws_s3_bucket_public_access_block" "cloudfront_origin" {
  bucket = aws_s3_bucket.cloudfront_origin.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ==============================================================================
# CloudFront Origin Access Control (OAC)
# CloudFrontがS3にアクセスするための認証設定
# ==============================================================================

resource "aws_cloudfront_origin_access_control" "default" {
  name                              = "oac-${var.bucket_name}"
  description                       = "OAC for ${var.bucket_name}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# ==============================================================================
# CloudFront Distribution
# コンテンツ配信ネットワーク (CDN)
# ==============================================================================

resource "aws_cloudfront_distribution" "s3_distribution" {
  enabled             = true
  default_root_object = "index.html"

  # オリジン設定：コンテンツの取得元（S3バケット）
  origin {
    domain_name              = aws_s3_bucket.cloudfront_origin.bucket_regional_domain_name
    origin_id                = "S3-${var.bucket_name}"
    origin_access_control_id = aws_cloudfront_origin_access_control.default.id
  }

  # デフォルトのキャッシュ動作
  default_cache_behavior {
    target_origin_id       = "S3-${var.bucket_name}"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD"]
    cached_methods  = ["GET", "HEAD"]

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400
  }

  # 地理的制限なし
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # SSL証明書（CloudFrontのデフォルト証明書を使用）
  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name      = "cloudfront-${var.bucket_name}"
    ManagedBy = "Terraform"
  }
}

# ==============================================================================
# S3バケットポリシー
# CloudFrontからのみアクセスを許可
# ==============================================================================

resource "aws_s3_bucket_policy" "cloudfront_origin" {
  bucket = aws_s3_bucket.cloudfront_origin.id

  # CloudFrontディストリビューションが作成された後に適用
  depends_on = [
    aws_cloudfront_distribution.s3_distribution,
    aws_s3_bucket_public_access_block.cloudfront_origin
  ]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipal"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.cloudfront_origin.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.s3_distribution.arn
          }
        }
      }
    ]
  })
}

# ==============================================================================
# テスト用ファイルのアップロード
# ==============================================================================

# index.html
resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.cloudfront_origin.id
  key          = "index.html"
  source       = "${path.module}/upload_file/index.html"
  content_type = "text/html"
  etag         = filemd5("${path.module}/upload_file/index.html")
}

# error.html
resource "aws_s3_object" "error" {
  bucket       = aws_s3_bucket.cloudfront_origin.id
  key          = "error.html"
  source       = "${path.module}/upload_file/error.html"
  content_type = "text/html"
  etag         = filemd5("${path.module}/upload_file/error.html")
}
