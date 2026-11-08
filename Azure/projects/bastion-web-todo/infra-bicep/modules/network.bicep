// =============================================================================
// network.bicep
//   Network for a public bastion VM and public HTTP web VM.
// =============================================================================

@description('Resource name prefix.')
param namePrefix string

@description('Environment name.')
param environment string

@description('Azure region.')
param location string

@description('Source IP/CIDR allowed to SSH into the bastion VM.')
param allowedSshSourceAddressPrefix string

@description('Common tags.')
param tags object = {}

var vnetName = 'vnet-${namePrefix}-${environment}'
var bastionSubnetName = 'snet-bastion'
var webSubnetName = 'snet-web'
var bastionNsgName = 'nsg-${namePrefix}-bas-${environment}'
var webNsgName = 'nsg-${namePrefix}-web-${environment}'
var bastionPipName = 'pip-${namePrefix}-bas-${environment}'
var webPipName = 'pip-${namePrefix}-web-${environment}'
var bastionNicName = 'nic-${namePrefix}-bas-${environment}'
var webNicName = 'nic-${namePrefix}-web-${environment}'

var vnetAddressPrefix = '10.10.0.0/16'
var bastionSubnetPrefix = '10.10.1.0/24'
var webSubnetPrefix = '10.10.2.0/24'
var bastionPrivateIp = '10.10.1.10'
var webPrivateIp = '10.10.2.10'

// 踏み台 VM への SSH を許可する NSG を作成する
resource bastionNsg 'Microsoft.Network/networkSecurityGroups@2024-07-01' = {
  name: bastionNsgName
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'Allow-SSH-From-Allowed-Source'
        properties: {
          description: 'Allow SSH to the bastion VM only from the approved source.'
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

// Web VM への SSH は踏み台経由、HTTP はインターネットから許可する NSG を作成する
resource webNsg 'Microsoft.Network/networkSecurityGroups@2024-07-01' = {
  name: webNsgName
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'Allow-SSH-From-Bastion-Subnet'
        properties: {
          description: 'Allow SSH to the web VM only from the bastion subnet.'
          priority: 1000
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: bastionSubnetPrefix
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '22'
        }
      }
      {
        name: 'Allow-HTTP-From-Internet'
        properties: {
          description: 'Allow the TODO app to be reached from the internet.'
          priority: 1010
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: 'Internet'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '80'
        }
      }
    ]
  }
}

// 踏み台用と Web 用のサブネットを持つ VNet を作成する
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
    subnets: [
      {
        name: bastionSubnetName
        properties: {
          addressPrefix: bastionSubnetPrefix
          networkSecurityGroup: {
            id: bastionNsg.id
          }
        }
      }
      {
        name: webSubnetName
        properties: {
          addressPrefix: webSubnetPrefix
          networkSecurityGroup: {
            id: webNsg.id
          }
        }
      }
    ]
  }
}

// 踏み台 VM に割り当てる Public IP を作成する
resource bastionPublicIp 'Microsoft.Network/publicIPAddresses@2024-07-01' = {
  name: bastionPipName
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

// Web VM の HTTP 公開に使う Public IP を作成する
resource webPublicIp 'Microsoft.Network/publicIPAddresses@2024-07-01' = {
  name: webPipName
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

// 踏み台 VM に接続する NIC を作成する
resource bastionNic 'Microsoft.Network/networkInterfaces@2024-07-01' = {
  name: bastionNicName
  location: location
  tags: tags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddress: bastionPrivateIp
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnet.name, bastionSubnetName)
          }
          publicIPAddress: {
            id: bastionPublicIp.id
          }
        }
      }
    ]
  }
}

// Web VM に接続する NIC を作成し、HTTP 公開用 Public IP を関連付ける
resource webNic 'Microsoft.Network/networkInterfaces@2024-07-01' = {
  name: webNicName
  location: location
  tags: tags
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

@description('Bastion VM NIC resource ID.')
output bastionNicId string = bastionNic.id

@description('Web VM NIC resource ID.')
output webNicId string = webNic.id

@description('Bastion public IP address.')
output bastionPublicIpAddress string = bastionPublicIp.properties.ipAddress

@description('Web VM private IP address.')
output webPrivateIpAddress string = webPrivateIp

@description('Web VM public IP address.')
output webPublicIpAddress string = webPublicIp.properties.ipAddress
