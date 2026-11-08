## このサンプルでできること

この Lambda 関数をデプロイすると、以下のことが可能になります：

### 基本機能

- **HTTP 200 レスポンスの返却**: "Hello from Terraform Lambda!"というメッセージを含む JSON レスポンスを返します
- **CloudWatch ログへの出力**: 関数が実行されるたびに"Function started"というログが CloudWatch Logs に記録されます

### 主なユースケース

#### 1. 学習・検証用途

- **Terraform によるインフラコード管理の学習**: AWS Lambda 関数をコードで定義・管理する基礎を学べます
- **Lambda 関数の動作確認**: 最小構成で Lambda 関数がどのように動作するかを理解できます
- **デプロイプロセスの理解**: Terraform を使ったデプロイフローを体験できます

#### 2. 実用的な拡張例

このサンプルをベースに、以下のような実用的な機能に拡張できます：

**API バックエンド**

- API Gateway と連携させて、REST API のバックエンドとして利用
- ユーザー情報の取得、データの作成・更新などの処理を実装

**データ処理パイプライン**

- S3 イベントトリガーでファイルアップロード時に自動実行
- 画像のリサイズ、ログファイルの解析、データの変換などを実行

**スケジュール実行**

- EventBridge と連携して定期的にバッチ処理を実行
- 日次レポートの生成、データベースのクリーンアップなど

**通知・アラート**

- CloudWatch Alarm のトリガーで実行
- Slack への通知、メール送信、SNS へのメッセージ配信

**マイクロサービス連携**

- 他の AWS サービスとの統合ポイントとして利用
- DynamoDB、RDS、SQS、SNS などとの連携処理

#### 3. 開発ワークフローでの活用

- **CI/CD パイプラインのテスト**: GitHubActions や CodePipeline との統合テスト
- **環境構築のテンプレート**: 開発・ステージング・本番環境の構築ベース
- **IaC (Infrastructure as Code) のベストプラクティス**: チーム開発での共通基盤

## ディレクトリ構成

```text
.
├── main.tf
└── src
    └── index.py

```

## 1. Python コード (src/index.py)

```python
import json

def lambda_handler(event, context):
    print("Function started")
    return {
        'statusCode': 200,
        'body': json.dumps('Hello from Terraform Lambda!')
    }

```

## 2. Terraform 構成 (main.tf)

```hcl
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-1" # 東京リージョン
}

# ---------------------------------------------
# 1. IAM Role & Policy
#    Lambda実行用の最小限の権限 (ログ出力のみ)
# ---------------------------------------------

resource "aws_iam_role" "lambda_exec" {
  name = "minimal_lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# ---------------------------------------------
# 2. Archive File
#    PythonコードをZIP化
# ---------------------------------------------

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/lambda_function.zip"
}

# ---------------------------------------------
# 3. Lambda Function
# ---------------------------------------------

resource "aws_lambda_function" "minimal_lambda" {
  filename      = data.archive_file.lambda_zip.output_path
  function_name = "minimal-terraform-python-lambda"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "index.lambda_handler" # ファイル名.関数名
  runtime       = "python3.11"

  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic_execution,
    data.archive_file.lambda_zip
  ]
}

# ---------------------------------------------
# Output
# ---------------------------------------------

output "lambda_function_arn" {
  value = aws_lambda_function.minimal_lambda.arn
}

```

## .gitignore (推奨)

```gitignore
.terraform/
.terraform.lock.hcl
*.tfstate
*.tfstate.backup
*.zip

```
