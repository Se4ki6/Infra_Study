# Bicep 初心者向け実装解説

このドキュメントは、`resource-project/bastion-web-todo` の Bicep 実装を初めて読む人向けに説明します。

今回作ったものは、単純な「VM を 2 台立てる」構成ではありません。ポイントは、TODO アプリの HTTP はインターネットに公開しつつ、管理用の SSH は踏み台サーバー経由に絞っていることです。

## 作成する構成

```text
Internet
  |
  | SSH 22/tcp
  | allowedSshSourceAddressPrefix で指定した IP だけ許可
  v
Bastion VM
  Public IP: あり
  Private IP: 10.10.1.10
  |
  | SSH 22/tcp
  | 踏み台サブネットからだけ許可
  v
Web VM
  Public IP: あり
  Private IP: 10.10.2.10
  HTTP 80/tcp はインターネットから許可
  Nginx で TODO アプリをホスティング
```

外部から直接アクセスできる入口は 2 つあります。踏み台 VM は SSH 用、Web VM は HTTP 用です。Web VM に対する SSH はインターネットから許可せず、踏み台 VM 経由に限定します。

## ファイル構成

```text
resource-project/bastion-web-todo/
  README.md
  docs/
    implementation-guide.md
  infra-bicep/
    main.bicep
    main.bicepparam
    main.json
    cloud-init/
      web-todo.yaml
    modules/
      network.bicep
      virtual_machine.bicep
      auto_shutdown.bicep
```

初心者は、次の順番で読むと理解しやすいです。

1. `README.md`: デプロイ方法と接続方法
2. `infra-bicep/main.bicepparam`: 変更する値
3. `infra-bicep/main.bicep`: 全体の組み立て
4. `infra-bicep/modules/network.bicep`: 通信制御
5. `infra-bicep/modules/virtual_machine.bicep`: VM の作り方
6. `infra-bicep/cloud-init/web-todo.yaml`: Web VM 起動時のアプリ配置

NGINX そのものに不慣れな場合は、先に [nginx-guide.md](nginx-guide.md) を読むと `cloud-init/web-todo.yaml` の意味を追いやすくなります。

## Bicep の基本

Bicep は Azure リソースをコードで定義するための言語です。Terraform のように「ほしい状態」を書き、Azure にデプロイするとその状態に近づけてくれます。

Bicep には主に次の要素があります。

```bicep
param location string
var rgName = 'rg-example-dev'

resource rg 'Microsoft.Resources/resourceGroups@2024-11-01' = {
  name: rgName
  location: location
}

output resourceGroupName string = rg.name
```

`param` は外から渡す値です。リージョン、VM サイズ、SSH 公開鍵など、環境によって変わるものに使います。

`var` は Bicep ファイル内で使う一時的な値です。リソース名の組み立てなどに使います。

`resource` は Azure に作る実体です。Resource Group、VNet、Public IP、NIC、VM などをここで定義します。

`output` はデプロイ後に表示したい値です。今回だと踏み台の Public IP や SSH コマンドを出しています。

## main.bicep の役割

`main.bicep` は全体の入り口です。細かいリソース定義を全部ここに書くのではなく、役割ごとにモジュールへ分けています。

```bicep
targetScope = 'subscription'
```

これは「サブスクリプションスコープでデプロイする」という意味です。今回の Bicep は Resource Group 自体も作るため、Resource Group の外側である subscription scope にしています。

Resource Group を作る部分は次です。

```bicep
resource rg 'Microsoft.Resources/resourceGroups@2024-11-01' = {
  name: rgName
  location: location
  tags: commonTags
}
```

`Microsoft.Resources/resourceGroups@2024-11-01` は、リソースの種類と API バージョンです。Bicep では多くの Azure リソースがこの形式で書かれます。

## module とは

`module` は、別の Bicep ファイルを呼び出す仕組みです。今回の `main.bicep` は次のモジュールを呼び出しています。

