# Infra Study

AWS と Azure の学習・実装プロジェクトをまとめたモノレポです。既存のクロスクラウド実装も `Cross-Cloud/` に置いています。

| 領域 | 内容 |
| --- | --- |
| [AWS](AWS/README.md) | AWS のサービス別演習、複合プロジェクト、学習資料 |
| [Azure](Azure/README.md) | Azure のリソース学習、実装プロジェクト、Bicep/Terraform ガイド |
| [Cross-Cloud](Cross-Cloud/) | AWS と Azure を接続する実装。 [OIDC 版](Cross-Cloud/S3_OIDC_AzureFunction/README.md)、[STS ハンズオン](Cross-Cloud/S3_STS_AzureFunction/README.md) |
| [共通ドキュメント](docs/) | クラウド横断の IaC、監視、ネットワークなどのノート |

## 使い方

各プロジェクトの README に前提ツール、実行ディレクトリ、検証手順を記載しています。Terraform や Bicep のデプロイは、各手順を確認してから実行してください。Terraform state、実値入り変数ファイル、ローカル認証設定は Git に追加しないでください。

## 主な入口

- AWS の基本演習: [S3](AWS/resources/S3/)、[CloudFront + S3](AWS/resources/CloudFront_S3/)、[Lambda](AWS/resources/Lambda/)
- AWS の複合プロジェクト: [QR コード生成 API](AWS/projects/Lambda_ApiGW_QR_Generator/)、[AWS Blocks](AWS/projects/aws-blocks/)
- Azure の学習リソース: [Blob](Azure/resources/blob/)、[Functions](Azure/resources/functions/)、[VM と Bicep](Azure/resources/vm/)
- Azure のプロジェクト: [Bastion Web TODO](Azure/projects/bastion-web-todo/)、[OpenTelemetry 注文 API](Azure/projects/otel-order-api/)
