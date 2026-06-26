// resources.bicep — all in-resource-group resources for the Discount Tire
// Store Performance Advisor. Scoped to a resource group; called by main.bicep.
//
// Provisions:
//   * Azure AI Foundry account (CognitiveServices kind=AIServices)
//   * Azure AI Foundry project (child of the account)
//   * GPT-5.4 model deployment (Azure OpenAI via Foundry model catalog)
//   * Azure AI Search (backs the Foundry IQ knowledge base)
//   * Microsoft Fabric capacity (F4 SKU)
//   * Role assignments granting the deploying principal data-plane access

targetScope = 'resourceGroup'

// ---------------------------------------------------------------------------
// Parameters
// ---------------------------------------------------------------------------

@description('Azure region for all resources.')
param location string

@description('Azure region for AI Search. Can differ from primary when Search capacity is constrained.')
param searchLocation string = location

@description('Short unique suffix (5 chars) for globally unique resource names.')
param uniqueSuffix string

@description('Tags applied to every resource.')
param tags object

@description('Object ID of the principal that gets data-plane role assignments.')
param principalId string

@allowed([
  'User'
  'ServicePrincipal'
])
@description('Type of the principal for role assignments.')
param principalType string

@description('OpenAI model name from the Azure AI model catalog.')
param openAiModelName string = 'gpt-5.4'

@description('OpenAI model version.')
param openAiModelVersion string = '2026-03-05'

@description('Provisioned throughput in thousands of tokens per minute (TPM).')
param openAiCapacity int = 10

@description('Fabric capacity SKU. F4 = 4 CUs.')
param fabricSkuName string = 'F4'

@description('UPNs or object IDs of Fabric capacity administrators.')
param fabricAdminMembers array

@description('Set to true to provision a VNet with private endpoints for AI Services and AI Search. Public access is disabled when enabled.')
param enablePrivateNetworking bool = false

// ---------------------------------------------------------------------------
// Naming
// ---------------------------------------------------------------------------

var foundryAccountName = 'dt-agent-ai-${uniqueSuffix}'
var foundryProjectName = 'dt-agent-project'
var modelDeploymentName = 'gpt-54'
var searchServiceName = 'dt-agent-search-${uniqueSuffix}'
var fabricCapacityName = 'dtagentfabric${uniqueSuffix}'
var vnetName = 'dt-agent-vnet'
var peSubnetName = 'private-endpoints'
var foundryPeName = 'pe-dt-agent-ai'
var searchPeName = 'pe-dt-agent-search'

// ---------------------------------------------------------------------------
// Built-in role IDs
// ---------------------------------------------------------------------------

var roleCognitiveServicesContributor = '25fbc0a9-bd7c-42a3-aa1a-3b75d497ee68'
var roleCognitiveServicesOpenAIUser = '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd'
var roleSearchServiceContributor = '7ca78c08-252a-4471-8644-bb5ff32d4ba0'
var roleSearchIndexDataContributor = '8ebe5a00-799e-43f5-93ac-243d3dce84a7'
var roleSearchIndexDataReader = '1407120a-92aa-4202-b7e9-c0e197c71c8f'

// ---------------------------------------------------------------------------
// Azure AI Foundry account (CognitiveServices kind=AIServices)
// ---------------------------------------------------------------------------

resource foundryAccount 'Microsoft.CognitiveServices/accounts@2025-06-01' = {
  name: foundryAccountName
  location: location
  tags: tags
  kind: 'AIServices'
  sku: {
    name: 'S0'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    allowProjectManagement: true
    customSubDomainName: foundryAccountName
    publicNetworkAccess: enablePrivateNetworking ? 'Disabled' : 'Enabled'
    disableLocalAuth: false
  }
}

// ---------------------------------------------------------------------------
// Azure AI Foundry project
// ---------------------------------------------------------------------------

resource foundryProject 'Microsoft.CognitiveServices/accounts/projects@2025-06-01' = {
  parent: foundryAccount
  name: foundryProjectName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    displayName: 'Discount Tire Store Performance Advisor'
    description: 'Foundry project hosting the Store Performance Advisor agent with AI Search and Fabric data.'
  }
}

// ---------------------------------------------------------------------------
// GPT-5.4 model deployment
// ---------------------------------------------------------------------------

