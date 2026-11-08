# api_gateway.tf - API Gateway設定の解説

## 概要
このファイルは、AWS API Gatewayを使用してRESTful APIを構成し、Lambda関数と連携するためのリソースを定義しています。フロントエンド（S3）からのAPIリクエストを受け付け、Lambda関数にルーティングします。

## リソース構成

### 1. aws_api_gateway_rest_api.api
```terraform
resource "aws_api_gateway_rest_api" "api" {
  name = "${var.project_name}-api"
}
```
**目的**: REST APIの作成

**設定項目**:
- `name`: API名をプロジェクト名から自動生成
- このリソースがAPI全体のルート（エントリーポイント）となる
- 作成後、デフォルトで`/`（ルートリソース）が存在

**注意点**:
- デフォルトではエンドポイントタイプは`EDGE`（CloudFront経由）
- プライベートAPIや地域限定APIにする場合は`endpoint_configuration`を追加

---

### 2. aws_api_gateway_resource.hello
```terraform
resource "aws_api_gateway_resource" "hello" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "hello"
}
```
**目的**: `/hello`というパスを持つAPIリソースを作成

**設定項目**:
- `rest_api_id`: 所属するREST APIのID
- `parent_id`: 親リソースのID（ここではルート`/`）
- `path_part = "hello"`: このリソースのパス部分

**結果**:
- 完全なパスは `/hello` となる
- 複数階層にする場合は、リソースをネストして定義

**拡張例**:
```terraform
# /hello/world を作成する場合
resource "aws_api_gateway_resource" "world" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_resource.hello.id  # helloを親に
  path_part   = "world"
}
```

---

## GETメソッドの設定（Lambda統合）

### 3. aws_api_gateway_method.get_hello
```terraform
resource "aws_api_gateway_method" "get_hello" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.hello.id
  http_method   = "GET"
  authorization = "NONE"
}
```
**目的**: `/hello`に対するGETメソッドを定義

**設定項目**:
- `resource_id`: メソッドを追加するリソース（/hello）
- `http_method = "GET"`: HTTPメソッドの種類
- `authorization = "NONE"`: 認証なし（パブリックAPI）

**認証オプション**:
- `"NONE"`: 認証不要
- `"AWS_IAM"`: IAM認証（SigV4署名）
- `"CUSTOM"`: Lambda Authorizer（カスタム認証）
- `"COGNITO_USER_POOLS"`: Amazon Cognito認証

---

### 4. aws_api_gateway_integration.lambda_integration
```terraform
resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.hello.id
  http_method             = aws_api_gateway_method.get_hello.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.backend.invoke_arn
}
```
**目的**: GETメソッドとLambda関数を統合（連携）

**重要な設定項目**:

#### `type = "AWS_PROXY"` （Lambda Proxy統合）
- API Gatewayがリクエスト全体をそのままLambdaに転送
- Lambda側でHTTPレスポンス（ステータスコード、ヘッダー、ボディ）を完全に制御
- 最も一般的で柔軟な統合方法

**他のタイプ**:
- `"AWS"`: カスタム統合（レスポンスマッピングが必要）
- `"HTTP"` / `"HTTP_PROXY"`: HTTPエンドポイントへの統合
- `"MOCK"`: モックレスポンス（テスト用）

#### `integration_http_method = "POST"`
- ⚠️ **重要**: API GatewayからLambdaを呼び出す際は常にPOSTメソッドを使用
- クライアントからのHTTPメソッド（GET）とは異なる
- Lambda統合の仕様による制約

#### `uri = aws_lambda_function.backend.invoke_arn`
- Lambda関数の呼び出しARN
- 形式: `arn:aws:apigateway:region:lambda:path/2015-03-31/functions/arn:aws:lambda:region:account-id:function:function-name/invocations`

---

## CORSの設定（OPTIONSメソッド）

### なぜCORS設定が必要か？
ブラウザは、異なるオリジン（ドメイン）へのAPIリクエストを行う前に、**プリフライトリクエスト**（OPTIONSメソッド）を送信します。これに適切に応答しないと、APIが正常に動作しません。

**例**:
- フロントエンド: `https://my-bucket.s3-website-ap-northeast-1.amazonaws.com`
- API: `https://abc123.execute-api.ap-northeast-1.amazonaws.com`
- ドメインが異なるため、CORSが必要

### 5. aws_api_gateway_method.options_hello
```terraform
resource "aws_api_gateway_method" "options_hello" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.hello.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}
```
**目的**: プリフライトリクエストを受け付けるOPTIONSメソッドを定義

