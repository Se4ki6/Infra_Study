# lambda.tf - Lambda関数設定の解説

## 概要
このファイルは、API Gatewayから呼び出されるLambda関数とその関連リソース（IAMロール、実行権限、デプロイパッケージ）を定義しています。Lambda関数はサーバーレスアプリケーションのバックエンドロジックを実行します。

## リソース構成

### 1. aws_iam_role.lambda_role
```terraform
resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-lambda-role"

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
```
**目的**: Lambda関数が使用するIAMロールを作成

**Assume Role Policy（信頼ポリシー）の解説**:
- Lambda関数が実行時にこのロールを引き受ける（assume）ことを許可
- `Principal.Service = "lambda.amazonaws.com"`: Lambda serviceだけがこのロールを使用可能
- `Action = "sts:AssumeRole"`: ロールの引き受けを許可

**IAMロールの必要性**:
- Lambda関数は、AWSリソース（CloudWatch Logs、S3、DynamoDBなど）にアクセスする際に権限が必要
- このロールにポリシーをアタッチすることで、Lambda関数の権限を制御

---

### 2. aws_iam_role_policy_attachment.lambda_logs
```terraform
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
```
**目的**: CloudWatch Logsへの書き込み権限を付与

**AWSLambdaBasicExecutionRoleの内容**:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "*"
    }
  ]
}
```

**付与される権限**:
- `logs:CreateLogGroup`: ロググループの作成
- `logs:CreateLogStream`: ログストリームの作成
- `logs:PutLogEvents`: ログイベントの書き込み

**重要性**:
- Lambda関数内の`print()`や`logger.info()`の出力がCloudWatch Logsに記録される
- この権限がないと、ログが表示されずデバッグが困難になる

**追加権限の例**:
```terraform
# DynamoDBアクセスが必要な場合
resource "aws_iam_role_policy" "lambda_dynamodb" {
  name = "${var.project_name}-lambda-dynamodb"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:Query"
      ]
      Resource = aws_dynamodb_table.main.arn
    }]
  })
}
```

---

### 3. data.archive_file.lambda_zip
```terraform
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/src/lambda/app.py"
  output_path = "${path.module}/lambda_function.zip"
}
```
**目的**: Lambda関数のコードをZIPファイルにパッケージング

**設定項目**:
- `type = "zip"`: ZIPアーカイブとして作成
- `source_file`: 単一ファイルをZIP化（app.py）
- `output_path`: 生成されるZIPファイルのパス

**データソースの特徴**:
- `data`ブロックは既存リソースの参照や計算に使用
- ファイルが変更されると、自動的にZIPが再生成される
- `output_base64sha256`属性で、コンテンツのハッシュ値を取得可能

**複数ファイルをZIP化する場合**:
```terraform
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/src/lambda"  # ディレクトリ全体
  output_path = "${path.module}/lambda_function.zip"
}
```

**外部依存関係がある場合**:
```terraform
# requirements.txtがある場合は、事前にpipでインストール
resource "null_resource" "pip_install" {
  triggers = {
    requirements = filemd5("${path.module}/src/lambda/requirements.txt")
  }

  provisioner "local-exec" {
    command = "pip install -r ${path.module}/src/lambda/requirements.txt -t ${path.module}/src/lambda/packages"
  }
}

data "archive_file" "lambda_zip" {
  depends_on  = [null_resource.pip_install]
  type        = "zip"
  source_dir  = "${path.module}/src/lambda"
  output_path = "${path.module}/lambda_function.zip"
}
```

---

### 4. aws_lambda_function.backend
```terraform
resource "aws_lambda_function" "backend" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.project_name}-api"
  role             = aws_iam_role.lambda_role.arn
  handler          = "app.lambda_handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime          = "python3.9"
}
```
**目的**: Lambda関数の本体を作成

**主要な設定項目**:

#### `filename`
- デプロイするZIPファイルのパス
- 50MBまで（それ以上はS3経由でデプロイ）

#### `function_name`
- Lambda関数の名前
- AWSコンソールやCLIで参照される識別子

#### `role`
- Lambda関数が実行時に使用するIAMロールのARN
- このロールの権限で、AWSリソースにアクセス

#### `handler = "app.lambda_handler"`
- Lambda関数のエントリーポイント
- 形式: `ファイル名.関数名`
- `app.py`内の`lambda_handler`関数が呼び出される

**app.pyの構造**:
```python
def lambda_handler(event, context):
    # eventにはAPI Gatewayからのリクエスト情報が含まれる
    # contextにはLambda実行環境の情報が含まれる
    return {
        "statusCode": 200,
        "body": "Hello"
    }
