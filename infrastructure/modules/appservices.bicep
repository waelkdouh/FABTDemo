@description('Location for all resources')
param location string

@description('Name of the Web Farm')
param serverFarmName string

@description('Web Farm Sku name, minimum P1v2')
@allowed([
  'P1v2'
  'P2v2'
  'P3v2'
])
param skuName string = 'P1v2'

param webSites array = [
  {
    name: 'test'
  }
  {
    name: 'test2'
  }
]

@description('Name of private endpoint subnet')
param privateEndpointSubnetName string

@description('Name of the spoke vnet')
param spokeVNetName string

@description('delegation subnet name')
param delegationSubnetName string

@description('Name of the hub vnet')
param hubVNetName string

var serverFarmSKUTier = 'PremiumV2'

resource spokevnet 'Microsoft.Network/virtualNetworks@2021-03-01' existing = {
  scope: resourceGroup()
  name: spokeVNetName
}

resource hubvnet 'Microsoft.Network/virtualNetworks@2021-03-01' existing = {
  scope: resourceGroup()
  name: hubVNetName
}

resource privateDNSZonesSites 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: 'privatelink.azurewebsites.net'
  location: 'global'
}

resource privateDNSZoneLinkSitesSpoke 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  parent: privateDNSZonesSites
  name: '${spokevnet.name}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: spokevnet.id
    }
  }
}

resource privateDNSZoneLinkSitesHub 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  parent: privateDNSZonesSites
  name: '${hubvnet.name}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork:{
      id: hubvnet.id
    }
  }
}


resource serverFarm 'Microsoft.Web/serverfarms@2021-02-01' = {
  name: serverFarmName
  location: location
  sku: {
    name: skuName
    tier: serverFarmSKUTier
  }
  kind: 'app'
}

module webAppsModule 'appservices-webapp.bicep' = [for (wa, i) in webSites: {
  name: 'webapp${i}'
  params: {
    location: location
    privateDNSZonesSitesId: privateDNSZonesSites.id
    serverFarmId: serverFarm.id
    delegationSubnetName: delegationSubnetName
    privateEndpointSubnetName: privateEndpointSubnetName
    attachVNetName: spokevnet.name
    siteName: wa.name
  }
}]


output hostNames array = [for (site, i) in webSites : {
  Hostnames: webAppsModule[i].outputs.hostNames[0]
}]

