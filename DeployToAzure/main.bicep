// --------------------------------------------------------------------------------
// Main file that deploys all Azure Resources for one environment
// --------------------------------------------------------------------------------
// TODO: put the queue names into an array and create them from that
// --------------------------------------------------------------------------------
// To deploy this Bicep manually:
// 	 az login
//   az account set --subscription d1ced742-2c89-420b-a12a-6d9dc6d48c43
//   az deployment group create --resource-group rg_functionexample --template-file 'main.bicep' --parameters orgPrefix=lll appPrefix=funcdemo  
// --------------------------------------------------------------------------------
param environmentCode string ='dev'
param location string = resourceGroup().location
param orgPrefix string = 'org'
param appPrefix string = 'app'
param appSuffix string = '1'
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
    queue1Name: 'orders-received'
    queue2Name: 'orders-to-erp'

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
  dependsOn: [storageModule, serviceBusModule, functionModule, cosmosModule]
  params: {
    templateFileName: '~keyvault.bicep'
    orgPrefix: orgPrefix
    appPrefix: appPrefix
    environmentCode: environmentCode
    appSuffix: appSuffix
    location: location
    runDateTime:runDateTime
  }
}
