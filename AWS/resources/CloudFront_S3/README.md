# CloudFront + S3 静的コンテンツ配信（WAF付き）

CloudFront と S3 を組み合わせた静的コンテンツ配信システムです。WAF（Web Application Firewall）による保護機能付き。

## 📚 概要

- **CDN**: CloudFront によるグローバル配信
- **オリジン**: S3 バケット
- **セキュリティ**: WAF によるアクセス制御
- **HTTPS**: CloudFront によるSSL/TLS終端

## 🏗️ アーキテクチャ

```
┌──────────┐      HTTPS       ┌────────────┐     ┌────────────┐
│ ユーザー  │ ───────────────> │    WAF     │────>│ CloudFront │
└──────────┘                   └────────────┘     └────────────┘
                                                        │
                                                        ▼
                                                  ┌────────────┐
                                                  │    S3      │
                                                  │ (Origin)   │
                                                  └────────────┘
```

## 📁 ファイル構成

```
CloudFront_S3/
├── cloudfront.tf        # CloudFront ディストリビューション定義
├── s3.tf                # S3 バケット定義
├── waf.tf               # WAF 定義
├── providers.tf         # プロバイダー設定
├── variables.tf         # 変数定義
├── outputs.tf           # 出力定義
├── terraform.tfvars     # 変数値
├── _terraform.tfvars    # テンプレート
├── docs/                # ドキュメント
│   └── cloudfront-beginner-guide.md
├── state/               # Terraform 状態ファイル
│   └── terraform.tfstate
└── upload_file/         # S3 にアップロードするファイル
    ├── example.txt
    ├── docs/
    ├── images/
    └── website/
```

## 🚀 使い方

```powershell
# 初期化
terraform init

# 実行計画確認
terraform plan

# デプロイ
terraform apply

# CloudFront URL 確認
terraform output cloudfront_domain_name

# 削除
terraform destroy
```

## 🔧 設定項目

| 変数          | 説明              |
| ------------- | ----------------- |
| `bucket_name` | S3 バケット名     |
| `aws_region`  | AWS リージョン    |
| `environment` | 環境名 (dev/prod) |

## 🛡️ WAF ルール

このプロジェクトには以下の WAF ルールが含まれています：

- レートベース制限
- AWS マネージドルール
- カスタムルール（必要に応じて）

## 📖 関連ドキュメント

- [CloudFront 初心者ガイド](docs/cloudfront-beginner-guide.md)
- [CloudFront Functions 解説](../docs/cloudfront/about_CloudFront_Functions.md)
- [CloudFront vs S3 比較](../docs/cloudfront/difference_between_CloudFront_S3.md)

## 🔗 関連プロジェクト

- [CloudFront_test](../CloudFront_test/) - CloudFront 最小構成（学習用）
- [CloudFront_Functions](../CloudFront_Functions/) - CloudFront Functions
- [S3](../S3/) - S3 基本構成
