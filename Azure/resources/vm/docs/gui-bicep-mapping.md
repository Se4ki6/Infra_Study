# ポータルGUI ↔ Bicep 対応表（VM構成）

デプロイ済みの `rg-vm-dev`（sekishiro-learn / japaneast）を題材に、
**Azureポータルのどの画面のどの項目を、Bicepのどこで設定しているか**を1リソースずつ対応させる。

- 対象Bicep: [`resource-learn/vm/infra-bicep/`](../infra-bicep/)
  - [main.bicep](../infra-bicep/main.bicep) … オーケストレーション（RG作成 + module呼び出し）
  - [modules/network.bicep](../infra-bicep/modules/network.bicep) … VNet / Subnet / NSG / Public IP / NIC
  - [modules/virtual_machine.bicep](../infra-bicep/modules/virtual_machine.bicep) … VM本体 / OSディスク
  - [modules/auto_shutdown.bicep](../infra-bicep/modules/auto_shutdown.bicep) … 自動シャットダウン
- 深掘り: [NSG / VNet / Subnet / Public IP / NIC の関係性](reference/nsg-vnet-subnet-pip-nic.md)（NSGの評価順序、踏み台/3層構成のユースケース）

## 進め方

デプロイ順（依存の浅い順）に、1リソースずつ「ポータル画面 → Bicepの該当行」を対応させる。

| # | リソース | ポータルの種類 | 主なBicep | 対応表 | 画像 |
|---|---|---|---|---|---|
| 1 | Resource Group `rg-vm-dev` | リソース グループ | main.bicep | ✅ | ✅ |
| 2 | Virtual Network + Subnet `vnet-vm-dev` | 仮想ネットワーク | network.bicep | ✅ | ✅ |
| 3 | Network Security Group `nsg-vm-dev` | NSG | network.bicep | ✅ | ✅ |
| 4 | Public IP `pip-vm-dev` | パブリック IP | network.bicep | ✅ | ⬜ |
| 5 | Network Interface `nic-vm-dev` | ネットワーク インターフェイス | network.bicep | ✅ | ⬜ |
| 6 | Virtual Machine `vm-vm-dev` | 仮想マシン | virtual_machine.bicep | ✅ | ⬜ |
| 7 | OS Disk `osdisk-vm-dev` | ディスク | virtual_machine.bicep | ✅ | ⬜ |
| 8 | Auto-Shutdown スケジュール | VMの「自動シャットダウン」 | auto_shutdown.bicep | ✅ | ⬜ |

### スクショの入れ方（後で一括アップ）

画像は下記の**決められたファイル名**で公開Blobにアップすれば、ドキュメント内のリンクが自動で表示される（貼り直し不要）。

```powershell
# 例（ファイル名は下の一覧に合わせること）
az storage blob upload --account-name stpublicdevuhmtgr --container-name public-assets --name images/vnet-subnet.png --file .\vnet-subnet.png --auth-mode login
```

**アップすべきファイル名一覧（`images/` 配下）:**

| セクション | ファイル名 | 撮る画面 |
|---|---|---|
| 1 | `rg-rm-dev_overview.png` | RG概要（アップ済み） |
| 2 | `vnet-subnet.png` | vnet-vm-dev のサブネット編集（VNet/16 と Subnet/24 が見える画面） |
| 3 | `nsg-rules.png` | nsg-vm-dev の「インバウンド セキュリティ規則」 |
| 4 | `pip-overview.png` | pip-vm-dev の概要 |
| 5 | `nic-ipconfig.png` | nic-vm-dev の「IP構成」 |
| 6 | `vm-overview.png` | vm-vm-dev の概要 |
| 7 | `osdisk-overview.png` | osdisk-vm-dev の概要 |
| 8 | `vm-autoshutdown.png` | vm-vm-dev >「自動シャットダウン」 |

> ファイル名は **ASCII・ハイフン/アンダースコア** で。スペース/日本語はURLエンコードが要るので避ける。

---

## 1. Resource Group `rg-vm-dev`

すべてのリソースの入れ物。Bicepでは `main.bicep` が `subscription` スコープで最初に作る。

### ポータルでの見方
- 「リソース グループ」→ `rg-vm-dev` → **概要(Overview)**（タグは左メニュー「タグ」）

