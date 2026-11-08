# AWS Infrastructure as Code - Terraform プロジェクト集

このリポジトリは、TerraformによるAWSインフラストラクチャの構築・管理を学習・実践するためのプロジェクト集です。

## 📚 プロジェクト概要

| フォルダ                                                | 説明                                                            |
| ------------------------------------------------------- | --------------------------------------------------------------- |
| [S3](S3/)                                               | S3バケットの作成、静的ウェブサイトホスティング、署名付きURL生成 |
| [CloudFront_S3](CloudFront_S3/)                         | CloudFront + S3 による静的コンテンツ配信（WAF付き）             |
| [CloudFront_test](CloudFront_test/)                     | CloudFront + S3 最小構成（学習用）                              |
| [CloudFront_Functions](CloudFront_Functions/)           | CloudFront Functions によるURL書き換え                          |
| [Lambda](Lambda/)                                       | AWS Lambda の基本構成                                           |
| [Lambda_ApiGW_QR_Generator](Lambda_ApiGW_QR_Generator/) | API Gateway + Lambda による QRコード生成                        |
| [S3_APIGW_Lambda_SimpleApp](S3_APIGW_Lambda_SimpleApp/) | S3 + API Gateway + Lambda のシンプルなアプリケーション          |
| [S3_STS_AzureFunction](S3_STS_AzureFunction/)           | S3 へのアクセスを AWS STS 経由のみに限定（Azure Functions から） |
| [docs](docs/)                                           | 共通ドキュメント（Lambda、CloudFront Functions の解説）         |

## 🏗️ アーキテクチャ

```
┌─────────────────────────────────────────────────────────────────┐
│                         AWS Cloud                                │
│  ┌──────────┐     ┌─────────────┐     ┌────────────┐           │
│  │ CloudFront│────>│   S3       │     │  Lambda    │           │
│  │  (CDN)   │     │ (静的配信)  │     │ (サーバレス)│           │
│  └──────────┘     └─────────────┘     └────────────┘           │
│       │                                      │                   │
│       │           ┌─────────────┐           │                   │
│       └──────────>│ CloudFront  │           │                   │
│                   │ Functions   │           │                   │
│                   └─────────────┘           │                   │
│                                             │                   │
│                   ┌─────────────┐           │                   │
│                   │ API Gateway │<──────────┘                   │
│                   └─────────────┘                               │
└─────────────────────────────────────────────────────────────────┘
```

## 🚀 クイックスタート

### 前提条件

- [Terraform](https://www.terraform.io/) >= 1.9.0
- [AWS CLI](https://aws.amazon.com/cli/) 設定済み
- Python 3.x（一部スクリプト用）

### 基本的な使い方

```powershell
# 各プロジェクトフォルダに移動
cd <project-folder>

# Terraform初期化
terraform init

# 実行計画確認
terraform plan

# リソース作成
terraform apply

# リソース削除
terraform destroy
```

## 📖 学習パス

1. **初級**: [S3](S3/) - S3バケットの基本操作
2. **中級**: [CloudFront_test](CloudFront_test/) - CloudFront + S3 最小構成
3. **中級**: [CloudFront_Functions](CloudFront_Functions/) - エッジでのURL処理
4. **上級**: [CloudFront_S3](CloudFront_S3/) - WAF付き本格構成
5. **応用**: [Lambda_ApiGW_QR_Generator](Lambda_ApiGW_QR_Generator/) - サーバレスAPI

## 📁 ドキュメント

- [Lambda 開発ガイド](docs/Lambda/about_lambda.md)
- [CloudFront Functions 解説](docs/cloudfront/about_CloudFront_Functions.md)
- [CloudFront 初心者ガイド](CloudFront_S3/docs/cloudfront-beginner-guide.md)

## ⚠️ セキュリティ注意事項

- `terraform.tfvars` には機密情報を含む可能性があります - Git にコミットしないでください
- `.terraform/` フォルダは `.gitignore` に追加してください
- IAM 認証情報は環境変数または AWS CLI プロファイルを使用してください

## 📝 ライセンス

このプロジェクトは学習・検証目的で作成されています。
