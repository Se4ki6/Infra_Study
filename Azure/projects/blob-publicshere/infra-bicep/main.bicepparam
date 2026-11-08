using './main.bicep'

param namePrefix = 'public'
param environment = 'dev'
param location = 'japaneast'
param containerName = 'public-assets'
param tags = {
  purpose: 'public-assets'
}
