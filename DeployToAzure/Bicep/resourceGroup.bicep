// --------------------------------------------------------------------------------
// This BICEP file will create a Resource Group
// --------------------------------------------------------------------------------
param resourceGroupName string = 'rg_functiondemo_dev'

resource resourceGroupResource 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
}
