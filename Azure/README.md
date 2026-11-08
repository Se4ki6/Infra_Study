# Azure 学習プロジェクト

Azure のリソース構築とアプリ実装を学ぶ領域です。IaC はプロジェクトごとに Terraform または Bicep を使います。作業方針は [AGENTS.md](AGENTS.md) にまとめています。

## リソース学習

- [Blob Storage](resources/blob/)
- [Functions](resources/functions/)
- [VM と Bicep](resources/vm/)

## プロジェクト

- [Bastion Web TODO](projects/bastion-web-todo/)
- [Blob public share](projects/blob-publicshere/)
- [Resource cleanup checker](projects/resource-cleanup-checker/)
- [OpenTelemetry 注文 API](projects/otel-order-api/)

## 資料とツール

- [実装計画](plans/)
- [Zenn の記事案・下書き](zenn/)
- [Codex 向け規約とスキル](.codex/)

相対パスで記載されたコマンドを実行するときは、`Azure/` ディレクトリを作業ディレクトリにします。Terraform state、実値入り `*.tfvars`、Azure CLI の認証情報、実値入り `local.settings.json` はコミットしないでください。
