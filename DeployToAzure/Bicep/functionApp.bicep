// ----------------------------------------------------------------------------------------------------
// This BICEP file will create an Azure Function for the Azure Function Example Project
// TODO: can I split the unique configuration keys out into a separate file to make this more generic?
// ----------------------------------------------------------------------------------------------------
param orgPrefix string = 'org'
param appPrefix string = 'app'
@allowed(['dev','qa','stg','prod'])
param environmentCode string = 'dev'
param appSuffix string = '1'
param location string = resourceGroup().location
param runDateTime string = utcNow()
param templateFileName string = '~functionApp.bicep'
param functionAppSku string = 'Y1'
param functionAppSkuFamily string = 'Y'
param functionAppSkuTier string = 'Dynamic'
param functionStorageAccountName string

// configuration keys unique to this solution...
param keyVaultName string = 'keyVaultName'
param cosmosDatabaseName string = 'cosmos-demo-db'
param productsContainerName string = 'products'
param ordersContainerName string = 'orders'
param orderReceivedQueue string = 'orders-received'
param ordersToErpQueue string = 'orders-to-erp'

// --------------------------------------------------------------------------------
var functionAppName = toLower('${orgPrefix}-${appPrefix}-func-${environmentCode}${appSuffix}')
var appServicePlanName = toLower('${functionAppName}-appsvc')
var functionInsightsName = toLower('${functionAppName}-insights')

var cosmosConnectionStringReference = '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=cosmosConnectionString)'
var serviceBusReceiveConnectionStringReference = '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=serviceBusReceiveConnectionString)'
var serviceBusSendConnectionStringReference = '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=serviceBusSendConnectionString)'

// --------------------------------------------------------------------------------
resource storageAccountResource 'Microsoft.Storage/storageAccounts@2019-06-01' existing = { name: functionStorageAccountName }
var functionStorageAccountConnectionString = 'DefaultEndpointsProtocol=https;AccountName=${storageAccountResource.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(storageAccountResource.id, storageAccountResource.apiVersion).keys[0].value}'

resource appInsightsResource 'Microsoft.Insights/components@2020-02-02-preview' = {
    name: functionInsightsName
    location: location
    kind: 'web'
    tags: {
      LastDeployed: runDateTime
      TemplateFile:templateFileName
    }
  properties: {
        Application_Type: 'web'
        //RetentionInDays: 90
        publicNetworkAccessForIngestion: 'Enabled'
        publicNetworkAccessForQuery: 'Enabled'
    }
}

resource appServiceResource 'Microsoft.Web/serverfarms@2021-03-01' = {
    name: appServicePlanName
    location: location
    kind: 'functionapp'
    tags: {
      LastDeployed: runDateTime
      TemplateFile: templateFileName
      SKU: functionAppSku
    }
    sku: {
        name: functionAppSku
        tier: functionAppSkuTier
        size: functionAppSku
        family: functionAppSkuFamily
        capacity: 0
    }
    properties: {
        perSiteScaling: false
        maximumElasticWorkerCount: 1
        isSpot: false
        reserved: true
        isXenon: false
        hyperV: false
        targetWorkerCount: 0
        targetWorkerSizeId: 0
    }
}

