# 📚 共通ドキュメント

このフォルダには、AWS サービスに関する共通ドキュメントが格納されています。

## 📁 フォルダ構成

```
docs/
├── about_apigateway.md              # API Gateway 概要
├── Lambda/
│   ├── about_lambda.md              # Lambda 開発ガイド
│   ├── lambda_example.md            # Terraform での Lambda 構成例
│   └── memo                         # メモ
├── cloudfront/
│   ├── about_CloudFront_Functions.md    # CloudFront Functions 解説
│   ├── difference_between_CloudFront_S3.md  # CloudFront vs S3 比較
│   ├── flowchart.md                 # フローチャート
│   └── sequence_diagram.md          # シーケンス図
├── amplify/
│   └── about_amplify.md             # AWS Amplify 概要
├── AWS_API_Gateway/
│   └── about_aws_api_gateway.md     # API Gateway 詳細解説
├── Lambda_ApiGW_QR_Generator/
│   ├── design.md                    # 設計ドキュメント
│   ├── review.md                    # レビュー
│   └── todo.md                      # TODO リスト
└── S3_APIGW_Lambda_SimpleApp/
    ├── api_gateway.tf.description.md
    ├── lambda.tf.description.md
    ├── main.tf.description.md
    ├── outputs.tf.description.md
    ├── s3.tf.description.md
    └── variable.tf.description.md
```

## 📖 ドキュメント一覧

### Lambda

| ファイル                                      | 内容                                                   |
| --------------------------------------------- | ------------------------------------------------------ |
| [about_lambda.md](Lambda/about_lambda.md)     | Lambda の概要、ランタイム、IaC定義、ベストプラクティス |
| [lambda_example.md](Lambda/lambda_example.md) | Terraform による Lambda 関数のデプロイ例               |

### CloudFront

| ファイル                                                                              | 内容                                      |
| ------------------------------------------------------------------------------------- | ----------------------------------------- |
| [about_CloudFront_Functions.md](cloudfront/about_CloudFront_Functions.md)             | CloudFront Functions の概要とユースケース |
| [difference_between_CloudFront_S3.md](cloudfront/difference_between_CloudFront_S3.md) | CloudFront と S3 の違い                   |

### API Gateway

| ファイル                                                             | 内容                 |
| -------------------------------------------------------------------- | -------------------- |
| [about_apigateway.md](about_apigateway.md)                           | API Gateway 概要     |
| [about_aws_api_gateway.md](AWS_API_Gateway/about_aws_api_gateway.md) | API Gateway 詳細解説 |

### Amplify

| ファイル                                     | 内容             |
| -------------------------------------------- | ---------------- |
| [about_amplify.md](amplify/about_amplify.md) | AWS Amplify 概要 |

## 🔗 関連プロジェクト

- [Lambda](../Lambda/) - Lambda 基本構成
- [CloudFront_Functions](../CloudFront_Functions/) - CloudFront Functions 実装
- [Lambda_ApiGW_QR_Generator](../Lambda_ApiGW_QR_Generator/) - QRコード生成API
- [S3_APIGW_Lambda_SimpleApp](../S3_APIGW_Lambda_SimpleApp/) - シンプルなサーバレスアプリ
