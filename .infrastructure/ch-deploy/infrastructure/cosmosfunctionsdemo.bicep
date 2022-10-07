param location string = resourceGroup().location
param functionAppName string
param cosmosAccountName string
param cosmosDatabaseName string
param cosmosContainerName string
param cosmosContainerPartitionKey string
param ordersContainerName string
param ordersPartitionKey string

var functionHostName = '${functionAppName}.azurewebsites.net'
var functionScmHostName = '${functionAppName}.scm.azurewebsites.net'
var functionStorage = uniqueString(functionAppName)
var functionFarmName = '${functionAppName}-farm'
var appInsightsName = '${functionAppName}-insights'

resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2020-06-01-preview' = {
    name: cosmosAccountName
    location: location
    tags: {
        defaultExperience: 'Core (SQL)'
        'hidden-cosmos-mmspecial': ''
        'CosmosAccountType': 'Non-Production'
    }
    kind: 'GlobalDocumentDB'
    identity: {
        type: 'None'
    }
    properties: {
        publicNetworkAccess: 'Enabled'
        enableAutomaticFailover: false
        enableMultipleWriteLocations: false
        isVirtualNetworkFilterEnabled: false
        virtualNetworkRules: [            
        ]
        disableKeyBasedMetadataWriteAccess: false
        enableFreeTier: false
        enableAnalyticalStorage: false
        createMode: 'Default'
        databaseAccountOfferType: 'Standard'
        consistencyPolicy: {
            defaultConsistencyLevel: 'Session'
            maxIntervalInSeconds: 5
            maxStalenessPrefix: 100
        }
        capabilities: [
            {
                name: 'EnableServerless'
            }
        ]
        ipRules: [            
        ]
        backupPolicy: {
            type: 'Periodic'
            periodicModeProperties: {
                backupIntervalInMinutes: 240
                backupRetentionIntervalInHours: 8
            }
        }
    }
}

resource cosmosDb 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2020-06-01-preview' = {
    name: '${cosmosAccount.name}/${cosmosDatabaseName}'
    properties: {
        resource: {
            id: cosmosDatabaseName
        }
    }
}

resource cosmosContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2020-06-01-preview' = {
    name: '${cosmosDb.name}/${cosmosContainerName}'
    properties: {
        resource: {
            id: cosmosContainerName
            indexingPolicy: {
                indexingMode: 'consistent'
                automatic: true
                includedPaths: [
                    {
                        path: '/*'
                    }
                ]
                excludedPaths: [
                    {
                        path: '/"_etag"/?'
                    }
                ]
            }
            partitionKey: {
                paths: [
                    cosmosContainerPartitionKey
                ]
                kind: 'Hash'
            }
            conflictResolutionPolicy: {
                mode: 'LastWriterWins'
                conflictResolutionPath: '/_ts'
            }
        }
    }
}

resource ordersContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2020-06-01-preview' = {
    name: '${cosmosDb.name}/${ordersContainerName}'
    properties: {
        resource: {
            id: ordersContainerName
            indexingPolicy: {
                indexingMode: 'consistent'
                automatic: true
                includedPaths: [
                    {
                        path: '/*'
                    }
                ]
                excludedPaths: [
                    {
                        path: '/"_etag"/?'
                    }
                ]
            }
            partitionKey: {
                paths: [
                    ordersPartitionKey
                ]
                kind: 'hash'
            }
            conflictResolutionPolicy: {
                mode: 'LastWriterWins'
                conflictResolutionPath: '/_ts'
            }
        }
    }
}

resource storage 'Microsoft.Storage/storageAccounts@2019-06-01' = {
    name: functionStorage
    location: location
    sku: {
        name: 'Standard_LRS'
        tier: 'Standard'
    }
    kind: 'Storage'
    properties: {
        networkAcls: {
            bypass: 'AzureServices'
            virtualNetworkRules: [                
            ]
            ipRules: [                
            ]
            defaultAction: 'Allow'
        }
        supportsHttpsTrafficOnly: true
        encryption: {
            services: {
                file: {
                    keyType: 'Account'
                    enabled: true
                }
                blob: {
                    keyType: 'Account'
                    enabled: true
                }
            }
            keySource: 'Microsoft.Storage'
        }
    }
}

resource blobServices 'Microsoft.Storage/storageAccounts/blobServices@2019-06-01' = {
    name: '${storage.name}/default'
    sku: {
        name: 'Standard_LRS'
        tier: 'Standard'
    }
    properties: {
        cors: {
            corsRules: [                
            ]
        }
        deleteRetentionPolicy: {
            enabled: true
            days: 7
        }
    }
}

resource appInsights 'Microsoft.Insights/components@2020-02-02-preview' = {
    name: appInsightsName
    location: location
    kind: 'web'
    properties: {
        Application_Type: 'web'
        RetentionInDays: 90
        publicNetworkAccessForIngestion: 'Enabled'
        publicNetworkAccessForQuery: 'Enabled'
    }
}

resource appService 'Microsoft.Web/serverFarms@2019-08-01' = {
    name: functionFarmName
    location: location
    kind: 'functionapp'
    sku: {
        name: 'Y1'
        tier: 'Dyanmic'
        size: 'Y1'
        family: 'Y'
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

resource functionApp 'Microsoft.Web/sites@2018-11-01' = {
    name: functionAppName
    location: location
    kind: 'functionapp,linux'
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
        serverFarmId: appService.id
        reserved: false
        isXenon: false
        hyperV: false
        siteConfig: {
            appSettings: [
                {
                    name: 'AzureWebJobsStorage'
                    value: 'DefaultEndpointsProtocol=https;AccountName=${storage.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(storage.id, '2019-06-01').keys[0].value}'
                }
                {
                    name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
                    value: 'DefaultEndpointsProtocol=https;AccountName=${storage.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(storage.id, '2019-06-01').keys[0].value}'
                }
                {
                    name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
                    value: '${reference(appInsights.id, '2018-05-01-preview').InstrumentationKey}'
                }
                {
                    name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
                    value: 'InstrumentationKey=${reference(appInsights.id, '2018-05-01-preview').InstrumentationKey}'
                }
                {
                    name: 'Functions_WORKER_RUNTIME'
                    value: 'dotnet'
                }
                {
                    name: 'FUNCTIONS_EXTENSION_VERSION'
                    value: '~3'
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
    name: '${functionApp.name}/web'
    location: location
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
    name: '${functionApp.name}/${functionApp.name}.azurewebsites.net'
    location: location
    properties: {
        siteName: functionAppName
        hostNameType: 'Verified'
    }
}