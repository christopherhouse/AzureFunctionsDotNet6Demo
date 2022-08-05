// --------------------------------------------------------------------------------
// Main file that deploys all Azure Resources for one environment
// --------------------------------------------------------------------------------
// To deploy this Bicep manually:
// 	 az login
//   az account set --subscription d1ced742-2c89-420b-a12a-6d9dc6d48c43
//   az deployment group create -n main-deploy-20220805T140000Z --resource-group rg_functiondemo_dev --template-file 'main.bicep' --parameters environmentCode=dev orgPrefix=lll appPrefix=funcdemo  
//   az deployment group create -n main-deploy-20220805T140000Z --resource-group rg_functiondemo_qa --template-file 'main.bicep' --parameters environmentCode=qa orgPrefix=lll appPrefix=funcdemo  
// --------------------------------------------------------------------------------
param environmentCode string ='dev'
param location string = resourceGroup().location
param orgPrefix string = 'org'
param appPrefix string = 'app'
param appSuffix string = ''  // '-1' 
param storageSku string = 'Standard_LRS'
param functionAppSku string = 'Y1'
param functionAppSkuFamily string = 'Y'
param functionAppSkuTier string = 'Dynamic'
param runDateTime string = utcNow()

// --------------------------------------------------------------------------------
var deploymentSuffix = '-deploy-${runDateTime}'

// --------------------------------------------------------------------------------
module storageModule 'storage.bicep' = {
  name: 'storage${deploymentSuffix}'
  params: {
    storageSku: storageSku

    templateFileName: '~storage.bicep'
    orgPrefix: orgPrefix
    appPrefix: appPrefix
    environmentCode: environmentCode
    appSuffix: appSuffix
    location: location
    runDateTime:runDateTime
  }
}
module servicebusModule 'servicebus.bicep' = {
  name: 'servicebus${deploymentSuffix}'
  params: {
    queueNames: ['orders-received','orders-to-erp']

    templateFileName: '~servicebus.bicep'
    orgPrefix: orgPrefix
    appPrefix: appPrefix
    environmentCode: environmentCode
    appSuffix: appSuffix
    location: location
    runDateTime:runDateTime
  }
}
module functionModule 'function.bicep' = {
  name: 'function${deploymentSuffix}'
  dependsOn: [storageModule]
  params: {
    functionAppSku: functionAppSku
    functionAppSkuFamily: functionAppSkuFamily
    functionAppSkuTier: functionAppSkuTier
    functionStorageAccountName: storageModule.outputs.functionStorageAccountName

    templateFileName: '~function.bicep'
    orgPrefix: orgPrefix
    appPrefix: appPrefix
    environmentCode: environmentCode
    appSuffix: appSuffix
    location: location
    runDateTime:runDateTime
  }
}
module cosmosModule 'cosmos.bicep' = {
  name: 'cosmos${deploymentSuffix}'
  dependsOn: [storageModule]
  params: {
    templateFileName: '~cosmos.bicep'
    orgPrefix: orgPrefix
    appPrefix: appPrefix
    environmentCode: environmentCode
    appSuffix: appSuffix
    location: location
    runDateTime:runDateTime
  }
}
module keyVaultModule 'keyvault.bicep' = {
  name: 'keyvault${deploymentSuffix}'
  dependsOn: [storageModule, servicebusModule, functionModule, cosmosModule]
  params: {
    functionAppPrincipalId: functionModule.outputs.functionAppPrincipalId
    functionInsightsKey: functionModule.outputs.functionInsightsKey
    functionStorageAccountName: functionModule.outputs.functionStorageAccountName
    serviceBusName: servicebusModule.outputs.serviceBusName
    cosmosAccountName: cosmosModule.outputs.cosmosAccountName

    templateFileName: '~keyvault.bicep'
    orgPrefix: orgPrefix
    appPrefix: appPrefix
    environmentCode: environmentCode
    appSuffix: appSuffix
    location: location
    runDateTime:runDateTime
  }
}