```bicep
module network 'modules/network.bicep' = {
  name: 'network'
  scope: rg
  params: {
    namePrefix: prefix
    environment: env
    location: location
    allowedSshSourceAddressPrefix: allowedSshSourceAddressPrefix
    tags: commonTags
  }
}
```

重要なのは `scope: rg` です。`main.bicep` 自体は subscription scope ですが、VNet や VM は Resource Group の中に作る必要があります。そのため、モジュールのデプロイ先を `rg` にしています。

モジュールを使う理由は、ファイルを役割ごとに分けて読みやすくするためです。

- `network.bicep`: ネットワークだけを担当
- `virtual_machine.bicep`: VM 本体だけを担当
- `auto_shutdown.bicep`: 自動停止だけを担当

## パラメーターと bicepparam

`main.bicep` には次のようなパラメーターがあります。

```bicep
param namePrefix string
param environment string
param location string
param sshPublicKey string
param allowedSshSourceAddressPrefix string
```

これらの値を別ファイルにまとめたものが `main.bicepparam` です。

```bicep
using './main.bicep'

param namePrefix = 'todo'
param environment = 'dev'
param location = 'japaneast'
```

`main.bicepparam` には安全側のダミー値も入れています。

```bicep
param allowedSshSourceAddressPrefix = '0.0.0.0/32'
```

これは「何も許可しない」ための値です。実際にデプロイするときは、自分の Public IP に差し替えます。

```powershell
$myIp = (Invoke-RestMethod 'https://api.ipify.org')
$allowedSsh = "$myIp/32"
$sshKey = Get-Content $HOME\.ssh\id_ed25519.pub -Raw

az deployment sub create `
  --location japaneast `
  --parameters .\main.bicepparam `
  --parameters sshPublicKey="$sshKey" allowedSshSourceAddressPrefix="$allowedSsh"
```

## ネットワーク設計

ネットワークは `modules/network.bicep` で作っています。

作成している主なリソースは次です。

- VNet
- 踏み台用 Subnet
- Web 用 Subnet
- 踏み台用 NSG
- Web 用 NSG
- 踏み台用 Public IP
- Web 用 Public IP
- 踏み台用 NIC
- Web 用 NIC

アドレスは次のように分けています。

```bicep
var vnetAddressPrefix = '10.10.0.0/16'
var bastionSubnetPrefix = '10.10.1.0/24'
var webSubnetPrefix = '10.10.2.0/24'
var bastionPrivateIp = '10.10.1.10'
var webPrivateIp = '10.10.2.10'
```

`10.10.0.0/16` という大きな VNet の中に、踏み台用と Web 用の 2 つのサブネットを作っています。

## NSG による通信制御

NSG は Network Security Group の略で、Azure の仮想ネットワークで使うファイアウォールのようなものです。

踏み台 VM 側の NSG では、SSH を指定 IP からだけ許可しています。

```bicep
sourceAddressPrefix: allowedSshSourceAddressPrefix
destinationPortRange: '22'
```

つまり、デプロイ時に `allowedSshSourceAddressPrefix` に `203.0.113.10/32` を渡した場合、その IP からだけ踏み台 VM に SSH できます。

Web VM 側の NSG では、SSH は踏み台サブネットからだけ許可し、HTTP はインターネットから許可しています。

```bicep
sourceAddressPrefix: bastionSubnetPrefix
destinationPortRange: '22'
```

```bicep
sourceAddressPrefix: 'Internet'
destinationPortRange: '80'
```

このため、Web VM の TODO アプリはブラウザから直接開けます。一方で、Web VM への SSH は踏み台サブネット以外から受け付けません。

Azure NSG には既定で `DenyAllInbound` があります。そのため、明示的に許可していない受信通信は拒否されます。

## Web VM に Public IP を付ける理由

`network.bicep` では、踏み台 NIC と Web NIC の両方に Public IP を関連付けています。

```bicep
publicIPAddress: {
  id: bastionPublicIp.id
}
```

Web NIC 側は、TODO アプリの HTTP 公開に使います。

```bicep
resource webNic 'Microsoft.Network/networkInterfaces@2024-07-01' = {
  name: webNicName
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddress: webPrivateIp
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnet.name, webSubnetName)
          }
          publicIPAddress: {
            id: webPublicIp.id
          }
        }
      }
    ]
  }
}
```

ただし、Public IP を付けるだけでは通信は通りません。Web VM 側の NSG で HTTP 80 番をインターネットから許可することで、ブラウザから `http://<web-public-ip>` で TODO アプリに到達できるようになります。SSH 22 番は踏み台サブネットからだけ許可しているため、管理経路は踏み台経由に絞られます。

