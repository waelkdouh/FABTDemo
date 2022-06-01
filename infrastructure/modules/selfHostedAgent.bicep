param location string = resourceGroup().location

@secure()
param devopsPAT string
param devopsOrg string
param devopsPool string
param agentVMName string

resource parentVM 'Microsoft.Compute/virtualMachines@2021-07-01' existing = {
  name: agentVMName
}

resource DevopsAgentSetup 'Microsoft.Compute/virtualMachines/runCommands@2021-07-01' ={
  name: 'DevopsAgentSetup'
  location: location
  parent: parentVM
  properties: {
    asyncExecution: false
    source: {
      script: '''
        mkdir c:\agent
      '''
    }
  }
}

resource DevopsAgentDownload 'Microsoft.Compute/virtualMachines/runCommands@2021-07-01' = {
  name: 'DevopsDotNetDownload'
  location: location
  parent: parentVM
  dependsOn:[ 
    DevopsAgentSetup
  ]
  properties:{
    asyncExecution: false
    source:{
      script:'''
      Invoke-WebRequest -Uri "https://dot.net/v1/dotnet-install.ps1" -OutFile "c:\dotnet-install.ps1"
      '''
    }
  }
}

resource DevopsAgentInstall 'Microsoft.Compute/virtualMachines/runCommands@2021-07-01' = {
  name: 'DevopsDotNetInstall'
  location: location
  parent: parentVM
  dependsOn:[
    DevopsAgentDownload
  ]
  properties: {
    asyncExecution: false
    source: {
      script: '''
      cd c: ;.\dotnet-install.ps1
      '''
    }
  }
}

resource vsbuildtoolsdownload 'Microsoft.Compute/virtualMachines/runCommands@2021-07-01' = {
  name: 'vsbuildtoolsdownload'
  location: location
  parent: parentVM
  dependsOn: [
    DevopsAgentInstall
  ]
  properties: {
    asyncExecution: false
    source: {
      script: '''
      Invoke-WebRequest -Uri "https://aka.ms/vs/17/release/vs_BuildTools.exe" -OutFile c:\vs_BuildTools.exe
      '''
    }
  }
}

resource vsbuildtoolsinstall 'Microsoft.Compute/virtualMachines/runCommands@2021-07-01' = {
  name: 'vsbuildtoolsinstall'
  location: location
  parent: parentVM
  dependsOn: [
    vsbuildtoolsdownload
  ]
  properties: {
    asyncExecution: false
    source: {
      script: '''
      cd c:\; .\vs_BuildTools.exe --quiet --add Microsoft.VisualStudio.Workload.VCTools
      '''
    }
  }
}

resource devopsAgentDownload 'Microsoft.Compute/virtualMachines/runCommands@2021-07-01' = {
  name: 'devopsAgentDownload'
  location: location
  parent: parentVM
  dependsOn: [
    vsbuildtoolsinstall
  ]
  properties:{
    asyncExecution: false
    source: {
      script: '''
      Invoke-WebRequest -Uri "https://vstsagentpackage.azureedge.net/agent/2.202.1/vsts-agent-win-x64-2.202.1.zip" -OutFile c:\agentInstall.zip
      '''
    }
  }
}

resource devopsAgentInstall 'Microsoft.Compute/virtualMachines/runCommands@2021-07-01' = {
  name: 'DevopsAgentInstall'
  location: location
  parent: parentVM
  dependsOn: [
    devopsAgentDownload
  ]
  properties: {
    asyncExecution: false
    source: {
      script: '''
      Add-Type -AssemblyName System.IO.Compression.FileSystem; [System.IO.Compression.ZipFile]::ExtractToDirectory("c:\agentInstall.zip", "c:\agent")
      '''
    }
  }
}

resource devopsAgentConfig 'Microsoft.Compute/virtualMachines/runCommands@2021-07-01' = {
  name: 'devopsAgentConfig'
  location: location
  parent: parentVM
  dependsOn: [
    devopsAgentInstall
  ]
  properties: {
    asyncExecution: false
    protectedParameters:[
      {
        name: 'devopsPAT'
        value: devopsPAT
      }
      {
        name: 'devopsOrg'
        value: devopsOrg
      }
      {
        name: 'devopsPool'
        value: devopsPool
      }
      {
        name: 'agentName'
        value: agentVMName
      }
    ]
    source:{
      script: '''
      param(
        [string]$devopsOrg,
        [string]$devopsPAT,
        [string]$devopsPool,
        [string]$agentName,
        [string]$runasusername,
        [securestring]$runaspwd
      )
      cd c:\agent; .\config.cmd --unattended --url "https://dev.azure.com/$devopsOrg" --auth pat --token $devopsPAT --pool $devopsPool --agent $agentName --runAsService --runAsAutoLogon --windowsLogonAccount "NT AUTHORITY\SYSTEM"
      '''
    }
  }
}
