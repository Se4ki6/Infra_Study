# Bicep 雛形

`.codex/rules/bicep-conventions.md` の規約に沿った最小テンプレ。実装時はここをベースに、**公式 docs で apiVersion とプロパティを確認してから**埋める。

## main.bicep（RG 内デプロイ）

```bicep
// リソース名のプレフィックス（例: app）
@description('リソース名のプレフィックス（10字以内推奨）')
@minLength(2)
@maxLength(10)
param namePrefix string

// 環境識別子
@description('環境識別子')
@allowed(['dev', 'stg', 'prod'])
param environment string = 'dev'

@description('デプロイ先リージョン')
param location string = resourceGroup().location

@description('全リソース共通のタグ')
param tags object = {}

// 命名の正規化と一意 suffix（Terraform の locals 相当）
var prefix = toLower(namePrefix)
var env = toLower(environment)
var suffix = take(uniqueString(resourceGroup().id), 6)

var storageAccountName = take('st${prefix}${env}${suffix}', 24)
var logAnalyticsName = 'log-${prefix}-${env}'
var appInsightsName = 'appi-${prefix}-${env}'

var commonTags = union(tags, {
  environment: env
})

// Function App が利用するストレージとデプロイ用コンテナを作成する
module storageAccount 'modules/storage_account.bicep' = {
  name: 'storageAccount'
  params: {
    name: storageAccountName
    location: location
    deploymentContainerName: 'app-package'
    tags: commonTags
  }
}

// 最小監視構成（Log Analytics + Application Insights）
module monitoring 'modules/monitoring.bicep' = {
  name: 'monitoring'
  params: {
    logAnalyticsName: logAnalyticsName
    appInsightsName: appInsightsName
    location: location
    tags: commonTags
  }
}

// 後続が接続に使う値だけ出す（キーは出さない）
output storageAccountName string = storageAccount.outputs.name
```

## modules/storage_account.bicep

```bicep
@description('Storage Account 名（24字以内・小文字英数字のみ）')
param name string

@description('デプロイ先リージョン')
param location string

@description('デプロイ用 Blob コンテナ名')
param deploymentContainerName string = 'app-package'

@description('タグ')
param tags object = {}

// Function App の実行とパッケージ配置に必要な Storage Account を作成する
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: name
  location: location
  tags: tags
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    // セキュリティ既定値（conventions.md 準拠）
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    supportsHttpsTrafficOnly: true
  }
}

// Blob サービス（コンテナの親）
resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  parent: storageAccount
  name: 'default'
}

// コード配置先になる Blob コンテナ（非公開）
resource deploymentContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = {
  parent: blobService
  name: deploymentContainerName
  properties: {
    publicAccess: 'None'
  }
}

output id string = storageAccount.id
output name string = storageAccount.name
// endpoint は出してよいが、アクセスキーは output に出さない
output blobEndpoint string = storageAccount.properties.primaryEndpoints.blob
```

## main.bicepparam

```bicep
using './main.bicep'

param namePrefix = 'app'
param environment = 'dev'
param tags = {
  project: 'azure-learning'
  managedBy: 'bicep'
}
```

## RG 作成から始める場合（targetScope）

```bicep
targetScope = 'subscription'

param namePrefix string
param environment string = 'dev'
param location string = 'japaneast'

var rgName = 'rg-${toLower(namePrefix)}-${toLower(environment)}'

// 他リソースの土台となる Resource Group を先に作成する
resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: rgName
  location: location
}

// RG スコープのモジュールへ scope: rg で渡す
module storage 'modules/storage_account.bicep' = {
  name: 'storage'
  scope: rg
  params: {
    name: take('st${toLower(namePrefix)}${toLower(environment)}${take(uniqueString(rg.id), 6)}', 24)
    location: location
  }
}
```

> apiVersion はテンプレ作成時点の例。実装時は必ず https://learn.microsoft.com/azure/templates/ で最新を確認すること。
