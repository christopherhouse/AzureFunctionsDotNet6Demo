// --------------------------------------------------------------------------------
// This BICEP file will create KeyVault secrets specific to this project
// module keyVaultSecretsModule 'keyVaultSecrets.bicep' = {
//   name: 'keyvaultSecrets${deploymentSuffix}'
//   dependsOn: [ keyVaultModule ]
//   params: {
//     keyVaultName: keyVaultModule.outputs.keyVaultName
//     functionInsightsKey: functionModule.outputs.functionInsightsKey
//     functionStorageAccountName: functionModule.outputs.functionStorageAccountName
//     serviceBusName: servicebusModule.outputs.serviceBusName
//     cosmosAccountName: cosmosModule.outputs.cosmosAccountName
//   }
// }
// --------------------------------------------------------------------------------
param keyVaultName string

param functionStorageAccountName string
param serviceBusName string
param cosmosAccountName string
param functionInsightsKey string

// --------------------------------------------------------------------------------
resource functionStorageAccountResource 'Microsoft.Storage/storageAccounts@2021-04-01' existing = { name: functionStorageAccountName }
var functionStorageAccountConnectionString = 'DefaultEndpointsProtocol=https;AccountName=${functionStorageAccountResource.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(functionStorageAccountResource.id, functionStorageAccountResource.apiVersion).keys[0].value}'

resource cosmosResource 'Microsoft.DocumentDB/databaseAccounts@2022-02-15-preview' existing = { name: cosmosAccountName }
var cosmosKey = '${listKeys(cosmosResource.id, cosmosResource.apiVersion).primaryMasterKey}'
var cosmosConnectionString = 'AccountEndpoint=https://${cosmosAccountName}.documents.azure.com:443/;AccountKey=${cosmosKey}'

resource serviceBusResource 'Microsoft.ServiceBus/namespaces@2021-11-01' existing = { name: serviceBusName }
var serviceBusEndpoint = '${serviceBusResource.id}/AuthorizationRules/RootManageSharedAccessKey' 
var serviceBusSendConnectionString = 'Endpoint=sb://${serviceBusResource.name}.servicebus.windows.net/;SharedAccessKeyName=send;SharedAccessKey=${listKeys(serviceBusEndpoint, serviceBusResource.apiVersion).primaryKey}' 
var serviceBusListenConnectionString = 'Endpoint=sb://${serviceBusResource.name}.servicebus.windows.net/;SharedAccessKeyName=listen;SharedAccessKey=${listKeys(serviceBusEndpoint, serviceBusResource.apiVersion).primaryKey}' 

// --------------------------------------------------------------------------------
resource keyvaultResource 'Microsoft.KeyVault/vaults@2021-11-01-preview' existing = { 
  name: keyVaultName 
  resource functionInsightsSecret 'secrets' = {
    name: 'functionAppInsightsKey'
    properties: {
      value: functionInsightsKey
    }
  }
  resource iotHubSecret 'secrets' = {
    name: 'functionStorageAccountConnectionString'
    properties: {
      value: functionStorageAccountConnectionString
    }
  }
  resource cosmosSecret 'secrets' = {
    name: 'cosmosConnectionString'
    properties: {
      value: cosmosConnectionString
    }
  }
  resource serviceBusReceiveSecret 'secrets' = {
    name: 'serviceBusReceiveConnectionString'
    properties: {
      value: serviceBusListenConnectionString
    }
  }
  resource serviceBusSendSecret 'secrets' = {
    name: 'serviceBusSendConnectionString'
    properties: {
      value: serviceBusSendConnectionString
    }
  }
}