**注意点**:
- OPTIONSメソッドには認証を設定しない（プリフライトは認証前に行われる）

---

### 6. aws_api_gateway_integration.options_integration
```terraform
resource "aws_api_gateway_integration" "options_integration" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.hello.id
  http_method = aws_api_gateway_method.options_hello.http_method
  type        = "MOCK"
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}
```
**目的**: OPTIONSメソッドにモック統合を設定

**なぜMOCKタイプか？**
- プリフライトリクエストはヘッダー情報を返すだけで、実際の処理は不要
- Lambdaを呼び出す必要がないため、MOCKで効率的に応答
- コストとレイテンシを削減

**設定項目**:
- `type = "MOCK"`: モック統合（実際のバックエンドを呼ばない）
- `request_templates`: 固定レスポンス（200 OK）

---

### 7. aws_api_gateway_method_response.options_200
```terraform
resource "aws_api_gateway_method_response" "options_200" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.hello.id
  http_method = aws_api_gateway_method.options_hello.http_method
  status_code = "200"
  response_models = {
    "application/json" = "Empty"
  }
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}
```
**目的**: OPTIONSメソッドのレスポンス定義

**設定項目**:
- `status_code = "200"`: 成功ステータス
- `response_parameters`: レスポンスヘッダーの定義
  - `true`は、このヘッダーが存在することを示す（値は次のリソースで設定）

---

### 8. aws_api_gateway_integration_response.options_integration_response
```terraform
resource "aws_api_gateway_integration_response" "options_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.hello.id
  http_method = aws_api_gateway_method.options_hello.http_method
  status_code = aws_api_gateway_method_response.options_200.status_code
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'",
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}
```
**目的**: 統合レスポンスで実際のCORSヘッダー値を設定

**重要なヘッダー**:

#### `Access-Control-Allow-Origin`
- `'*'`: すべてのオリジンを許可（開発用）
- 本番環境では特定のドメインに制限を推奨: `'https://example.com'`

#### `Access-Control-Allow-Methods`
- 許可するHTTPメソッドのリスト
- ここでは`'GET,OPTIONS,POST,PUT'`を許可

#### `Access-Control-Allow-Headers`
- クライアントが送信できるヘッダーのリスト
- 標準的なヘッダーセット（認証、コンテンツタイプなど）

**注意点**:
- 値は文字列リテラルとして`'...'`で囲む必要がある（Terraformの仕様）
- セキュリティのため、本番環境では最小限の権限に制限

---

## デプロイメントとステージ

### 9. aws_api_gateway_deployment.deployment
```terraform
resource "aws_api_gateway_deployment" "deployment" {
  depends_on = [
    aws_api_gateway_integration.lambda_integration,
    aws_api_gateway_integration.options_integration
  ]
  rest_api_id = aws_api_gateway_rest_api.api.id
}
```
**目的**: APIの変更をデプロイ（実際に有効化）

**重要ポイント**:
- `depends_on`: すべてのメソッドと統合が完成してからデプロイ
- APIリソースを変更しただけでは反映されない（デプロイが必要）
- デプロイごとに新しいデプロイメントIDが作成される

**ベストプラクティス**:
```terraform
# デプロイのトリガーを明示的に管理
resource "aws_api_gateway_deployment" "deployment" {
  depends_on = [
    aws_api_gateway_integration.lambda_integration,
    aws_api_gateway_integration.options_integration
  ]
  rest_api_id = aws_api_gateway_rest_api.api.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.hello.id,
      aws_api_gateway_method.get_hello.id,
      aws_api_gateway_integration.lambda_integration.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}
```

---

### 10. aws_api_gateway_stage.dev
```terraform
resource "aws_api_gateway_stage" "dev" {
  deployment_id = aws_api_gateway_deployment.deployment.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
  stage_name    = "dev"
}
```
**目的**: APIのステージ（環境）を作成

**設定項目**:
- `stage_name = "dev"`: 開発環境ステージ
- このステージ名がURLの一部になる: `https://{api-id}.execute-api.{region}.amazonaws.com/dev/hello`

**ステージの利点**:
- 複数の環境を管理（dev、staging、prod）
- 各ステージで異なる設定（スロットリング、ログ、キャッシュなど）
- カナリアデプロイメントのサポート

