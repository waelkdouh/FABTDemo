@description('VM Name')
param vmName string

@description('location of VM')
param location string = resourceGroup().location

@description('VM Size depends on your needs for devops')
param vmSize string = 'Standard_DS1_v2'

@description('VM Image Publisher for VM image')
param imagePublisher string

@description('VM Image Offer from marketplace')
param imageOffer string

@description('VM IMage Sku from marketplace')
param imageSku string

@description('VM Image SKU Version - ')
param imageVersion string

param adminUserName string
@secure()
param adminPassword string

param vnetResourceGroup string
param vnetName string
param subnetName string

var subnetId = resourceId(vnetResourceGroup, 'Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName)

resource nic 'Microsoft.Network/networkInterfaces@2021-03-01' = {
  name: '${vmName}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnetId
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}

resource DevOpsAgent 'Microsoft.Compute/virtualMachines@2021-07-01' = {
  name: vmName
  location: location
  tags: {

  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
      }
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: imageSku
        version: imageVersion
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUserName
      adminPassword: adminPassword
    }
  }

}

output vmName string = vmName
