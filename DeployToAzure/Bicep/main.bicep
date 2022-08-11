// --------------------------------------------------------------------------------
// Main file that deploys all Azure Resources for one environment
// --------------------------------------------------------------------------------
// To deploy this Bicep manually:
// 	 az login
//   az account set --subscription d1ced742-2c89-420b-a12a-6d9dc6d48c43
//   az deployment group create -n main-deploy-20220805T140000Z --resource-group rg_functiondemo_dev --template-file 'main.bicep' --parameters environmentCode=dev orgPrefix=lll appPrefix=funcdemo  
//   az deployment group create -n main-deploy-20220805T140000Z --resource-group rg_functiondemo_qa --template-file 'main.bicep' --parameters environmentCode=qa orgPrefix=lll appPrefix=funcdemo  
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
param runDateTime string = utcNow()

// --------------------------------------------------------------------------------
var deploymentSuffix = '-deploy-${runDateTime}'
var keyVaultName = '${orgPrefix}${appPrefix}vault${environmentCode}${appSuffix}'

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
    functionAppSku: functionAppSku
    functionAppSkuFamily: functionAppSkuFamily
    functionAppSkuTier: functionAppSkuTier
    functionStorageAccountName: storageModule.outputs.functionStorageAccountName
    keyVaultName: keyVaultName

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

    templateFileName: '~cosmosDatabase.bicep'
    orgPrefix: orgPrefix
    appPrefix: appPrefix
    environmentCode: environmentCode
    appSuffix: appSuffix
    location: location
    runDateTime: runDateTime
  }
}

// Create a powershell step to put Owner Object Ids into variables:
//   > Connect-AzureAD
//   > $owner1UserObjectId = (Get-AzureAdUser -ObjectId 'lyleluppes@microsoft.com').ObjectId
var owner1UserObjectId = 'd4aaf634-e777-4307-bb6e-7bf2305d166e' // Lyle's AD Guid
var owner2UserObjectId = '209019b5-167b-45cd-ab9c-f987fa262040' // Chris's AD Guid
var adminUserIds = [ owner1UserObjectId, owner2UserObjectId ]
var applicationUserIds = [ functionModule.outputs.functionAppPrincipalId ]
module keyVaultModule 'keyVault.bicep' = {
  name: 'keyvault${deploymentSuffix}'
  dependsOn: [ storageModule, servicebusModule, functionModule, cosmosModule ]
  params: {
    adminUserObjectIds: adminUserIds
    applicationUserObjectIds: applicationUserIds
    keyVaultName: keyVaultName

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
  dependsOn: [ storageModule, servicebusModule, functionModule, cosmosModule, keyVaultModule ]
  params: {
    keyVaultName: keyVaultName
    functionInsightsKey: functionModule.outputs.functionInsightsKey
    functionStorageAccountName: functionModule.outputs.functionStorageAccountName
    serviceBusName: servicebusModule.outputs.serviceBusName
    cosmosAccountName: cosmosModule.outputs.cosmosAccountName
  }
}
