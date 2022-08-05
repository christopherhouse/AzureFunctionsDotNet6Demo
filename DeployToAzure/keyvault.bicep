// --------------------------------------------------------------------------------
// This BICEP file will create a KeyVault for the Azure Function Example Project
// TODO: Split out access policies and secrets into separate files
// --------------------------------------------------------------------------------
param orgPrefix string = 'org'
param appPrefix string = 'app'
@allowed(['dev','qa','stg','prod'])
param environmentCode string = 'dev'
param appSuffix string = '1'
param location string = resourceGroup().location
param runDateTime string = utcNow()
param templateFileName string = '~keyvault.bicep'

param functionStorageAccountName string
param serviceBusName string
param cosmosAccountName string
param functionAppPrincipalId string 
param functionInsightsKey string

// --------------------------------------------------------------------------------
var keyVaultName = '${orgPrefix}-${appPrefix}-keyvault-${environmentCode}${appSuffix}'

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

var owner1UserObjectId = 'd4aaf634-e777-4307-bb6e-7bf2305d166e' // Lyle's AD Guid
var owner2UserObjectId = '209019b5-167b-45cd-ab9c-f987fa262040' // Chris's AD Guid

// --------------------------------------------------------------------------------
resource keyvaultResource 'Microsoft.KeyVault/vaults@2021-11-01-preview' = {
  name: keyVaultName
  location: location
  tags: {
    LastDeployed: runDateTime
    TemplateFile: templateFileName
  }
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId

    // add function app and web app identities in the access policies so they can read the secrets
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId:  owner1UserObjectId
        permissions: {
          secrets: ['All']
          certificates: ['All']
          keys: ['All']
        } 
      }
      {
        tenantId: subscription().tenantId
        objectId:  owner2UserObjectId
        permissions: {
          secrets: ['All']
          certificates: ['All']
          keys: ['All']
        } 
      }
      {
        tenantId: subscription().tenantId
        objectId:  functionAppPrincipalId
        permissions: {
          secrets: [ 'get' ]
          certificates: [ 'get' ]
          keys: [ 'get' ]
        }
      }
    ]
    enabledForDeployment: false          // VMs can retrieve certificates
    enabledForTemplateDeployment: false  // ARM can retrieve values
    enablePurgeProtection: true         // Not allowing to purge key vault or its objects after deletion
    enableSoftDelete: true
    softDeleteRetentionInDays: 7
    enableRbacAuthorization: false      // Use Access Policies model
    createMode: 'default'               // Creating or updating the key vault (not recovering)
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'deny'
    }
  }

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

output keyVaultName string = keyVaultName
