# ============================================================
# このファイルの内容は main.tf に統合されました
# ============================================================
#
# Lambda関連のリソース（IAM Role、ビルドプロセス、Lambda Function）は
# 処理順と関連性をわかりやすくするため、main.tf に統合されています。
#
# 統合日: 2026年1月17日
# 参照: main.tf の「Lambda Function Resources」セクション
#
# ============================================================
# 以下は参考用に元のコードをコメントアウトして保持しています
# ============================================================

# # --- IAM Role ---
# resource "aws_iam_role" "lambda_exec" {
#   name = "qr_generator_lambda_role-${var.environment}"
#
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [{
#       Action = "sts:AssumeRole"
#       Effect = "Allow"
#       Principal = {
#         Service = "lambda.amazonaws.com"
#       }
#     }]
#   })
# }
#
# resource "aws_iam_role_policy_attachment" "lambda_logs" {
#   role       = aws_iam_role.lambda_exec.name
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
# }
#
# # --- ビルド実行用のスクリプト（初回とコード変更時） ---
# resource "null_resource" "lambda_build" {
#   triggers = {
#     handler_hash      = filemd5("${path.module}/lambda_code/handler.py")
#     requirements_hash = filemd5("${path.module}/lambda_code/requirements.txt")
#   }
#
#   provisioner "local-exec" {
#     command     = var.is_windows ? "powershell -ExecutionPolicy Bypass -File ${path.module}/script/build.ps1" : "bash ${path.module}/script/build.sh"
#     working_dir = path.module
#   }
# }
#
# # --- Lambda Function ---
# resource "aws_lambda_function" "qr_generator" {
#   depends_on = [null_resource.lambda_build]
#
#   filename         = "${path.module}/lambda_function_payload.zip"
#   function_name    = "qr-generator-${var.environment}"
#   role             = aws_iam_role.lambda_exec.arn
#   handler          = "handler.lambda_handler"
#   runtime          = "python3.13"
#   source_code_hash = null_resource.lambda_build.id
#
#   environment {
#     variables = {
#       LOG_LEVEL = "INFO"
#     }
#   }
#
#   lifecycle {
#     replace_triggered_by = [null_resource.lambda_build]
#   }
# }
