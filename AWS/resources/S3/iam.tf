# ==============================================================================
# S3署名付きURL生成用のIAMリソース
# ==============================================================================

# ------------------------------------------------------------------------------
# IAMポリシー: S3署名付きURL生成用
# ------------------------------------------------------------------------------
resource "aws_iam_policy" "s3_presigned_url_generator" {
  name        = "${var.bucket_name}-presigned-url-generator"
  description = "S3バケットのオブジェクトに対する署名付きURL生成用ポリシー"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowS3GetObject"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.example.arn,
          "${aws_s3_bucket.example.arn}/*"
        ]
      }
    ]
  })

  tags = {
    Name        = "${var.bucket_name}-presigned-url-generator"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# ------------------------------------------------------------------------------
# IAMユーザー: ローカル開発用
# ------------------------------------------------------------------------------
resource "aws_iam_user" "s3_presigned_url_user" {
  count = var.create_iam_user ? 1 : 0
  name  = "${var.bucket_name}-presigned-url-user"

  tags = {
    Name        = "${var.bucket_name}-presigned-url-user"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# ポリシーをユーザーにアタッチ
resource "aws_iam_user_policy_attachment" "s3_presigned_url_user_policy" {
  count      = var.create_iam_user ? 1 : 0
  user       = aws_iam_user.s3_presigned_url_user[0].name
  policy_arn = aws_iam_policy.s3_presigned_url_generator.arn
}

# アクセスキーの作成
resource "aws_iam_access_key" "s3_presigned_url_user_key" {
  count = var.create_iam_user ? 1 : 0
  user  = aws_iam_user.s3_presigned_url_user[0].name
}

# ------------------------------------------------------------------------------
# IAMロール: Lambda/EC2用
# ------------------------------------------------------------------------------
resource "aws_iam_role" "s3_presigned_url_role" {
  count = var.create_iam_role ? 1 : 0
  name  = "${var.bucket_name}-presigned-url-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = var.iam_role_service # "lambda.amazonaws.com" or "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "${var.bucket_name}-presigned-url-role"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# ポリシーをロールにアタッチ
resource "aws_iam_role_policy_attachment" "s3_presigned_url_role_policy" {
  count      = var.create_iam_role ? 1 : 0
  role       = aws_iam_role.s3_presigned_url_role[0].name
  policy_arn = aws_iam_policy.s3_presigned_url_generator.arn
}