resource modelDeployment 'Microsoft.CognitiveServices/accounts/deployments@2025-06-01' = {
  parent: foundryAccount
  name: modelDeploymentName
  sku: {
    name: 'GlobalStandard'
    capacity: openAiCapacity
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: openAiModelName
      version: openAiModelVersion
    }
  }
}

// ---------------------------------------------------------------------------
// Azure AI Search
// ---------------------------------------------------------------------------

resource searchService 'Microsoft.Search/searchServices@2024-06-01-preview' = {
  name: searchServiceName
  location: searchLocation
  tags: tags
  sku: {
    name: 'basic'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    replicaCount: 1
    partitionCount: 1
    hostingMode: 'default'
    publicNetworkAccess: enablePrivateNetworking ? 'disabled' : 'enabled'
    semanticSearch: 'free'
    authOptions: {
      aadOrApiKey: {
        aadAuthFailureMode: 'http401WithBearerChallenge'
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Microsoft Fabric capacity (F4)
// ---------------------------------------------------------------------------

resource fabricCapacity 'Microsoft.Fabric/capacities@2023-11-01' = {
  name: fabricCapacityName
  location: location
  tags: tags
  sku: {
    name: fabricSkuName
    tier: 'Fabric'
  }
  properties: {
    administration: {
      members: fabricAdminMembers
    }
  }
}

// ---------------------------------------------------------------------------
// Role assignments — deploying principal
// ---------------------------------------------------------------------------

resource foundryAccountContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(principalId)) {
  name: guid(foundryAccount.id, principalId, roleCognitiveServicesContributor)
  scope: foundryAccount
  properties: {
    principalId: principalId
    principalType: principalType
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleCognitiveServicesContributor)
  }
}

resource foundryOpenAIUser 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(principalId)) {
  name: guid(foundryAccount.id, principalId, roleCognitiveServicesOpenAIUser)
  scope: foundryAccount
  properties: {
    principalId: principalId
    principalType: principalType
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleCognitiveServicesOpenAIUser)
  }
}

resource searchContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(principalId)) {
  name: guid(searchService.id, principalId, roleSearchServiceContributor)
  scope: searchService
  properties: {
    principalId: principalId
    principalType: principalType
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleSearchServiceContributor)
  }
}

resource searchIndexDataContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(principalId)) {
  name: guid(searchService.id, principalId, roleSearchIndexDataContributor)
  scope: searchService
  properties: {
    principalId: principalId
    principalType: principalType
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleSearchIndexDataContributor)
  }
}

resource searchIndexDataReader 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(principalId)) {
  name: guid(searchService.id, principalId, roleSearchIndexDataReader)
  scope: searchService
  properties: {
    principalId: principalId
    principalType: principalType
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleSearchIndexDataReader)
  }
}

// ---------------------------------------------------------------------------
// Foundry project MSI -> Search Index Data Reader
// ---------------------------------------------------------------------------

resource projectSearchReader 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(searchService.id, foundryProject.id, roleSearchIndexDataReader)
  scope: searchService
  properties: {
    principalId: foundryProject.identity.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleSearchIndexDataReader)
  }
}

resource foundryAccountSearchReader 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(searchService.id, foundryAccount.id, roleSearchIndexDataReader)
  scope: searchService
  properties: {
    principalId: foundryAccount.identity.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleSearchIndexDataReader)
  }
}

// ---------------------------------------------------------------------------
// Foundry project -> AI Search connection
// ---------------------------------------------------------------------------

var searchConnectionName = 'ai-search-connection'

resource projectSearchConnection 'Microsoft.CognitiveServices/accounts/projects/connections@2025-06-01' = {
  parent: foundryProject
  name: searchConnectionName
  properties: {
    category: 'CognitiveSearch'
    authType: 'AAD'
    target: 'https://${searchService.name}.search.windows.net'
    isSharedToAll: true
    metadata: {
      ApiType: 'Azure'
      ResourceId: searchService.id
      Location: location
    }
  }
  dependsOn: [
    projectSearchReader
  ]
}

// ---------------------------------------------------------------------------
// Private networking (optional — gated on `enablePrivateNetworking`)
// ---------------------------------------------------------------------------
//
// When enabled, provisions:
//   * VNet with a /24 subnet for private endpoints
//   * Private endpoints for AI Foundry and AI Search
//   * Private DNS zones linked to the VNet for name resolution

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = if (enablePrivateNetworking) {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: peSubnetName
        properties: {
          addressPrefix: '10.0.1.0/24'
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
    ]
  }
}

