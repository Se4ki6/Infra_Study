# S3 静的ウェブサイトホスティング設定

## 概要

S3 バケットを静的ウェブサイトとしてホスティングするための設定を追加しました。この設定により、S3 バケットをウェブサーバーとして使用し、HTML、CSS、JavaScript などの静的コンテンツを公開できます。

## 変更日

2025 年 11 月 22 日

## 変更内容

### 1. 新しい変数の追加 (`variables.tf`)

```terraform
// 静的ウェブサイトホスティングを有効にするかどうか
variable "enable_website_hosting" {
  description = "静的ウェブサイトホスティングを有効にするかどうか"
  type        = bool
  default     = false
}
```

**説明**: ウェブサイトホスティング機能の ON/OFF を切り替えるためのフラグ変数です。

---

### 2. パブリックアクセスブロック設定の変更 (`main.tf`)

#### 変更前

```terraform
block_public_acls       = true
block_public_policy     = true
ignore_public_acls      = true
restrict_public_buckets = true
```

#### 変更後

```terraform
block_public_acls       = !var.enable_website_hosting
block_public_policy     = !var.enable_website_hosting
ignore_public_acls      = !var.enable_website_hosting
restrict_public_buckets = !var.enable_website_hosting
```

**説明**: `enable_website_hosting`が`true`の場合、パブリックアクセスを許可します。静的ウェブサイトとして公開するには、バケットへのパブリックアクセスが必要です。

---

### 3. ウェブサイト設定リソースの追加 (`main.tf`)

```terraform
// S3バケットの静的ウェブサイトホスティング設定
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
```

**説明**:

- バケットをウェブサイトとして設定
- トップページとして`index.html`を指定
- エラーページとして`error.html`を指定
- `count`パラメータで条件付き作成を実現

---

### 4. バケットポリシーの追加 (`main.tf`)

```terraform
// S3バケットのパブリック読み取りを許可するバケットポリシー
resource "aws_s3_bucket_policy" "public_read" {
  count  = var.enable_website_hosting ? 1 : 0
  bucket = aws_s3_bucket.example.id

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
```

**説明**:

- すべてのユーザーがバケット内のオブジェクトを読み取れるようにする
- `s3:GetObject`アクションのみを許可（書き込みは不可）
- `depends_on`で依存関係を明示的に定義

---

### 5. 複数ファイルアップロードへの変更 (`main.tf`)

#### 変更前（単一ファイル）

```terraform
resource "aws_s3_object" "upload_file" {
  bucket = aws_s3_bucket.example.id
  key    = var.object_key
  source = var.source_path
  // ...
}
```

#### 変更後（複数ファイル対応）

```terraform
resource "aws_s3_object" "upload_file" {
  for_each = fileset(var.upload_folder, "**")

  bucket = aws_s3_bucket.example.id
  key    = var.s3_prefix == "" ? each.value : "${var.s3_prefix}/${each.value}"
  source = "${var.upload_folder}/${each.value}"
  // ...
}
```

**説明**:

- `fileset`関数でフォルダ内の全ファイルを自動検出
- `for_each`で各ファイルに対してリソースを作成
- サブディレクトリも再帰的に処理

---

### 6. Content-Type の自動判定 (`main.tf`)

#### 変更前

```terraform
content_type = "text/plain"
```

#### 変更後

```terraform
content_type = lookup({
  "html" = "text/html",
  "css"  = "text/css",
  "js"   = "application/javascript",
  "json" = "application/json",
  "png"  = "image/png",
  "jpg"  = "image/jpeg",
  "jpeg" = "image/jpeg",
  "gif"  = "image/gif",
  "svg"  = "image/svg+xml",
  "txt"  = "text/plain"
}, lower(split(".", each.value)[length(split(".", each.value)) - 1]), "application/octet-stream")
```

**説明**:

- ファイルの拡張子に基づいて適切な MIME タイプを自動設定
- ブラウザが正しくファイルを表示できるようになる
- 未知の拡張子は`application/octet-stream`として扱う

---

### 7. 出力の追加 (`outputs.tf` - 新規ファイル)

```terraform
// S3バケットのウェブサイトエンドポイント
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
```

**説明**:

- ウェブサイトの URL を確認しやすくする
- `terraform apply`後に自動表示される

---

### 8. 設定ファイルの更新 (`terraform.tfvars`)

```terraform
// 静的ウェブサイトホスティングを有効にする
// true: ウェブサイトとして公開, false: プライベートなストレージとして使用
enable_website_hosting = true
```

**説明**: ウェブサイトホスティング機能を有効化します。

---

### 9. サンプル HTML ファイルの追加

#### `upload_file/index.html`

トップページ用のサンプル HTML ファイル。グラデーション背景とモダンなデザイン。

#### `upload_file/error.html`

404 エラーページ用のサンプル HTML ファイル。ユーザーフレンドリーなエラー表示。

---

## 使用方法

### 1. ウェブサイトホスティングを有効化

`terraform.tfvars`で設定（すでに設定済み）:

```terraform
enable_website_hosting = true
```

### 2. Terraform を適用

```bash
terraform plan
terraform apply
```

### 3. ウェブサイト URL を確認

`terraform apply`の出力または以下のコマンドで確認:

```bash
terraform output website_endpoint
```

### 4. ブラウザでアクセス

出力された URL にアクセスして、ウェブサイトが表示されることを確認します。

---

## ファイル構成

```
S3/
├── main.tf                    # メインの設定ファイル (更新)
├── variables.tf               # 変数定義 (更新)
├── terraform.tfvars           # 変数の値 (更新)
├── outputs.tf                 # 出力定義 (新規)
└── upload_file/
    ├── index.html             # トップページ (新規)
    ├── error.html             # エラーページ (新規)
    ├── example.txt
    ├── example2.txt
    └── example3.txt
```

---

## セキュリティに関する注意事項

### パブリックアクセス

- `enable_website_hosting = true`の場合、バケット内のすべてのファイルが**公開**されます
- 機密情報を含むファイルはアップロードしないでください
- プライベートなストレージとして使用する場合は`enable_website_hosting = false`に設定してください

### ベストプラクティス

1. **環境ごとに分離**: 開発環境と本番環境でバケットを分ける
2. **CloudFront の使用**: より高速で安全な配信のため、CloudFront との組み合わせを推奨
3. **HTTPS の使用**: CloudFront を使用して HTTPS 化を実現
4. **アクセスログの有効化**: 不正アクセスの検知のためログを記録

---

## トラブルシューティング

### ウェブサイトにアクセスできない

1. `terraform output website_endpoint`で URL を確認
2. バケットポリシーが正しく適用されているか確認
3. パブリックアクセスブロック設定を確認

### 403 Forbidden エラー

- バケットポリシーが正しく設定されているか確認
- `aws_s3_bucket_public_access_block`の設定を確認

### ファイルが正しく表示されない

- Content-Type が正しく設定されているか確認
- ブラウザのキャッシュをクリア

---

## 関連リソース

- [AWS S3 静的ウェブサイトホスティング公式ドキュメント](https://docs.aws.amazon.com/ja_jp/AmazonS3/latest/userguide/WebsiteHosting.html)
- [Terraform AWS Provider - S3 Bucket Website Configuration](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_website_configuration)
- [S3 バケットポリシーの例](https://docs.aws.amazon.com/ja_jp/AmazonS3/latest/userguide/example-bucket-policies.html)
