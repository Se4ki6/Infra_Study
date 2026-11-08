# Serverless Web App with Terraform

このドキュメントは、S3 (Frontend) + API Gateway + Lambda (Backend) を使用したサーバーレスアプリケーションの構築ガイドおよびコードセットです。VSCode の Markdown プレビュー (`Ctrl+K V`) で閲覧することを推奨します。

## 1. プロジェクト構成

```plaintext
.
├── main.tf                 # プロバイダー設定
├── variables.tf            # 変数定義
├── lambda.tf               # Lambda関数の定義
├── api_gateway.tf          # API Gatewayの定義 (REST API + CORS)
├── s3.tf                   # S3静的ウェブサイトホスティング設定
├── outputs.tf              # APIのエンドポイント等の出力
├── src
│   ├── lambda
│   │   └── app.py          # Lambdaのソースコード (Python)
│   └── frontend
│       └── index.html      # フロントエンドのソースコード

```

---

## 2. Lambda Function (Backend)

API Gateway の**Lambda プロキシ統合**を使用するため、ステータスコードやヘッダーを含む JSON を返却する必要があります。特に CORS ヘッダーが重要です。

`src/lambda/app.py`

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

---

## 3. Terraform Infrastructure

### `main.tf`

```hcl
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

```

### `variables.tf`

```hcl
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-1"
}

variable "project_name" {
  description = "Project name prefix"
  type        = string
  default     = "serverless-demo"
}

```

### `lambda.tf`

IAM ロールと Lambda 関数の定義、およびソースコードの ZIP 化を行います。

```hcl
# IAM Role for Lambda
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

# Attach Basic Execution Role (CloudWatch Logs)
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Zip the Python code
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/src/lambda/app.py"
  output_path = "${path.module}/lambda_function.zip"
}

# Lambda Function
resource "aws_lambda_function" "backend" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.project_name}-api"
  role             = aws_iam_role.lambda_role.arn
  handler          = "app.lambda_handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime          = "python3.9"
}

# Permission for API Gateway to invoke Lambda
resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.backend.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}

```

### `api_gateway.tf`

API Gateway の設定です。GET メソッドと、CORS 用の OPTIONS メソッドを設定します。

```hcl
# REST API
resource "aws_api_gateway_rest_api" "api" {
  name = "${var.project_name}-api"
}

# Resource (/hello)
resource "aws_api_gateway_resource" "hello" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "hello"
}

# --- GET Method (Proxy Integration) ---
resource "aws_api_gateway_method" "get_hello" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.hello.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.hello.id
  http_method             = aws_api_gateway_method.get_hello.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.backend.invoke_arn
}

# --- CORS: OPTIONS Method (Mock) ---
resource "aws_api_gateway_method" "options_hello" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.hello.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "options_integration" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.hello.id
  http_method = aws_api_gateway_method.options_hello.http_method
  type        = "MOCK"
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

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

# --- Deployment & Stage ---
resource "aws_api_gateway_deployment" "deployment" {
  depends_on = [
    aws_api_gateway_integration.lambda_integration,
    aws_api_gateway_integration.options_integration
  ]
  rest_api_id = aws_api_gateway_rest_api.api.id
}

resource "aws_api_gateway_stage" "dev" {
  deployment_id = aws_api_gateway_deployment.deployment.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
  stage_name    = "dev"
}

```

### `s3.tf`

静的ウェブサイトホスティングの設定です。

```hcl
# Random suffix for unique bucket name
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "frontend" {
  bucket = "${var.project_name}-frontend-${random_id.bucket_suffix.hex}"
  force_destroy = true
}

resource "aws_s3_bucket_website_configuration" "hosting" {
  bucket = aws_s3_bucket.frontend.id
  index_document {
    suffix = "index.html"
  }
}

# Public Read Policy (for website hosting)
resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "allow_public_read" {
  depends_on = [aws_s3_bucket_public_access_block.public_access]
  bucket     = aws_s3_bucket.frontend.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.frontend.arn}/*"
      },
    ]
  })
}

# Upload index.html
resource "aws_s3_object" "index_html" {
  bucket       = aws_s3_bucket.frontend.id
  key          = "index.html"
  source       = "${path.module}/src/frontend/index.html"
  content_type = "text/html"
  etag         = filemd5("${path.module}/src/frontend/index.html")
}

```

### `outputs.tf`

構築後にターミナルに表示される情報です。

```hcl
output "api_endpoint" {
  description = "API Gateway Endpoint URL"
  value       = "${aws_api_gateway_stage.dev.invoke_url}/hello"
}

output "website_endpoint" {
  description = "S3 Website URL"
  value       = aws_s3_bucket_website_configuration.hosting.website_endpoint
}

```

---

## 4. Frontend (Client)

Terraform 構築後、`terraform output api_endpoint` で出力された URL を以下のコードの `API_URL` に設定し、再度 `terraform apply` または手動アップロードを行ってください。

`src/frontend/index.html`

```html
<!DOCTYPE html>
<html lang="ja">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Serverless Demo</title>
    <style>
      body {
        font-family: sans-serif;
        text-align: center;
        margin-top: 50px;
      }
      button {
        padding: 10px 20px;
        font-size: 16px;
        cursor: pointer;
      }
      #result {
        margin-top: 20px;
        color: #333;
        font-weight: bold;
      }
    </style>
  </head>
  <body>
    <h1>Serverless App</h1>
    <button onclick="callApi()">APIを呼び出す</button>
    <div id="result"></div>

    <script>
      // Terraform outputの api_endpoint をここに貼り付け
      const API_URL = "YOUR_API_GATEWAY_URL/dev/hello";

      async function callApi() {
        const resultDiv = document.getElementById("result");
        resultDiv.innerText = "Loading...";

        try {
          const response = await fetch(API_URL);
          if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
          }
          const data = await response.json();
          resultDiv.innerText = "Response: " + data.message;
          console.log(data);
        } catch (error) {
          console.error("Error:", error);
          resultDiv.innerText = "Error: " + error.message;
        }
      }
    </script>
  </body>
</html>
```
