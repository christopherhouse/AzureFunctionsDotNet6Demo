// --------------------------------------------------------------------------------
// This BICEP file will create a Cosmos Database for the Azure Function Example Project
// TODO: Change this to use array of containers...
// --------------------------------------------------------------------------------
param orgPrefix string = 'org'
param appPrefix string = 'app'
@allowed(['dev','qa','stg','prod'])
param environmentCode string = 'dev'
param appSuffix string = '1'
param location string = resourceGroup().location
param runDateTime string = utcNow()
param templateFileName string = '~function.bicep'

param productsContainerName string = 'products'
param productsPartitionKey string = '/category'
param ordersContainerName string = 'orders'
param ordersPartitionKey string = '/customerNumber'

// --------------------------------------------------------------------------------
var cosmosAccountName = '${orgPrefix}-${appPrefix}-cosmos-acct${environmentCode}${appSuffix}'
var cosmosDatabaseName = '${orgPrefix}-${appPrefix}-cosmos-db${environmentCode}${appSuffix}'

// --------------------------------------------------------------------------------
resource cosmosAccountResource 'Microsoft.DocumentDB/databaseAccounts@2022-05-15' = {
    name: cosmosAccountName
    location: location
    tags: {
        LastDeployed: runDateTime
        templateFileName: templateFileName
        defaultExperience: 'Core (SQL)'
        CosmosAccountType: 'Non-Production'
    }
    kind: 'GlobalDocumentDB'
    identity: {
        type: 'None'
    }
    properties: {
        publicNetworkAccess: 'Enabled'
        locations: [
            {
              locationName: location
              failoverPriority: 0
              isZoneRedundant: false
            }
          ]
        enableAutomaticFailover: false
        enableMultipleWriteLocations: false
        isVirtualNetworkFilterEnabled: false
        virtualNetworkRules: []
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

resource cosmosDbResource 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2020-06-01-preview' = {
    name: '${cosmosAccountResource.name}/${cosmosDatabaseName}'
    properties: {
        resource: {
            id: cosmosDatabaseName
        }
        options: {
        }
    }
}

resource productsContainerResource 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2020-06-01-preview' = {
    name: '${cosmosDbResource.name}/${productsContainerName}'
    properties: {
        resource: {
            id: productsContainerName
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
                    productsPartitionKey
                ]
                kind: 'Hash'
            }
            conflictResolutionPolicy: {
                mode: 'LastWriterWins'
                conflictResolutionPath: '/_ts'
            }
        }
        options: {
        }
    }
}

resource ordersContainerResource 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2020-06-01-preview' = {
    name: '${cosmosDbResource.name}/${ordersContainerName}'
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
        options: {
        }
    }
}

output cosmosAccountName string = cosmosAccountName
