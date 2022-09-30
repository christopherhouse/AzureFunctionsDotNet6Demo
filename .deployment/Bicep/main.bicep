// --------------------------------------------------------------------------------
// Main file that deploys all Azure Resources for one environment
// --------------------------------------------------------------------------------
// NOTE: To make this pipeline work, your service principal may need to be in the
//   "acr pull" role for the container registry.
// --------------------------------------------------------------------------------
// To deploy this Bicep manually:
// 	 az login
//   az account set --subscription <subscriptionId>
//   az deployment group create -n main-deploy-20220823T110000Z --resource-group rg_functiondemo_dev --template-file 'main.bicep' --parameters orgPrefix=xxx appPrefix=fundemo environmentCode=dev keyVaultOwnerUserId1=xxxxxxxx-xxxx-xxxx keyVaultOwnerUserId2=xxxxxxxx-xxxx-xxxx
//   az deployment group create -n main-deploy-20220823T110000Z --resource-group rg_functiondemo_qa  --template-file 'main.bicep' --parameters orgPrefix=xxx appPrefix=fundemo environmentCode=qa  keyVaultOwnerUserId1=xxxxxxxx-xxxx-xxxx keyVaultOwnerUserId2=xxxxxxxx-xxxx-xxxx
// --------------------------------------------------------------------------------
// To list the available bicep container registry image tags:
//   $registryName = 'lllbicepregistry'
//   Write-Host "Scanning for repository tags in $registryName"
//   az acr repository list --name $registryName -o tsv | Foreach-Object { 
//     $thisModule = $_
//     az acr repository show-tags --name $registryName --repository $_ --output tsv  | Foreach-Object { 
//       Write-Host "$thisModule`:$_"
//     }
//   }
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
var cosmosDatabaseName = 'FuncDemoDatabase'
var cosmosOrdersContainerName = 'orders'
var cosmosProductsContainerName = 'products'
var queueOrdersReceived = 'orders-received'
var queueERP =  'orders-to-erp' 

//module storageModule 'br/lllbicepmodules:storageaccount:2022-09-04.425' = {
module storageModule 'storageaccount.bicep' = {
  name: 'storage${deploymentSuffix}'
  params: {
    storageSku: storageSku

    templateFileName: 'storageaccount:2022-09-04.425'
    orgPrefix: orgPrefix
    appPrefix: appPrefix
    environmentCode: environmentCode
    appSuffix: appSuffix
    location: location
    runDateTime: runDateTime
  }
}

//module servicebusModule 'br/lllbicepmodules:servicebus:2022-08-31.335' = {
module servicebusModule 'servicebus.bicep' = {
  name: 'servicebus${deploymentSuffix}'
  params: {
    queueNames: [ queueOrdersReceived, queueERP ]

    templateFileName: 'servicebus:2022-08-31.335'
    orgPrefix: orgPrefix
    appPrefix: appPrefix
    environmentCode: environmentCode
    appSuffix: appSuffix
    location: location
    runDateTime: runDateTime
  }
}
var cosmosContainerArray = [
  { name: cosmosProductsContainerName, partitionKey: '/category' }
  { name: cosmosOrdersContainerName, partitionKey: '/customerNumber' }
]

//module cosmosModule 'br/lllbicepmodules:cosmosdatabase:2022-08-31.335' = {
module cosmosModule 'cosmosdatabase.bicep' = {
  name: 'cosmos${deploymentSuffix}'
  params: {
    containerArray: cosmosContainerArray
    cosmosDatabaseName: cosmosDatabaseName

    templateFileName: 'cosmosdatabase:2022-08-31.335'
    orgPrefix: orgPrefix
    appPrefix: appPrefix
    environmentCode: environmentCode
    appSuffix: appSuffix
    location: location
    runDateTime: runDateTime
  }
}
//module functionModule 'br/lllbicepmodules:functionapp:2022-09-04.425' = {
module functionModule 'functionapp.bicep' = {
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

