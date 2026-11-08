# ============================================================
# S3 Bucket for Static Website Hosting
# ============================================================

# --- S3 Bucket ---
resource "aws_s3_bucket" "website" {
  bucket = "${var.project_name}-frontend-${var.environment}-${local.bucket_suffix}"

  tags = {
    Name = "${var.project_name}-frontend-${var.environment}"
  }
}

# --- Bucket Versioning ---
resource "aws_s3_bucket_versioning" "website" {
  bucket = aws_s3_bucket.website.id

  versioning_configuration {
    status = "Enabled"
  }
}

# --- Static Website Configuration ---
resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

# --- Public Access Block (Allow public access for static website) ---
resource "aws_s3_bucket_public_access_block" "website" {
  bucket = aws_s3_bucket.website.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# --- Bucket Policy for Public Read Access ---
resource "aws_s3_bucket_policy" "website" {
  bucket = aws_s3_bucket.website.id

  # Public Access Blockの設定が適用されてからポリシーを適用
  depends_on = [aws_s3_bucket_public_access_block.website]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.website.arn}/*"
      }
    ]
  })
}

# --- CORS Configuration (for API calls) ---
resource "aws_s3_bucket_cors_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

# ============================================================
# Upload Files
# ============================================================

# --- index.html ---
resource "aws_s3_object" "index_html" {
  bucket       = aws_s3_bucket.website.id
  key          = "index.html"
  source       = "${path.module}/upload_file/index.html"
  content_type = "text/html; charset=utf-8"
  etag         = filemd5("${path.module}/upload_file/index.html")

  tags = {
    Name = "QR Generator Frontend"
  }
}
