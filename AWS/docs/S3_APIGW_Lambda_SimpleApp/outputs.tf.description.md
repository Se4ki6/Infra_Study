# outputs.tf - 出力値定義の解説

## 概要
このファイルは、Terraformで作成したリソースの重要な情報を出力として定義します。`terraform apply`実行後、これらの値がコンソールに表示され、他のTerraformモジュールや外部システムから参照できるようになります。

**注意**: 現在このファイルは空ですが、本来は以下のような出力値を定義すべきです。

---

## 出力値（output）とは？

### 目的
1. **デプロイ後の確認**: 作成されたリソースのURLやIDを確認
2. **他のモジュールとの連携**: 出力値を他のTerraformモジュールの入力として使用
3. **自動化**: CI/CDパイプラインやスクリプトでの使用
4. **ドキュメンテーション**: デプロイされたインフラの重要な情報を記録

### 基本構文
```terraform
output "output_name" {
  description = "Output description"
  value       = resource.type.name.attribute
  sensitive   = false  # 機密情報の場合はtrue
}
```

---

## 推奨される出力値定義

このプロジェクトに追加すべき出力値を以下に示します：

### 1. S3関連の出力

```terraform
# S3バケット名
output "s3_bucket_name" {
  description = "Name of the S3 bucket hosting the frontend"
  value       = aws_s3_bucket.frontend.id
}

# S3ウェブサイトエンドポイント
output "website_endpoint" {
  description = "S3 website endpoint URL"
  value       = aws_s3_bucket_website_configuration.hosting.website_endpoint
}

# S3ウェブサイトURL（フル）
output "website_url" {
  description = "Full URL of the static website"
  value       = "http://${aws_s3_bucket_website_configuration.hosting.website_endpoint}"
}

# S3バケットARN
output "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.frontend.arn
}
```

**使用例**:
```bash
terraform apply
# Apply complete! Resources: 10 added, 0 changed, 0 destroyed.
#
# Outputs:
#
# s3_bucket_name = "serverless-demo-frontend-a3b2c1d4"
# website_endpoint = "serverless-demo-frontend-a3b2c1d4.s3-website-ap-northeast-1.amazonaws.com"
# website_url = "http://serverless-demo-frontend-a3b2c1d4.s3-website-ap-northeast-1.amazonaws.com"
```

ブラウザでアクセス:
```bash
# macOS/Linux
open $(terraform output -raw website_url)

# Windows PowerShell
Start-Process (terraform output -raw website_url)
```

---

### 2. API Gateway関連の出力

```terraform
# API Gateway ID
output "api_gateway_id" {
  description = "ID of the API Gateway REST API"
  value       = aws_api_gateway_rest_api.api.id
}

# API Gateway ステージURL
output "api_endpoint" {
  description = "API Gateway endpoint URL for the dev stage"
  value       = aws_api_gateway_stage.dev.invoke_url
}

# API Gateway フル URL（/helloエンドポイント）
output "api_hello_url" {
  description = "Full URL for the /hello endpoint"
  value       = "${aws_api_gateway_stage.dev.invoke_url}/hello"
}

# API Gateway Execution ARN
output "api_execution_arn" {
  description = "Execution ARN of the API Gateway"
  value       = aws_api_gateway_rest_api.api.execution_arn
}
```

**使用例**:
```bash
# API URLを取得
API_URL=$(terraform output -raw api_hello_url)

# curlでテスト
curl $API_URL

# 出力例:
# {
#   "message": "Hello from Lambda!",
#   "input": {...}
# }
```

**index.htmlへの組み込み**:
```bash
# API URLを取得して変数に設定
API_URL=$(terraform output -raw api_hello_url)
echo "Update index.html with: const API_URL = '$API_URL';"
```

---

### 3. Lambda関連の出力