    templateFileName: 'functionapp:2022-09-04.425'
    orgPrefix: orgPrefix
    appPrefix: appPrefix
    environmentCode: environmentCode
    appSuffix: appSuffix
    location: location
    runDateTime: runDateTime
  }
}
//module keyVaultModule 'br/lllbicepmodules:keyvault:2022-08-31.335' = {
module keyVaultModule 'keyvault.bicep' = {
  name: 'keyvault${deploymentSuffix}'
  dependsOn: [ functionModule ]
  params: {
    adminUserObjectIds: [ keyVaultOwnerUserId1, keyVaultOwnerUserId2 ]
    applicationUserObjectIds: [ functionModule.outputs.functionAppPrincipalId ]

    templateFileName: 'keyvault:2022-08-31.335'
    orgPrefix: orgPrefix
    appPrefix: appPrefix
    environmentCode: environmentCode
    appSuffix: appSuffix
    location: location
    runDateTime: runDateTime
  }
}
//module keyVaultSecret1 'br/lllbicepmodules:keyvaultsecret:2022-08-26.309' = {
module keyVaultSecret1 'keyvaultsecret.bicep' = {
  name: 'keyVaultSecret1${deploymentSuffix}'
  dependsOn: [ keyVaultModule, functionModule ]
  params: {
    keyVaultName: keyVaultModule.outputs.keyVaultName
    secretName: 'functionAppInsightsKey'
    secretValue: functionModule.outputs.functionInsightsKey
  }
}
//module keyVaultSecret2 'br/lllbicepmodules:keyvaultsecretcosmosconnection:2022-08-26.314' = {
module keyVaultSecret2 'keyvaultsecretcosmosconnection.bicep' = {
  name: 'keyVaultSecret2${deploymentSuffix}'
  dependsOn: [ keyVaultModule, cosmosModule ]
  params: {
    keyVaultName: keyVaultModule.outputs.keyVaultName
    keyName: 'cosmosConnectionString'
    cosmosAccountName: cosmosModule.outputs.cosmosAccountName
  }
}
//module keyVaultSecret3 'br/lllbicepmodules:keyvaultsecretservicebusconnection:2022-08-26.314' = {
module keyVaultSecret3 'keyvaultsecretservicebusconnection.bicep' = {
  name: 'keyVaultSecret3${deploymentSuffix}'
  dependsOn: [ keyVaultModule, servicebusModule ]
  params: {
    keyVaultName: keyVaultModule.outputs.keyVaultName
    keyName: 'serviceBusSendConnectionString'
    serviceBusName: servicebusModule.outputs.serviceBusName
    accessKeyName: 'send'
  }
}
//module keyVaultSecret4 'br/lllbicepmodules:keyvaultsecretservicebusconnection:2022-08-26.314' = {
module keyVaultSecret4 'keyvaultsecretservicebusconnection.bicep' = {
  name: 'keyVaultSecret4${deploymentSuffix}'
  dependsOn: [ keyVaultModule, servicebusModule ]
  params: {
    keyVaultName: keyVaultModule.outputs.keyVaultName
    keyName: 'serviceBusReceiveConnectionString'
    serviceBusName: servicebusModule.outputs.serviceBusName
    accessKeyName: 'listen'
  }
}
//module keyVaultSecret5 'br/lllbicepmodules:keyvaultsecretstorageconnection:2022-08-26.314' = {
module keyVaultSecret5 'keyvaultsecretstorageconnection.bicep' = {
  name: 'keyVaultSecret5${deploymentSuffix}'
  dependsOn: [ keyVaultModule, storageModule ]
  params: {
    keyVaultName: keyVaultModule.outputs.keyVaultName
    keyName: 'functionStorageAccountConnectionString'
    storageAccountName: storageModule.outputs.functionStorageAccountName
  }
}
//module functionAppSettingsModule 'br/lllbicepmodules:functionappsettings:2022-08-24.257' = {
module functionAppSettingsModule 'functionappsettings.bicep' = {
  name: 'functionAppSettings${deploymentSuffix}'
  dependsOn: [ keyVaultSecret1, keyVaultSecret2, keyVaultSecret3, keyVaultSecret4, keyVaultSecret5, functionModule ]
  params: {
    functionAppName: functionModule.outputs.functionAppName
    functionStorageAccountName: functionModule.outputs.functionStorageAccountName
    functionInsightsKey: functionModule.outputs.functionInsightsKey
    customAppSettings: {
      cosmosDatabaseName: cosmosDatabaseName
      cosmosContainerName: cosmosProductsContainerName
      ordersContainerName: cosmosOrdersContainerName
      orderReceivedQueue: queueOrdersReceived
      cosmosConnectionStringReference: '@Microsoft.KeyVault(VaultName=${keyVaultModule.outputs.keyVaultName};SecretName=cosmosConnectionString)'
      serviceBusReceiveConnectionStringReference: '@Microsoft.KeyVault(VaultName=${keyVaultModule.outputs.keyVaultName};SecretName=serviceBusReceiveConnectionString)'
      serviceBusSendConnectionStringReference: '@Microsoft.KeyVault(VaultName=${keyVaultModule.outputs.keyVaultName};SecretName=serviceBusSendConnectionString)'
    }
  }
}