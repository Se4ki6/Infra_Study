# CloudFront + S3 最小構成

CloudFrontを使ってS3の静的コンテンツを配信する**最小限の構成**です。<br>
初心者の学習・検証用に、必要最低限の機能のみを実装しています。

## 📚 何ができるか

- S3バケットに静的コンテンツ（HTML）を配置
- CloudFront経由でコンテンツを高速配信
- S3への直接アクセスをブロック（OAC使用）
- HTTPSへの自動リダイレクト

## 🏗️ 構成

```
┌──────────┐      HTTPS      ┌─────────────┐      OAC       ┌────────┐
│ ユーザー │ ───────────────> │ CloudFront  │ ─────────────> │   S3   │
└──────────┘                  └─────────────┘                └────────┘
                                   (CDN)                    (オリジン)
```

### 主要なリソース

- **S3バケット**: 静的コンテンツの保存先
- **CloudFront Distribution**: CDN（コンテンツ配信ネットワーク）
- **OAC (Origin Access Control)**: CloudFrontからS3への認証
- **S3バケットポリシー**: CloudFrontのみアクセス許可

## 🚀 使い方

### 1. バケット名を設定

[terraform.tfvars](terraform.tfvars) を編集して、グローバルで一意なバケット名を設定してください。

```hcl
bucket_name = "my-cloudfront-minimal-test-bucket-20251213"
```

### 2. Terraformで環境を構築

```powershell
# 初期化
terraform init

# 実行計画を確認
terraform plan

# リソースを作成
terraform apply
```

### 3. CloudFrontのURLにアクセス

実行後に表示される `cloudfront_url` にアクセスしてください。

```
Outputs:

cloudfront_url = "https://d1234567890abc.cloudfront.net"
```

## 📁 ファイル構成

```
CloudFront/
├── providers.tf          # Terraformとプロバイダーの設定
├── variables.tf          # 変数定義
├── terraform.tfvars      # 変数の値（バケット名）
├── main.tf               # メインのリソース定義
├── outputs.tf            # 出力値の定義
├── README.md             # このファイル
└── upload_file/          # S3にアップロードするファイル
    ├── index.html        # トップページ
    └── error.html        # エラーページ
```

## 🔍 各リソースの役割

### S3バケット (`aws_s3_bucket`)
- 静的コンテンツ（HTML、画像など）を保存
- CloudFrontのオリジン（配信元）として機能

### S3パブリックアクセスブロック (`aws_s3_bucket_public_access_block`)
- S3への直接アクセスを完全にブロック
- CloudFront経由のみアクセス可能にする

### CloudFront OAC (`aws_cloudfront_origin_access_control`)
- CloudFrontがS3にアクセスするための認証情報
- OAI（旧方式）の後継で、より安全

### CloudFront Distribution (`aws_cloudfront_distribution`)
- CDNのメイン設定
- キャッシュ、HTTPS、オリジン設定などを管理

### S3バケットポリシー (`aws_s3_bucket_policy`)
- CloudFrontのみにS3へのアクセスを許可
- 他のアクセスは全て拒否

## 🧪 動作確認

1. **CloudFront経由でアクセス**
   ```
   https://d1234567890abc.cloudfront.net/
   → ✅ index.htmlが表示される
   ```

2. **存在しないページへのアクセス**
   ```
   https://d1234567890abc.cloudfront.net/notfound.html
   → ✅ error.htmlが表示される
   ```

3. **S3への直接アクセス（失敗することを確認）**
   ```
   https://<bucket-name>.s3.amazonaws.com/index.html
   → ❌ Access Denied（これが正常）
   ```

## 🧹 削除

検証が終わったら、リソースを削除してください。

```powershell
terraform destroy
```

## 💡 学習ポイント

### 1. Origin Access Control (OAC)
CloudFrontからS3へのアクセスを制御する仕組みです。<br>
- OACを使用すると、S3バケットを完全にプライベートに保ちながら、CloudFront経由のみアクセスを許可できます
- 旧方式のOAI（Origin Access Identity）よりも推奨されます

### 2. キャッシュ動作
CloudFrontは取得したコンテンツをエッジロケーション（世界中のサーバー）にキャッシュします。
- `min_ttl`: 最小キャッシュ時間（0秒）
- `default_ttl`: デフォルトキャッシュ時間（3600秒 = 1時間）
- `max_ttl`: 最大キャッシュ時間（86400秒 = 24時間）

### 3. HTTPS リダイレクト
`viewer_protocol_policy = "redirect-to-https"` により、HTTPアクセスは自動的にHTTPSにリダイレクトされます。

## 📖 参考資料

- [AWS CloudFront公式ドキュメント](https://docs.aws.amazon.com/cloudfront/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

## ⚙️ カスタマイズのヒント

このミニマル構成から、以下のような機能を追加できます：

- **カスタムドメイン**: Route53とACM証明書を使用
- **WAF**: IP制限やレート制限を追加
- **ログ記録**: アクセスログをS3に保存
- **カスタムエラーページ**: 403/404などのカスタマイズ
- **複数オリジン**: 動的コンテンツ用のALBを追加

まずはこの最小構成で動作を理解してから、徐々に機能を追加していくことをお勧めします！