```terraform
# Lambda関数名
output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.backend.function_name
}

# Lambda関数ARN
output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.backend.arn
}

# Lambda IAMロールARN
output "lambda_role_arn" {
  description = "ARN of the Lambda execution role"
  value       = aws_iam_role.lambda_role.arn
}

# Lambda CloudWatch Logs URL（コンソールリンク）
output "lambda_logs_url" {
  description = "CloudWatch Logs URL for the Lambda function"
  value       = "https://console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#logsV2:log-groups/log-group/$252Faws$252Flambda$252F${aws_lambda_function.backend.function_name}"
}
```

**使用例**:
```bash
# Lambda関数を直接テスト
aws lambda invoke \
  --function-name $(terraform output -raw lambda_function_name) \
  --payload '{"httpMethod":"GET","path":"/hello"}' \
  response.json

cat response.json

# CloudWatch Logsを確認
aws logs tail /aws/lambda/$(terraform output -raw lambda_function_name) --follow
```

---

### 4. プロジェクト情報の出力

```terraform
# プロジェクト名
output "project_name" {
  description = "Project name used for resource naming"
  value       = var.project_name
}

# リージョン
output "aws_region" {
  description = "AWS region where resources are deployed"
  value       = var.aws_region
}

# デプロイ完了メッセージ
output "deployment_summary" {
  description = "Summary of the deployed resources"
  value       = <<-EOT
    Deployment Complete!

    Frontend URL: http://${aws_s3_bucket_website_configuration.hosting.website_endpoint}
    API Endpoint: ${aws_api_gateway_stage.dev.invoke_url}/hello

    Next Steps:
    1. Open the Frontend URL in your browser
    2. Update index.html with the API Endpoint URL
    3. Test the API by clicking the button
  EOT
}
```

---

## 出力値の活用例

### 1. 他のモジュールでの使用

**モジュール構成**:
```
infrastructure/
├── modules/
│   ├── backend/       # このプロジェクト
│   │   └── outputs.tf
│   └── monitoring/
│       └── main.tf
└── main.tf
```

**modules/backend/outputs.tf**:
```terraform
output "api_endpoint" {
  value = aws_api_gateway_stage.dev.invoke_url
}
```

**modules/monitoring/main.tf**:
```terraform
variable "api_endpoint" {
  type = string
}

resource "aws_cloudwatch_metric_alarm" "api_errors" {
  alarm_name          = "api-gateway-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "5XXError"
  namespace           = "AWS/ApiGateway"
  period              = "60"
  statistic           = "Sum"
  threshold           = "10"

  dimensions = {
    ApiName = var.api_endpoint
  }
}
```

**root main.tf**:
```terraform
module "backend" {
  source = "./modules/backend"
}

module "monitoring" {
  source       = "./modules/monitoring"
  api_endpoint = module.backend.api_endpoint  # 出力値を使用
}
```

---

### 2. CI/CDパイプラインでの使用

**GitHub Actions例**:
```yaml
name: Deploy Infrastructure

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Terraform Apply
        run: terraform apply -auto-approve

      - name: Get API URL
        id: api_url
        run: echo "url=$(terraform output -raw api_hello_url)" >> $GITHUB_OUTPUT

      - name: Update Frontend Config
        run: |
          sed -i "s|YOUR_API_GATEWAY_URL|${{ steps.api_url.outputs.url }}|g" src/frontend/index.html

      - name: Deploy Frontend
        run: aws s3 sync src/frontend/ s3://$(terraform output -raw s3_bucket_name)/
```

---

### 3. スクリプトでの自動化

**deploy_and_test.sh**:
```bash
#!/bin/bash

# インフラをデプロイ
terraform apply -auto-approve

# 出力値を取得
API_URL=$(terraform output -raw api_hello_url)
WEBSITE_URL=$(terraform output -raw website_url)

# APIをテスト
echo "Testing API..."
curl -s $API_URL | jq .

# index.htmlを更新
echo "Updating index.html..."
sed -i "s|YOUR_API_GATEWAY_URL|$API_URL|g" src/frontend/index.html

# フロントエンドを再アップロード
echo "Uploading updated frontend..."
aws s3 cp src/frontend/index.html s3://$(terraform output -raw s3_bucket_name)/

# ブラウザで開く
echo "Opening website..."
open $WEBSITE_URL

echo "Deployment complete!"
```

