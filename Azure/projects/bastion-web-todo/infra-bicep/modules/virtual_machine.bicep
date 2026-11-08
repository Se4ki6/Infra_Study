// =============================================================================
// virtual_machine.bicep
//   Reusable Ubuntu VM module with SSH key authentication.
// =============================================================================

@description('VM name.')
param vmName string

@description('Azure region.')
param location string

@description('VM size.')
@allowed([
  'Standard_B1s'
  'Standard_B1ms'
  'Standard_D2as_v4'
  'Standard_D2s_v3'
])
param vmSize string = 'Standard_D2as_v4'

@description('Linux admin user name.')
@minLength(1)
param adminUsername string

@description('OpenSSH public key.')
param sshPublicKey string

@description('NIC resource ID.')
param nicId string

@description('OS disk name.')
param osDiskName string

@description('Base64-encoded cloud-init data. Leave empty when not needed.')
param customData string = ''

@description('Common tags.')
param tags object = {}

var imageReference = {
  publisher: 'Canonical'
  offer: '0001-com-ubuntu-server-jammy'
  sku: '22_04-lts-gen2'
  version: 'latest'
}

var baseOsProfile = {
  computerName: vmName
  adminUsername: adminUsername
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

var osProfile = empty(customData) ? baseOsProfile : union(baseOsProfile, {
  customData: customData
})

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
    osProfile: osProfile
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
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
}

@description('VM resource ID.')
output vmId string = vm.id

@description('VM name.')
output vmName string = vm.name
