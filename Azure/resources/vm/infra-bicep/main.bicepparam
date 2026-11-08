// =============================================================================
// main.bicepparam
//   ダミー値を入れた params。実デプロイ時には CLI の --parameters で
//   sshPublicKey と allowedSshSourceAddressPrefix を必ず上書きすること。
// =============================================================================

using './main.bicep'

param namePrefix = 'vm'
param environment = 'dev'
param location = 'japaneast'

param vmSize = 'Standard_D2as_v4'
param adminUsername = 'azureuser'

// ダミー公開鍵。実デプロイ時に CLI 引数で必ず差し替える
// 例: --parameters sshPublicKey="$(Get-Content $HOME\.ssh\id_ed25519.pub -Raw)"
param sshPublicKey = 'ssh-rsa REPLACE_ME_WITH_YOUR_REAL_PUBLIC_KEY_AT_DEPLOY_TIME dummy@example.com'

// 何も許可しない安全側のダミー。実デプロイ時に自分の IP/32 に上書きする
// 例: --parameters allowedSshSourceAddressPrefix="<myip>/32"
param allowedSshSourceAddressPrefix = '0.0.0.0/32'

// Auto-Shutdown（毎日 22:00 JST に停止）
param enableAutoShutdown = true
param autoShutdownTime = '2200'
param autoShutdownTimeZone = 'Tokyo Standard Time'

param tags = {
  project: 'azure-learning'
  managedBy: 'bicep'
  workload: 'vm-minimal'
}