## VM モジュール

VM 本体は `modules/virtual_machine.bicep` で定義しています。このモジュールは踏み台 VM と Web VM の両方で使い回しています。

```bicep
module bastionVm 'modules/virtual_machine.bicep' = {
  name: 'bastionVm'
  scope: rg
  params: {
    vmName: bastionVmName
    nicId: network.outputs.bastionNicId
  }
}
```

```bicep
module webVm 'modules/virtual_machine.bicep' = {
  name: 'webVm'
  scope: rg
  params: {
    vmName: webVmName
    nicId: network.outputs.webNicId
    customData: base64(loadTextContent('cloud-init/web-todo.yaml'))
  }
}
```

踏み台 VM と Web VM の違いは、渡している NIC と `customData` です。

踏み台 VM には Public IP 付き NIC を渡します。Web VM には Private IP のみの NIC を渡します。

Web VM にはさらに `customData` を渡しています。これは VM 初回起動時に実行される cloud-init の内容です。

## SSH 鍵認証

VM モジュールではパスワードログインを無効にしています。

```bicep
linuxConfiguration: {
  disablePasswordAuthentication: true
  ssh: {
    publicKeys: [
      {
        path: '/home/${adminUsername}/.ssh/authorized_keys'
        keyData: sshPublicKey
      }
    ]
  }
}
```

`sshPublicKey` に渡した公開鍵が、VM 内の `authorized_keys` に登録されます。秘密鍵はローカル PC 側に残し、Azure へ渡すのは公開鍵だけです。

## cloud-init で TODO アプリを入れる

Web VM には `cloud-init/web-todo.yaml` を渡しています。

```bicep
customData: base64(loadTextContent('cloud-init/web-todo.yaml'))
```

`loadTextContent` はファイルの中身を Bicep に読み込む関数です。Azure VM の `customData` は Base64 文字列が必要なため、`base64(...)` で変換しています。

cloud-init 側では、Nginx をインストールしています。

```yaml
package_update: true
packages:
  - nginx
```

その後、`/var/www/html/index.html` に TODO アプリの HTML を書き込んでいます。

```yaml
write_files:
  - path: /var/www/html/index.html
```

最後に Nginx を有効化して再起動します。

```yaml
runcmd:
  - systemctl enable nginx
  - systemctl restart nginx
```

この仕組みにより、Web VM が起動した時点で TODO アプリが動く状態になります。

## output の使い方

`main.bicep` の最後には output を定義しています。

```bicep
output bastionPublicIpAddress string = network.outputs.bastionPublicIpAddress
output webPrivateIpAddress string = network.outputs.webPrivateIpAddress
output webPublicIpAddress string = network.outputs.webPublicIpAddress
```

output はデプロイ完了後に Azure CLI の結果として表示されます。IP アドレスだけでなく、SSH コマンドも出すようにしています。

```bicep
output webSshCommand string = 'ssh -J ${adminUsername}@${network.outputs.bastionPublicIpAddress} ${adminUsername}@${network.outputs.webPrivateIpAddress}'
```

`-J` は SSH の ProxyJump です。踏み台 VM を経由して Web VM に SSH するために使います。

TODO アプリを手元のブラウザで見る場合は、Web VM の Public IP にアクセスします。

```bicep
output todoAppUrl string = 'http://${network.outputs.webPublicIpAddress}'
```

