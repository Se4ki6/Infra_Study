// S3バケットのウェブサイトエンドポイント
// 静的ウェブサイトホスティングを有効にした場合、このURLでアクセス可能
output "website_endpoint" {
  description = "S3バケットのウェブサイトエンドポイントURL"
  value       = var.enable_website_hosting ? "http://${aws_s3_bucket_website_configuration.main[0].website_endpoint}" : "ウェブサイトホスティングは無効です"
}

// S3バケットのドメイン名
output "bucket_domain_name" {
  description = "S3バケットのドメイン名"
  value       = aws_s3_bucket.example.bucket_domain_name
}

// S3バケット名
output "bucket_name" {
  description = "S3バケット名"
  value       = aws_s3_bucket.example.id
}

// S3バケットのARN
output "bucket_arn" {
  description = "S3バケットのARN"
  value       = aws_s3_bucket.example.arn
}

// ==============================================================================
// IAMユーザー・ロール関連の出力
// ==============================================================================

// IAMユーザーの情報を出力
output "iam_user_name" {
  description = "IAMユーザー名"
  value       = var.create_iam_user ? aws_iam_user.s3_presigned_url_user[0].name : null
}

output "iam_user_arn" {
  description = "IAMユーザーARN"
  value       = var.create_iam_user ? aws_iam_user.s3_presigned_url_user[0].arn : null
}

output "iam_access_key_id" {
  description = "IAMアクセスキーID"
  value       = var.create_iam_user ? aws_iam_access_key.s3_presigned_url_user_key[0].id : null
  sensitive   = true
}

output "iam_secret_access_key" {
  description = "IAMシークレットアクセスキー"
  value       = var.create_iam_user ? aws_iam_access_key.s3_presigned_url_user_key[0].secret : null
  sensitive   = true
}

// IAMロールの情報を出力
output "iam_role_name" {
  description = "IAMロール名"
  value       = var.create_iam_role ? aws_iam_role.s3_presigned_url_role[0].name : null
}

output "iam_role_arn" {
  description = "IAMロールARN"
  value       = var.create_iam_role ? aws_iam_role.s3_presigned_url_role[0].arn : null
}

// ==============================================================================
// 画像ファイル関連の出力 (ステップ2)
// ==============================================================================

// 画像用のベースパス
output "images_base_path" {
  description = "S3内の画像ファイルのベースパス"
  value       = var.images_prefix
}

// アップロードされた画像ファイルのリスト
output "uploaded_images" {
  description = "アップロードされた画像ファイルのキー一覧"
  value       = var.enable_images_upload ? [for obj in aws_s3_object.upload_images : obj.key] : []
}

// 画像アクセス用のベースURL
output "images_base_url" {
  description = "S3内の画像ファイルのベースURL（署名付きURLのベース）"
  value       = "s3://${aws_s3_bucket.example.id}/${var.images_prefix}/"
}
