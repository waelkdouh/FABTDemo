@description('Location for all resources.')
param location string

@description('The administrator username of the SQL logical server')
param sqlAdministratorLogin string

@description('The administrator password of the SQL logical server.')
@secure()
param sqlAdministratorLoginPassword string

@description('Name of your Private Endpoint')
param sqlServerPrivateEndpointName string

@description('Link name between your Private Endpoint and your Web App')
param privateLinkConnectionName3 string = 'PrivateEndpointLink3'

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

@description('Private Endpoint Subnet Name')
param privateEndpointSubnet string

var sqlServerName_var = 'sqlserver${uniqueString(resourceGroup().id)}'
var databaseName_var = '${sqlServerName_var}/coreDb'

var privateDnsZoneNameSql = 'privatelink${environment().suffixes.sqlServerHostname}'

resource sqlServerName 'Microsoft.Sql/servers@2021-11-01-preview' = {
  name: sqlServerName_var
  location: location
  tags: {
    displayName: sqlServerName_var
  }
  properties: {
    administratorLogin: sqlAdministratorLogin
    administratorLoginPassword: sqlAdministratorLoginPassword
    version: '12.0'
    publicNetworkAccess: 'Disabled'
  }
}

resource databaseName 'Microsoft.Sql/servers/databases@2021-11-01-preview' = {
  name: databaseName_var
  location: location
  sku: {
    name: 'Basic'
    tier: 'Basic'
    capacity: 5
  }
  tags: {
    displayName: databaseName_var
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    // edition: 'Basic'
    maxSizeBytes: 104857600
    // requestedServiceObjectiveName: 'Basic'
    sampleName: 'AdventureWorksLT'
  }
  dependsOn: [
    sqlServerName
  ]
}

resource privateEndpoint3 'Microsoft.Network/privateEndpoints@2020-06-01' = {
  name: sqlServerPrivateEndpointName
  location: location
  properties: {
    subnet: {
      id: resourceId('Microsoft.Network/virtualNetworks/subnets', spokevnet.name , privateEndpointSubnet)
    }
    privateLinkServiceConnections: [
      {
        name: privateLinkConnectionName3
        properties: {
          privateLinkServiceId: sqlServerName.id
          groupIds: [
            'sqlServer'
          ]
        }
      }
    ]
  }
}

resource privateDnsZonesSql 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: privateDnsZoneNameSql
  location: 'global'
}

resource privateDnsZoneLinkSqlSpoke 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  parent: privateDnsZonesSql
  name: 'sql-${spokevnet.name}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: spokevnet.id
    }
  }
}

resource privateDnsZoneLinkSqlHub 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  parent: privateDnsZonesSql
  name: 'sql-${hubvnet.name}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: hubvnet.id
    }
  }
}

resource privateDnsZoneGroupSql 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-03-01' = {
  parent: privateEndpoint3
  name: 'dnsgroupnameSql'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: privateDnsZonesSql.id
        }
      }
    ]
  }
}
