# AWS Lambda 開発ガイド

## 1. 概要

**AWS Lambda** は、サーバーのプロビジョニングや管理を行わずにコードを実行できる、イベント駆動型のサーバーレスコンピューティングサービスです。

| 特徴                 | 説明                                                               |
| -------------------- | ------------------------------------------------------------------ |
| **フルマネージド**   | インフラ管理不要。AWS がパッチ適用やスケーリングを担当。           |
| **イベント駆動**     | API Gateway, S3, DynamoDB, EventBridge などのイベントで発火。      |
| **自動スケーリング** | リクエスト数に応じて自動的に並列実行数がスケール。                 |
| **従量課金**         | リクエスト数と実行時間（ミリ秒単位）に基づく課金。待機時間は無料。 |

---

## 2. ランタイムとハンドラー

Lambda 関数にはエントリーポイントとなる「ハンドラー」が必要です。

### Python ランタイム

ファイル名: `lambda_function.py`

```python
import json
import logging

# ロガーの設定
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    """
    AWS Lambda ハンドラー関数
    :param event: イベントデータ (dict)
    :param context: ランタイム情報 (object)
    :return: API Gatewayへのレスポンス形式 (dict)
    """

    # イベント内容のログ出力
    logger.info(f"Received event: {json.dumps(event)}")

    # クエリパラメータの取得例 (API Gateway経由の場合)
    query_params = event.get('queryStringParameters', {})
    name = query_params.get('name', 'World')

    response_body = {
        "message": f"Hello, {name}!",
        "input": event
    }

    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json"
        },
        "body": json.dumps(response_body)
    }

```

### Node.js ランタイム

ファイル名: `index.js` または `index.mjs`

```javascript
exports.handler = async (event, context) => {
  console.log("EVENT: \n" + JSON.stringify(event, null, 2));

  const name = event.queryStringParameters?.name || "World";

  const response = {
    statusCode: 200,
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      message: `Hello, ${name}!`,
      awsRequestId: context.awsRequestId,
    }),
  };

  return response;
};
```

### Go ランタイム

ファイル名: `main.go`

```go
package main

import (
	"context"
	"fmt"
	"github.com/aws/aws-lambda-go/lambda"
)

type MyEvent struct {
	Name string `json:"name"`
}

type MyResponse struct {
	Message string `json:"message"`
}

func HandleRequest(ctx context.Context, name MyEvent) (MyResponse, error) {
	return MyResponse{Message: fmt.Sprintf("Hello %s!", name.Name)}, nil
}

func main() {
	lambda.Start(HandleRequest)
}

```

---

## 3. インフラストラクチャ定義 (IaC)

### AWS SAM (Serverless Application Model)

`template.yaml` の記述例。

```yaml
AWSTemplateFormatVersion: "2010-09-09"
Transform: AWS::Serverless-2016-10-31
Description: Sample SAM Template

Globals:
  Function:
    Timeout: 10
    MemorySize: 128
    Runtime: python3.9

Resources:
  HelloWorldFunction:
    Type: AWS::Serverless::Function
    Properties:
      CodeUri: hello_world/
      Handler: app.lambda_handler
      Environment:
        Variables:
          LOG_LEVEL: INFO
      Events:
        HelloWorldApi:
          Type: Api
          Properties:
            Path: /hello
            Method: get
```

### Terraform

`main.tf` の記述例。

```hcl
resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_lambda_function" "test_lambda" {
  filename      = "lambda_function_payload.zip"
  function_name = "lambda_function_name"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "index.test"

  source_code_hash = filebase64sha256("lambda_function_payload.zip")

  runtime = "nodejs18.x"

  environment {
    variables = {
      foo = "bar"
    }
  }
}

```

---

## 4. 主な制限 (Quotas)

> **Note:** 一部の制限は申請により緩和可能です。

| 項目                         | デフォルト制限          | 備考               |
| ---------------------------- | ----------------------- | ------------------ |
| **実行時間 (タイムアウト)**  | 最大 15 分              |                    |
| **メモリ割り当て**           | 128 MB ～ 10,240 MB     | 1MB 単位で設定可能 |
| **同時実行数**               | 1,000 (リージョン毎)    | 緩和申請可能       |
| **デプロイパッケージサイズ** | 50 MB (Zip 圧縮時) <br> |

<br> 250 MB (解凍時) | これを超える場合はコンテナイメージを使用 |
| **/tmp ディレクトリ容量** | 512 MB ～ 10,240 MB | 設定で変更可能 |

---

## 5. ベストプラクティス

1. **Lambda ハンドラーを分離する**

- ハンドラーロジックとビジネスロジックを分離し、単体テストを容易にする。

2. **実行環境の再利用**

- DB 接続や HTTP クライアントの初期化はハンドラー関数の**外側**で行い、コールドスタート対策と接続の再利用を行う。

```python
# 良い例: グローバルスコープで初期化
import boto3
dynamodb = boto3.resource('dynamodb')

def handler(event, context):
    # dynamodb クライアントを再利用
    table = dynamodb.Table('users')
    ...

```

3. **必要最小限の権限 (IAM)**

- `AWSLambdaBasicExecutionRole` に加え、アクセスするリソース (S3, DynamoDB) への権限のみを付与する。

4. **環境変数の利用**

- DB 接続文字列や API キーなどはコードにハードコーディングせず、環境変数または Secrets Manager を使用する。

5. **Lambda Layers の活用**

- 共通のライブラリやコードは Layers にまとめて、複数の関数で共有する。

---

## 6. VS Code 推奨拡張機能

Lambda 開発を効率化するために以下の拡張機能が推奨されます。

- **AWS Toolkit** (`amazonwebservices.aws-toolkit-vscode`)
- ローカルでの Lambda 実行・デバッグ
- AWS リソースのエクスプローラー
- SAM アプリケーションのデプロイ

- **YAML** (`redhat.vscode-yaml`)
- CloudFormation / SAM テンプレートの検証
