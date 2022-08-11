// --------------------------------------------------------------------------------
// This BICEP file will create a KeyVault
// --------------------------------------------------------------------------------
param orgPrefix string = 'org'
param appPrefix string = 'app'
@allowed(['dev','qa','stg','prod'])
param environmentCode string = 'dev'
param appSuffix string = '1'
param location string = resourceGroup().location
param runDateTime string = utcNow()
param templateFileName string = '~keyVault.bicep'

param functionAppPrincipalId string 
param owner1UserObjectId string = 'd4aaf634-e777-4307-bb6e-7bf2305d166e' // Lyle's AD Guid
param owner2UserObjectId string = '209019b5-167b-45cd-ab9c-f987fa262040' // Chris's AD Guid

// --------------------------------------------------------------------------------
var keyVaultName = '${orgPrefix}${appPrefix}vault${environmentCode}${appSuffix}'

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

    // Use Access Policies model
    enableRbacAuthorization: false      
    // add function app and web app identities in the access policies so they can read the secrets
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId:  functionAppPrincipalId
        permissions: {
          secrets: [ 'get' ]
          certificates: [ 'get' ]
          keys: [ 'get' ]
        }
      }
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
    ]
    enabledForDeployment: false          // VMs can retrieve certificates
    enabledForTemplateDeployment: false  // ARM can retrieve values
    enablePurgeProtection: true          // Not allowing to purge key vault or its objects after deletion
    enableSoftDelete: false
    createMode: 'default'                // Creating or updating the key vault (not recovering)
  }
}

output keyVaultName string = keyVaultName