```

#### `source_code_hash`
- ZIPファイルのBase64エンコードされたSHA256ハッシュ
- コードが変更された場合にのみ、Lambda関数を更新
- 効率的なデプロイ（差分更新）を実現

#### `runtime = "python3.9"`
- Lambda関数の実行環境
- サポートされるランタイム: Python 3.8/3.9/3.10/3.11/3.12, Node.js, Java, .NET, Go, Ruby など

**その他の重要な設定（オプション）**:

#### メモリとタイムアウト
```terraform
resource "aws_lambda_function" "backend" {
  # ...existing config...
  memory_size = 256   # MB (デフォルト: 128, 最大: 10240)
  timeout     = 10    # 秒 (デフォルト: 3, 最大: 900)
}
```
- `memory_size`: 割り当てメモリ（CPU性能も比例）
- `timeout`: 最大実行時間

#### 環境変数
```terraform
resource "aws_lambda_function" "backend" {
  # ...existing config...
  environment {
    variables = {
      ENVIRONMENT = "dev"
      DB_TABLE    = aws_dynamodb_table.main.name
      API_KEY     = var.api_key  # 機密情報は避けるべき
    }
  }
}
```

#### VPC設定（プライベートリソースアクセス）
```terraform
resource "aws_lambda_function" "backend" {
  # ...existing config...
  vpc_config {
    subnet_ids         = [aws_subnet.private_a.id, aws_subnet.private_b.id]
    security_group_ids = [aws_security_group.lambda.id]
  }
}
```

#### レイヤー（共通ライブラリ）
```terraform
resource "aws_lambda_function" "backend" {
  # ...existing config...
  layers = [
    aws_lambda_layer_version.common_libs.arn
  ]
}
```

---

### 5. aws_lambda_permission.apigw_lambda
```terraform
resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.backend.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}
```
**目的**: API GatewayがLambda関数を呼び出すことを許可

**⚠️ 重要**: このリソースがないと、API Gatewayは403エラーでLambdaを呼び出せません

**設定項目の詳細**:

#### `statement_id`
- 権限ステートメントの一意の識別子
- Lambda関数のリソースベースポリシーに追加される

#### `action = "lambda:InvokeFunction"`
- 許可するアクション（Lambda関数の実行）

#### `principal = "apigateway.amazonaws.com"`
- 誰に権限を与えるか（API Gatewayサービス）

#### `source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"`
- どのAPI Gatewayからの呼び出しを許可するか
- 形式: `arn:aws:execute-api:region:account-id:api-id/stage/method/path`
- `/*/*`: すべてのステージとパスを許可
- より厳密にする場合: `"${aws_api_gateway_rest_api.api.execution_arn}/dev/GET/hello"`

**セキュリティのベストプラクティス**:
```terraform
# 特定のステージとパスのみ許可
resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGatewayDev"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.backend.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/${aws_api_gateway_stage.dev.stage_name}/*"
}
```

**他のトリガーの例**:

#### S3トリガー
```terraform
resource "aws_lambda_permission" "s3_lambda" {
  statement_id  = "AllowExecutionFromS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.backend.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.uploads.arn
}
```

#### EventBridgeトリガー
```terraform
resource "aws_lambda_permission" "eventbridge_lambda" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.backend.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.schedule.arn
}
```

---

## Lambda関数のコード（app.py）の解説

```python
import json

def lambda_handler(event, context):
    # API Gatewayからのリクエスト情報を取得
    print("Received event: " + json.dumps(event, indent=2))

    # レスポンスボディの作成
    body = {
        "message": "Hello from Lambda!",
        "input": event
    }

    # プロキシ統合用レスポンス
    response = {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json",
            # CORS設定: 全ドメインからのアクセスを許可
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "OPTIONS,POST,GET",
            "Access-Control-Allow-Headers": "Content-Type"
        },
        "body": json.dumps(body)
    }

    return response
```

### eventオブジェクトの構造（API Gateway Proxy統合）
```python
{
  "resource": "/hello",
  "path": "/hello",
  "httpMethod": "GET",
  "headers": {
    "Accept": "*/*",
    "User-Agent": "Mozilla/5.0...",
    "X-Forwarded-For": "203.0.113.1",
    ...
  },
  "queryStringParameters": {"key": "value"},
  "pathParameters": None,
  "body": None,
  "isBase64Encoded": False
}
```