![rg-vm-dev の概要画面](https://stpublicdevuhmtgr.blob.core.windows.net/public-assets/images/rg-rm-dev_overview.png)

### GUI ↔ Bicep 対応

| ポータルの項目 | 値（今回） | Bicep | 該当箇所 |
|---|---|---|---|
| リソース グループ名 | `rg-vm-dev` | `var rgName = 'rg-${prefix}-${env}'` | [main.bicep:65](../infra-bicep/main.bicep#L65) |
| 場所(Location) | Japan East | `location: location` | [main.bicep:81](../infra-bicep/main.bicep#L81) |
| サブスクリプション | sekishiro-learn | `targetScope = 'subscription'`（ログイン中のサブスク） | [main.bicep:8](../infra-bicep/main.bicep#L8) |
| リソース種別 | Microsoft.Resources/resourceGroups | `resource rg 'Microsoft.Resources/resourceGroups@2024-11-01'` | [main.bicep:79](../infra-bicep/main.bicep#L79) |
| タグ `environment` | dev | `union(tags, { environment: env })` | [main.bicep:70-72](../infra-bicep/main.bicep#L70-L72) |
| タグ `project`/`managedBy`/`workload` | azure-learning / bicep / vm-minimal | `param tags`（bicepparam） | [main.bicepparam:29-33](../infra-bicep/main.bicepparam#L29-L33) |

### メモ
- 名前の `rg-` は CAF 略語規約。`{prefix}-{env}` で `rg-vm-dev`。`prefix`/`env` は `namePrefix='vm'`/`environment='dev'` を `toLower()` 正規化（[main.bicep:62-63](../infra-bicep/main.bicep#L62-L63)）。
- 概要の **「デプロイ: 3 成功」** は `main.bicep` が呼ぶ **module 3つ**（`network`/`virtualMachine`/`autoShutdown`）がRGスコープの「ネストされたデプロイ」として記録されたもの（[main.bicep:86-126](../infra-bicep/main.bicep#L86-L126)）。「設定 > デプロイ」で履歴が見られる。

---

## 2. Virtual Network + Subnet `vnet-vm-dev`

VMを置くプライベートネットワーク。VNet=`10.0.0.0/16`、その中の Subnet=`10.0.0.0/24`。

### ポータルでの見方
- `vnet-vm-dev` → **概要**（アドレス空間）／ **設定 > サブネット**（`snet-default` とNSG紐付け）

![vnet-vm-dev のサブネット/アドレス空間](https://stpublicdevuhmtgr.blob.core.windows.net/public-assets/images/vnet-subnet.png)

### GUI ↔ Bicep 対応（VNet）

| ポータルの項目 | 値 | Bicep | 該当箇所 |
|---|---|---|---|
| 名前 | `vnet-vm-dev` | `var vnetName = 'vnet-${namePrefix}-${environment}'` | [network.bicep:23](../infra-bicep/modules/network.bicep#L23) |
| リソース種別 | Microsoft.Network/virtualNetworks | `resource vnet '...@2024-07-01'` | [network.bicep:60](../infra-bicep/modules/network.bicep#L60) |
| アドレス空間 | 10.0.0.0/16 | `var vnetAddressPrefix = '10.0.0.0/16'` → `addressPrefixes` | [network.bicep:30](../infra-bicep/modules/network.bicep#L30), [66-68](../infra-bicep/modules/network.bicep#L66-L68) |
| 場所 | Japan East | `location: location` | [network.bicep:62](../infra-bicep/modules/network.bicep#L62) |

### GUI ↔ Bicep 対応（Subnet）

| ポータルの項目 | 値 | Bicep | 該当箇所 |
|---|---|---|---|
| サブネット名 | `snet-default` | `var subnetName = 'snet-default'` | [network.bicep:24](../infra-bicep/modules/network.bicep#L24) |
| サブネット アドレス範囲 | 10.0.0.0/24（10.0.0.0〜10.0.0.255） | `var subnetAddressPrefix = '10.0.0.0/24'` → `addressPrefix` | [network.bicep:31](../infra-bicep/modules/network.bicep#L31), [78](../infra-bicep/modules/network.bicep#L78) |
| NSG | `nsg-vm-dev` | `networkSecurityGroup: { id: nsg.id }` | [network.bicep:79-81](../infra-bicep/modules/network.bicep#L79-L81) |
| 親VNet | `vnet-vm-dev` | `parent: vnet` | [network.bicep:75](../infra-bicep/modules/network.bicep#L75) |

### メモ
- NSGは **サブネットに紐付け**（NICではなく）。配下NIC全部に同じルールが効く。
- **「使用可能なIP: 250」** … `/24`=256個だが、Azureは各サブネットで**先頭5つ(.0/.1/.2/.3)と.255を予約**するので実質250前後。VM内部IPが `10.0.0.4` から始まるのはこのため。
- サブネットはVNetの子リソースなので、リソース一覧には単独で出ずVNetの中に表示される。

---

## 3. Network Security Group `nsg-vm-dev`

ファイアウォール的な受信制御。今回はSSH(22)を自分のIPからのみ許可。

### ポータルでの見方
- `nsg-vm-dev` → **設定 > インバウンド セキュリティ規則(Inbound security rules)**

![nsg-vm-dev のインバウンド規則](https://stpublicdevuhmtgr.blob.core.windows.net/public-assets/images/nsg-rules.png)

### GUI ↔ Bicep 対応（規則 `Allow-SSH-From-MyIP`）

| ポータルの項目 | 値 | Bicep | 該当箇所 |
|---|---|---|---|
| 名前 | Allow-SSH-From-MyIP | `name: 'Allow-SSH-From-MyIP'` | [network.bicep:42](../infra-bicep/modules/network.bicep#L42) |
| 優先度 | 1000 | `priority: 1000` | [network.bicep:45](../infra-bicep/modules/network.bicep#L45) |
| 方向 | 受信(Inbound) | `direction: 'Inbound'` | [network.bicep:46](../infra-bicep/modules/network.bicep#L46) |
| アクション | 許可(Allow) | `access: 'Allow'` | [network.bicep:47](../infra-bicep/modules/network.bicep#L47) |
| プロトコル | TCP | `protocol: 'Tcp'` | [network.bicep:48](../infra-bicep/modules/network.bicep#L48) |
| ソース | 160.237.73.239/32（自分のIP） | `sourceAddressPrefix: allowedSshSourceAddressPrefix`（CLIで注入） | [network.bicep:49](../infra-bicep/modules/network.bicep#L49) |
| 宛先ポート | 22 | `destinationPortRange: '22'` | [network.bicep:52](../infra-bicep/modules/network.bicep#L52) |
| NSG種別 | Microsoft.Network/networkSecurityGroups | `resource nsg '...@2024-07-01'` | [network.bicep:35](../infra-bicep/modules/network.bicep#L35) |

### メモ
- ポータルには他に **DenyAllInBound(65500)** など**既定規則**が並ぶが、これはBicepに書いていない**Azureの標準ルール**。明示Denyを書かなくても「許可した以外は全部拒否」になる（[network.bicep:34](../infra-bicep/modules/network.bicep#L34) のコメント）。
- ソースIPをダミー`0.0.0.0/32`のままにするとSSH不可。デプロイ時にCLIで実IP注入するのが肝。

---

## 4. Public IP `pip-vm-dev`

VMへの外部到達点。SSH接続先の `20.48.89.165`。

### ポータルでの見方
- `pip-vm-dev` → **概要**（IPアドレス / SKU / 割り当て / 関連付け）

![pip-vm-dev の概要](https://stpublicdevuhmtgr.blob.core.windows.net/public-assets/images/pip-overview.png)

### GUI ↔ Bicep 対応

| ポータルの項目 | 値 | Bicep | 該当箇所 |
|---|---|---|---|
| 名前 | `pip-vm-dev` | `var pipName = 'pip-${namePrefix}-${environment}'` | [network.bicep:26](../infra-bicep/modules/network.bicep#L26) |
| IPアドレス | 20.48.89.165 | （Azureが割当。Staticなので固定） | — |
| SKU | Standard | `sku: { name: 'Standard' ... }` | [network.bicep:90-93](../infra-bicep/modules/network.bicep#L90-L93) |
| 割り当て | 静的(Static) | `publicIPAllocationMethod: 'Static'` | [network.bicep:95](../infra-bicep/modules/network.bicep#L95) |
| IPバージョン | IPv4 | `publicIPAddressVersion: 'IPv4'` | [network.bicep:96](../infra-bicep/modules/network.bicep#L96) |
| 関連付け | nic-vm-dev（ipconfig1） | NIC側で `publicIPAddress: { id: publicIp.id }` | [network.bicep:114-116](../infra-bicep/modules/network.bicep#L114-L116) |

### メモ
- **Static** なので停止/再起動してもIPが変わらない（SSH先が固定できる）。Dynamicだと再起動で変わることがある。
- Standard SKU必須（Basic SKUは2025-09-30リタイア済 / [network.bicep:85](../infra-bicep/modules/network.bicep#L85) コメント）。

---

## 5. Network Interface `nic-vm-dev`

VMとサブネット/Public IPをつなぐ仮想NIC。

### ポータルでの見方
- `nic-vm-dev` → **設定 > IP構成(IP configurations)**

![nic-vm-dev の IP構成](https://stpublicdevuhmtgr.blob.core.windows.net/public-assets/images/nic-ipconfig.png)

### GUI ↔ Bicep 対応

| ポータルの項目 | 値 | Bicep | 該当箇所 |
|---|---|---|---|
| 名前 | `nic-vm-dev` | `var nicName = 'nic-${namePrefix}-${environment}'` | [network.bicep:27](../infra-bicep/modules/network.bicep#L27) |
| IP構成名 | ipconfig1 | `name: 'ipconfig1'` | [network.bicep:108](../infra-bicep/modules/network.bicep#L108) |
| プライベートIP割り当て | 動的(Dynamic) → 10.0.0.4 | `privateIPAllocationMethod: 'Dynamic'` | [network.bicep:110](../infra-bicep/modules/network.bicep#L110) |
| サブネット | snet-default | `subnet: { id: subnet.id }` | [network.bicep:111-113](../infra-bicep/modules/network.bicep#L111-L113) |
| パブリックIP | pip-vm-dev | `publicIPAddress: { id: publicIp.id }` | [network.bicep:114-116](../infra-bicep/modules/network.bicep#L114-L116) |
| NIC種別 | Microsoft.Network/networkInterfaces | `resource nic '...@2024-07-01'` | [network.bicep:101](../infra-bicep/modules/network.bicep#L101) |

### メモ
- NICが「サブネット」「Public IP」を束ねる結節点。VMはこのNICのIDだけ受け取る（[main.bicep:108](../infra-bicep/main.bicep#L108) で `network.outputs.nicId` を VMへ渡す疎結合設計）。

---

## 6. Virtual Machine `vm-vm-dev`

本命。OS/サイズ/ディスク/SSH鍵/ネットワークをまとめる。

### ポータルでの見方
- `vm-vm-dev` → **概要**（OS/サイズ/Public IP/場所）。詳細は「設定 > オペレーティング システム」「サイズ」など

![vm-vm-dev の概要](https://stpublicdevuhmtgr.blob.core.windows.net/public-assets/images/vm-overview.png)

### GUI ↔ Bicep 対応

| ポータルの項目 | 値 | Bicep | 該当箇所 |
|---|---|---|---|
| 名前 / コンピューター名 | `vm-vm-dev` | `var vmName`（main）→ `computerName: vmName` | [main.bicep:66](../infra-bicep/main.bicep#L66), [virtual_machine.bicep:66](../infra-bicep/modules/virtual_machine.bicep#L66) |
| サイズ | Standard_D2as_v4 | `vmSize`（bicepparam）→ `hardwareProfile.vmSize` | [main.bicepparam:13](../infra-bicep/main.bicepparam#L13), [virtual_machine.bicep:51](../infra-bicep/modules/virtual_machine.bicep#L51) |
| OSイメージ | Ubuntu Server 22.04 LTS Gen2 | `imageReference`(Canonical / jammy / 22_04-lts-gen2) | [virtual_machine.bicep:37-42](../infra-bicep/modules/virtual_machine.bicep#L37-L42) |
| 管理者ユーザー名 | azureuser | `adminUsername: adminUsername` | [virtual_machine.bicep:67](../infra-bicep/modules/virtual_machine.bicep#L67) |
| 認証方式 | SSH公開鍵（パスワード無効） | `disablePasswordAuthentication: true` + `ssh.publicKeys` | [virtual_machine.bicep:70-77](../infra-bicep/modules/virtual_machine.bicep#L70-L77) |
| ネットワーク インターフェイス | nic-vm-dev | `networkProfile.networkInterfaces[0].id = nicId` | [virtual_machine.bicep:82-90](../infra-bicep/modules/virtual_machine.bicep#L82-L90) |
| ブート診断 | 有効（マネージド） | `diagnosticsProfile.bootDiagnostics.enabled: true` | [virtual_machine.bicep:93-96](../infra-bicep/modules/virtual_machine.bicep#L93-L96) |
| VM種別 | Microsoft.Compute/virtualMachines | `resource vm '...@2024-07-01'` | [virtual_machine.bicep:45](../infra-bicep/modules/virtual_machine.bicep#L45) |

### メモ
- `computerName`(OS内のホスト名)とAzure上のVMリソース名を同じ`vm-vm-dev`にしている（SSHログイン後のプロンプト `azureuser@vm-vm-dev` がこれ）。
- SSH公開鍵は `path: /home/azureuser/.ssh/authorized_keys` に埋め込まれる（[virtual_machine.bicep:74](../infra-bicep/modules/virtual_machine.bicep#L74)）。

---

## 7. OS Disk `osdisk-vm-dev`

VMの起動ディスク。VMとは別リソースとして一覧に出る。

### ポータルでの見方
- `osdisk-vm-dev` → **概要**（サイズ / ストレージの種類）

![osdisk-vm-dev の概要](https://stpublicdevuhmtgr.blob.core.windows.net/public-assets/images/osdisk-overview.png)

### GUI ↔ Bicep 対応

| ポータルの項目 | 値 | Bicep | 該当箇所 |
|---|---|---|---|
| 名前 | `osdisk-vm-dev` | `var osDiskName`（main）→ `osDisk.name` | [main.bicep:67](../infra-bicep/main.bicep#L67), [virtual_machine.bicep:56](../infra-bicep/modules/virtual_machine.bicep#L56) |
| サイズ | 30 GiB | `diskSizeGB: 30` | [virtual_machine.bicep:59](../infra-bicep/modules/virtual_machine.bicep#L59) |
| ストレージの種類 | Standard HDD (LRS) | `managedDisk.storageAccountType: 'Standard_LRS'` | [virtual_machine.bicep:60-62](../infra-bicep/modules/virtual_machine.bicep#L60-L62) |
| 作成方法 | イメージから | `createOption: 'FromImage'` | [virtual_machine.bicep:57](../infra-bicep/modules/virtual_machine.bicep#L57) |
| ホストキャッシュ | 読み取り/書き込み | `caching: 'ReadWrite'` | [virtual_machine.bicep:58](../infra-bicep/modules/virtual_machine.bicep#L58) |

### メモ
- VMを`deallocate`(停止)しても**ディスクは残り少額課金**が続く。完全に止めるにはRGごと削除。
- SSHで見えた「Usage of /: 5.6% of 28.89GB」がこの30GBディスク。

---

## 8. Auto-Shutdown スケジュール

消し忘れ防止に毎日22:00で自動停止。DevTestLabのScheduleリソース。

### ポータルでの見方
- `vm-vm-dev` → **操作(Operations) > 自動シャットダウン(Auto-shutdown)**

![vm-vm-dev の自動シャットダウン](https://stpublicdevuhmtgr.blob.core.windows.net/public-assets/images/vm-autoshutdown.png)

### GUI ↔ Bicep 対応

| ポータルの項目 | 値 | Bicep | 該当箇所 |
|---|---|---|---|
| 自動シャットダウン | オン(Enabled) | `enableAutoShutdown`(main)＋`status: 'Enabled'` | [main.bicep:115](../infra-bicep/main.bicep#L115), [auto_shutdown.bicep:33](../infra-bicep/modules/auto_shutdown.bicep#L33) |
| スケジュールされたシャットダウン | 22:00 | `dailyRecurrence.time`（bicepparamの`autoShutdownTime='2200'`） | [main.bicepparam:26](../infra-bicep/main.bicepparam#L26), [auto_shutdown.bicep:35-37](../infra-bicep/modules/auto_shutdown.bicep#L35-L37) |
| タイム ゾーン | (UTC+9) Tokyo Standard Time | `timeZoneId`（bicepparamの`autoShutdownTimeZone`） | [main.bicepparam:27](../infra-bicep/main.bicepparam#L27), [auto_shutdown.bicep:38](../infra-bicep/modules/auto_shutdown.bicep#L38) |
| 通知 | オフ | `notificationSettings.status: 'Disabled'` | [auto_shutdown.bicep:44](../infra-bicep/modules/auto_shutdown.bicep#L44) |
| 対象VM | vm-vm-dev | `targetResourceId: vmId` | [auto_shutdown.bicep:39](../infra-bicep/modules/auto_shutdown.bicep#L39) |

### メモ
- リソース名は `shutdown-computevm-vm-vm-dev`。**この命名規約でないとポータルの「自動シャットダウン」欄に紐づかない**（[auto_shutdown.bicep:28-29](../infra-bicep/modules/auto_shutdown.bicep#L28-L29)）。
- `enableAutoShutdown=true` のときだけ作られる条件付きmodule（[main.bicep:115](../infra-bicep/main.bicep#L115) の `if (enableAutoShutdown)`）。
- **停止(Stop/deallocate)であって削除ではない**。翌朝はまた自分で起動する。
