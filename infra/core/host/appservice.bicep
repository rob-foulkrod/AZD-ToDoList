param location string
param tags object
param name string
param serviceName string

@description('Base URL of the Azure Functions API (e.g. https://func-xxx.azurewebsites.net)')
param apiUrl string

param applicationInsightsConnectionString string

// Linux App Service Plan (Basic B1)
resource appServicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: 'plan-${name}'
  location: location
  tags: tags
  sku: {
    name: 'B1'
    tier: 'Basic'
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
}

resource appService 'Microsoft.Web/sites@2023-01-01' = {
  name: name
  location: location
  tags: union(tags, { 'azd-service-name': serviceName })
  kind: 'app,linux'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'DOTNETCORE|10.0'
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      appSettings: [
        {
          name: 'API_URL'
          value: apiUrl
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: applicationInsightsConnectionString
        }
      ]
    }
  }
}

output appServiceUrl string = 'https://${appService.properties.defaultHostName}'
output principalId string = appService.identity.principalId
output name string = appService.name