### レスポンス形式（Proxy統合）
Lambda関数は、以下の形式でレスポンスを返す必要があります：
```python
{
  "statusCode": 200,           # 必須
  "headers": {                 # オプション
    "Content-Type": "application/json"
  },
  "body": "..."               # 必須（文字列）
}
```

---

## アーキテクチャ全体での役割

```
[API Gateway]
   ↓ Invoke
[Lambda Function] ← このファイルで定義
   ├─ ビジネスロジック実行
   ├─ データベースアクセス（必要に応じて）
   └─ レスポンス生成
      ↓
[API Gateway]
   ↓
[S3 Frontend]
```

---

## ベストプラクティス

### 1. エラーハンドリング
```python
import json
import traceback

def lambda_handler(event, context):
    try:
        # ビジネスロジック
        result = process_request(event)

        return {
            "statusCode": 200,
            "headers": {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*"
            },
            "body": json.dumps(result)
        }
    except ValueError as e:
        # バリデーションエラー
        return {
            "statusCode": 400,
            "body": json.dumps({"error": str(e)})
        }
    except Exception as e:
        # 予期しないエラー
        print(f"Error: {traceback.format_exc()}")
        return {
            "statusCode": 500,
            "body": json.dumps({"error": "Internal Server Error"})
        }
```

### 2. ロギング
```python
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    logger.info(f"Request ID: {context.request_id}")
    logger.info(f"Event: {json.dumps(event)}")

    # 処理...

    logger.info(f"Response sent successfully")
```

### 3. コールドスタート対策
```python
import json
import boto3

# グローバルスコープで初期化（コールドスタート時のみ実行）
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('my-table')

def lambda_handler(event, context):
    # ハンドラーは毎回実行される
    response = table.get_item(Key={'id': '123'})
    return {
        "statusCode": 200,
        "body": json.dumps(response['Item'])
    }
```

### 4. デッドレターキュー（DLQ）
```terraform
resource "aws_sqs_queue" "lambda_dlq" {
  name = "${var.project_name}-lambda-dlq"
}

resource "aws_lambda_function" "backend" {
  # ...existing config...

  dead_letter_config {
    target_arn = aws_sqs_queue.lambda_dlq.arn
  }
}
```

### 5. 予約された同時実行数
```terraform
resource "aws_lambda_function" "backend" {
  # ...existing config...

  reserved_concurrent_executions = 10  # 最大同時実行数を制限
}
```

---

## 関連ファイル

- [api_gateway.tf](./api_gateway.tf.description.md): Lambda関数を呼び出すAPI Gateway
- [s3.tf](./s3.tf.description.md): APIを利用するフロントエンド
- [variables.tf](./variable.tf.description.md): プロジェクト名の変数定義
- [src/lambda/app.py](../../S3_APIGW_Lambda_SimpleApp/src/lambda/app.py): Lambda関数のコード

---

## デプロイ後の確認

### 1. Lambda関数が正しく作成されたか確認
```bash
aws lambda get-function --function-name serverless-demo-api
```

### 2. Lambda関数を直接テスト
```bash
aws lambda invoke \
  --function-name serverless-demo-api \
  --payload '{"httpMethod":"GET","path":"/hello"}' \
  response.json

cat response.json
```

### 3. CloudWatch Logsでログ確認
```bash
aws logs tail /aws/lambda/serverless-demo-api --follow
```

### 4. IAMロールの確認
```bash
aws iam get-role --role-name serverless-demo-lambda-role
```

---

## トラブルシューティング

### 問題: Lambda関数が503エラー
**原因**: API GatewayがLambdaを呼び出す権限がない
**解決策**: `aws_lambda_permission`リソースが正しく設定されているか確認

### 問題: Lambda関数内でタイムアウト
**原因**: 処理時間がタイムアウト設定を超えている
**解決策**: `timeout`を増やす、または処理を最適化

### 問題: メモリ不足エラー
**原因**: 割り当てメモリが不足
**解決策**: `memory_size`を増やす（CPU性能も向上）

### 問題: CloudWatch Logsにログが表示されない
**原因**: IAMロールにCloudWatch Logs権限がない
**解決策**: `AWSLambdaBasicExecutionRole`がアタッチされているか確認

### 問題: 外部ライブラリ（requests等）が見つからない
**原因**: ZIPにライブラリが含まれていない
**解決策**: `pip install -t`でライブラリを含めるか、Lambda Layerを使用

### 問題: VPC内のリソースにアクセスできない
**原因**: VPC設定が不足、またはNAT Gatewayがない
**解決策**: VPC設定とセキュリティグループを確認、インターネットアクセスにはNAT Gatewayが必要