resource functionAppResource 'Microsoft.Web/sites@2021-03-01' = {
    name: functionAppName
    location: location
    kind: 'functionapp,linux'
    tags: {
      LastDeployed: runDateTime
      TemplateFile: templateFileName
      SKU: functionAppSku
    }
    identity: {
      type: 'SystemAssigned'
    }
    properties: {
        enabled: true
        hostNameSslStates: [
            {
                name: '${functionAppName}.azurewebsites.net'
                sslState: 'Disabled'
                hostType: 'Standard'
            }
            {
                name: '${functionAppName}.scm.azurewebsites.net'
                sslState: 'Disabled'
                hostType: 'Repository'
            }
        ]
        serverFarmId: appServiceResource.id
        reserved: false
        isXenon: false
        hyperV: false
        siteConfig: {
            appSettings: [
                {
                    name: 'AzureWebJobsStorage'
                    value: functionStorageAccountConnectionString
                }
                {
                    name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
                    value: functionStorageAccountConnectionString
                }
                {
                    name: 'WEBSITE_CONTENTSHARE'
                    value: toLower(functionAppName)
                }
                {
                    name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
                    value: appInsightsResource.properties.InstrumentationKey
                }
                {
                    name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
                    value: 'InstrumentationKey=${reference(appInsightsResource.id, '2018-05-01-preview').InstrumentationKey}'
                }
                {
                    name: 'FUNCTIONS_WORKER_RUNTIME'
                    value: 'dotnet'
                }
                {
                    name: 'FUNCTIONS_EXTENSION_VERSION'
                    value: '~4'
                }
                {
                    name: 'cosmosDatabaseName'
                    value: cosmosDatabaseName
                }
                {
                    name: 'cosmosContainerName'
                    value: productsContainerName
                }
                {
                    name: 'ordersContainerName'
                    value: ordersContainerName
                }
                {
                    name: 'orderReceivedQueue'
                    value: orderReceivedQueue
                }
                {
                    name: 'ordersToErpQueue'
                    value: ordersToErpQueue
                }
                {
                    name: 'cosmosConnectionString'
                    value: cosmosConnectionStringReference
                }
                {
                    name: 'serviceBusReceiveConnectionString'
                    value: serviceBusReceiveConnectionStringReference
                }
                {
                    name: 'serviceBusSendConnectionString'
                    value: serviceBusSendConnectionStringReference
                }        
              ]            
        }
        scmSiteAlsoStopped: false
        clientAffinityEnabled: false
        clientCertEnabled: false
        hostNamesDisabled: false
        dailyMemoryTimeQuota: 0
        httpsOnly: true
        redundancyMode: 'None'
    }
}

resource functionAppConfig 'Microsoft.Web/sites/config@2018-11-01' = {
    name: '${functionAppResource.name}/web'
    properties: {
        numberOfWorkers: -1
        defaultDocuments: [
            'Default.htm'
            'Default.html'
            'Default.asp'
            'index.htm'
            'index.html'
            'iisstart.htm'
            'default.aspx'
            'index.php'
            'hostingstart.html'
        ]
        netFrameworkVersion: 'v4.0'
        linuxFxVersion: 'dotnet|3.1'
        requestTracingEnabled: false
        remoteDebuggingEnabled: false
        httpLoggingEnabled: false
        logsDirectorySizeLimit: 35
        detailedErrorLoggingEnabled: false
        publishingUsername: '$${functionAppName}'
        azureStorageAccounts: {            
        }
        scmType: 'None'
        use32BitWorkerProcess: false
        webSocketsEnabled: false
        alwaysOn: false
        managedPipelineMode: 'Integrated'
        virtualApplications: [
            {
                virtualPath: '/'
                physicalPath: 'site\\wwwroot'
                preloadEnabled: true
            }
        ]
        loadBalancing: 'LeastRequests'
        experiments: {
            rampUpRules: [                
            ]
        }
        autoHealEnabled: false
        cors: {
            allowedOrigins: [
                'https://functions.azure.com'
                'https://functions-staging.azure.com'
                'https://functions-next.azure.com'
            ]
            supportCredentials: false
        }
        localMySqlEnabled: false
        ipSecuriyRestrictions: [
            {
                ipAddress: 'Any'
                action: 'Allow'
                priority: 1
                name: 'Allow all'
                description: 'Wide open to the world :)'
            }
        ]
        scmIpSecurityRestrictions: [
            {
                ipAddress: 'Any'
                action: 'Allow'
                priority: 1
                name: 'Allow all'
                description: 'Wide open to the world :)'
            }            
        ]
        scmIpSecurityRestrictionsUseMain: false
        http20Enabled: true
        minTlsVersion: '1.2'
        ftpsState: 'AllAllowed'
        reservedInstanceCount: 0
    }
}

resource functionAppBinding 'Microsoft.Web/sites/hostNameBindings@2018-11-01' = {
    name: '${functionAppResource.name}/${functionAppResource.name}.azurewebsites.net'
    properties: {
        siteName: functionAppName
        hostNameType: 'Verified'
    }
}

output functionAppPrincipalId string = functionAppResource.identity.principalId
output functionAppName string = functionAppName
output functionInsightsName string = functionInsightsName
output functionInsightsKey string = appInsightsResource.properties.InstrumentationKey
output functionStorageAccountName string = functionStorageAccountName
