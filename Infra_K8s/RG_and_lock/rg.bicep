// ========== rg.bicep ==========

targetScope = 'subscription'

// Parameters to modify according to context
@description('Location for all resources')
param location string

@description('Name of the environment')
param nameEnvironmentRG string

@description('The ID of the resource that manages this resource group')
param RGID string = subscription().id

// Params for the Lock
@description('Specifies the level of the lock. CanNotDelete = authorized users are able to read and modify the resources, but not delete. ReadOnly = authorized users can only read from a resource, they can t modify or delete it.')
@allowed([
  'CanNotDelete'
  'NotSpecified'
  'ReadOnly'
])
param lockLevel string

@description('Notes about the lock. Maximum of 512 characters.')
param lockNotes string

// Variables
var RGName = 'RG-${nameEnvironmentRG}'

// Resource

// Resource Group creation
resource RG 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: RGName
  location: location
  managedBy: RGID
  properties: {}
}

// This part deploys resources as well as a lock into the resource group
module lockRg '' = {
  name: 'LockHubRGDeploy'
  scope: RG  // Passing newly created resource group as module's deployment scope
  params: {
    lockLevel: lockLevel
    lockNotes: lockNotes
    nameEnvironmentRG: nameEnvironmentRG
  }
}

//az deployment sub create --location XXXXX --template-file RG_1.bicep --parameters RG_1.parameters.jsonc
