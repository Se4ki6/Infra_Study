@description('Storage Account 名（24字以内・小文字英数字のみ）')
param name string

@description('デプロイ先リージョン')
param location string

@description('公開Blobコンテナ名')
param containerName string = 'public-assets'

@description('タグ')
param tags object = {}

// 画像共有用に匿名Blob読み取りを許可する Storage Account
// NOTE: conventions.md の既定 allowBlobPublicAccess=false から意図的に逸脱（公開共有が目的のため）
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: name
  location: location
  tags: tags
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: true
    supportsHttpsTrafficOnly: true
  }
}

// Blob サービス（バージョニング・削除保持ポリシー）
resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    isVersioningEnabled: true
    deleteRetentionPolicy: {
      enabled: true
      days: 7
    }
    containerDeleteRetentionPolicy: {
      enabled: true
      days: 7
    }
  }
}

// 匿名読み取り専用（コンテナ一覧は不可）の公開コンテナ
resource publicContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = {
  parent: blobService
  name: containerName
  properties: {
    publicAccess: 'Blob'
  }
}

output id string = storageAccount.id
output name string = storageAccount.name
output containerName string = publicContainer.name
// endpoint は出してよいが、アクセスキーは output に出さない
output blobEndpoint string = storageAccount.properties.primaryEndpoints.blob
