@description('Location for all resources.')
param location string

@description('Name of the Web Farm')
param serverFarmName string 

@description('Web App 1 name must be unique DNS name worldwide')
param site1_Name string

@description('Web App 2 name must be unique DNS name worldwide')
param site2_Name string

@description('SKU name, must be minimum P1v2')
@allowed([
  'P1v2'
  'P2v2'
  'P3v2'
])
param skuName string = 'P1v2'

@description('SKU size, must be minimum P1v2')
@allowed([
  'P1v2'
  'P2v2'
  'P3v2'
])
param skuSize string = 'P1v2'

@description('SKU family, must be minimum P1v2')
@allowed([
  'P1v2'
  'P2v2'
  'P3v2'
])
param skuFamily string = 'P1v2'

param hubVNetName string

param spokeVNetName string

resource hubvnet 'Microsoft.Network/virtualNetworks@2021-05-01' existing = {
  scope: resourceGroup()
  name: hubVNetName
}

resource spokevnet 'Microsoft.Network/virtualNetworks@2021-05-01' existing = {
  scope: resourceGroup()
  name: spokeVNetName
}

@description('Delegation Subnet Name')
param delegationSubnet string

@description('Private Endpoint Subnet Name')
param privateEndpointSubnet string

@description('Name of your Private Endpoint')
param feAppPrivateEndpointName string

@description('Name of your Private Endpoint')
param apiAppPrivateEndpointName string

@description('Link name between your Private Endpoint and your Web App')
param privateLinkConnectionFeAppName string = 'privateLinkConnectionFeApp'

@description('Link name between your Private Endpoint and your Web App')
param privateLinkConnectionApiAppName string = 'privateLinkConnectionApiApp'

var webapp_dns_name = '.azurewebsites.net'
var privateDNSZoneNameSites = 'privatelink.azurewebsites.net'
var SKU_tier = 'PremiumV2'

resource serverFarm 'Microsoft.Web/serverfarms@2021-02-01' = {
  name: serverFarmName
  location: location
  sku: {
    name: skuName
    tier: SKU_tier
    size: skuSize
    family: skuFamily
    capacity: 1
  }
  kind: 'app'
}

resource webApp1 'Microsoft.Web/sites@2021-03-01' = {
  name: site1_Name
  location: location
  kind: 'app'
  properties: {
    serverFarmId: serverFarm.id
    siteConfig: {
      minTlsVersion: '1.2'
    }
  }
}

resource webApp2 'Microsoft.Web/sites@2021-03-01' = {
  name: site2_Name
  location: location
  kind: 'app'
  properties: {
    serverFarmId: serverFarm.id
    siteConfig: {
      minTlsVersion: '1.2'
    }
  }
}

resource webApp2AppSettingsApp1 'Microsoft.Web/sites/config@2020-06-01' = {
  parent: webApp1
  name: 'appsettings'
  properties: {
    WEBSITE_DNS_SERVER: '168.63.129.16'
    WEBSITE_VNET_ROUTE_ALL: '1'
  }
}

resource webApp2AppSettingsApp2 'Microsoft.Web/sites/config@2020-06-01' = {
  parent: webApp2
  name: 'appsettings'
  properties: {
    WEBSITE_DNS_SERVER: '168.63.129.16'
    WEBSITE_VNET_ROUTE_ALL: '1'
  }
}

resource webApp1Binding 'Microsoft.Web/sites/hostNameBindings@2019-08-01' = {
  parent: webApp1
  name: '${webApp1.name}${webapp_dns_name}'
  properties: {
    siteName: webApp1.name
    hostNameType: 'Verified'
  }
}

resource webApp2Binding 'Microsoft.Web/sites/hostNameBindings@2019-08-01' = {
  parent: webApp2
  name: '${webApp2.name}${webapp_dns_name}'
  properties: {
    siteName: webApp2.name
    hostNameType: 'Verified'
  }
}

resource webApp1NetworkConfig 'Microsoft.Web/sites/networkConfig@2020-06-01' = {
  parent: webApp1
  name: 'virtualNetwork'
  properties: {
    subnetResourceId: resourceId('Microsoft.Network/virtualNetworks/subnets',spokevnet.name,delegationSubnet)
  }
}

resource webApp2NetworkConfig 'Microsoft.Web/sites/networkConfig@2020-06-01' = {
  parent: webApp2
  name: 'virtualNetwork'
  properties: {
    subnetResourceId: resourceId('Microsoft.Network/virtualNetworks/subnets',spokevnet.name ,delegationSubnet)
  }
}

resource feAppPrivateEndpoint 'Microsoft.Network/privateEndpoints@2020-06-01' = {
  name: feAppPrivateEndpointName
  location: location
  properties: {
    subnet: {
      id: resourceId('Microsoft.Network/virtualNetworks/subnets',spokevnet.name,privateEndpointSubnet)
    }
    privateLinkServiceConnections: [
      {
        name: privateLinkConnectionFeAppName
        properties: {
          privateLinkServiceId: webApp1.id
          groupIds: [
            'sites'
          ]
        }
      }
    ]
  }
}

resource privateEndpoint2 'Microsoft.Network/privateEndpoints@2020-06-01' = {
  name: apiAppPrivateEndpointName
  location: location
  properties: {
    subnet: {
      id: resourceId('Microsoft.Network/virtualNetworks/subnets',spokevnet.name ,privateEndpointSubnet)
    }
    privateLinkServiceConnections: [
      {
        name: privateLinkConnectionApiAppName
        properties: {
          privateLinkServiceId: webApp2.id
          groupIds: [
            'sites'
          ]
        }
      }
    ]
  }
}

resource privateDnsZonesSites 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: privateDNSZoneNameSites
  location: 'global'
}

resource privateDnsZoneLinkSitesSpoke 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  parent: privateDnsZonesSites
  name: '${spokevnet.name}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: spokevnet.id
    }
  }
}

resource privateDnsZoneLinkSitesHub 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  parent: privateDnsZonesSites
  name: '${hubvnet.name}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: hubvnet.id
    }
  }
}

resource privateDnsZoneGroupSites1 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-03-01' = {
  parent: feAppPrivateEndpoint
  name: 'dnsgroupnamesite1'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: privateDnsZonesSites.id
        }
      }
    ]
  }
}

resource privateDnsZoneGroupSites2 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-03-01' = {
  parent: privateEndpoint2
  name: 'dnsgroupnamesite2'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: privateDnsZonesSites.id
        }
      }
    ]
  }
}

output webAppHostName string = webApp1.properties.hostNames[0]
output apiAppHostName string = webApp2.properties.hostNames[0]
output webApp1Url string = 'http://${webApp1.properties.hostNames[0]}/'
output webApp2Url string = 'http://${webApp2.properties.hostNames[0]}/'
