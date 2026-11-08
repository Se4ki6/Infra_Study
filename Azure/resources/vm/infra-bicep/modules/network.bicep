// =============================================================================
// network.bicep
//   VNet / Subnet / NSG / Public IP / NIC をまとめて作成する最小ネットワーク。
//   VM モジュールに NIC ID を渡すことで疎結合に保つ。
// =============================================================================

@description('リソース名のプレフィックス（小文字正規化済みを推奨）')
param namePrefix string

@description('環境識別子（dev / stg / prod）')
param environment string

@description('デプロイ先リージョン')
param location string

@description('SSH を許可する送信元 IP/CIDR。0.0.0.0/32 は何も許可しないダミー値')
param allowedSshSourceAddressPrefix string

@description('共通タグ')
param tags object = {}

// ---- 命名（CAF 略語 + {prefix}-{env}） ----
var vnetName   = 'vnet-${namePrefix}-${environment}'
var subnetName = 'snet-default'
var nsgName    = 'nsg-${namePrefix}-${environment}'
var pipName    = 'pip-${namePrefix}-${environment}'
var nicName    = 'nic-${namePrefix}-${environment}'

// ---- アドレス空間（最小） ----
var vnetAddressPrefix   = '10.0.0.0/16'
var subnetAddressPrefix = '10.0.0.0/24'

// SSH(22/TCP) を allowedSshSourceAddressPrefix からのみ許可する NSG
// その他の受信は Azure 既定の DenyAllInbound に任せる（明示 Deny は書かない）
resource nsg 'Microsoft.Network/networkSecurityGroups@2024-07-01' = {
  name: nsgName
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'Allow-SSH-From-MyIP'
        properties: {
          description: 'SSH を指定送信元 IP のみ許可'
          priority: 1000
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: allowedSshSourceAddressPrefix
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '22'
        }
      }
    ]
  }
}

// VM を配置するためのプライベートネットワーク本体
resource vnet 'Microsoft.Network/virtualNetworks@2024-07-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
  }
}

// VNet 内のセグメント。NIC をここに配置し、NSG をサブネットに紐付ける
resource subnet 'Microsoft.Network/virtualNetworks/subnets@2024-07-01' = {
  parent: vnet
  name: subnetName
  properties: {
    addressPrefix: subnetAddressPrefix
    networkSecurityGroup: {
      id: nsg.id
    }
  }
}

// VM への外部到達点。Standard SKU + Static（Basic SKU は 2025-09-30 でリタイア済）
resource publicIp 'Microsoft.Network/publicIPAddresses@2024-07-01' = {
  name: pipName
  location: location
  tags: tags
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
}

// VM と VNet/Public IP を接続する NIC（NSG はサブネット側に付与）
resource nic 'Microsoft.Network/networkInterfaces@2024-07-01' = {
  name: nicName
  location: location
  tags: tags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnet.id
          }
          publicIPAddress: {
            id: publicIp.id
          }
        }
      }
    ]
  }
}

// ---- 出力（後続モジュール / 接続情報） ----
@description('VM モジュールに渡す NIC リソース ID')
output nicId string = nic.id

@description('SSH 接続先の Public IP アドレス（Static なので作成時点で確定）')
// 注: Static でも作成直後 / what-if の段階では空文字列で返ることがある（既知の ARM 応答挙動）。
//      実際の IP は `az network public-ip show -g <rg> -n <pipName>` で再確認する。
output publicIpAddress string = publicIp.properties.ipAddress
