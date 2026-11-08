# Azure VM 最小構成 Bicep Plan

## 目的

Azure VM を **最小構成・最小スペック**で立て、Bicep の書き方と VM 周辺リソース（VNet / NSG / NIC / Public IP / Managed Disk）の関係を学ぶ。
`terraform destroy` 相当として、**Resource Group ごと一発削除** で全リソースを消せる構成にする。
コードを完成させること自体ではなく、各概念の理解と「最小構成で動く VM を実構築 → 削除できる」を確認することが目的。

## 対象ディレクトリ

```
resources/vm/infra-bicep/
├── main.bicep                 ← targetScope='subscription'。RG + module 呼び出し
├── main.bicepparam            ← 環境ごとのパラメータ（SSH 公開鍵・許可元 IP はダミー）
└── modules/
    ├── network.bicep          ← VNet / Subnet / NSG / Public IP / NIC
    ├── virtual_machine.bicep  ← VM 本体（OS ディスク含む）
    └── auto_shutdown.bicep    ← DevTestLab schedule（自動シャットダウン）
```

既存 `resources/functions/infra-terraform/`（Terraform）とは別系統の学習領域として `resources/vm/infra-bicep/` を新設する。
Terraform `modules/` と Bicep `modules/` を1対1で揃える方針自体は維持（Functions 側と同じ思想）。

## リソース一覧

| # | リソース | 種別 (Microsoft.*) | apiVersion（目安・実装時に裏取り） | 役割 |
|---|---|---|---|---|
| 1 | Resource Group | `Microsoft.Resources/resourceGroups` | `2024-03-01` | 全リソースの土台。これを削除すれば中身が全て消える（destroy 相当） |
| 2 | Virtual Network | `Microsoft.Network/virtualNetworks` | `2023-11-01` 以降 | VM を置くためのプライベートネットワーク |
| 3 | Subnet | `Microsoft.Network/virtualNetworks/subnets`（VNet の子） | 同上 | VNet 内のセグメント。NIC をここに配置 |
| 4 | Network Security Group | `Microsoft.Network/networkSecurityGroups` | `2023-11-01` 以降 | SSH (22/TCP) を**指定元 IP のみ**許可。それ以外は拒否 |
| 5 | Public IP Address | `Microsoft.Network/publicIPAddresses` | `2023-11-01` 以降 | VM への外部到達点。**Standard SKU・Static**（Basic SKU は 2025-09-30 でリタイア済み） |
| 6 | Network Interface | `Microsoft.Network/networkInterfaces` | `2023-11-01` 以降 | VM と VNet/Public IP/NSG を接続する NIC |
| 7 | Virtual Machine | `Microsoft.Compute/virtualMachines` | `2024-07-01` 以降 | Ubuntu 22.04 LTS、サイズ `Standard_B1s`、SSH 鍵認証のみ |
| 8 | OS Managed Disk | VM の `storageProfile.osDisk`（暗黙生成） | （VM の apiVersion に従う） | Standard_LRS HDD、30 GiB |
| 9 | Auto-Shutdown Schedule | `Microsoft.DevTestLab/schedules` | `2018-09-15` | 毎日 22:00 JST に VM を自動停止（消し忘れ防止・追加課金なし） |

> apiVersion はこの計画の時点での目安。**bicep-coder には「実装時に https://learn.microsoft.com/azure/templates/ で最新を確認」を必須で渡す。**

## 命名

CAF 略語 + `{prefix}-{env}` + 一意 suffix。`.claude/rules/bicep-conventions.md` に準拠。

