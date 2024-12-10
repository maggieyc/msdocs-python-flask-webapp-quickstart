param name string
param location string
param acrAdminUserEnabled bool


@description('Key Vault Resource ID where we store the admin credentials')
param adminCredentialsKeyVaultResourceId string

@secure()
@description('Key Vault secret name for ACR Admin Username')
param adminCredentialsKeyVaultSecretUserName string

@secure()
@description('Key Vault secret name for ACR Admin Password #1')
param adminCredentialsKeyVaultSecretUserPassword1 string




resource adminCredentialsKeyVault 'Microsoft.KeyVault/vaults@2021-10-01' existing = {
  name: last(split(adminCredentialsKeyVaultResourceId, '/'))
}

resource acr 'Microsoft.ContainerRegistry/registries@2021-09-01' = {
  name: name
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: acrAdminUserEnabled
  }
}


// Store ACR Username as a secret
resource secretAdminUserName 'Microsoft.KeyVault/vaults/secrets@2023-02-01' = {
  name: adminCredentialsKeyVaultSecretUserName
  parent: adminCredentialsKeyVault
  properties: {
    value: acr.listCredentials().username
  }
}

// Store ACR Password #1 as a secret
resource secretAdminPassword1 'Microsoft.KeyVault/vaults/secrets@2023-02-01' = {
  name: adminCredentialsKeyVaultSecretUserPassword1
  parent: adminCredentialsKeyVault
  properties: {
    value: acr.listCredentials().passwords[0].value
  }
}



//output credentials object = {
//  username: acr.listCredentials().username
//  password: acr.listCredentials().passwords[0].value
//}
