variable "aws_profile" {
  type        = string
  description = "AWS CLIで設定したプロファイル名（例: default）"

}

variable "aws_region" {
  type        = string
  description = "AWSリージョン（例: ap-northeast-1）"
}

variable "github_token" {
  type        = string
  description = "GitHubのPersonal Access Token"
  sensitive   = true # ログにトークンが出ないようにする優しさ
}

variable "github_repository_url" {
  type        = string
  description = "GitHubリポジトリのURL（例: https://github.com/username/repository）"
}

variable "app_name" {
  type    = string
  default = "obsidian-memo-hoster"
}
