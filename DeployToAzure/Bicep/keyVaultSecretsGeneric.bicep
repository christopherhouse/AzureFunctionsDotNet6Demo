// --------------------------------------------------------------------------------
// This BICEP file will create KeyVault secrets based on an array
// --------------------------------------------------------------------------------
param keyVaultName string
param valuesArray array

// --------------------------------------------------------------------------------
resource keyVault 'Microsoft.KeyVault/vaults@2021-11-01-preview' existing = {
  name: keyVaultName
}

resource keyVaultSecretsResource 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = [for secret in valuesArray: {
  name: secret.name
  parent: keyVault
  properties: {
    value: secret.value
  }
}]
