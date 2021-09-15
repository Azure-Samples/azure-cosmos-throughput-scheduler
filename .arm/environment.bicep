param location string = resourceGroup().location
param env string = 'prod'
param namePostfix string = uniqueString(subscription().id, resourceGroup().id)
param d365url string = 'https://crfusa.crm.dynamics.com'

// App Service Plan
resource serverFarm 'Microsoft.Web/serverfarms@2020-06-01' = {
  name: 'functions'
  location: resourceGroup().location
  kind: 'windows'
  sku: {
    tier: 'Dynamic'
    name: 'Y1'
  }
}

// Storage Account
resource storageAcct 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: take('c2ccrmsync${namePostfix}', 24)
  location: resourceGroup().location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    supportsHttpsTrafficOnly: true
  }
}

var primaryKey = listKeys(storageAcct.name, storageAcct.apiVersion).keys[0].value
var storageConnString = 'DefaultEndpointsProtocol=https;AccountName=${storageAcct.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${primaryKey}'

// App Insights
resource workspace 'Microsoft.OperationalInsights/workspaces@2020-10-01' = {
  name: 'workspace-${namePostfix}'
  location: location
  properties: {
    sku: {
      name: 'Free'
    }
  }
}

resource insights 'Microsoft.Insights/components@2020-02-02-preview' = {
  name: 'insights-${namePostfix}'
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: workspace.id
  }
}

// Functions
resource functions 'Microsoft.Web/sites@2020-06-01' = {
  name: 'functions-${namePostfix}'
  dependsOn: [
    serverFarm
  ]
  location: location
  kind: 'functionapp,linux'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: serverFarm.id
    clientAffinityEnabled: false
    httpsOnly: true
    siteConfig: {
      ftpsState: 'FtpsOnly'
      http20Enabled: true
      linuxFxVersion: 'Python|3.9'
    }
  }

  resource settings 'config' = {
    name: 'appsettings'
    properties: {
      // Cosmos
      AzureCosmos: '@Microsoft.KeyVault(VaultName=${env}-c2c-vault;SecretName=Context--ConnectionString)'

      // D365 settings
      d365_url: d365url
      app_registration_clientid: '3602e48b-7723-4ae8-b9fc-cfaa2ef73d37'
      app_registration_secret: '@Microsoft.KeyVault(VaultName=michaelscrfkeyvault;SecretName=d365-production-secret)'

      AzureWebJobsStorage: storageConnString
      AzureWebJobsDisableHomepage: 'true'
      WEBSITE_CONTENTAZUREFILECONNECTIONSTRING: storageConnString
      APPINSIGHTS_INSTRUMENTATIONKEY: insights.properties.InstrumentationKey
      AZURE_FUNCTIONS_ENVIRONMENT: 'Production'
      FUNCTIONS_EXTENSION_VERSION: '~3'
      FUNCTIONS_WORKER_RUNTIME: 'powershell'
      TZ: 'America/Chicago'
      WEBSITE_CONTENTSHARE: 'crmc2csync'
    }
  }
}

// Output resources
output storageAccount string = storageConnString
output functionAppId string = functions.id