この URL を開くと、通信は次のように流れます。

```text
Local browser
  -> Web VM Public IP:80
  -> Web VM:80
```

## 自動シャットダウン

`modules/auto_shutdown.bicep` では、DevTestLab の schedule リソースを使って VM を毎日停止します。

```bicep
resource shutdownSchedule 'Microsoft.DevTestLab/schedules@2018-09-15' = {
  name: 'shutdown-computevm-${vmName}'
  properties: {
    status: 'Enabled'
    taskType: 'ComputeVmShutdownTask'
    dailyRecurrence: {
      time: time
    }
    timeZoneId: timeZoneId
    targetResourceId: vmId
  }
}
```

`main.bicep` では `enableAutoShutdown` が `true` のときだけ作成します。

```bicep
module webAutoShutdown 'modules/auto_shutdown.bicep' = if (enableAutoShutdown) {
  name: 'webAutoShutdown'
  scope: rg
  params: {
    vmId: webVm.outputs.vmId
    vmName: webVm.outputs.vmName
  }
}
```

`if (enableAutoShutdown)` は Bicep の条件付きデプロイです。不要な場合は `main.bicepparam` で `false` にできます。

## 依存関係

Bicep は、多くの場合リソース参照から依存関係を自動で判断します。

たとえば VM は NIC ID を受け取っています。

```bicep
nicId: network.outputs.webNicId
```

この場合、Bicep は「network モジュールが終わってから Web VM を作る必要がある」と判断できます。

明示的な `dependsOn` を書かなくてもよい場面が多いのは、Bicep の読みやすい点です。

## セキュリティ上の意図

今回の構成では、次の考え方を入れています。

- Web VM の HTTP はインターネットから許可する
- 踏み台 VM の SSH は自分の IP だけ許可する
- Web VM の SSH は踏み台サブネットだけ許可する
- VM ログインは SSH 鍵認証だけにする
- パスワードログインは無効にする

学習用途としては小さい構成ですが、「公開する入口を最小化する」という実運用でも重要な考え方を入れています。

## 動作確認の流れ

デプロイ後は、まず踏み台 VM に SSH できるか確認します。

```powershell
ssh azureuser@<bastion-public-ip>
```

次に、ローカル PC から ProxyJump で Web VM に入れるか確認します。

```powershell
ssh -J azureuser@<bastion-public-ip> azureuser@10.10.2.10
```

TODO アプリは Web VM の Public IP で確認します。

```text
http://<web-public-ip>
```

## よくある変更ポイント

VM サイズを変えたい場合は `main.bicepparam` を変更します。

```bicep
param bastionVmSize = 'Standard_D2as_v4'
param webVmSize = 'Standard_D2as_v4'
```

リージョンを変えたい場合も `main.bicepparam` を変更します。

```bicep
param location = 'japaneast'
```

Auto-shutdown を無効にしたい場合は次のようにします。

```bicep
param enableAutoShutdown = false
```

アドレス帯を変えたい場合は `modules/network.bicep` の次の値を変更します。

```bicep
var vnetAddressPrefix = '10.10.0.0/16'
var bastionSubnetPrefix = '10.10.1.0/24'
var webSubnetPrefix = '10.10.2.0/24'
```

ただし、既存の VNet やオンプレミスネットワークと接続する予定がある場合は、IP アドレス帯が重複しないように先に設計してください。

## この実装でまだ扱っていないこと

この構成は Bicep 学習用のシンプルなサンプルです。実運用では、次のような追加検討が必要です。

- Azure Bastion サービスを使うかどうか
- VM の監視、ログ、アラート
- OS 更新の運用
- TODO アプリの永続データ保存
- HTTPS 化
- Web サーバーの冗長化
- Azure Firewall や Private DNS などのネットワーク設計

まずは今回の構成で、Bicep の `param`、`var`、`resource`、`module`、`output` と、Azure の VNet、Subnet、NSG、NIC、VM の関係を理解するのが目的です。
