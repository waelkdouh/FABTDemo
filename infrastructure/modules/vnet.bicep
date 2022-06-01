@description('Location for all resources.')
param location string 

@description('Name of the VNet')
param virtualNetworkName string 

@description('CIDR of your VNet')
param virtualNetwork_CIDR string = '10.200.0.0/16'

@description('Name of the subnet')
param subnet1Name string 

@description('Name of the subnet')
param subnet2Name string

@description('Name of the subnet')
param subnet3Name string

@description('Name of the subnet')
param subnet4Name string 

@description('CIDR of your subnet')
param subnet1_CIDR string = '10.200.1.0/24'

@description('CIDR of your subnet')
param subnet2_CIDR string = '10.200.2.0/24'

@description('CIDR of your subnet')
param subnet3_CIDR string = '10.200.3.0/24'

@description('CIDR of your subnet')
param subnet4_CIDR string = '10.200.4.0/24'

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        virtualNetwork_CIDR
      ]
    }
    subnets: [
      {
        name: subnet1Name
        properties: {
          addressPrefix: subnet1_CIDR
          serviceEndpoints: [
            {
              service: 'Microsoft.Web'
              locations: [
                '*'
              ]
            }
          ]
        }
      }
      {
        name: subnet2Name
        properties: {
          addressPrefix: subnet2_CIDR
          delegations: [
            {
              name: 'delegation'
              properties: {
                serviceName: 'Microsoft.Web/serverfarms'
              }
            }
          ]
        }
      }
      {
        name: subnet3Name
        properties: {
          addressPrefix: subnet3_CIDR
          
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
      {
        name: subnet4Name
        properties: {
          addressPrefix: subnet4_CIDR
        }
      }
    ]
  }
}


output virtualNetworkName string = virtualNetwork.name
output virtualNetworkId string = virtualNetwork.id
output subnet1Name string = subnet1Name
output subnet2Name string = subnet2Name
output subnet3Name string = subnet3Name
output subnet4Name string = subnet4Name
