// --------------------------------------------------------------------------------
// This BICEP file will create a Service Bus for the Azure Function Example Project
// --------------------------------------------------------------------------------
// TODO: put the queue names into an array and create them from that
// --------------------------------------------------------------------------------
param orgPrefix string = 'org'
param appPrefix string = 'app'
@allowed(['dev','qa','stg','prod'])
param environmentCode string = 'dev'
param appSuffix string = '1'
param location string = resourceGroup().location
param runDateTime string = utcNow()
param templateFileName string = '~svcbus.bicep'

param queueNames array = ['orders-received', 'orders-to-erp']

// --------------------------------------------------------------------------------
var serviceBusName = '${orgPrefix}-${appPrefix}-svcbus-${environmentCode}-${appSuffix}'

// --------------------------------------------------------------------------------
resource svcBusResource 'Microsoft.ServiceBus/namespaces@2022-01-01-preview' = {
  name: serviceBusName
  location: location
  tags: {
    LastDeployed: runDateTime
    TemplateFile: templateFileName
  }
  sku: {
    name: 'Basic'
    tier: 'Basic'
  }
  properties: {
    minimumTlsVersion: '1.2'
    publicNetworkAccess: 'Enabled'
    disableLocalAuth: false
    zoneRedundant: false
  }
}

resource svcBusRootManageSharedAccessKeyResource 'Microsoft.ServiceBus/namespaces/AuthorizationRules@2022-01-01-preview' = {
  parent: svcBusResource
  name: 'RootManageSharedAccessKey'
  properties: {
    rights: [
      'Listen'
      'Manage'
      'Send'
    ]
  }
}

resource svcBusQueueResource 'Microsoft.ServiceBus/namespaces/queues@2022-01-01-preview' = [for queueName in queueNames: {
  parent: svcBusResource
  name: queueName
  properties: {
    maxMessageSizeInKilobytes: 256
    lockDuration: 'PT30S'
    maxSizeInMegabytes: 1024
    requiresDuplicateDetection: false
    requiresSession: false
    defaultMessageTimeToLive: 'P14D'
    deadLetteringOnMessageExpiration: false
    enableBatchedOperations: true
    duplicateDetectionHistoryTimeWindow: 'PT10M'
    maxDeliveryCount: 10
    status: 'Active'
    enablePartitioning: false
    enableExpress: false
  }
}]
