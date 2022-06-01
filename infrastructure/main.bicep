@description('Location for all resources.')
param location string = resourceGroup().location

@description('The administrator username of the SQL logical server')
param sqlAdministratorLogin string = 'admingoeshere'

param devopsAgentOSSettings object
param devopsAgentVMName string = 'devopsAgent'
param devopsOrg string
param devopsPool string
param devopsVMUserName string
param keyVaultName string
param keyVaultResourceGroupName string
param devopsVMPasswordSecretName string
param devopsPatSecretName string

@description('Array of website objects containing a property called name, that indicates how you would like the website named')
param websitesArray array = [
  {
    name: 'feweb-${uniqueString(resourceGroup().id)}'
  }
  {
    name: 'webapi-${uniqueString(resourceGroup().id)}'
  }
]

resource secretVault 'Microsoft.KeyVault/vaults@2019-09-01' existing = {
  name: keyVaultName
  scope: resourceGroup(keyVaultResourceGroupName)
}

module hubVNetModule 'modules/hubvnet.bicep' = {
  name: 'hubVNet'
  params: {
    location: location
  }
}

module vNetPeerings 'modules/vnetPeers.bicep' = {
  name: 'vnetPeers'
  params: {
    hubVNetName: hubVNetModule.outputs.virtualNetworkName
    spokeVNetName: vnetModule.outputs.virtualNetworkName
  }
  dependsOn:[
    vnetModule
    hubVNetModule
  ]
}

module vnetModule 'modules/vnet.bicep' = {
  name: 'myApp'
  params: {
    location: location
    virtualNetworkName: 'vnet1'
    subnet1Name: 'AppGatewaySubnet'
    subnet2Name: 'WebAppSubnet'
    subnet3Name: 'PrivateEndpointSubnet'
    subnet4Name: 'SqlServerSubnet'
  }
}

module appServiceModule 'modules/appservices.bicep' = {
  name: 'appServices'
  params: {
    delegationSubnetName: vnetModule.outputs.subnet2Name
    hubVNetName: hubVNetModule.outputs.virtualNetworkName
    location: location
    privateEndpointSubnetName: vnetModule.outputs.subnet3Name
    skuName: 'P1v2'
    serverFarmName: 'serverFarm'
    spokeVNetName: vnetModule.outputs.virtualNetworkName
    webSites: websitesArray
  }
}

module sqlServerServiceModule 'modules/sql-server.bicep' = {
  name: 'sqlServer'
  params: {
    location: location
    sqlAdministratorLogin: sqlAdministratorLogin
    sqlAdministratorLoginPassword: secretVault.getSecret(devopsVMPasswordSecretName)
    sqlServerPrivateEndpointName: 'sqlServerPrivateEndpoint'
    hubVNetName: hubVNetModule.outputs.virtualNetworkName
    spokeVNetName: vnetModule.outputs.virtualNetworkName
    privateEndpointSubnet: vnetModule.outputs.subnet3Name
  }
}

module appGatewayModule 'modules/app-gateway.bicep' = {
  name: 'appGateway'
  params: {
    location: location
    appGatewayName: 'myAppGateway'
    webAppHostNames: appServiceModule.outputs.hostNames
    virtualNetworkName: vnetModule.outputs.virtualNetworkName
    appGatewaySubnet: vnetModule.outputs.subnet1Name
  }
}

module agentVM 'modules/vmdeploy.bicep' ={
  name: 'devopsAgentVM'
  params: {
    imagePublisher: devopsAgentOSSettings.ImagePublisher
    imageVersion: devopsAgentOSSettings.ImageVersion
    subnetName: hubVNetModule.outputs.dnsSubnetName
    vnetName: hubVNetModule.outputs.virtualNetworkName
    adminPassword: secretVault.getSecret(devopsVMPasswordSecretName)
    adminUserName: devopsVMUserName
    imageOffer: devopsAgentOSSettings.ImageOffer
    vmName: devopsAgentVMName
    imageSku: devopsAgentOSSettings.ImageSku
    vnetResourceGroup: resourceGroup().name
    location: location
  }
}

module agentDependencies 'modules/selfHostedAgent.bicep' = {
  name: 'devopsAgentScripts'
  params: {
    location: location
    agentVMName: agentVM.outputs.vmName
    devopsOrg: devopsOrg
    devopsPAT: secretVault.getSecret(devopsPatSecretName)
    devopsPool: devopsPool
  }
  dependsOn: [
    agentVM
  ]
}

output appGatewayUrl string = appGatewayModule.outputs.appGatewayUrl
output webAppUrls array = appServiceModule.outputs.hostNames
