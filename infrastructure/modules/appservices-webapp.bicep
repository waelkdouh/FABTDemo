@description('location')
param location string

@description('site name')
param siteName string

@description('resource id of the server farm')
param serverFarmId string

@description('vnet name that webapp is attached to')
param attachVNetName string

@description('delegation subnet Name')
param delegationSubnetName string

@description('private endpoint subnet name')
param privateEndpointSubnetName string

@description('private dns zones site id')
param privateDNSZonesSitesId string

var uniqueSiteName = '${siteName}${uniqueString(resourceGroup().id)}' 

resource attachVNet 'Microsoft.Network/virtualNetworks@2021-03-01' existing = {
  scope: resourceGroup()
  name: attachVNetName
}

resource webApp 'Microsoft.Web/sites@2021-02-01' =  {
  name: uniqueSiteName
  location: location
  kind: 'app'
  properties: {
    serverFarmId: serverFarmId
    siteConfig: {
      minTlsVersion: '1.2'
      appSettings:[
        {
          name: 'WEBSITE_DNS_SERVER'
          value: '168.63.129.16'
        }
        {
          name: 'WEBSITE_VNET_ROUTE_ALL'
          value: '1'
        }
      ]
    }
    virtualNetworkSubnetId: resourceId('Microsoft.Network/virtualNetworks/subnets', attachVNet.name, delegationSubnetName)
  }
}

resource webAppBinding 'Microsoft.Web/sites/hostNameBindings@2021-02-01'= {
  name: '${uniqueSiteName}.azurewebsites.net'
  parent: webApp
  properties: {
    siteName: uniqueSiteName
    hostNameType: 'Verified'
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2020-06-01' = {
  name: '${uniqueSiteName}privateEndpoint'
  location: location
  properties: {
    subnet: {
      id: resourceId('Microsoft.Network/virtualNetworks/subnets', attachVNet.name, privateEndpointSubnetName )
    }
    privateLinkServiceConnections:[
      {
        name: 'privateLinkConnection${uniqueSiteName}'
        properties: {
          privateLinkServiceId: webApp.id
          groupIds: [
            'sites'
          ]
        }
      }
    ]
  }
}

resource privateDnsZoneGroupSites 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-03-01' =  {
  parent: privateEndpoint
  name: 'dnsgroupnamesite${uniqueSiteName}'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: privateDNSZonesSitesId
        }
      }
    ]
  }
}

output hostNames array = webApp.properties.hostNames
