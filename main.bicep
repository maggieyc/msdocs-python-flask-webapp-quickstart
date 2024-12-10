@description('The location for the resources')
param location string = resourceGroup().location

@description('Name of the ACR')
param containerRegistryName string

@description('Name of the container image')
param containerRegistryImageName string

@description('Version of the container image')
param containerRegistryImageVersion string

@description('Name of the App Service Plan')
param appServicePlanName string

@description('Name of the Web App')
param webAppName string



@description('Name of the Key Vault')
param keyVaultName string

@description('Enable vault for deployment')
param enableVaultForDeployment bool = true

@description('Key Vault role assignments')
param roleAssignments array = [

  {
    principalId: '7200f83e-ec45-4915-8c52-fb94147cfe5a'
    roleDefinitionIdOrName: 'Key Vault Secrets User'
    principalType: 'ServicePrincipal'
  }

  {
    principalId: 'a03130df-486f-46ea-9d5c-70522fe056de' // Group.
    roleDefinitionIdOrName: 'Key Vault Administrator'
    principalType: 'Group'
  }

  {
    principalId: '25d8d697-c4a2-479f-96e0-15593a830ae5'
    roleDefinitionIdOrName: 'Key Vault Secrets User'
    principalType: 'ServicePrincipal'
  }

]

@description('Name of the Key Vault secret for ACR Username')
param acrAdminUserNameSecretName string = 'acrAdminUserName'

@description('Name of the Key Vault secret for ACR Password')
param acrAdminUserPasswordSecretName string = 'acrAdminUserPassword1'


module keyVault './modules/key-vault.bicep' = {
  name: 'keyVaultModule'
  params: {
    name: keyVaultName
    location: location
    enableVaultForDeployment: enableVaultForDeployment
    roleAssignments: roleAssignments
    enableSoftDelete: true
  }
}


module acr './modules/acr.bicep' = {
  name: 'acrModule'
  params: {
    name: containerRegistryName
    location: location
    acrAdminUserEnabled: true
    adminCredentialsKeyVaultResourceId: keyVault.outputs.keyVaultResourceId
    adminCredentialsKeyVaultSecretUserName: acrAdminUserNameSecretName
    adminCredentialsKeyVaultSecretUserPassword1: acrAdminUserPasswordSecretName
  }
}


module appServicePlan './modules/asp.bicep' = {
  name: 'appServicePlanModule'
  params: {
    name: appServicePlanName
    location: location
    sku: {
      capacity: 1
      family: 'B'
      name: 'B1'
      size: 'B1'
      tier: 'Basic'
    }
    kind: 'Linux'
    reserved: true
  }
}

resource keyvault 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: keyVaultName
}

// Deploy Web App with secrets from Key Vault

module webApp './modules/awa.bicep' = {
  name: 'webAppModule'
  params: {
    name: webAppName
    location: location
    kind: 'app'
    serverFarmResourceId: appServicePlan.outputs.resourceId
    siteConfig: {
      linuxFxVersion: 'DOCKER|${containerRegistryName}.azurecr.io/${containerRegistryImageName}:${containerRegistryImageVersion}'
      appCommandLine: ''
    }
    appSettingsKeyValuePairs: {
      WEBSITES_ENABLE_APP_SERVICE_STORAGE: 'false'
    }
    dockerRegistryServerUrl: 'https://${containerRegistryName}.azurecr.io'
    dockerRegistryServerUserName: keyvault.getSecret(acrAdminUserNameSecretName)
    dockerRegistryServerPassword: keyvault.getSecret(acrAdminUserPasswordSecretName)
  }
}
