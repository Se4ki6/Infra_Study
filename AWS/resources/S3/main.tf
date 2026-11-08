terraform {
  // terraformのバージョンを指定
  required_version = ">= 1.9.0"

  // awsプロバイダーのバージョンを指定
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

// awsプロバイダーの設定
provider "aws" {
  // regionを指定
  region = "ap-southeast-2"
  // SSO プロファイルを使用
  profile = "AdministratorAccess-339126664118"
}

// S3バケットの作成
// aws_s3_bucket: S3バケットを作成するリソース（`resource "<リソースタイプ>" "<リソース名>"`）
resource "aws_s3_bucket" "example" {
  // バケット名を指定 (グローバルで一意である必要がある)
  bucket = var.bucket_name // variables.tf で定義されている変数から値を取得

  // バケットに付与するタグ
  // タグを使用することでリソースの管理や検索が容易になる
  tags = {
    Name        = var.bucket_name // バケットの表示名
    Environment = var.environment // 環境の種類 (dev, staging, prodなど)
    ManagedBy   = "Terraform"     // このリソースがTerraformで管理されていることを示す
  }
}

// S3バケットのバージョニング設定（変更履歴を保持するための設定）
// バージョニングを有効にすることで、オブジェクトの複数バージョンを保持できる
// 誤削除や上書きからデータを保護するために推奨される設定
resource "aws_s3_bucket_versioning" "example" {
  // 対象のS3バケットIDを指定
  bucket = aws_s3_bucket.example.id

  versioning_configuration {
    // バージョニングを有効化 ("Enabled" or "Suspended")
    status = "Enabled"
  }
}

// S3バケットの暗号化設定
// サーバーサイド暗号化により、保存されるデータを自動的に暗号化する
// セキュリティ要件を満たすために重要な設定
resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  // 対象のS3バケットIDを指定
  bucket = aws_s3_bucket.example.id

  rule {
    // デフォルトの暗号化設定を適用
    apply_server_side_encryption_by_default {
      // 暗号化アルゴリズムを指定
      // AES256: AWS S3マネージドキーによる暗号化
      // aws:kms: AWS KMSマネージドキーによる暗号化も選択可能
      sse_algorithm = "AES256"
    }
  }
}

// S3バケットのパブリックアクセスブロック設定
// バケットへの意図しない公開アクセスを防ぐためのセキュリティ設定
// セキュリティベストプラクティスとして推奨される
// 静的ウェブサイトホスティングを有効にする場合はパブリックアクセスを許可する必要がある
resource "aws_s3_bucket_public_access_block" "main" {
  // 対象のS3バケットIDを指定
  bucket = aws_s3_bucket.example.id

  // 静的ウェブサイトホスティングが有効な場合はパブリックアクセスを許可
  // それ以外の場合は完全にプライベートに設定
  block_public_acls       = !var.enable_website_hosting
  block_public_policy     = !var.enable_website_hosting
  ignore_public_acls      = !var.enable_website_hosting
  restrict_public_buckets = !var.enable_website_hosting
}

// S3バケットの静的ウェブサイトホスティング設定
// この設定によりS3バケットを静的ウェブサイトとして公開できる
resource "aws_s3_bucket_website_configuration" "main" {
  count  = var.enable_website_hosting ? 1 : 0
  bucket = aws_s3_bucket.example.id

  // インデックスドキュメント (デフォルトページ)
  index_document {
    suffix = "index.html"
  }

  // エラードキュメント (404エラー時に表示されるページ)
  error_document {
    key = "error.html"
  }
}