---

### 4. JSONフォーマットでの出力

```bash
# すべての出力値をJSON形式で取得
terraform output -json > outputs.json

# jqで特定の値を抽出
cat outputs.json | jq -r '.api_endpoint.value'
```

**outputs.json**:
```json
{
  "api_endpoint": {
    "sensitive": false,
    "type": "string",
    "value": "https://abc123.execute-api.ap-northeast-1.amazonaws.com/dev"
  },
  "website_url": {
    "sensitive": false,
    "type": "string",
    "value": "http://serverless-demo-frontend-a3b2c1d4.s3-website-ap-northeast-1.amazonaws.com"
  }
}
```

---

## sensitive属性の使用

機密情報を含む出力値は、`sensitive = true`を設定します：

```terraform
output "database_password" {
  description = "Database password (sensitive)"
  value       = random_password.db_password.result
  sensitive   = true
}

output "api_key" {
  description = "API key for external service"
  value       = var.api_key
  sensitive   = true
}
```

**動作**:
```bash
terraform apply
# Outputs:
#
# api_key = <sensitive>
# database_password = <sensitive>

# 値を取得する場合
terraform output -raw api_key
# abc123xyz789  ← 実際の値が表示される
```

---

## 複雑な出力値の例

### マップ形式
```terraform
output "api_endpoints" {
  description = "Map of API endpoints"
  value = {
    hello     = "${aws_api_gateway_stage.dev.invoke_url}/hello"
    users     = "${aws_api_gateway_stage.dev.invoke_url}/users"
    products  = "${aws_api_gateway_stage.dev.invoke_url}/products"
  }
}
```

### リスト形式
```terraform
output "lambda_log_groups" {
  description = "List of CloudWatch Log Groups"
  value = [
    "/aws/lambda/${aws_lambda_function.backend.function_name}",
    "/aws/apigateway/${var.project_name}"
  ]
}
```

### オブジェクト形式
```terraform
output "infrastructure_info" {
  description = "Complete infrastructure information"
  value = {
    frontend = {
      bucket_name = aws_s3_bucket.frontend.id
      website_url = "http://${aws_s3_bucket_website_configuration.hosting.website_endpoint}"
    }
    backend = {
      api_url      = aws_api_gateway_stage.dev.invoke_url
      lambda_name  = aws_lambda_function.backend.function_name
      lambda_arn   = aws_lambda_function.backend.arn
    }
    metadata = {
      project_name = var.project_name
      region       = var.aws_region
      deployed_at  = timestamp()
    }
  }
}
```

---

## ベストプラクティス

### 1. 明確な説明を記述
```terraform
# ❌ Bad
output "url" {
  value = aws_api_gateway_stage.dev.invoke_url
}

# ✅ Good
output "api_endpoint" {
  description = "API Gateway endpoint URL for the dev stage. Use this URL to make API requests."
  value       = aws_api_gateway_stage.dev.invoke_url
}
```

### 2. 使いやすい形式で出力
```terraform
# ❌ Bad - 手動でURL組み立てが必要
output "api_id" {
  value = aws_api_gateway_rest_api.api.id
}

# ✅ Good - すぐに使えるフルURL
output "api_hello_url" {
  description = "Full URL for the /hello endpoint"
  value       = "${aws_api_gateway_stage.dev.invoke_url}/hello"
}
```

### 3. 機密情報を保護
```terraform
output "db_connection_string" {
  description = "Database connection string"
  value       = "postgresql://${var.db_username}:${var.db_password}@${aws_db_instance.main.endpoint}/mydb"
  sensitive   = true  # パスワードを含むため
}
```

