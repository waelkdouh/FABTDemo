@description('Location for all resources.')
param location string 

@description('Hub Virtual Network Address Space in CIDR format')
param addressSpace string = '10.100.0.0/16'

@description('Firewall Subnet Name')
param firewallSubnetName string = 'firewallSubnet'

@description('CIDR for firewall subnet - must be within vnet CIDR')
param firewallSubnetCIDR string = '10.100.0.0/24'

@description('DNS subnet name')
param dnsSubnetName string = 'dnsSubnet'

@description('CIDER for dns subnet - must be within vnet CIDR')
param dnsSubnetCIDR string = '10.100.1.0/24'

@description('CIDR for azure basion subnet')
param bastionSubnetCIDR string ='10.100.2.0/26'

@description('CIDR for Azure Firewall Subnet')
param azureFirewallSubnetCIDR string = '10.100.3.0/26'

@description('VNet Name')
param vNetName string = 'HubVNet'

resource hubVNet 'Microsoft.Network/virtualNetworks@2021-03-01' = {
  name: vNetName
  location: location
  properties: {
    addressSpace : {
      addressPrefixes : [
        addressSpace
      ]
    }
    subnets: [
      {
        name: firewallSubnetName
        properties: {
          addressPrefix: firewallSubnetCIDR
        }
      }
      {
        name: dnsSubnetName
        properties: {
          addressPrefix: dnsSubnetCIDR
        }
      }
      {
        name: 'AzureBastionSubnet'
        properties:{
          addressPrefix: bastionSubnetCIDR
        }
      }
      {
        name: 'AzureFirewallSubnet'
        properties: {
          addressPrefix: azureFirewallSubnetCIDR
        }
      }
    ]
  }
}

output virtualNetworkName string = hubVNet.name
output dnsSubnetName string = dnsSubnetName
