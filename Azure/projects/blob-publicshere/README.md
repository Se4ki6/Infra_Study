# blob-publicshere

画像共有など、匿名で読み取り可能な Blob コンテナを持つ Storage Account を構築する学習用リソース（Bicep）。

- 実装: [infra-bicep/](infra-bicep/)
- 元になった構成案: [main.tf](main.tf)（Terraform 版の下書き）
- 解説・Q&A: `docs/blob-publicshere/`（未作成。Q&A が発生したら作成する）

## 構成（何を作るか）

`infra-bicep/main.bicep` は `targetScope = 'subscription'` で以下を作成する。

| リソース | 内容 |
|---|---|
| Resource Group | `rg-{namePrefix}-{environment}`（既定値: `rg-public-dev`） |
| Storage Account | `st{namePrefix}{environment}{suffix}`（既定値プレフィックス: `stpublicdev...`）。`Standard_LRS` |
| Blob コンテナ | `public-assets`（既定値。`containerName` パラメータで変更可） |

### セキュリティ設定（`.claude/rules/bicep-conventions.md` からの意図的な逸脱を含む）

- `minimumTlsVersion: TLS1_2`
- `supportsHttpsTrafficOnly: true`（HTTP禁止）
- `allowBlobPublicAccess: true` ← **既定の `false` から意図的に逸脱**（画像などを匿名公開する用途のため）
- コンテナの `publicAccess: Blob` ← **既定の `None` から意図的に逸脱**（匿名の読み取りは可、コンテナ一覧は不可）

### データ保護設定（`blobServices` プロパティ）

- `isVersioningEnabled: true`（バージョニング有効）
- `deleteRetentionPolicy`: 7日間の論理削除保持
- `containerDeleteRetentionPolicy`: 7日間の論理削除保持（コンテナ削除時）

### パラメータ（`main.bicepparam` の既定値）

```bicep
namePrefix   = 'public'
environment  = 'dev'
location     = 'japaneast'
containerName = 'public-assets'
tags = { purpose: 'public-assets' }
```

### 出力（キーは出さない）

`resourceGroupName` / `storageAccountName` / `containerName` / `blobEndpoint`

## 事前準備

以降のコマンドはすべて **このディレクトリ（`resource-project/blob-publicshere/`）で実行する**（`infra-bicep/...` が相対パスのため）。

```powershell
cd resource-project/blob-publicshere
az login
az account set --subscription "<サブスクリプション名 or ID>"
```

サブスクリプションスコープのデプロイのため、`--location` の指定が必須（RG自体の作成先リージョンとして使われる）。

## what-if（差分確認・破壊的操作なし）

実際の変更は行わず、何が作成・変更されるかを確認する。

```powershell
az deployment sub what-if `
  --location japaneast `
  --template-file infra-bicep/main.bicep `
  --parameters infra-bicep/main.bicepparam
```

## デプロイ

what-if の内容を確認し、問題なければ実行する。

```powershell
az deployment sub create `
  --name "blob-publicshere-$(Get-Date -Format 'yyyyMMddHHmmss')" `
  --location japaneast `
  --template-file infra-bicep/main.bicep `
  --parameters infra-bicep/main.bicepparam
```

デプロイ後、コンテナの匿名アクセスを確認する場合:

```powershell
az storage account show --name <storageAccountName> --query allowBlobPublicAccess
az storage container show --name public-assets --account-name <storageAccountName> --auth-mode login --query properties.publicAccess
```

## 破棄（destroy）

Bicep には Terraform の `destroy` に相当するコマンドはない。このリソースは専用の Resource Group にまとまっているため、**RG ごと削除**するのが最も確実。

```powershell
# 削除対象の確認（何が消えるか一覧表示のみ、実削除はしない）
az resource list --resource-group rg-public-dev -o table

# 実削除（不可逆操作。必ず確認してから実行する）
az group delete --name rg-public-dev --yes
```

RG 自体は残して中身だけ空にしたい場合は、Bicep の complete モードで空テンプレートを当てる方法もあるが、事故りやすいため通常は RG 削除を推奨する。

> `--yes` を付けると確認プロンプトなしで即削除されるため、必ずリソース名（環境）を確認してから実行すること。
