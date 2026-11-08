# Lambda + API Gateway QRコード生成

API Gateway と Lambda を使用した QR コード生成 API です。

## 📚 概要

REST API エンドポイントにリクエストを送信すると、Lambda 関数が QR コードを生成して返します。

## 🏗️ アーキテクチャ

```
┌──────────┐      HTTPS      ┌─────────────┐               ┌────────────┐
│ クライアント │ ───────────> │ API Gateway │ ────────────> │  Lambda    │
└──────────┘                  └─────────────┘               │ (QR生成)   │
                                                            └────────────┘
                                    │
                                    ▼
                              ┌────────────┐
                              │    S3      │
                              │ (QR保存)   │
                              └────────────┘
```

## 📁 ファイル構成

```
Lambda_ApiGW_QR_Generator/
├── Lambda_ApiGw/            # API Gateway + Lambda 構成
│   ├── api_gateway.tf       # API Gateway 定義
│   ├── lambda.tf            # Lambda 定義
│   ├── main.tf              # プロバイダー設定
│   ├── outputs.tf           # 出力定義
│   ├── variable.tf          # 変数定義
│   ├── dev.tfvars           # 開発環境変数
│   ├── prod.tfvars          # 本番環境変数
│   ├── lambda_code/         # Lambda ソースコード
│   └── script/              # ユーティリティスクリプト
└── S3/                      # S3 バケット構成
    ├── s3.tf                # S3 バケット定義
    ├── main.tf              # プロバイダー設定
    ├── outputs.tf           # 出力定義
    ├── dev.tfvars           # 開発環境変数
    └── prod.tfvars          # 本番環境変数
```

## 🚀 使い方

### 1. S3 バケットのデプロイ

```powershell
cd S3

# 初期化
terraform init

# 開発環境へデプロイ
terraform apply -var-file="dev.tfvars"

# 本番環境へデプロイ
terraform apply -var-file="prod.tfvars"
```

### 2. API Gateway + Lambda のデプロイ

```powershell
cd Lambda_ApiGw

# 初期化
terraform init

# 開発環境へデプロイ
terraform apply -var-file="dev.tfvars"

# 本番環境へデプロイ
terraform apply -var-file="prod.tfvars"
```

### 3. API エンドポイント確認

```powershell
terraform output api_endpoint
```

## 🧪 動作確認

```bash
# QRコード生成リクエスト
curl -X POST https://<api-id>.execute-api.<region>.amazonaws.com/prod/qr \
  -H "Content-Type: application/json" \
  -d '{"text": "Hello World"}'
```

## 🔧 環境変数

| 変数          | 説明              | デフォルト     |
| ------------- | ----------------- | -------------- |
| `environment` | 環境名 (dev/prod) | dev            |
| `aws_region`  | AWS リージョン    | ap-northeast-1 |

## 📖 関連ドキュメント

- [設計ドキュメント](../docs/Lambda_ApiGW_QR_Generator/design.md)
- [Lambda 開発ガイド](../docs/Lambda/about_lambda.md)
- [API Gateway 解説](../docs/about_apigateway.md)

## 🔗 関連プロジェクト

- [Lambda](../Lambda/) - Lambda 基本構成
- [S3](../S3/) - S3 基本構成
