// =============================================================================
// auto_shutdown.bicep
//   Daily VM auto-shutdown using DevTestLab schedules.
// =============================================================================

@description('Target VM resource ID.')
param vmId string

@description('Target VM name.')
param vmName string

@description('Azure region.')
param location string

@description('Shutdown time in HHmm format.')
param time string = '2200'

@description('Windows time zone ID.')
param timeZoneId string = 'Tokyo Standard Time'

@description('Common tags.')
param tags object = {}

resource shutdownSchedule 'Microsoft.DevTestLab/schedules@2018-09-15' = {
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
      status: 'Disabled'
      timeInMinutes: 30
    }
  }
}