| リソース | 形式 | 例（prefix=`vm`, env=`dev`） |
|---|---|---|
| Resource Group | `rg-{prefix}-{env}` | `rg-vm-dev` |
| VNet | `vnet-{prefix}-{env}` | `vnet-vm-dev` |
| Subnet | `snet-default` | `snet-default` |
| NSG | `nsg-{prefix}-{env}` | `nsg-vm-dev` |
| Public IP | `pip-{prefix}-{env}` | `pip-vm-dev` |
| NIC | `nic-{prefix}-{env}` | `nic-vm-dev` |
| Virtual Machine | `vm-{prefix}-{env}` | `vm-vm-dev` |
| OS Disk | `osdisk-{prefix}-{env}` | `osdisk-vm-dev` |
| Auto-Shutdown | `shutdown-computevm-{vmName}`（DevTestLab の規約名） | `shutdown-computevm-vm-vm-dev` |

- 一意 suffix は今回は **不要**（VM 名は RG 内で一意であればよい）。命名の prefix/env で十分。
- prefix/env は `param` で受け、`toLower()` で正規化。

## パラメータ

| param | 型 | 既定値 | 制約 / 説明 |
|---|---|---|---|
| `namePrefix` | `string` | `'vm'` | `@minLength(2) @maxLength(10)` |
| `environment` | `string` | `'dev'` | `@allowed(['dev','stg','prod'])` |
| `location` | `string` | `'eastus'` | サブスクスコープのため `resourceGroup().location` は使えない |
| `vmSize` | `string` | `'Standard_B1s'` | `@allowed(['Standard_B1s','Standard_B1ls','Standard_B2ats_v2'])` |
| `adminUsername` | `string` | `'azureuser'` | `@minLength(1)` |
| `sshPublicKey` | `string` | （`.bicepparam` でダミー） | `@description('OpenSSH 形式の公開鍵。実デプロイ時に CLI で上書き')` |
| `allowedSshSourceAddressPrefix` | `string` | （`.bicepparam` でダミー `'0.0.0.0/32'`） | `@description('SSH を許可する送信元 IP/CIDR。必ず実デプロイ時に自分の IP に上書き')` |
| `enableAutoShutdown` | `bool` | `true` | DevTestLab スケジュール作成可否 |
| `autoShutdownTime` | `string` | `'2200'` | `HHmm` 形式 |
| `autoShutdownTimeZone` | `string` | `'Tokyo Standard Time'` | Windows タイムゾーン名 |
| `tags` | `object` | `{}` | 共通タグ。`environment` を必ず merge |

ハードコードしないものは全部 `param` に出す。制約は `@allowed` / `@minLength` / `@maxLength` で表現。

## セキュリティ既定値（明示確認したもの）

`.claude/rules/bicep-conventions.md` の方針に加え、VM 固有で以下を **計画段階で確定**：

1. **SSH 鍵認証のみ**：`linuxConfiguration.disablePasswordAuthentication = true`、`adminPassword` プロパティは使わない
2. **NSG 既定**：受信は明示許可ルールのみ。ルール例：
   - `Allow-SSH-From-MyIP`: priority 1000、Inbound、Allow、TCP、`sourceAddressPrefix = allowedSshSourceAddressPrefix`、`destinationPortRange = '22'`
   - その他の受信は Azure 既定の `DenyAllInbound` に任せる（明示 Deny は書かない）
3. **Public IP は Standard SKU + Static**：Basic SKU はリタイア済み。Static にして NSG 設計を安定させる
4. **OS Disk 暗号化**：プラットフォーム管理キー（Microsoft.Compute 既定）で at-rest 暗号化される。`securityProfile.encryptionAtHost` は **false（既定）** とする（B シリーズはサポートが限定的なため・要件外なら無効が無難）
5. **Boot Diagnostics**：マネージドストレージ方式（`diagnosticsProfile.bootDiagnostics.enabled = true`、`storageUri` 未指定）にして、追加 Storage Account を作らない
6. **System-assigned Managed Identity**：今回は **無効**（最小構成、必要になったら付ける）
7. **output に機微情報を出さない**：SSH 公開鍵・パスワードは output しない。`adminUsername` と `publicIpAddress`（接続先）は output してよい

