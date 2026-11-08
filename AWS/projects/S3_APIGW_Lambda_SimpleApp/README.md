# S3 + API Gateway + Lambda シンプルアプリケーション

S3 で静的フロントエンドをホスティングし、API Gateway + Lambda でバックエンド API を提供するシンプルなサーバレスアプリケーションです。

## 📚 概要

- **フロントエンド**: S3 静的ウェブサイトホスティング
- **バックエンド**: API Gateway + Lambda
- **構成**: フルサーバレスアーキテクチャ

## 🏗️ アーキテクチャ

```
┌──────────┐     静的コンテンツ    ┌────────────┐
│ ブラウザ  │ ─────────────────> │    S3      │
│          │                     │ (HTML/JS)  │
└──────────┘                     └────────────┘
     │
     │  API リクエスト
     ▼
┌─────────────┐               ┌────────────┐
│ API Gateway │ ────────────> │  Lambda    │
└─────────────┘               │ (Backend)  │
                              └────────────┘
```

## 📁 ファイル構成

```
S3_APIGW_Lambda_SimpleApp/
├── main.tf              # プロバイダー設定
├── s3.tf                # S3 バケット定義
├── api_gateway.tf       # API Gateway 定義
├── lambda.tf            # Lambda 定義
├── variable.tf          # 変数定義
├── outputs.tf           # 出力定義
└── src/                 # Lambda ソースコード
```

## 🚀 使い方

実値入りの `dev.tfvars` / `prod.tfvars` は移行対象から除外しています。`Variable.tf` を確認し、必要なローカル変数ファイルを作成してください（ルート `.gitignore` で Git 対象外です）。以下のコマンドはモノレポのルートから実行します。

```powershell
cd AWS/projects/S3_APIGW_Lambda_SimpleApp

# 初期化
terraform init

# 実行計画確認
terraform plan

# デプロイ（デフォルト）
terraform apply

# 開発環境へデプロイ
# dev.tfvars / prod.tfvars は実値を含む可能性があるため移行対象外。必要な変数を確認してローカルで作成してください。
terraform apply -var-file="dev.tfvars"

# 本番環境へデプロイ
terraform apply -var-file="prod.tfvars"

# URL確認
terraform output
```

## 🔧 設定項目

| 変数          | 説明              | デフォルト     |
| ------------- | ----------------- | -------------- |
| `environment` | 環境名 (dev/prod) | dev            |
| `aws_region`  | AWS リージョン    | ap-northeast-1 |
| `bucket_name` | S3 バケット名     | -              |

## 📖 関連ドキュメント

詳細な設計ドキュメントは以下を参照してください：

- [main.tf 解説](../../docs/S3_APIGW_Lambda_SimpleApp/main.tf.description.md)
- [s3.tf 解説](../../docs/S3_APIGW_Lambda_SimpleApp/s3.tf.description.md)
- [api_gateway.tf 解説](../../docs/S3_APIGW_Lambda_SimpleApp/api_gateway.tf.description.md)
- [lambda.tf 解説](../../docs/S3_APIGW_Lambda_SimpleApp/lambda.tf.description.md)
- [outputs.tf 解説](../../docs/S3_APIGW_Lambda_SimpleApp/outputs.tf.description.md)
- [variable.tf 解説](../../docs/S3_APIGW_Lambda_SimpleApp/variable.tf.description.md)

## 🔗 関連プロジェクト

- [S3](../../resources/S3/) - S3 基本構成
- [Lambda](../../resources/Lambda/) - Lambda 基本構成
- [Lambda_ApiGW_QR_Generator](../Lambda_ApiGW_QR_Generator/) - QRコード生成API
