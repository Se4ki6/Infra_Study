````markdown
# 爆速QRコード生成API Terraform テンプレート

## 1. ディレクトリ構成

```text
.
├── main.tf           # プロバイダー設定
├── lambda.tf         # Lambda関連リソース定義
├── api_gateway.tf    # API Gateway関連リソース定義
├── outputs.tf        # APIエンドポイント出力
├── lambda/
│   ├── handler.py    # Lambdaロジック
│   └── requirements.txt # 依存ライブラリ
└── build.sh          # デプロイ用パッケージングスクリプト
```
````

---

## 2. main.tf

```hcl
provider "aws" {
  region = "ap-northeast-1"
}
```

---

## 3. lambda.tf

```hcl
# --- IAM Role ---
resource "aws_iam_role" "lambda_exec" {
  name = "qr_generator_lambda_role"

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

# --- Lambda Function ---
resource "aws_lambda_function" "qr_generator" {
  filename         = "lambda_function_payload.zip"
  function_name    = "qr-generator"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "handler.lambda_handler"
  runtime          = "python3.9"
  source_code_hash = filebase64sha256("lambda_function_payload.zip")

  environment {
    variables = {
      LOG_LEVEL = "INFO"
    }
  }
}
```

---

## 4. api_gateway.tf

```hcl
# --- API Gateway (HTTP API) ---
resource "aws_apigatewayv2_api" "lambda_api" {
  name          = "qr-generator-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "lambda_api" {
  api_id      = aws_apigatewayv2_api.lambda_api.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_apigatewayv2_integration" "lambda_api" {
  api_id           = aws_apigatewayv2_api.lambda_api.id
  integration_type = "AWS_PROXY"

  integration_method     = "POST"
  integration_uri        = aws_lambda_function.qr_generator.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "lambda_api" {
  api_id    = aws_apigatewayv2_api.lambda_api.id
  route_key = "GET /generate"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_api.id}"
}

resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.qr_generator.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.lambda_api.execution_arn}/*/*"
}
```

---

## 5. lambda/handler.py

```python
import segno
import io
import base64
import json

def lambda_handler(event, context):
    # クエリパラメータからURLを取得
    query_params = event.get('queryStringParameters', {})
    target_url = query_params.get('url', '[https://google.com](https://google.com)') if query_params else '[https://google.com](https://google.com)'

    # QRコードをメモリ上で生成
    out = io.BytesIO()
    qrcode = segno.make(target_url)
    qrcode.save(out, kind='png', scale=5)

    # Base64エンコード
    qr_base64 = base64.b64encode(out.getvalue()).decode('utf-8')

    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'image/png',
            'Access-Control-Allow-Origin': '*'
        },
        'body': qr_base64,
        'isBase64Encoded': True
    }

```

---

## 6. lambda/requirements.txt

```text
segno

```

---

## 7. outputs.tf

```hcl
output "api_endpoint" {
  description = "QR Code Generation URL"
  value       = "${aws_apigatewayv2_api.lambda_api.api_endpoint}/generate?url=[https://example.com](https://example.com)"
}

```

---

## 8. build.sh (パッケージング手順)

```bash
#!/bin/bash

# ライブラリを一時フォルダにインストールしてzip化するスクリプト
export PKG_DIR="python_payload"
rm -rf $PKG_DIR && mkdir $PKG_DIR
rm -f lambda_function_payload.zip

# ライブラリのインストール
pip install -r lambda/requirements.txt -t $PKG_DIR

# ソースコードのコピー
cp lambda/handler.py $PKG_DIR

# zip化
cd $PKG_DIR
zip -r ../lambda_function_payload.zip .
cd ..

# クリーンアップ
rm -rf $PKG_DIR

echo "Build complete: lambda_function_payload.zip"

```

---

## 9. 実行フロー

1. `chmod +x build.sh` で権限付与。
2. `./build.sh` を実行して `lambda_function_payload.zip` を生成。
3. `terraform init`
4. `terraform apply`

```

```