### セキュリティ面の懸念（学習者が認識すべきこと）

| # | 懸念 | このプランでの扱い | 本番でやるべきこと |
|---|---|---|---|
| S1 | **VM が Public IP で露出**。スキャナの的になる | NSG で送信元 IP を `allowedSshSourceAddressPrefix` に厳格制限。`.bicepparam` に自分の IP を**コミットしない**（CLI で上書き） | Azure Bastion を経由し Public IP なしにする |
| S2 | **SSH 22 番が既知ポート**。ブルートフォースの対象 | NSG で送信元限定のため到達不可。鍵認証のみ | JIT (Just-in-Time) VM Access（Defender for Servers 有料） |
| S3 | **`allowedSshSourceAddressPrefix` を雑に `0.0.0.0/0` にすると全世界開放** | param 既定値はダミー（`'0.0.0.0/32'` = 何も許可しない）。実デプロイ時に自分の IP を渡すまで SSH 不可 | NSG ルール作成を Policy で強制チェック |
| S4 | **OS パッチ未自動化** | プラン外。手動 `apt upgrade` 想定 | Update Manager / Automation Update Management |
| S5 | **Defender for Cloud 未設定** | プラン外（有料） | 本番では有効化推奨 |
| S6 | **Boot Diagnostics ログにアクセス可能なロールが広い** | マネージドストレージ方式で最低限に | RBAC を最小権限に絞る |
| S7 | **SSH 公開鍵が `.bicepparam` ファイルに書かれる** | 公開鍵自体は機密ではないが、`.bicepparam` のデフォルトは**ダミー**にする。実値は CLI 引数で渡す | Key Vault 参照（`getSecret`）に置き換え |
| S8 | **VM が停止していてもディスクと Public IP は課金される** | `enableAutoShutdown=true` で停止は自動化。**ただし完全に課金止めるには Deallocate（=自動シャットダウンの挙動）が必要**。ディスク/IP の課金は停止中も継続 | 使い終わったら RG ごと削除（このプランの destroy 設計） |

## モジュール分割

```
main.bicep (targetScope='subscription')
├── resource rg (Microsoft.Resources/resourceGroups)
├── module network        (scope: rg) → VNet / Subnet / NSG / Public IP / NIC
├── module virtual_machine (scope: rg) → VM 本体、nicId を入力で受ける
└── module auto_shutdown  (scope: rg, enableAutoShutdown=true のときのみ) → DevTestLab schedule
```

各モジュールの境界：

- `modules/network.bicep`
  - 入力: `namePrefix`, `environment`, `location`, `allowedSshSourceAddressPrefix`, `tags`
  - 出力: `nicId`（VM が参照）、`publicIpAddress`（接続先表示用、ただし作成時点では未割り当てなので fqdn ではなく "あとで参照する形" にするか output からは抜く）
  - VNet `10.0.0.0/16`、Subnet `10.0.0.0/24` で最小

- `modules/virtual_machine.bicep`
  - 入力: `vmName`, `location`, `vmSize`, `adminUsername`, `sshPublicKey`, `nicId`, `tags`
  - 出力: `vmId`（auto_shutdown が参照）、`vmName`
  - OS イメージ: Canonical `0001-com-ubuntu-server-jammy` `22_04-lts-gen2`、`latest`
  - OS Disk: `Standard_LRS`、`diskSizeGB: 30`、`createOption: 'FromImage'`、`name: 'osdisk-...'`

- `modules/auto_shutdown.bicep`
  - 入力: `vmId`, `vmName`, `location`, `time` (HHmm), `timeZoneId`, `tags`
  - 出力: なし
  - `name: 'shutdown-computevm-${vmName}'` で DevTestLab の規約名にする
  - `properties.targetResourceId = vmId`、`properties.taskType = 'ComputeVmShutdownTask'`、`properties.status = 'Enabled'`

## What-if スコープ

