param hubVNetName string

param spokeVNetName string

var hubVNetId = resourceId('Microsoft.Network/virtualNetworks',hubVNetName)

var spokeVNetId = resourceId('Microsoft.Network/virtualNetworks', spokeVNetName)

resource hubvnet 'Microsoft.Network/virtualNetworks@2021-05-01' existing = {
  scope: resourceGroup()
  name: hubVNetName
}

resource spokevnet 'Microsoft.Network/virtualNetworks@2021-05-01' existing = {
  scope: resourceGroup()
  name: spokeVNetName
}

resource hubToSpokePeer 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-05-01' ={
  name: 'hubToSpokePeer'
  parent: hubvnet
  properties: {
    allowGatewayTransit: true
    allowForwardedTraffic: true
    allowVirtualNetworkAccess: true
    remoteVirtualNetwork: {
      id: spokeVNetId
    }
  }
}

resource spokeToHubPeer 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-05-01' ={
  name: 'spokeToHubPeer'
  parent: spokevnet
  properties: {
    allowGatewayTransit: false
    allowForwardedTraffic: true
    allowVirtualNetworkAccess: true
    remoteVirtualNetwork: {
      id: hubVNetId
    }
  }
}
