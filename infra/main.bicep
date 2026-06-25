// main.bicep — entry point for `azd up`.
//
// Subscription-scoped: creates the resource group and delegates resource
// creation to resources.bicep.
//
// Resources provisioned:
//   * Azure AI Foundry account (CognitiveServices kind=AIServices)
//   * Azure AI Foundry project (child of the account)
//   * GPT-4.1 model deployment (Azure OpenAI via Foundry model catalog)
//   * Azure AI Search (backs the Foundry IQ knowledge base)
//   * Microsoft Fabric capacity (F4 SKU)
//
// Region defaults to East US 2; override with `azd env set AZURE_LOCATION`.

targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the azd environment. Used to derive resource names and the resource group name.')
param environmentName string

@minLength(1)
@description('Azure region for all resources. Defaults to East US 2. Override with `azd env set AZURE_LOCATION <region>`.')
param location string = 'eastus2'

@description('Object ID of the principal (signed-in user or service principal) that runs `azd up`. azd populates this automatically as AZURE_PRINCIPAL_ID.')
param principalId string

@allowed([
  'User'
  'ServicePrincipal'
])
@description('Type of the principal that runs `azd up`. Used by role assignments to disambiguate.')
param principalType string = 'User'

@description('Azure region for AI Search when the primary region is out of capacity. Defaults to the primary location when empty or unset.')
param searchLocation string = ''

@description('UPNs or object IDs of Fabric capacity administrators. Defaults to the deploying principal.')
param fabricAdminMembers array = []

@description('UPN (email) of the deploying user for Fabric capacity admin. Override with `azd env set FABRIC_ADMIN_UPN user@domain.com`.')
param fabricAdminUpn string = ''

@description('Set to true to provision VNet + private endpoints for AI Services and AI Search. Override with `azd env set ENABLE_PRIVATE_NETWORKING true`.')
param enablePrivateNetworking bool = false

// ---------------------------------------------------------------------------
// Naming
// ---------------------------------------------------------------------------

var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var uniqueSuffix = substring(resourceToken, 0, 5)
var resourceGroupName = 'DT-Agent-POC'

var commonTags = {
  'azd-env-name': environmentName
  SecurityControl: 'Ignore'
  Project: 'discount-tire-store-advisor'
  Environment: environmentName
}

// ---------------------------------------------------------------------------
// Resource group
// ---------------------------------------------------------------------------

resource resourceGroup 'Microsoft.Resources/resourceGroups@2024-11-01' = {
  name: resourceGroupName
  location: location
  tags: commonTags
}

// ---------------------------------------------------------------------------
// All in-group resources delegated to resources.bicep
// ---------------------------------------------------------------------------

module resources 'resources.bicep' = {
  name: 'resources'
  scope: resourceGroup
  params: {
    location: location
    searchLocation: empty(searchLocation) ? location : searchLocation
    uniqueSuffix: uniqueSuffix
    tags: commonTags
    principalId: principalId
    principalType: principalType
    fabricAdminMembers: !empty(fabricAdminMembers) ? fabricAdminMembers : (!empty(fabricAdminUpn) ? [fabricAdminUpn] : [principalId])
    enablePrivateNetworking: enablePrivateNetworking
  }
}

// ---------------------------------------------------------------------------
// Outputs (consumed by azd as env vars)
// ---------------------------------------------------------------------------

output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = tenant().tenantId
output AZURE_RESOURCE_GROUP string = resourceGroup.name

output AZURE_AI_FOUNDRY_NAME string = resources.outputs.foundryAccountName
output AZURE_AI_FOUNDRY_ENDPOINT string = resources.outputs.foundryAccountEndpoint
output AZURE_AI_PROJECT_NAME string = resources.outputs.foundryProjectName
output AZURE_AI_PROJECT_ENDPOINT string = resources.outputs.foundryProjectEndpoint

output AZURE_MODEL_DEPLOYMENT_NAME string = resources.outputs.modelDeploymentName
output AZURE_MODEL_NAME string = resources.outputs.modelName

output AZURE_SEARCH_SERVICE_NAME string = resources.outputs.searchServiceName
output AZURE_SEARCH_ENDPOINT string = resources.outputs.searchEndpoint
output AZURE_AI_SEARCH_CONNECTION_NAME string = resources.outputs.searchConnectionName

output FABRIC_CAPACITY_NAME string = resources.outputs.fabricCapacityName
output FABRIC_CAPACITY_ID string = resources.outputs.fabricCapacityId
