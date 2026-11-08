// =============================================================================
// auto_shutdown.bicep
//   DevTestLab Schedule で毎日 1 回 VM を自動シャットダウン（消し忘れ防止）。
//   schedule の name は `shutdown-computevm-{vmName}` という DevTestLab 規約名にする。
//   この schedule は VM スコープのリソースなので、VM 削除時に一緒に消える。
// =============================================================================

@description('対象 VM のリソース ID')
param vmId string

@description('対象 VM 名（schedule 名の生成に使用）')
param vmName string

@description('デプロイ先リージョン')
param location string

@description('シャットダウン時刻（HHmm 形式、例: 2200）')
param time string = '2200'

@description('Windows タイムゾーン ID（例: Tokyo Standard Time）')
param timeZoneId string = 'Tokyo Standard Time'

@description('共通タグ')
param tags object = {}

// DevTestLab Schedule。targetResourceId に対象 VM を指定して自動停止を設定する
resource shutdownSchedule 'Microsoft.DevTestLab/schedules@2018-09-15' = {
  // DevTestLab の規約名: `shutdown-computevm-{vmName}` でないとポータルから VM の Auto-shutdown として認識されない
  name: 'shutdown-computevm-${vmName}'
  location: location
  tags: tags
  properties: {
    status: 'Enabled'
    taskType: 'ComputeVmShutdownTask'
    dailyRecurrence: {
      time: time
    }
    timeZoneId: timeZoneId
    targetResourceId: vmId
    notificationSettings: {
      // 通知は今回無効。必要になったら status: 'Enabled' + emailRecipient を渡す
      // 注: status: 'Disabled' のとき timeInMinutes は機能しない。
      //      将来 Enabled に変更する際は通知時間も見直すこと。
      status: 'Disabled'
      timeInMinutes: 30
    }
  }
}
