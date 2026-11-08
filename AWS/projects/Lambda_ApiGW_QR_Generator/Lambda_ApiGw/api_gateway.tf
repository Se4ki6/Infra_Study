# ============================================================
# このファイルの内容は main.tf に統合されました
# ============================================================
#
# API Gateway関連のリソースは処理順と関連性をわかりやすくするため、
# main.tf に統合されています。
#
# 統合日: 2026年1月17日
# 参照: main.tf の「API Gateway Resources」セクション
#
# ============================================================
# 以下は参考用に元のコードをコメントアウトして保持しています
# ============================================================

# # --- API Gateway (HTTP API) ---
# resource "aws_apigatewayv2_api" "lambda_api" {
#   name          = "qr-generator-api-${var.environment}"
#   protocol_type = "HTTP"
# }
#
# resource "aws_apigatewayv2_stage" "lambda_api" {
#   api_id      = aws_apigatewayv2_api.lambda_api.id
#   name        = "$default"
#   auto_deploy = true
# }
#
# resource "aws_apigatewayv2_integration" "lambda_api" {
#   api_id           = aws_apigatewayv2_api.lambda_api.id
#   integration_type = "AWS_PROXY"
#
#   integration_method     = "POST"
#   integration_uri        = aws_lambda_function.qr_generator.invoke_arn
#   payload_format_version = "2.0"
# }
#
# resource "aws_apigatewayv2_route" "lambda_api" {
#   api_id    = aws_apigatewayv2_api.lambda_api.id
#   route_key = "GET /generate"
#   target    = "integrations/${aws_apigatewayv2_integration.lambda_api.id}"
# }
#
# resource "aws_lambda_permission" "api_gw" {
#   statement_id  = "AllowExecutionFromAPIGateway"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.qr_generator.function_name
#   principal     = "apigateway.amazonaws.com"
#   source_arn    = "${aws_apigatewayv2_api.lambda_api.execution_arn}/*/*"
# }
