// =============================================================================
// main.bicep
//   Bastion VM + public HTTP Web VM for a small TODO app.
//   Subscription scope: creates the resource group, then deploys all resources
//   into that group.
// =============================================================================

targetScope = 'subscription'

@description('Resource name prefix. Keep it short because VM names have length limits.')
@minLength(2)
@maxLength(10)
param namePrefix string

@description('Environment name.')
@allowed([
  'dev'
  'stg'
  'prod'
])
param environment string

@description('Azure region.')
param location string

@description('VM size for the bastion server.')
@allowed([
  'Standard_B1s'
  'Standard_B1ms'
  'Standard_D2as_v4'
  'Standard_D2s_v3'
])
param bastionVmSize string = 'Standard_D2as_v4'

@description('VM size for the web server.')
@allowed([
  'Standard_B1s'
  'Standard_B1ms'
  'Standard_D2as_v4'
  'Standard_D2s_v3'
])
param webVmSize string = 'Standard_D2as_v4'

@description('Linux admin user name for both VMs.')
@minLength(1)
param adminUsername string

@description('OpenSSH public key used for SSH login.')
param sshPublicKey string

@description('Source IP/CIDR allowed to SSH into the bastion VM. Use your public IP with /32.')
param allowedSshSourceAddressPrefix string

@description('Enable daily auto-shutdown for both VMs.')
param enableAutoShutdown bool = true

@description('Auto-shutdown time in HHmm format.')
param autoShutdownTime string = '2200'

@description('Windows time zone ID for auto-shutdown.')
param autoShutdownTimeZone string = 'Tokyo Standard Time'

@description('Common tags.')
param tags object = {}

var prefix = toLower(namePrefix)
var env = toLower(environment)

var rgName = 'rg-${prefix}-${env}'
var bastionVmName = 'vm-${prefix}-bas-${env}'
var webVmName = 'vm-${prefix}-web-${env}'

var commonTags = union(tags, {
  environment: env
  workload: 'bastion-web-todo'
})

resource rg 'Microsoft.Resources/resourceGroups@2024-11-01' = {
  name: rgName
  location: location
  tags: commonTags
}

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

module bastionVm 'modules/virtual_machine.bicep' = {
  name: 'bastionVm'
  scope: rg
  params: {
    vmName: bastionVmName
    location: location
    vmSize: bastionVmSize
    adminUsername: adminUsername
    sshPublicKey: sshPublicKey
    nicId: network.outputs.bastionNicId
    osDiskName: 'osdisk-${prefix}-bas-${env}'
    tags: commonTags
  }
}

module webVm 'modules/virtual_machine.bicep' = {
  name: 'webVm'
  scope: rg
  params: {
    vmName: webVmName
    location: location
    vmSize: webVmSize
    adminUsername: adminUsername
    sshPublicKey: sshPublicKey
    nicId: network.outputs.webNicId
    osDiskName: 'osdisk-${prefix}-web-${env}'
    customData: base64(loadTextContent('cloud-init/web-todo.yaml'))
    tags: commonTags
  }
}

module bastionAutoShutdown 'modules/auto_shutdown.bicep' = if (enableAutoShutdown) {
  name: 'bastionAutoShutdown'
  scope: rg
  params: {
    vmId: bastionVm.outputs.vmId
    vmName: bastionVm.outputs.vmName
    location: location
    time: autoShutdownTime
    timeZoneId: autoShutdownTimeZone
    tags: commonTags
  }
}

module webAutoShutdown 'modules/auto_shutdown.bicep' = if (enableAutoShutdown) {
  name: 'webAutoShutdown'
  scope: rg
  params: {
    vmId: webVm.outputs.vmId
    vmName: webVm.outputs.vmName
    location: location
    time: autoShutdownTime
    timeZoneId: autoShutdownTimeZone
    tags: commonTags
  }
}

@description('Resource group name.')
output resourceGroupName string = rg.name

@description('Bastion VM name.')
output bastionVmName string = bastionVm.outputs.vmName

@description('Web VM name.')
output webVmName string = webVm.outputs.vmName

@description('Bastion public IP address.')
output bastionPublicIpAddress string = network.outputs.bastionPublicIpAddress

@description('Web VM private IP address.')
output webPrivateIpAddress string = network.outputs.webPrivateIpAddress

@description('Web VM public IP address.')
output webPublicIpAddress string = network.outputs.webPublicIpAddress

@description('SSH command for the bastion VM.')
output bastionSshCommand string = 'ssh ${adminUsername}@${network.outputs.bastionPublicIpAddress}'

@description('SSH command for the private web VM through the bastion VM.')
output webSshCommand string = 'ssh -J ${adminUsername}@${network.outputs.bastionPublicIpAddress} ${adminUsername}@${network.outputs.webPrivateIpAddress}'

@description('Public URL for browsing the TODO app.')
output todoAppUrl string = 'http://${network.outputs.webPublicIpAddress}'
