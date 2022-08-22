// --------------------------------------------------------------------------------
// Main file that deploys all Azure Resources for one environment
// --------------------------------------------------------------------------------
// To deploy this Bicep manually:
// 	 az login
//   az account set --subscription <subscriptionId>
//   az deployment group create -n main-deploy-20220822T082901Z --resource-group rg_functiondemo_dev --template-file 'main.bicep' --parameters orgPrefix=lll appPrefix=fundemo environmentCode=dev keyVaultOwnerUserId1=d4aaf634-e777-4307-bb6e-7bf2305d166e keyVaultOwnerUserId2=209019b5-167b-45cd-ab9c-f987fa262040
//   az deployment group create -n main-deploy-20220822T082901Z --resource-group rg_functiondemo_qa  --template-file 'main.bicep' --parameters orgPrefix=lll appPrefix=fundemo environmentCode=qa  keyVaultOwnerUserId1=d4aaf634-e777-4307-bb6e-7bf2305d166e keyVaultOwnerUserId2=209019b5-167b-45cd-ab9c-f987fa262040
// --------------------------------------------------------------------------------
param environmentCode string = 'dev'
param location string = resourceGroup().location
param orgPrefix string = 'org'
param appPrefix string = 'app'
param appSuffix string = '' // '-1' 
param storageSku string = 'Standard_LRS'
param functionAppSku string = 'Y1'
param functionAppSkuFamily string = 'Y'
param functionAppSkuTier string = 'Dynamic'
param keyVaultOwnerUserId1 string = ''
param keyVaultOwnerUserId2 string = ''
param runDateTime string = utcNow()

// --------------------------------------------------------------------------------
var deploymentSuffix = '-${runDateTime}'

// --------------------------------------------------------------------------------
// TODO: I need a way to create a resource group here
// --------------------------------------------------------------------------------

module storageModule 'storageAccount.bicep' = {
  name: 'storage${deploymentSuffix}'
  params: {
    storageSku: storageSku

    templateFileName: '~storageAccount.bicep'
    orgPrefix: orgPrefix
    appPrefix: appPrefix
    environmentCode: environmentCode
    appSuffix: appSuffix
    location: location
    runDateTime: runDateTime
  }
}
module servicebusModule 'serviceBus.bicep' = {
  name: 'servicebus${deploymentSuffix}'
  params: {
    queueNames: [ 'orders-received', 'orders-to-erp' ]

    templateFileName: '~serviceBus.bicep'
    orgPrefix: orgPrefix
    appPrefix: appPrefix
    environmentCode: environmentCode
    appSuffix: appSuffix
    location: location
    runDateTime: runDateTime
  }
}
module functionModule 'functionApp.bicep' = {
  name: 'function${deploymentSuffix}'
  dependsOn: [ storageModule ]
  params: {
    functionName: 'process'
    functionKind: 'functionapp,linux'
    functionAppSku: functionAppSku
    functionAppSkuFamily: functionAppSkuFamily
    functionAppSkuTier: functionAppSkuTier
    functionStorageAccountName: storageModule.outputs.functionStorageAccountName
    appInsightsLocation: location

    templateFileName: '~functionApp.bicep'
    orgPrefix: orgPrefix
    appPrefix: appPrefix
    environmentCode: environmentCode
    appSuffix: appSuffix
    location: location
    runDateTime: runDateTime
  }
}

var cosmosContainerArray = [
  { name: 'products', partitionKey: '/category' }
  { name: 'orders', partitionKey: '/customerNumber' }
]
module cosmosModule 'cosmosDatabase.bicep' = {
  name: 'cosmos${deploymentSuffix}'
  dependsOn: [ storageModule ]
  params: {
    containerArray: cosmosContainerArray
    cosmosDatabaseName: 'FuncDemoDatabase'

    templateFileName: '~cosmosDatabase.bicep'
    orgPrefix: orgPrefix
    appPrefix: appPrefix
    environmentCode: environmentCode
    appSuffix: appSuffix
    location: location
    runDateTime: runDateTime
  }
}

