// // ----------------------------------------------------------------------------------------------------
// // This BICEP file will create a Resource Group
// // ----------------------------------------------------------------------------------------------------
// param appPrefix string = 'app'
// @allowed([ 'dev', 'qa', 'stg', 'prod' ])
// param environmentCode string = 'dev'
// param location string
// param runDateTime string = utcNow()
// param templateFileName string = '~functionApp.bicep'

// // ----------------------------------------------------------------------------------------------------
// var resourceGroupName = '$rg-${appPrefix}-${environmentCode}'

// // ----------------------------------------------------------------------------------------------------
// // Error: must be scoped to Subscription (...???)
// resource resourceGroupResource 'Microsoft.Resources/resourceGroups@2021-04-01' = {
//   name: resourceGroupName
//   location: location
//   tags: {
//     LastDeployed: runDateTime
//     TemplateFile: templateFileName
//   }
//   properties: {}
// }
