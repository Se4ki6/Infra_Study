terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-1" # 東京リージョン
  // SSO プロファイルを使用
  profile = "AdministratorAccess-339126664118"
}

# ---------------------------------------------
# 1. IAM Role & Policy
#    Lambda実行用の最小限の権限 (ログ出力のみ)
# ---------------------------------------------

resource "aws_iam_role" "lambda_exec" {
  name = "minimal_lambda_role"

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

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# ---------------------------------------------
# 2. Archive File
#    PythonコードをZIP化
# ---------------------------------------------

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/lambda_function.zip"
}

# ---------------------------------------------
# 3. Lambda Function
# ---------------------------------------------

resource "aws_lambda_function" "minimal_lambda" {
  filename      = data.archive_file.lambda_zip.output_path
  function_name = "minimal-terraform-python-lambda"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "index.lambda_handler" # ファイル名.関数名
  runtime       = "python3.11"

  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic_execution,
    data.archive_file.lambda_zip
  ]
}

# ---------------------------------------------
# Output
# ---------------------------------------------

output "lambda_function_arn" {
  value = aws_lambda_function.minimal_lambda.arn
}
