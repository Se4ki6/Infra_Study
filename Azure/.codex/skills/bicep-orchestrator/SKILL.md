---
name: bicep-orchestrator
description: Bicep で Azure リソースを企画から段階的に作るための Codex ワークフロー。ユーザーとのインタビュー、計画ファイル作成、計画承認、Bicep 実装、読み取りレビュー、az bicep build / what-if 提示までを、このリポジトリの学習フローに沿って進めるときに使う。
---

# Bicep Orchestrator

このスキルは、Bicep で複数リソースやモジュール群を企画段階から作るときに使う。
Codex では Claude の subagent 定義を前提にせず、メインの Codex がフェーズを分けて実装とレビューを進める。

## 必ず読む

1. `AGENTS.md`
2. `.codex/rules/bicep-conventions.md`
3. `.codex/rules/bicep-templates.md`
4. 既存 Terraform と揃える場合は `resources/functions/infra-terraform/`
5. Azure リソース種別と apiVersion は `microsoft-learn` スキル、または公式 `https://learn.microsoft.com/azure/templates/` で確認する

## 進め方

1. インタビューで、作りたいもの、含めるリソース、環境、命名 prefix、対象ディレクトリを確認する。
2. `plans/<topic>-bicep-plan.md` に計画を書く。
3. 計画をユーザーに提示し、未解決の質問が空になってから明示承認を得る。
4. 承認後に Bicep を実装する。デプロイはしない。
5. 実装後、レビュー観点だけで読み直す。問題は深刻度付きで提示し、修正するかユーザーに確認する。
6. `az bicep build --file <target>/main.bicep` を実行できる場合は実行する。
7. `az deployment group what-if` は認証とスコープが確認できる場合だけ実行する。実行できない場合はコマンドを提示する。

## 計画ファイルの固定スキーマ

```markdown
# <タイトル> Bicep Plan

## 目的
<何を・なぜ作るか>

## 対象ディレクトリ
<例: resources/functions/infra-bicep/>

## リソース一覧
| リソース | 種別 (Microsoft.*) | apiVersion | 役割 |
|---|---|---|---|

## 命名
<CAF 略語 + {prefix}-{env} + uniqueString suffix の方針>

## パラメータ
<環境差分として param に出す値>

## セキュリティ既定値
<TLS、公開設定、キー output 禁止など>

## モジュール分割
<main.bicep と modules/*.bicep の構成>

## What-if スコープ
<resource group / subscription / bicepparam>

## 未解決の質問
<承認前に決めること。なければ「なし」>
```

## 実装ルール

- `.codex/rules/bicep-conventions.md` に従う。
- 各リソース定義の直前に日本語 1 行コメントを書く。
- アクセスキー、接続文字列、secure 値を output に出さない。
- apiVersion は記憶で断定せず、公式情報で確認する。
- `az deployment ... create` は実行しない。

## レビュー観点

- 計画との整合
- 命名規則、パラメータ化、タグ
- セキュリティ既定値
- output の機密漏れ
- apiVersion とリソース種別
- モジュール分割
- `az bicep build` の結果
