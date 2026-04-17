targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the environment that maps to the azd environment (azd-env-name tag).')
param environmentName string

@minLength(1)
@description('Primary Azure region for all resources.')
param location string

var tags = { 'azd-env-name': environmentName, SecurityControl: 'Ignore' }
var resourceSuffix = take(uniqueString(subscription().id, environmentName, location), 6)

// ---------------------------------------------------------------------------
// Resource Group
// ---------------------------------------------------------------------------
resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: 'rg-${environmentName}'
  location: location
  tags: tags
}

// ---------------------------------------------------------------------------
// Monitoring (Log Analytics + Application Insights)
// ---------------------------------------------------------------------------
module monitoring './core/monitor/monitoring.bicep' = {
  name: 'monitoring'
  scope: rg
  params: {
    location: location
    tags: tags
    logAnalyticsName: 'log-taskdemo-${resourceSuffix}'
    applicationInsightsName: 'appi-taskdemo-${resourceSuffix}'
  }
}

// ---------------------------------------------------------------------------
// Application Insights Dashboard (enables `azd monitor`)
// ---------------------------------------------------------------------------
module dashboard './core/monitor/dashboard.bicep' = {
  name: 'dashboard'
  scope: rg
  params: {
    location: location
    tags: tags
    name: 'dash-taskdemo-${resourceSuffix}'
    applicationInsightsId: monitoring.outputs.applicationInsightsId
    applicationInsightsName: monitoring.outputs.applicationInsightsName
  }
}

// ---------------------------------------------------------------------------
// Storage Account  (managed-identity only — no shared-key access)
// ---------------------------------------------------------------------------
module storage './core/storage/storage.bicep' = {
  name: 'storage'
  scope: rg
  params: {
    location: location
    tags: tags
    name: 'sttaskdemo${resourceSuffix}'
  }
}

// ---------------------------------------------------------------------------
// API — Azure Functions (Consumption plan, Windows, .NET 8 isolated)
// ---------------------------------------------------------------------------
module api './core/host/function.bicep' = {
  name: 'api'
  scope: rg
  params: {
    location: location
    tags: union(tags, { 'azd-service-name': 'api' })
    name: 'func-taskdemo-${resourceSuffix}'
    storageAccountName: storage.outputs.name
    tableServiceUri: storage.outputs.tableServiceUri
    applicationInsightsConnectionString: monitoring.outputs.applicationInsightsConnectionString
  }
}

// ---------------------------------------------------------------------------
// Web — Azure App Service (Linux, .NET 8)
// ---------------------------------------------------------------------------
module web './core/host/appservice.bicep' = {
  name: 'web'
  scope: rg
  params: {
    location: location
    tags: union(tags, { 'azd-service-name': 'web' })
    name: 'app-taskdemo-${resourceSuffix}'
    apiUrl: api.outputs.functionAppUrl
    applicationInsightsConnectionString: monitoring.outputs.applicationInsightsConnectionString
  }
}

// ---------------------------------------------------------------------------
// RBAC — grant Function App's MI access to Storage
// ---------------------------------------------------------------------------
module apiStorageRoles './core/security/roleAssignments.bicep' = {
  name: 'api-storage-roles'
  scope: rg
  params: {
    principalId: api.outputs.principalId
    storageAccountName: storage.outputs.name
  }
}

// ---------------------------------------------------------------------------
// Outputs consumed by azd and the application
// ---------------------------------------------------------------------------
output AZURE_LOCATION string = location
output SERVICE_WEB_URI string = web.outputs.appServiceUrl
output SERVICE_API_URI string = api.outputs.functionAppUrl
