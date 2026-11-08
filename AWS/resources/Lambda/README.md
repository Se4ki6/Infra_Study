# AWS Lambda 基本構成

Terraform による AWS Lambda 関数の基本的なデプロイ構成です。

## 📚 概要

AWS Lambda はサーバーレスコンピューティングサービスで、コードを実行するためのサーバー管理が不要です。

## 🏗️ 構成

```
┌──────────────┐
│   Lambda     │
│  Function    │
│  (Python)    │
└──────────────┘
```

## 📁 ファイル構成

```
Lambda/
├── main.tf              # Lambda リソース定義
├── terraform.tfstate    # Terraform 状態ファイル
└── src/
    └── index.py         # Lambda ハンドラー
```

## 🚀 使い方

```powershell
# 初期化
terraform init

# 実行計画確認
terraform plan

# デプロイ
terraform apply

# 削除
terraform destroy
```

## 📝 Lambda ハンドラー

`src/index.py` に Lambda 関数のエントリーポイントを定義します。

```python
def handler(event, context):
    return {
        'statusCode': 200,
        'body': 'Hello from Lambda!'
    }
```

## 📖 関連ドキュメント

- [Lambda 開発ガイド](../docs/Lambda/about_lambda.md)
- [Lambda 構成例](../docs/Lambda/lambda_example.md)

## 🔗 次のステップ

- [Lambda_ApiGW_QR_Generator](../Lambda_ApiGW_QR_Generator/) - API Gateway との連携
- [S3_APIGW_Lambda_SimpleApp](../S3_APIGW_Lambda_SimpleApp/) - S3 + API Gateway + Lambda
