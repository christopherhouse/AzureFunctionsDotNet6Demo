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
param keyVaultName string = 'kvName'

param adminUserObjectIds array
param applicationUserObjectIds array

// --------------------------------------------------------------------------------
var adminAccessPolicies = [for adminUser in adminUserObjectIds: {
  objectId: adminUser
  tenantId: subscription().tenantId
  permissions: {
    certificates: [ 'all' ]
    secrets: [ 'all' ]
    keys: [ 'all' ]
  }
}]
var applicationUserPolicies = [for appUser in applicationUserObjectIds: {
  objectId: appUser
  tenantId: subscription().tenantId
  permissions: {
    secrets: [ 'get' ]
  }
}]
var accessPolicies = union(adminAccessPolicies, applicationUserPolicies)

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
    accessPolicies: accessPolicies

    enabledForDeployment: false          // VMs can retrieve certificates
    enabledForTemplateDeployment: false  // ARM can retrieve values
    enablePurgeProtection: true          // Not allowing to purge key vault or its objects after deletion
    enableSoftDelete: false
    createMode: 'default'                // Creating or updating the key vault (not recovering)
  }
}
