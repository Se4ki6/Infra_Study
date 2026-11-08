# Bicep 規約（このプロジェクト）

このプロジェクトで Bicep を書く/レビューする全コンポーネント（bicep-orchestrator / bicep-coder / bicep-reviewer）が従う共通規約。
既存 Terraform 構成（`resources/functions/infra-terraform/`）と同じ思想を Bicep に揃えるための規約。
元になる Terraform の locals は `resources/functions/infra-terraform/main.tf` を参照。

## ディレクトリ構成

Terraform の `modules/` と1対1で対応させる。

```
infra/
├── main.bicep              ← オーケストレーション（module 呼び出し）
├── main.bicepparam         ← 環境ごとのパラメータ
└── modules/
    ├── resource_group.bicep
    ├── storage_account.bicep
    ├── monitoring.bicep
    └── function_app.bicep
```

## スコープ

- RG を作るところから始めるなら `main.bicep` 冒頭で `targetScope = 'subscription'`
- 既存 RG 内にデプロイするなら既定（`resourceGroup`）のまま

## 命名規則

CAF 略語 + `{prefix}-{env}` + 一意 suffix。Terraform 側と同じ値になるよう揃える。

| リソース | 略語/形式 | 例 |
|---|---|---|
| Resource Group | `rg-{prefix}-{env}` | `rg-app-dev` |
| Storage Account | `st{prefix}{env}{suffix}`（ハイフン無・小文字・24字以内） | `stappdev3k9x2a` |
| Log Analytics | `log-{prefix}-{env}` | `log-app-dev` |
| Application Insights | `appi-{prefix}-{env}` | `appi-app-dev` |
| App Service Plan | `plan-{prefix}-{env}` | `plan-app-dev` |
| Function App | `func-{prefix}-{env}-{suffix}` | `func-app-dev-3k9x2a` |

- 一意 suffix は Bicep では `uniqueString(resourceGroup().id)` を使う（Terraform の `random_string` 相当）。先頭6文字程度を切り出す: `take(uniqueString(resourceGroup().id), 6)`
- prefix/env は `param` で受け、`toLower()` と `substring()`/`take()` で正規化する
- Storage は記号不可・24字制限があるため必ず長さを切り詰める

## パラメータ化

```bicep
@description('リソース名のプレフィックス（10字以内推奨）')
@minLength(2)
@maxLength(10)
param namePrefix string

@description('環境識別子')
@allowed(['dev', 'stg', 'prod'])
param environment string

@description('全リソース共通のタグ')
param tags object = {}

@description('デプロイ先リージョン')
param location string = resourceGroup().location
```

- 環境差分になる値は必ず `param` に出す（ハードコードしない）
- 制約は `@allowed` `@minLength` `@maxLength` で表現し、意図を `@description` に書く

## タグ

```bicep
var commonTags = union(tags, {
  environment: environment
})
```

全リソースの `tags:` に `commonTags` を渡す。

## セキュリティ既定値（必須）

Terraform 側で守っている既定値を Bicep でも維持する。

- Storage: `minimumTlsVersion: 'TLS1_2'`、`allowBlobPublicAccess: false`、`supportsHttpsTrafficOnly: true`
- Blob コンテナ: `publicAccess: 'None'`
- 不要な公開はしない: 必要に応じ `publicNetworkAccess: 'Disabled'`
- キー・接続文字列は `output` に出さない。必要なら `listKeys()` で実行時取得する

## 出力（output）

- 後続が接続に使う値（コンテナ endpoint、リソース ID/name 等）だけを出す
- アクセスキー等の機微情報は output に書かない

## コメント

- 各リソース定義の直前に日本語1行で「何のためのリソースか」を書く（既存 `.tf` と同じ密度）
- 該当する学習トピック docs があればリンクを併記する

## 参考 URL（調査時に確認）

- Bicep ベストプラクティス: https://learn.microsoft.com/azure/azure-resource-manager/bicep/best-practices
- リソースリファレンス（種別 + apiVersion）: https://learn.microsoft.com/azure/templates/
- CAF 命名略語: https://learn.microsoft.com/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations
- bicepparam: https://learn.microsoft.com/azure/azure-resource-manager/bicep/parameter-files
