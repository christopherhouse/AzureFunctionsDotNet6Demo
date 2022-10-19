param orgPrefix string = 'org'
param appPrefix string = 'app'
@allowed(['dev','demo','qa','stg','prod'])
param environment string = 'dev'
param appSuffix string = ''
param functionName string = ''
param functionStorageNameSuffix string = 'store'
param dataStorageNameSuffix string = 'data'

// --------------------------------------------------------------------------------
var  sanitizedOrgPrefix = replace(replace(replace(toLower(orgPrefix), ' ', ''), '-', ''), '_', '')
var  sanitizedAppPrefix = replace(replace(replace(toLower(appPrefix), ' ', ''), '-', ''), '_', '')
var  sanitizedAppSuffix = replace(replace(replace(toLower(appSuffix), ' ', ''), '-', ''), '_', '')
var  sanitizedEnvironment = toLower(environment)

// --------------------------------------------------------------------------------
output functionAppName string =            toLower('${sanitizedOrgPrefix}-${sanitizedAppPrefix}-${functionName}-${sanitizedEnvironment}${sanitizedAppSuffix}')
output functionAppServicePlanName string = toLower('${sanitizedOrgPrefix}-${sanitizedAppPrefix}-${functionName}-${sanitizedEnvironment}${sanitizedAppSuffix}-appsvc')
output functionInsightsName string =       toLower('${sanitizedOrgPrefix}-${sanitizedAppPrefix}-${functionName}-${sanitizedEnvironment}${sanitizedAppSuffix}-insights')

output cosmosAccountName string = '${sanitizedOrgPrefix}-${sanitizedAppPrefix}-cosmos-${sanitizedEnvironment}${sanitizedAppSuffix}'
output serviceBusName string =    '${sanitizedOrgPrefix}-${sanitizedAppPrefix}-svcbus-${sanitizedEnvironment}${sanitizedAppSuffix}'

// Key Vaults and Storage Accounts can only be 24 characters long
output keyVaultName string =        take(toLower('${sanitizedOrgPrefix}${sanitizedAppPrefix}vault${sanitizedEnvironment}${sanitizedAppSuffix}'), 24)
output functionStorageName string = take(toLower('${sanitizedOrgPrefix}${sanitizedAppPrefix}${sanitizedEnvironment}${appSuffix}${functionStorageNameSuffix}'), 24)
output dataStorageName string =     take(toLower('${sanitizedOrgPrefix}${sanitizedAppPrefix}${sanitizedEnvironment}${appSuffix}${dataStorageNameSuffix}'), 24)
