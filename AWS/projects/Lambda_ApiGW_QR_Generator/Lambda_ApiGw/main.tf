terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

# ============================================================
# Lambda Function Resources
# ============================================================
# 処理順序：
# 1. IAM Role (Lambda実行用)
# 2. ビルドプロセス (依存ライブラリのインストール)
# 3. Lambda Function (ビルド完了後にデプロイ)

# --- Step 1: IAM Role for Lambda Execution ---
resource "aws_iam_role" "lambda_exec" {
  name = "qr_generator_lambda_role-${var.environment}"

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

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# --- Step 2: Build Lambda Deployment Package ---
# ソースコード変更時に自動的にビルドを実行
resource "null_resource" "lambda_build" {
  triggers = {
    handler_hash      = filemd5("${path.module}/lambda_code/handler.py")
    requirements_hash = filemd5("${path.module}/lambda_code/requirements.txt")
  }

  provisioner "local-exec" {
    command     = var.is_windows ? "powershell -ExecutionPolicy Bypass -File ${path.module}/script/build.ps1" : "bash ${path.module}/script/build.sh"
    working_dir = path.module
  }
}

# --- Step 3: Lambda Function ---
# ビルド完了後にデプロイされる
resource "aws_lambda_function" "qr_generator" {
  depends_on = [null_resource.lambda_build]

  filename         = "${path.module}/lambda_function_payload.zip"
  function_name    = "qr-generator-${var.environment}"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "handler.lambda_handler"
  runtime          = "python3.13"
  source_code_hash = null_resource.lambda_build.id

  environment {
    variables = {
      LOG_LEVEL = "INFO"
    }
  }

  lifecycle {
    replace_triggered_by = [null_resource.lambda_build]
  }
}

# ============================================================
# API Gateway Resources
# ============================================================
# 処理順序：
# 1. API Gateway HTTP API (エンドポイントの作成)
# 2. Integration (LambdaとAPI Gatewayの統合)
# 3. Route (URLパスとHTTPメソッドの定義)
# 4. Stage (デプロイステージの設定)
# 5. Lambda Permission (API GatewayからのLambda呼び出し許可)

# --- Step 1: API Gateway HTTP API ---
resource "aws_apigatewayv2_api" "lambda_api" {
  name          = "qr-generator-api-${var.environment}"
  protocol_type = "HTTP"
}

# --- Step 2: Lambda Integration ---
# Lambda関数とAPI Gatewayを統合
resource "aws_apigatewayv2_integration" "lambda_api" {
  api_id           = aws_apigatewayv2_api.lambda_api.id
  integration_type = "AWS_PROXY"

  integration_method     = "POST"
  integration_uri        = aws_lambda_function.qr_generator.invoke_arn
  payload_format_version = "2.0"
}

# --- Step 3: API Route ---
# エンドポイントのルーティング設定
resource "aws_apigatewayv2_route" "lambda_api" {
  api_id    = aws_apigatewayv2_api.lambda_api.id
  route_key = "GET /generate"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_api.id}"
}

# --- Step 4: API Stage ---
# デプロイステージの設定（自動デプロイ有効）
resource "aws_apigatewayv2_stage" "lambda_api" {
  api_id      = aws_apigatewayv2_api.lambda_api.id
  name        = "$default"
  auto_deploy = true
}

# --- Step 5: Lambda Permission ---
# API GatewayからLambdaを呼び出す権限を付与
resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.qr_generator.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.lambda_api.execution_arn}/*/*"
}