module keyVaultModule 'keyVault.bicep' = {
  name: 'keyvault${deploymentSuffix}'
  dependsOn: [ functionModule ]
  params: {
    //adminUserObjectIds: [ keyVaultOwnerUserId1, keyVaultOwnerUserId2 ]
    adminUserObjectIds: [ ]
    applicationUserObjectIds: [ functionModule.outputs.functionAppPrincipalId ]

    templateFileName: '~keyVault.bicep'
    orgPrefix: orgPrefix
    appPrefix: appPrefix
    environmentCode: environmentCode
    appSuffix: appSuffix
    location: location
    runDateTime: runDateTime
  }
}
module keyVaultSecret1 'keyVaultSecret.bicep' = {
  name: 'keyvaultSecret1${deploymentSuffix}'
  dependsOn: [ keyVaultModule ]
  params: {
    keyVaultName: keyVaultModule.outputs.keyVaultName
    secretName:  'functionAppInsightsKey'
    secretValue: functionModule.outputs.functionInsightsKey
  }
}
resource cosmosResource 'Microsoft.DocumentDB/databaseAccounts@2022-02-15-preview' existing = { name: cosmosModule.outputs.cosmosAccountName }
var cosmosKey = '${listKeys(cosmosResource.id, cosmosResource.apiVersion).primaryMasterKey}'
var cosmosConnectionString = 'AccountEndpoint=https://${cosmosModule.outputs.cosmosAccountName}.documents.azure.com:443/;AccountKey=${cosmosKey}'
module keyVaultSecret2 'keyVaultSecret.bicep' = {
  name: 'keyvaultSecret2${deploymentSuffix}'
  dependsOn: [ keyVaultModule ]
  params: {
    keyVaultName: keyVaultModule.outputs.keyVaultName
    secretName: 'cosmosConnectionString'
    secretValue: cosmosConnectionString
  }
}
resource functionStorageAccountResource 'Microsoft.Storage/storageAccounts@2021-04-01' existing = { name: storageModule.name }
var functionStorageAccountConnectionString = 'DefaultEndpointsProtocol=https;AccountName=${functionStorageAccountResource.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(functionStorageAccountResource.id, functionStorageAccountResource.apiVersion).keys[0].value}'
module keyVaultSecret3 'keyVaultSecret.bicep' = {
  name: 'keyvaultSecret3${deploymentSuffix}'
  dependsOn: [ keyVaultModule ]
  params: {
    keyVaultName: keyVaultModule.outputs.keyVaultName
    secretName: 'functionStorageAccountConnectionString'
    secretValue: functionStorageAccountConnectionString
  }
}

resource serviceBusResource 'Microsoft.ServiceBus/namespaces@2021-11-01' existing = { name: servicebusModule.name }
var serviceBusEndpoint = '${serviceBusResource.id}/AuthorizationRules/RootManageSharedAccessKey' 
var serviceBusSendConnectionString = 'Endpoint=sb://${serviceBusResource.name}.servicebus.windows.net/;SharedAccessKeyName=send;SharedAccessKey=${listKeys(serviceBusEndpoint, serviceBusResource.apiVersion).primaryKey}' 
var serviceBusListenConnectionString = 'Endpoint=sb://${serviceBusResource.name}.servicebus.windows.net/;SharedAccessKeyName=listen;SharedAccessKey=${listKeys(serviceBusEndpoint, serviceBusResource.apiVersion).primaryKey}' 
module keyVaultSecret4 'keyVaultSecret.bicep' = {
  name: 'keyvaultSecret4${deploymentSuffix}'
  dependsOn: [ keyVaultModule ]
  params: {
    keyVaultName: keyVaultModule.outputs.keyVaultName
    secretName: 'serviceBusReceiveConnectionString'
    secretValue: serviceBusListenConnectionString
   }
}
module keyVaultSecret5 'keyVaultSecret.bicep' = {
  name: 'keyvaultSecret5${deploymentSuffix}'
  dependsOn: [ keyVaultModule ]
  params: {
    keyVaultName: keyVaultModule.outputs.keyVaultName
    secretName: 'serviceBusSendConnectionString'
    secretValue: serviceBusSendConnectionString 
  }
}


module functionAppSettingsModule './functionAppSettings.bicep' = {
  name: 'functionAppSettings${deploymentSuffix}'
  dependsOn: [ keyVaultSecret1, keyVaultSecret2, keyVaultSecret3, keyVaultSecret4, keyVaultSecret5 ]
  params: {
    functionAppName: functionModule.outputs.functionAppName
    functionStorageAccountName: functionModule.outputs.functionStorageAccountName
    functionInsightsKey: functionModule.outputs.functionInsightsKey
    customAppSettings: {
      cosmosConnectionStringReference: '@Microsoft.KeyVault(VaultName=${keyVaultModule.outputs.keyVaultName};SecretName=cosmosConnectionString)'
      serviceBusReceiveConnectionStringReference: '@Microsoft.KeyVault(VaultName=${keyVaultModule.outputs.keyVaultName};SecretName=serviceBusReceiveConnectionString)'
      serviceBusSendConnectionStringReference: '@Microsoft.KeyVault(VaultName=${keyVaultModule.outputs.keyVaultName};SecretName=serviceBusSendConnectionString)'
    }
  }
}
