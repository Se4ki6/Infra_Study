# Azure - Codex Project Guide

## Project Purpose

このリポジトリは Azure を学ぶために、実際に Azure リソースを立てて動かすことを軸にした学習プロジェクトです。
リソースは Terraform または Bicep のどちらで書くかを、その都度ユーザーが選んで構築します。
コード完成だけでなく、Azure の概念理解、IaC ツールごとの設計思想、実構築までの流れを重視します。

## Non-Negotiable Rules

- 勝手に実装を進めない。学習目的の作業では、解説 -> ユーザー確認 -> 実装 の順を守る。
- Terraform / Bicep はユーザーが選ぶ。未指定なら確認する。
- 外向き・不可逆な操作を勝手にしない。`terraform apply`、`az deployment ... create` などのデプロイ操作は必ずユーザーの明示許可を取る。
- `terraform plan`、`az deployment ... what-if`、`az bicep build` は確認・検証として提案または実行してよい。ただし Azure 認証や課金影響が絡む場合は事前に説明する。
- 質疑応答は `docs/{resource-name}/` に残す。Web ソース付きの深掘り情報は `docs/{resource-name}/reference/` に分離する。

## Workflow Entry Points

- Bicep でリソースを企画から作る場合は、`bicep-orchestrator` スキルを使う。
- Terraform でリソースを作る場合は、既存構成 `resources/functions/infra-terraform/` をベースにする。
- Bicep の共通規約は `.codex/rules/bicep-conventions.md` を参照する。
- Bicep の雛形は `.codex/rules/bicep-templates.md` を参照する。
- Microsoft / Azure 公式 Docs 調査は `microsoft-learn` スキルを優先する。
- 一般 Web 調査や Zenn 記事用の根拠集めは `use-tavily` スキルを使う。

## Repository Layout

- `resources/{resource-name}/` - リソースごとの実装。例: `infra-terraform/`、`infra-bicep/`、`app/`
- `plans/` - 実装計画
- `docs/{resource-name}/` - リソースごとの解説・Q&A
- `zenn/plan/` - Zenn 記事の構成案
- `zenn/publish/` - Zenn 記事の下書き・公開候補
- `.codex/rules/` - IaC 共通の規約・雛形
- `.codex/skills/` - このリポジトリで使う Codex 向けスキル
