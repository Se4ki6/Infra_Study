// ==============================================================================
// module: s3_secure_bucket
// ==============================================================================
// バケット本体と、単体で完結する安全側の設定だけを持つ。
// アクセス制御（誰がSTS経由で読めるか）は IAM ロール／ポリシー側で完結させ、
// バケットポリシーそのものは持たない。パブリックアクセスは Public Access Block で
// アカウント／バケット双方向から完全に塞ぐ。
// ==============================================================================

resource "aws_s3_bucket" "this" {
  bucket = var.bucket_name

  tags = merge(var.tags, {
    Name = var.bucket_name
  })
}

// バージョニング（誤削除・上書きからの保護）
resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = "Enabled"
  }
}

// サーバーサイド暗号化（SSE-S3）
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

// パブリックアクセスは全面ブロック。
// 静的ホスティングも署名付きURLも使わず、STS（AssumeRoleWithWebIdentity）経由のみに限定する。
resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

// ACL を無効化し、所有権をバケット所有者に統一する
resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

// ------------------------------------------------------------------------------
// 動作確認用のサンプルファイル（任意）
// ------------------------------------------------------------------------------
locals {
  sample_files = var.sample_files_folder == "" ? toset([]) : try(fileset(var.sample_files_folder, "**"), toset([]))
}

resource "aws_s3_object" "samples" {
  for_each = local.sample_files

  bucket = aws_s3_bucket.this.id
  key    = var.key_prefix == "" ? each.value : "${var.key_prefix}/${each.value}"
  source = "${var.sample_files_folder}/${each.value}"
  etag   = filemd5("${var.sample_files_folder}/${each.value}")

  content_type = lookup({
    "txt"  = "text/plain",
    "json" = "application/json",
    "csv"  = "text/csv",
    "md"   = "text/markdown",
    "pdf"  = "application/pdf",
    "png"  = "image/png",
    "jpg"  = "image/jpeg",
  }, lower(element(split(".", each.value), length(split(".", each.value)) - 1)), "application/octet-stream")

  tags = var.tags
}