### 4. デバッグ情報を含める
```terraform
output "debug_info" {
  description = "Debug information for troubleshooting"
  value = {
    lambda_log_group = "/aws/lambda/${aws_lambda_function.backend.function_name}"
    api_log_group    = "/aws/apigateway/${var.project_name}"
    s3_console_url   = "https://s3.console.aws.amazon.com/s3/buckets/${aws_s3_bucket.frontend.id}"
  }
}
```

---

## 完全な outputs.tf の推奨実装

```terraform
# ==========================================
# S3 Frontend Outputs
# ==========================================

output "s3_bucket_name" {
  description = "Name of the S3 bucket hosting the frontend"
  value       = aws_s3_bucket.frontend.id
}

output "website_url" {
  description = "Full URL of the static website"
  value       = "http://${aws_s3_bucket_website_configuration.hosting.website_endpoint}"
}

# ==========================================
# API Gateway Outputs
# ==========================================

output "api_endpoint" {
  description = "API Gateway base URL"
  value       = aws_api_gateway_stage.dev.invoke_url
}

output "api_hello_url" {
  description = "Full URL for the /hello endpoint"
  value       = "${aws_api_gateway_stage.dev.invoke_url}/hello"
}

# ==========================================
# Lambda Outputs
# ==========================================

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.backend.function_name
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.backend.arn
}

# ==========================================
# Deployment Summary
# ==========================================

output "deployment_summary" {
  description = "Quick reference for deployed resources"
  value = <<-EOT
    ========================================
    Deployment Complete!
    ========================================

    📦 Frontend:
       URL: http://${aws_s3_bucket_website_configuration.hosting.website_endpoint}
       Bucket: ${aws_s3_bucket.frontend.id}

    🚀 API:
       Base URL: ${aws_api_gateway_stage.dev.invoke_url}
       /hello endpoint: ${aws_api_gateway_stage.dev.invoke_url}/hello

    ⚡ Lambda:
       Function: ${aws_lambda_function.backend.function_name}
       Logs: aws logs tail /aws/lambda/${aws_lambda_function.backend.function_name} --follow

    🔧 Next Steps:
       1. Update src/frontend/index.html with the API URL
       2. Run: aws s3 sync src/frontend/ s3://${aws_s3_bucket.frontend.id}/
       3. Open the Frontend URL in your browser

    ========================================
  EOT
}
```

---

## 関連ファイル

- [s3.tf](./s3.tf.description.md): S3バケット（出力対象）
- [api_gateway.tf](./api_gateway.tf.description.md): API Gateway（出力対象）
- [lambda.tf](./lambda.tf.description.md): Lambda関数（出力対象）
- [variables.tf](./variable.tf.description.md): 変数定義

---

## デプロイ後の確認

```bash
# すべての出力値を表示
terraform output

# 特定の出力値を取得（生の値）
terraform output -raw website_url

# JSON形式で取得
terraform output -json

# 環境変数に設定
export API_URL=$(terraform output -raw api_hello_url)
echo $API_URL
```

---

## トラブルシューティング

### 問題: 出力値が表示されない
**原因**: `terraform apply`を実行していない、または出力が定義されていない
**解決策**: `terraform apply`を実行し、outputs.tfに定義を追加

### 問題: 出力値がエラーになる
```
Error: Missing resource instance key
```
**原因**: 参照しているリソースが存在しない、または条件付きで作成されている
**解決策**: リソースの存在を確認し、`count`や`for_each`を考慮

### 問題: sensitive値が見えない
**原因**: `sensitive = true`が設定されている
**解決策**: `terraform output -raw output_name`で値を取得

---

## 参考リンク

- [Terraform Output Values](https://developer.hashicorp.com/terraform/language/values/outputs)
- [Output Values CLI](https://developer.hashicorp.com/terraform/cli/commands/output)
