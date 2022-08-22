// --------------------------------------------------------------------------------
// This BICEP file will create a single KeyVault secret
// var keyVaultName = keyVaultModule.outputs.keyVaultName
// module keyVaultSecret1 'keyVaultSecret.bicep' = {
//   name: 'keyvaultSecret1${deploymentSuffix}'
//   dependsOn: [ keyVaultModule, functionModule ]
//   params: {
//     keyVaultName: keyVaultName
//     secretName: 'functionAppInsightsKey'
//     secretValue: functionModule.outputs.functionInsightsKey
//   }
// }
// // resource cosmosResource 'Microsoft.DocumentDB/databaseAccounts@2022-02-15-preview' existing = { name: cosmosModule.outputs.cosmosAccountName }
// // var cosmosKey = '${listKeys(cosmosResource.id, cosmosResource.apiVersion).primaryMasterKey}'
// // var cosmosConnectionString = 'AccountEndpoint=https://${cosmosModule.outputs.cosmosAccountName}.documents.azure.com:443/;AccountKey=${cosmosKey}'
// module keyVaultSecret2 'keyVaultSecret.bicep' = {
//   name: 'keyvaultSecret2${deploymentSuffix}'
//   dependsOn: [ keyVaultModule, cosmosModule ]
//   params: {
//     keyVaultName: keyVaultName
//     secretName: 'cosmosConnectionString'
//     // secretValue: cosmosConnectionString
//     secretValue: 'AccountEndpoint=https://${cosmosModule.outputs.cosmosAccountName}.documents.azure.com:443/;AccountKey=XXXX'
//   }
// }
// resource functionStorageAccountResource 'Microsoft.Storage/storageAccounts@2021-04-01' existing = { name: storageModule.name }
// var functionStorageAccountConnectionString = 'DefaultEndpointsProtocol=https;AccountName=${functionStorageAccountResource.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(functionStorageAccountResource.id, functionStorageAccountResource.apiVersion).keys[0].value}'
// module keyVaultSecret3 'keyVaultSecret.bicep' = {
//   name: 'keyvaultSecret3${deploymentSuffix}'
//   dependsOn: [ keyVaultModule, storageModule ]
//   params: {
//     keyVaultName: keyVaultName
//     secretName: 'functionStorageAccountConnectionString'
//     secretValue: functionStorageAccountConnectionString
//   }
// }

// resource serviceBusResource 'Microsoft.ServiceBus/namespaces@2021-11-01' existing = { name: servicebusModule.name }
// var serviceBusEndpoint = '${serviceBusResource.id}/AuthorizationRules/RootManageSharedAccessKey'
// var serviceBusSendConnectionString = 'Endpoint=sb://${serviceBusResource.name}.servicebus.windows.net/;SharedAccessKeyName=send;SharedAccessKey=${listKeys(serviceBusEndpoint, serviceBusResource.apiVersion).primaryKey}'
// var serviceBusListenConnectionString = 'Endpoint=sb://${serviceBusResource.name}.servicebus.windows.net/;SharedAccessKeyName=listen;SharedAccessKey=${listKeys(serviceBusEndpoint, serviceBusResource.apiVersion).primaryKey}'
// module keyVaultSecret4 'keyVaultSecret.bicep' = {
//   name: 'keyvaultSecret4${deploymentSuffix}'
//   dependsOn: [ keyVaultModule, servicebusModule ]
//   params: {
//     keyVaultName: keyVaultName
//     secretName: 'serviceBusReceiveConnectionString'
//     secretValue: serviceBusListenConnectionString
//   }
// }
// module keyVaultSecret5 'keyVaultSecret.bicep' = {
//   name: 'keyvaultSecret5${deploymentSuffix}'
//   dependsOn: [ keyVaultModule, servicebusModule ]
//   params: {
//     keyVaultName: keyVaultName
//     secretName: 'serviceBusSendConnectionString'
//     secretValue: serviceBusSendConnectionString
//   }
// }

// --------------------------------------------------------------------------------
param keyVaultName string
param secretName string
@secure()
param secretValue string
param enabledDate string = utcNow()
param expirationDate string = dateTimeAdd(utcNow(), 'P10Y')
param enabled bool = true

resource vault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}

resource secret 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: secretName
  parent: vault
  properties: {
    attributes: {
      enabled: enabled
      exp: dateTimeToEpoch(expirationDate)
      nbf: dateTimeToEpoch(enabledDate)
    }
    value: secretValue
  }
}
