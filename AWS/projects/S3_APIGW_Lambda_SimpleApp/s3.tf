# Random suffix for unique bucket name
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "frontend" {
  bucket        = "${var.project_name}-frontend-${random_id.bucket_suffix.hex}"
  force_destroy = true
}

resource "aws_s3_bucket_website_configuration" "hosting" {
  bucket = aws_s3_bucket.frontend.id
  index_document {
    suffix = "index.html"
  }
}

# Public Read Policy (for website hosting)
resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "allow_public_read" {
  depends_on = [aws_s3_bucket_public_access_block.public_access]
  bucket     = aws_s3_bucket.frontend.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.frontend.arn}/*"
      },
    ]
  })
}

# Upload HTML files
# etagにfilemd5を使用することで、ファイル内容が変更された場合に自動的に検知・再アップロードされる
resource "aws_s3_object" "index_html" {
  bucket       = aws_s3_bucket.frontend.id
  key          = "index.html"
  source       = "${path.module}/src/frontend/index.html"
  content_type = "text/html"
  # filemd5ハッシュを計算してファイルの整合性を検証
  etag         = filemd5("${path.module}/src/frontend/index.html")
}

resource "aws_s3_object" "error_html" {
  bucket       = aws_s3_bucket.frontend.id
  key          = "error.html"
  source       = "${path.module}/src/frontend/error.html"
  content_type = "text/html"
  # filemd5ハッシュを計算してファイルの整合性を検証
  etag         = filemd5("${path.module}/src/frontend/error.html")
}
