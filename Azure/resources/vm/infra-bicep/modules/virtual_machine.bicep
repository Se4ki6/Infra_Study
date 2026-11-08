// =============================================================================
// virtual_machine.bicep
//   Ubuntu 22.04 LTS の最小構成 VM 本体。
//   SSH 鍵認証のみ。adminPassword は使用しない。
// =============================================================================

@description('VM 名（CAF 略語 + プレフィックス + 環境）')
param vmName string

@description('デプロイ先リージョン')
param location string

@description('VM サイズ。B系はjapaneastで在庫切れのため2コア汎用を採用')
@allowed([
  'Standard_D2as_v4'
  'Standard_D2s_v3'
])
param vmSize string = 'Standard_D2as_v4'

@description('SSH ログインに使う管理ユーザー名')
@minLength(1)
param adminUsername string

@description('OpenSSH 形式の公開鍵。実デプロイ時に CLI 引数で上書き想定')
param sshPublicKey string

@description('VM を接続する NIC リソース ID')
param nicId string

@description('OS Disk 名（osdisk-{prefix}-{env} 形式）')
param osDiskName string

@description('共通タグ')
param tags object = {}

// Ubuntu 22.04 LTS Gen2（Canonical 公式）。`latest` でメンテ済みイメージに追従
var imageReference = {
  publisher: 'Canonical'
  offer: '0001-com-ubuntu-server-jammy'
  sku: '22_04-lts-gen2'
  version: 'latest'
}

// 最小構成の Linux VM。鍵認証のみ・Boot Diagnostics はマネージドストレージ方式
resource vm 'Microsoft.Compute/virtualMachines@2024-07-01' = {
  name: vmName
  location: location
  tags: tags
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      imageReference: imageReference
      osDisk: {
        name: osDiskName
        createOption: 'FromImage'
        caching: 'ReadWrite'
        diskSizeGB: 30
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      // SSH 鍵認証のみ。adminPassword は意図的に未指定
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
        provisionVMAgent: true
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nicId
          properties: {
            primary: true
          }
        }
      ]
    }
    // Boot Diagnostics をマネージドストレージで有効化（追加 Storage Account 不要）
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
}

// ---- 出力（auto_shutdown が参照） ----
@description('Auto-Shutdown モジュールが参照する VM リソース ID')
output vmId string = vm.id

@description('VM 名（main から再公開するため）')
output vmName string = vm.name