**拡張例** - 本番環境ステージ:
```terraform
resource "aws_api_gateway_stage" "prod" {
  deployment_id = aws_api_gateway_deployment.deployment.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
  stage_name    = "prod"

  # CloudWatch Logsを有効化
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway.arn
    format = "$requestId"
  }

  # スロットリング設定
  throttle_settings {
    burst_limit = 5000
    rate_limit  = 10000
  }

  # X-Rayトレーシング
  xray_tracing_enabled = true
}
```

---

## APIのフロー

```
[ブラウザ]
   ↓ GET /hello
[API Gateway]
   ├─ プリフライトリクエスト (OPTIONS /hello)
   │   └─ MOCK統合 → CORSヘッダーを返す
   │
   └─ 実際のリクエスト (GET /hello)
       └─ Lambda Proxy統合 → Lambda実行 → レスポンス
```

## アーキテクチャ全体での役割

```
[S3 Static Website]
   ↓ fetch(API_URL)
[API Gateway] ← このファイルで定義
   ├─ CORS処理（OPTIONS）
   └─ Lambda呼び出し（GET）
       ↓
[Lambda Function] (lambda.tfで定義)
   ↓
[レスポンス]
```

---

## ベストプラクティス

### 1. APIキーの追加（使用量プラン）
```terraform
resource "aws_api_gateway_api_key" "api_key" {
  name = "${var.project_name}-api-key"
}

resource "aws_api_gateway_usage_plan" "usage_plan" {
  name = "${var.project_name}-usage-plan"

  api_stages {
    api_id = aws_api_gateway_rest_api.api.id
    stage  = aws_api_gateway_stage.dev.stage_name
  }

  quota_settings {
    limit  = 10000
    period = "MONTH"
  }

  throttle_settings {
    burst_limit = 100
    rate_limit  = 50
  }
}
```

### 2. カスタムドメイン
```terraform
resource "aws_api_gateway_domain_name" "api" {
  domain_name              = "api.example.com"
  regional_certificate_arn = aws_acm_certificate.api.arn

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_base_path_mapping" "api" {
  api_id      = aws_api_gateway_rest_api.api.id
  stage_name  = aws_api_gateway_stage.dev.stage_name
  domain_name = aws_api_gateway_domain_name.api.domain_name
}
```

### 3. リクエスト/レスポンスのバリデーション
```terraform
resource "aws_api_gateway_request_validator" "validator" {
  name                        = "${var.project_name}-validator"
  rest_api_id                 = aws_api_gateway_rest_api.api.id
  validate_request_body       = true
  validate_request_parameters = true
}
```

### 4. CloudWatch Logsの有効化
```terraform
resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "/aws/apigateway/${var.project_name}"
  retention_in_days = 7
}

resource "aws_api_gateway_stage" "dev" {
  # ...existing config...

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
    })
  }
}
```

---

## 関連ファイル

- [lambda.tf](./lambda.tf.description.md): このAPIから呼び出されるLambda関数
- [s3.tf](./s3.tf.description.md): APIを呼び出すフロントエンド
- [variables.tf](./variable.tf.description.md): プロジェクト名の変数定義

---

## デプロイ後の確認

1. **API URLの取得**:
   ```bash
   terraform output api_endpoint
   ```

2. **curlでテスト**:
   ```bash
   curl https://abc123.execute-api.ap-northeast-1.amazonaws.com/dev/hello
   ```

3. **CORS動作確認**:
   ```bash
   curl -X OPTIONS \
     -H "Origin: https://example.com" \
     -H "Access-Control-Request-Method: GET" \
     https://abc123.execute-api.ap-northeast-1.amazonaws.com/dev/hello
   ```

---

## トラブルシューティング

### 問題: 500 Internal Server Error
- Lambda関数のCloudWatch Logsを確認
- Lambda実行ロールに適切な権限があるか確認
- Lambda関数がタイムアウトしていないか確認

### 問題: CORSエラー
- OPTIONSメソッドが正しく設定されているか確認
- `Access-Control-Allow-Origin`ヘッダーが正しいか確認
- ブラウザの開発者ツールでプリフライトリクエストを確認

### 問題: Lambda統合が動作しない
- `aws_lambda_permission`が設定されているか確認（lambda.tf）
- `integration_http_method`が`POST`になっているか確認
- Lambda関数のARNが正しいか確認

### 問題: 変更が反映されない
- `terraform apply`後にデプロイメントが実行されたか確認
- ステージが最新のデプロイメントを参照しているか確認
- ブラウザキャッシュをクリア
