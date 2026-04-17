param location string
param tags object
param name string
param serviceName string

param storageAccountName string
param tableServiceUri string
param applicationInsightsConnectionString string

// Consumption plan (Windows, dynamic)
resource functionPlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: 'plan-${name}'
  location: location
  tags: tags
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
  kind: 'functionapp'
  properties: {
    reserved: false
  }
}

resource functionApp 'Microsoft.Web/sites@2023-01-01' = {
  name: name
  location: location
  tags: union(tags, { 'azd-service-name': serviceName })
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: functionPlan.id
    httpsOnly: true
    siteConfig: {
      netFrameworkVersion: 'v10.0'
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      appSettings: [
        // Managed-identity-based host storage (no connection string / shared key)
        {
          name: 'AzureWebJobsStorage__accountName'
          value: storageAccountName
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'dotnet-isolated'
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: applicationInsightsConnectionString
        }
        // Table Storage URI for task data (MI auth via DefaultAzureCredential)
        {
          name: 'TABLE_SERVICE_URI'
          value: tableServiceUri
        }
      ]
    }
  }
}

output functionAppUrl string = 'https://${functionApp.properties.defaultHostName}'
output principalId string = functionApp.identity.principalId
output name string = functionApp.name