// --- Private DNS zones ---

resource dnsZoneCognitiveServices 'Microsoft.Network/privateDnsZones@2024-06-01' = if (enablePrivateNetworking) {
  name: 'privatelink.cognitiveservices.azure.com'
  location: 'global'
  tags: tags
}

resource dnsZoneOpenAI 'Microsoft.Network/privateDnsZones@2024-06-01' = if (enablePrivateNetworking) {
  name: 'privatelink.openai.azure.com'
  location: 'global'
  tags: tags
}

resource dnsZoneSearch 'Microsoft.Network/privateDnsZones@2024-06-01' = if (enablePrivateNetworking) {
  name: 'privatelink.search.windows.net'
  location: 'global'
  tags: tags
}

// --- VNet links for DNS zones ---

resource dnsLinkCognitive 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = if (enablePrivateNetworking) {
  parent: dnsZoneCognitiveServices
  name: '${vnetName}-cognitive-link'
  location: 'global'
  properties: {
    virtualNetwork: {
      id: vnet!.id
    }
    registrationEnabled: false
  }
}

resource dnsLinkOpenAI 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = if (enablePrivateNetworking) {
  parent: dnsZoneOpenAI
  name: '${vnetName}-openai-link'
  location: 'global'
  properties: {
    virtualNetwork: {
      id: vnet!.id
    }
    registrationEnabled: false
  }
}

resource dnsLinkSearch 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = if (enablePrivateNetworking) {
  parent: dnsZoneSearch
  name: '${vnetName}-search-link'
  location: 'global'
  properties: {
    virtualNetwork: {
      id: vnet!.id
    }
    registrationEnabled: false
  }
}

// --- Private endpoint: AI Foundry ---

resource peFoundry 'Microsoft.Network/privateEndpoints@2024-05-01' = if (enablePrivateNetworking) {
  name: foundryPeName
  location: location
  tags: tags
  properties: {
    subnet: {
      id: '${vnet!.id}/subnets/${peSubnetName}'
    }
    privateLinkServiceConnections: [
      {
        name: foundryPeName
        properties: {
          privateLinkServiceId: foundryAccount.id
          groupIds: [
            'account'
          ]
        }
      }
    ]
  }
}

resource peFoundryDnsGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-05-01' = if (enablePrivateNetworking) {
  parent: peFoundry
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'cognitive'
        properties: {
          privateDnsZoneId: dnsZoneCognitiveServices!.id
        }
      }
      {
        name: 'openai'
        properties: {
          privateDnsZoneId: dnsZoneOpenAI!.id
        }
      }
    ]
  }
}

// --- Private endpoint: AI Search ---

resource peSearch 'Microsoft.Network/privateEndpoints@2024-05-01' = if (enablePrivateNetworking) {
  name: searchPeName
  location: location
  tags: tags
  properties: {
    subnet: {
      id: '${vnet!.id}/subnets/${peSubnetName}'
    }
    privateLinkServiceConnections: [
      {
        name: searchPeName
        properties: {
          privateLinkServiceId: searchService.id
          groupIds: [
            'searchService'
          ]
        }
      }
    ]
  }
}

resource peSearchDnsGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-05-01' = if (enablePrivateNetworking) {
  parent: peSearch
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'search'
        properties: {
          privateDnsZoneId: dnsZoneSearch!.id
        }
      }
    ]
  }
}

// ---------------------------------------------------------------------------
// Outputs
// ---------------------------------------------------------------------------

output foundryAccountName string = foundryAccount.name
output foundryAccountEndpoint string = foundryAccount.properties.endpoint

output foundryProjectName string = foundryProject.name
output foundryProjectEndpoint string = 'https://${foundryAccount.name}.services.ai.azure.com/api/projects/${foundryProject.name}'

output modelDeploymentName string = modelDeploymentName
output modelName string = openAiModelName

output searchServiceName string = searchService.name
output searchEndpoint string = 'https://${searchService.name}.search.windows.net'
output searchConnectionName string = projectSearchConnection.name

output fabricCapacityName string = fabricCapacity.name
output fabricCapacityId string = fabricCapacity.id
