targetScope = 'subscription'

@description('リソース名のプレフィックス（10字以内推奨）')
@minLength(2)
@maxLength(10)
param namePrefix string = 'public'

@description('環境識別子')
@allowed(['dev', 'stg', 'prod'])
param environment string = 'dev'

@description('デプロイ先リージョン')
param location string = 'japaneast'

@description('全リソース共通のタグ')
param tags object = {
  purpose: 'public-assets'
}

@description('公開Blobコンテナ名（画像共有用）')
param containerName string = 'public-assets'

// 命名の正規化（Terraform の locals 相当）
var prefix = toLower(namePrefix)
var env = toLower(environment)

var rgName = 'rg-${prefix}-${env}'

var commonTags = union(tags, {
  environment: env
})

// 画像共有用の公開Blobを置くための Resource Group
resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: rgName
  location: location
  tags: commonTags
}

// 一意サフィックスは RG 作成後に rg.id から生成
var storageAccountName = take('st${prefix}${env}${take(uniqueString(rg.id), 6)}', 24)

// 匿名読み取り可能な Blob コンテナを持つ Storage Account
// （画像共有が目的のため、conventions.md の既定値から意図的に逸脱している）
module storageAccount 'modules/storage_account.bicep' = {
  name: 'storageAccount'
  scope: rg
  params: {
    name: storageAccountName
    location: location
    containerName: containerName
    tags: commonTags
  }
}

output resourceGroupName string = rg.name
output storageAccountName string = storageAccount.outputs.name
output containerName string = storageAccount.outputs.containerName
output blobEndpoint string = storageAccount.outputs.blobEndpoint
