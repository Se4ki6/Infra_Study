resource "aws_amplify_app" "this" {
  name         = var.app_name
  repository   = var.github_repository_url
  access_token = var.github_token

  build_spec = <<-EOT
    version: 1
    frontend:
      phases:
        preBuild:
          commands:
            - npm ci
        build:
          commands:
            - npm run build
      artifacts:
        baseDirectory: dist
        files:
          - '**/*'
      cache:
        paths:
          - node_modules/**/*
  EOT

  # 例：サブディレクトリをルートとして指定する場合
  custom_rule {
    source = "/"
    target = "/index.html"
    status = "200"
  }

  # build_spec = <<-EOT
  #   version: 1
  #   frontend:
  #     phases:
  #       # 何もビルドしない
  #       build:
  #         commands: []
  #     artifacts:
  #       # リポジトリのルートをそのまま公開する
  #       baseDirectory: /
  #       files:
  #         - '**/*'
  # EOT
}

resource "aws_amplify_branch" "main" {
  app_id            = aws_amplify_app.this.id
  branch_name       = "main"
  enable_auto_build = true
}