- `targetScope = 'subscription'`（main.bicep）
- What-if コマンド:

```powershell
# 構文 / lint（常に通す）
az bicep build --file resources/vm/infra-bicep/main.bicep

# 差分プレビュー（subscription スコープ）
az deployment sub what-if `
  --location eastus `
  --template-file resources/vm/infra-bicep/main.bicep `
  --parameters resources/vm/infra-bicep/main.bicepparam `
  --parameters sshPublicKey="$(Get-Content $HOME\.ssh\id_ed25519.pub -Raw)" `
  --parameters allowedSshSourceAddressPrefix="<自分の IP>/32"
```

- `.bicepparam` はダミー値で commit。実デプロイ時は CLI の `--parameters` で `sshPublicKey` と `allowedSshSourceAddressPrefix` を**必ず上書き**する。

## Destroy（terraform destroy 相当）

最小構成は全リソースが Resource Group の中に入る。Resource Group 自体も Bicep で作るため、

```powershell
# 一発で全リソース削除（destroy 相当）
az group delete --name rg-vm-dev --yes --no-wait
```

- 注意：DevTestLab の auto-shutdown schedule は VM スコープのため、VM 削除と一緒に消える。
- 注意：`az group delete` は復旧不能。本番では誤爆防止に `--confirm-with-what-if` の検討余地あり（学習用は不要）。

## コスト概算

リージョン `eastus`、為替 1 USD = ¥155 想定（2026 年時点の目安、最新は要確認）。
**常時稼働した場合の月額（30 日換算 = 720 時間）**：

| 項目 | 単価 | 月額 | 備考 |
|---|---|---|---|
| VM `Standard_B1s` (Linux PAYG) | $0.0104/h | **約 $7.49** | Burstable B シリーズ。CPU クレジット制 |
| OS Disk Standard_LRS 32 GiB (S4) | 月額固定 | **約 $1.54** | 30 GiB 指定でも次の課金単位 32 GiB に切り上げ |
| Public IP Standard Static | $0.005/h | **約 $3.65** | Public IP は **VM 停止中も課金** |
| VNet / Subnet / NSG / NIC | $0 | **$0** | これらは無料 |
| 帯域（egress 100 GB/月まで） | 無料枠内 | **$0** | 学習用途想定 |
| **合計（常時稼働）** | | **約 $12.68 / 月 ≒ ¥1,965** | |

**自動シャットダウン有効時の月額（22:00 JST 停止、8:00 起動 = 1 日 14 時間稼働、月 420 時間想定）**：

| 項目 | 月額 | 備考 |
|---|---|---|
| VM `Standard_B1s` (420h) | **約 $4.37** | 稼働時間のみ課金 |
| OS Disk Standard_LRS 32 GiB | **約 $1.54** | 停止中も課金 |
| Public IP Standard Static | **約 $3.65** | 停止中も課金 |
| **合計（自動停止あり）** | **約 $9.56 / 月 ≒ ¥1,481** | 約 25% 削減 |

**RG 削除後の月額**：**$0**。これが「使うときだけ作る」運用の最大利点。

> 単価は AWS と違って Azure は時期と為替で変動する。**実額は Azure Pricing Calculator** で確認:
> https://azure.microsoft.com/pricing/calculator/

## 未解決の質問

なし（計画承認待ち）。

## 参考

- VM Bicep リファレンス: https://learn.microsoft.com/azure/templates/microsoft.compute/virtualmachines
- DevTestLab schedules: https://learn.microsoft.com/azure/templates/microsoft.devtestlab/schedules
- CAF 略語: https://learn.microsoft.com/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations
- Bicep ベストプラクティス: https://learn.microsoft.com/azure/azure-resource-manager/bicep/best-practices
- Public IP Basic SKU リタイア: https://azure.microsoft.com/updates/upgrade-to-standard-sku-public-ip-addresses-in-azure-by-30-september-2025/
