// =============================================================================
// main.bicepparam
//   Safe defaults. Override sshPublicKey and allowedSshSourceAddressPrefix when
//   deploying.
// =============================================================================

using './main.bicep'

param namePrefix = 'todo'
param environment = 'dev'
param location = 'japaneast'

param bastionVmSize = 'Standard_D2as_v4'
param webVmSize = 'Standard_D2as_v4'
param adminUsername = 'azureuser'

// Replace at deploy time:
// --parameters sshPublicKey="$(Get-Content $HOME\.ssh\id_ed25519.pub -Raw)"
param sshPublicKey = 'ssh-rsa REPLACE_ME_WITH_YOUR_REAL_PUBLIC_KEY_AT_DEPLOY_TIME dummy@example.com'

// Replace at deploy time with your public IP/CIDR:
// $allowedSsh = "<your-public-ip>/32"
// --parameters allowedSshSourceAddressPrefix="$allowedSsh"
param allowedSshSourceAddressPrefix = '0.0.0.0/32'

param enableAutoShutdown = true
param autoShutdownTime = '2200'
param autoShutdownTimeZone = 'Tokyo Standard Time'

param tags = {
  project: 'azure-learning'
  managedBy: 'bicep'
}
