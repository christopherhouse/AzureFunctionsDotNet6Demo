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

var adminId1 = 'af35198e-8dc7-4a2e-a41e-b2ba79bebd51'
var adminId2 = 'c9be89aa-0783-4310-b73a-f81f4c3f5407'
module keyVaultModule 'keyVault.bicep' = {
  name: 'keyvault${deploymentSuffix}'
  dependsOn: [ functionModule ]
  params: {
    adminUserObjectIds: [ adminId1, adminId2 ]
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
module keyVaultSecretsModule 'keyVaultSecrets.bicep' = {
  name: 'keyvaultSecrets${deploymentSuffix}'
  dependsOn: [ keyVaultModule ]
  params: {
    keyVaultName: keyVaultModule.outputs.keyVaultName
    functionInsightsKey: functionModule.outputs.functionInsightsKey
    functionStorageAccountName: functionModule.outputs.functionStorageAccountName
    serviceBusName: servicebusModule.outputs.serviceBusName
    cosmosAccountName: cosmosModule.outputs.cosmosAccountName
  }
}
module functionAppSettingsModule './functionAppSettings.bicep' = {
  name: 'functionAppSettings${deploymentSuffix}'
  dependsOn: [ keyVaultSecretsModule ]
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
