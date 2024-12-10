param name string
param location string
param kind string
param serverFarmResourceId string
param siteConfig object
param appSettingsKeyValuePairs object

@secure()
param dockerRegistryServerUrl string

@secure()
param dockerRegistryServerUserName string

@secure()
param dockerRegistryServerPassword string


var dockerAppSettings = {
  DOCKER_REGISTRY_SERVER_URL: dockerRegistryServerUrl
  DOCKER_REGISTRY_SERVER_USERNAME: dockerRegistryServerUserName
  DOCKER_REGISTRY_SERVER_PASSWORD: dockerRegistryServerPassword
}


resource webApp 'Microsoft.Web/sites@2021-02-01' = {
  name: name
  location: location
  kind: kind
  properties: {
    serverFarmId: serverFarmResourceId
    siteConfig: {
      linuxFxVersion: siteConfig.linuxFxVersion
      appCommandLine: siteConfig.appCommandLine
      // Add appSettings within siteConfig
      appSettings: [
        for key in objectKeys(union(appSettingsKeyValuePairs, dockerAppSettings)): {
          name: key
          value: union(appSettingsKeyValuePairs, dockerAppSettings)[key]
        }
      ]
    }
  }
  
}
