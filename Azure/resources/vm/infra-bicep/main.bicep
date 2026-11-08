// =============================================================================
// main.bicep
//   Azure VM 最小構成のオーケストレーション（subscription スコープ）。
//   RG 作成 → network → virtual_machine → (任意) auto_shutdown の順に展開する。
//   RG ごと削除すれば全リソースが消える（terraform destroy 相当）。
// =============================================================================

targetScope = 'subscription'

// ---------------------------------------------------------------------------
// パラメータ
// ---------------------------------------------------------------------------

@description('リソース名のプレフィックス（10字以内推奨）')
@minLength(2)
@maxLength(10)
param namePrefix string

@description('環境識別子')
@allowed([
  'dev'
  'stg'
  'prod'
])
param environment string

@description('デプロイ先リージョン（subscription スコープのため resourceGroup().location は使えない）')
param location string

@description('VM サイズ。B系(B1s等)は本サブスク/リージョンで在庫切れのため、japaneastで在庫確認できた2コア汎用を採用')
@allowed([
  'Standard_D2as_v4'
  'Standard_D2s_v3'
])
param vmSize string

@description('SSH ログインに使う管理ユーザー名')
@minLength(1)
param adminUsername string

@description('OpenSSH 形式の公開鍵。実デプロイ時に必ず CLI で上書きする')
param sshPublicKey string

@description('SSH を許可する送信元 IP/CIDR。既定は何も許可しないダミー。実デプロイ時に自分の IP に上書き')
param allowedSshSourceAddressPrefix string

@description('Auto-Shutdown を有効化するか')
param enableAutoShutdown bool

@description('自動シャットダウン時刻（HHmm 形式）')
param autoShutdownTime string

@description('自動シャットダウン用タイムゾーン（Windows TZ ID）')
param autoShutdownTimeZone string

@description('共通タグ')
param tags object

// ---------------------------------------------------------------------------
// 命名の正規化（一意 suffix は不要。RG 内一意で十分）
// ---------------------------------------------------------------------------
var prefix = toLower(namePrefix)
var env    = toLower(environment)

var rgName     = 'rg-${prefix}-${env}'
var vmName     = 'vm-${prefix}-${env}'
var osDiskName = 'osdisk-${prefix}-${env}'

// environment タグを必ず付与する共通タグ
var commonTags = union(tags, {
  environment: env
})

// ---------------------------------------------------------------------------
// リソース定義
// ---------------------------------------------------------------------------

// すべての VM 関連リソースの土台となる Resource Group
resource rg 'Microsoft.Resources/resourceGroups@2024-11-01' = {
  name: rgName
  location: location
  tags: commonTags
}

// VNet / Subnet / NSG / Public IP / NIC をまとめて作成
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

// VM 本体（OS ディスク含む）。NIC ID を network から受け取る
module virtualMachine 'modules/virtual_machine.bicep' = {
  name: 'virtualMachine'
  scope: rg
  params: {
    vmName: vmName
    location: location
    vmSize: vmSize
    adminUsername: adminUsername
    sshPublicKey: sshPublicKey
    nicId: network.outputs.nicId
    osDiskName: osDiskName
    tags: commonTags
  }
}

// Auto-Shutdown（DevTestLab schedule）。enableAutoShutdown=true のときだけ作成
module autoShutdown 'modules/auto_shutdown.bicep' = if (enableAutoShutdown) {
  name: 'autoShutdown'
  scope: rg
  params: {
    vmId: virtualMachine.outputs.vmId
    vmName: virtualMachine.outputs.vmName
    location: location
    time: autoShutdownTime
    timeZoneId: autoShutdownTimeZone
    tags: commonTags
  }
}

// ---------------------------------------------------------------------------
// 出力（機微情報は出さない。公開鍵・パスワード相当は output しない）
// ---------------------------------------------------------------------------

@description('作成された Resource Group 名')
output resourceGroupName string = rg.name

@description('VM 名')
output vmName string = virtualMachine.outputs.vmName

@description('SSH 接続先の Public IP アドレス')
output publicIpAddress string = network.outputs.publicIpAddress
