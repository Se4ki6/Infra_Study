output "environment" {
  description = "Current Environment"
  value       = var.environment
}

output "api_endpoint" {
  description = "QR Code Generation URL"
  value       = "${aws_apigatewayv2_api.lambda_api.api_endpoint}/generate?url=https://example.com"
}

output "api_endpoint_full" {
  description = "Full API Endpoint URL "
  value       = aws_apigatewayv2_api.lambda_api.api_endpoint
}

output "test_command_windows" {
  description = "Test command for Windows"
  value       = "script\test.ps1 \"${aws_apigatewayv2_api.lambda_api.api_endpoint}\""
}

output "test_command_linux" {
  description = "Test command for Linux/Mac"
  value       = "script/test.sh \"${aws_apigatewayv2_api.lambda_api.api_endpoint}\""
}

output "curl_test_command" {
  description = "cURL command for manual testing"
  value       = "curl \"${aws_apigatewayv2_api.lambda_api.api_endpoint}/generate?url=https://github.com\" --output qr_test.png"
}

output "browser_test_url" {
  description = "Browser test URL"
  value       = "${aws_apigatewayv2_api.lambda_api.api_endpoint}/generate?url=https://github.com"
}

output "api_id" {
  description = "API Gateway ID"
  value       = aws_apigatewayv2_api.lambda_api.id
}

output "lambda_function_name" {
  description = "Lambda Function Name"
  value       = aws_lambda_function.qr_generator.function_name
}

# Dev環境のみのデバッグ情報
output "debug_info" {
  description = "Debug Information (dev only)"
  value = var.environment == "dev" ? {
    lambda_arn        = aws_lambda_function.qr_generator.arn
    lambda_version    = aws_lambda_function.qr_generator.version
    api_execution_arn = aws_apigatewayv2_api.lambda_api.execution_arn
  } : null
}

# 環境別のメッセージ
output "deployment_message" {
  description = "Deployment Status Message"
  value       = var.environment == "prod" ? "✅ Production deployment complete. Use with caution." : "🚀 Development environment ready for testing."
}
