@description('Location for all resources.')
param location string 

param appGatewayName string

@description('virtual network name')
param virtualNetworkName string

param webAppHostNames array

@description('Delegation Subnet Name')
param appGatewaySubnet string

@description('Private IP address to give to the app gw front end')
param appGatewayPrivateIp string = '10.200.1.5'

var applicationGatewayName_var = '${appGatewayName}-${uniqueString(resourceGroup().id)}'
var applicationGatewaySkuSize = 'Standard_v2'
var applicationGatewayTier = 'Standard_v2'
var applicationGatewayAutoScaleMinCapacity = 2
var applicationGatewayAutoScaleMaxCapacity = 5
var appGwIpConfigName = 'appGatewayIpConfigName'
var appGwFrontendPortName = 'appGatewayFrontendPort_80'
var appGwFrontendPort = 80
var appGwFrontendPortId = resourceId('Microsoft.Network/applicationGateways/frontendPorts/', applicationGatewayName_var, appGwFrontendPortName)
var appGwFrontendIpConfigName = 'appGatewayPublicFrontendIpConfig'
var appGwFrontendIpConfigId = resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations/', applicationGatewayName_var, appGwFrontendIpConfigName)
var appGwHttpSettingName = 'appGatewayHttpSetting_80'
var appGwHttpSettingId = resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection/', applicationGatewayName_var, appGwHttpSettingName)
var appGwHttpSettingProbeName = 'appGatewayHttpSettingProbe_443'
var appGwBackendAddressPoolName = 'appGatewayWebAppBackendPool'
var appGwBackendAddressPoolId = resourceId('Microsoft.Network/applicationGateways/backendAddressPools/', applicationGatewayName_var, appGwBackendAddressPoolName)
var appGwListenerName = 'appGatewayListener'
var appGwListenerId = resourceId('Microsoft.Network/applicationGateways/httpListeners/', applicationGatewayName_var, appGwListenerName)
var appGwRoutingRuleName = 'appGatewayRoutingRule'
var publicIpAddressName_var = 'myAppGatewayPublicIp-${uniqueString(resourceGroup().id)}'
var publicIpAddressSku = 'Standard'
var publicIpAddressAllocationType = 'Static'
var domainNameLabel_var = '${appGatewayName}${uniqueString(resourceGroup().id)}'

resource publicIpAddressName 'Microsoft.Network/publicIPAddresses@2020-05-01' = {
  name: publicIpAddressName_var
  location: location
  sku: {
    name: publicIpAddressSku
  }
  properties: {
    publicIPAllocationMethod: publicIpAddressAllocationType
    dnsSettings: {
      domainNameLabel: toLower(domainNameLabel_var)
    }
  }
}

resource applicationGatewayName 'Microsoft.Network/applicationGateways@2020-05-01' = {
  name: applicationGatewayName_var
  location: location
  properties: {
    sku: {
      name: applicationGatewaySkuSize
      tier: applicationGatewayTier
    }
    gatewayIPConfigurations: [
      {
        name: appGwIpConfigName
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName , appGatewaySubnet)
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: appGwFrontendIpConfigName
        properties: {
          publicIPAddress: {
            id: resourceId('Microsoft.Network/publicIPAddresses', publicIpAddressName.name)
          }
        }
      }
      {
        name: 'appgwprivateip'
        properties: {
          privateIPAddress: appGatewayPrivateIp
          privateIPAllocationMethod: 'Static'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName , appGatewaySubnet)
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: appGwFrontendPortName
        properties: {
          port: appGwFrontendPort
        }
      }
    ]
    backendAddressPools: [
      {
        name: appGwBackendAddressPoolName
        properties: {
          backendAddresses: [for (wa, i) in webAppHostNames: {  
            fqdn: webAppHostNames[i].Hostnames
            }]
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: appGwHttpSettingName
        properties: {
          port: 443
          protocol: 'Https'
          cookieBasedAffinity: 'Disabled'
          requestTimeout: 20
          pickHostNameFromBackendAddress: true
        }
      }
    ]
    httpListeners: [
      {
        name: appGwListenerName
        properties: {
          frontendIPConfiguration: {
            id: appGwFrontendIpConfigId
          }
          frontendPort: {
            id: appGwFrontendPortId
          }
          protocol: 'Http'
        }
      }
    ]
    requestRoutingRules: [
      {
        name: appGwRoutingRuleName
        properties: {
          ruleType: 'Basic'
          httpListener: {
            id: appGwListenerId
          }
          backendAddressPool: {
            id: appGwBackendAddressPoolId
          }
          backendHttpSettings: {
            id: appGwHttpSettingId
          }
        }
      }
    ]
    enableHttp2: true
    probes: [
      {
        name: appGwHttpSettingProbeName
        properties: {
          interval: 30
          minServers: 0
          path: '/'
          protocol: 'Http'
          timeout: 30
          unhealthyThreshold: 3
          pickHostNameFromBackendHttpSettings: true
        }
      }
    ]
    autoscaleConfiguration: {
      minCapacity: applicationGatewayAutoScaleMinCapacity
      maxCapacity: applicationGatewayAutoScaleMaxCapacity
    }
  }
}

output appGatewayUrl string = 'http://${publicIpAddressName.properties.dnsSettings.fqdn}/'