// S3バケットのパブリック読み取りを許可するバケットポリシー
// 静的ウェブサイトホスティングに必要
resource "aws_s3_bucket_policy" "public_read" {
  count  = var.enable_website_hosting ? 1 : 0
  bucket = aws_s3_bucket.example.id

  // aws_s3_bucket_public_access_blockの後に作成されるようにする
  depends_on = [aws_s3_bucket_public_access_block.main]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.example.arn}/*"
      }
    ]
  })
}

// ローカルのファイルをAWS S3バケットにアップロードする設定 (推奨版)
// aws_s3_object は aws_s3_bucket_object の後継リソース
// fileset関数で指定フォルダ内の全ファイルを自動検出してアップロード
resource "aws_s3_object" "upload_file" {
  // fileset関数でフォルダ内の全ファイルを取得し、for_eachで各ファイルに対してリソースを作成
  // fileset(path, pattern) - 指定パスから指定パターンに一致するファイルを取得
  // "**" は全サブディレクトリを再帰的に検索
  for_each = fileset(var.upload_folder, "**")

  // アップロード先のS3バケット名を指定
  bucket = aws_s3_bucket.example.id

  // S3内でのオブジェクトのキー (パス) を指定
  // each.value にはファイルの相対パス (例: "example.txt" や "subfolder/file.txt")
  // s3_prefix を結合してS3内のパスを構成
  key = var.s3_prefix == "" ? each.value : "${var.s3_prefix}/${each.value}"

  // ローカルのファイルパスを指定
  // upload_folder と相対パスを結合して完全なパスを構成
  source = "${var.upload_folder}/${each.value}"

  // filemd5ハッシュを計算して整合性を検証
  etag = filemd5("${var.upload_folder}/${each.value}")

  // コンテンツタイプを自動判定 (MIMEタイプ)
  // 拡張子に基づいて適切なContent-Typeを設定
  content_type = lookup({
    // テキスト系
    "html" = "text/html",
    "htm"  = "text/html",
    "css"  = "text/css",
    "txt"  = "text/plain",
    "xml"  = "text/xml",
    "csv"  = "text/csv",

    // JavaScript/TypeScript
    "js"  = "application/javascript",
    "mjs" = "application/javascript",
    "jsx" = "application/javascript",
    "ts"  = "application/typescript",
    "tsx" = "application/typescript",

    // データフォーマット
    "json" = "application/json",
    "yaml" = "application/x-yaml",
    "yml"  = "application/x-yaml",

    // 画像
    "png"  = "image/png",
    "jpg"  = "image/jpeg",
    "jpeg" = "image/jpeg",
    "gif"  = "image/gif",
    "svg"  = "image/svg+xml",
    "webp" = "image/webp",
    "ico"  = "image/x-icon",
    "bmp"  = "image/bmp",

    // フォント
    "woff"  = "font/woff",
    "woff2" = "font/woff2",
    "ttf"   = "font/ttf",
    "otf"   = "font/otf",
    "eot"   = "application/vnd.ms-fontobject",

    // 動画・音声
    "mp4"  = "video/mp4",
    "webm" = "video/webm",
    "mp3"  = "audio/mpeg",
    "wav"  = "audio/wav",
    "ogg"  = "audio/ogg",

    // ドキュメント
    "pdf" = "application/pdf",
    "zip" = "application/zip",
    "tar" = "application/x-tar",
    "gz"  = "application/gzip"
  }, lower(split(".", each.value)[length(split(".", each.value)) - 1]), "application/octet-stream")

  // キャッシュコントロール設定（CloudFront等で効果的）
  // 静的アセットは長めにキャッシュ、HTMLは短めに設定
  cache_control = lookup({
    // HTML: 5分
    "html" = "max-age=300, must-revalidate", // must-revalidate:キャッシュが古くなった（期限切れ）場合、必ず元のサーバーに確認してから使用するという指示。
    "htm"  = "max-age=300, must-revalidate",
    // CSS/JS: 1年（ハッシュ付き想定なのでimmutable）
    // immutable = ファイルが変更されないため、期限内は確認不要
    // max-age=1年 = ブラウザに「このファイルを1年間ローカルキャッシュに保持して、サーバーに確認せず使用してOK」と指示
    // → ネットワーク転送ゼロ、最高のパフォーマンス
    "css"   = "max-age=31536000, immutable",
    "js"    = "max-age=31536000, immutable",
    "png"   = "max-age=31536000, immutable", // 画像: 1年
    "jpg"   = "max-age=31536000, immutable",
    "jpeg"  = "max-age=31536000, immutable",
    "gif"   = "max-age=31536000, immutable",
    "svg"   = "max-age=31536000, immutable",
    "webp"  = "max-age=31536000, immutable",
    "woff2" = "max-age=31536000, immutable", // フォント: 1年
    "woff"  = "max-age=31536000, immutable"
  }, lower(split(".", each.value)[length(split(".", each.value)) - 1]), "max-age=86400") // デフォルト: 1日

  // 注意: aclパラメータは削除
  // バケットのパブリックアクセスブロック設定により、デフォルトでprivateになります
  // 静的ウェブサイトホスティングの場合はバケットポリシーでパブリックアクセスを許可
  // acl = "private"
}

// ==============================================================================
// 画像ファイル専用のアップロード設定 (ステップ2)
// ==============================================================================

// 画像専用プレフィックス (images/) 配下に画像をアップロード
// 署名付きURLで画像を配信する際に使用
resource "aws_s3_object" "upload_images" {
  // 画像アップロードが有効で、かつ画像フォルダが存在する場合のみ実行
  for_each = var.enable_images_upload ? fileset(var.images_upload_folder, "**") : []

  bucket = aws_s3_bucket.example.id

  // images/配下に配置
  key = "${var.images_prefix}/${each.value}"

  source = "${var.images_upload_folder}/${each.value}"

  etag = filemd5("${var.images_upload_folder}/${each.value}")

  // 画像のContent-Type設定
  content_type = lookup({
    "png"  = "image/png",
    "jpg"  = "image/jpeg",
    "jpeg" = "image/jpeg",
    "gif"  = "image/gif",
    "svg"  = "image/svg+xml",
    "webp" = "image/webp",
    "ico"  = "image/x-icon",
    "bmp"  = "image/bmp",
    "tiff" = "image/tiff",
    "tif"  = "image/tiff"
  }, lower(split(".", each.value)[length(split(".", each.value)) - 1]), "application/octet-stream")

  // 画像は長期キャッシュ（1年）- CloudFrontやブラウザキャッシュで効果的
  cache_control = "max-age=31536000, immutable"

  // 注意: このリソースはプライベートとして扱われ、署名付きURLでのみアクセス可能
}
