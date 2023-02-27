// ========== lock_rg.bicep ==========

targetScope = 'resourceGroup'

// Parameters to modify according to context

@description('Name of the environment')
param nameEnvironmentRG string

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
var lockName = 'RG-LOCK-${nameEnvironmentRG}'


// Resources

// Lock creation
resource lockRg 'Microsoft.Authorization/locks@2017-04-01' = {
  name: lockName
  properties: {
    level: lockLevel
    notes: lockNotes
  }
}

//az deployment group create --resource-group RG-Duna --template-file lock_rg.bicep --parameters lock_rg.parameters.jsonc
