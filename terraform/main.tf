# -----------------------------------------------------------------------------
# Main resources
# -----------------------------------------------------------------------------

locals {
  search_location = var.search_location != "" ? var.search_location : var.location
}

resource "random_string" "suffix" {
  length  = 5
  special = false
  upper   = false
}

# -----------------------------------------------------------------------------
# Resource Group
# -----------------------------------------------------------------------------

resource "azurerm_resource_group" "main" {
  name     = "DT-Agent-POC"
  location = var.location
  tags     = var.tags
}

# -----------------------------------------------------------------------------
# Azure AI Foundry account (Cognitive Services kind=AIServices)
# -----------------------------------------------------------------------------

resource "azurerm_cognitive_account" "foundry" {
  name                          = "dt-agent-ai-${random_string.suffix.result}"
  location                      = azurerm_resource_group.main.location
  resource_group_name           = azurerm_resource_group.main.name
  kind                          = "AIServices"
  sku_name                      = "S0"
  custom_subdomain_name         = "dt-agent-ai-${random_string.suffix.result}"
  public_network_access_enabled = !var.enable_private_networking
  local_auth_enabled            = true
  project_management_enabled    = true
  tags                          = var.tags

  identity {
    type = "SystemAssigned"
  }
}

# -----------------------------------------------------------------------------
# Azure AI Foundry project (child of account) — requires AzAPI
# -----------------------------------------------------------------------------

resource "azapi_resource" "foundry_project" {
  type      = "Microsoft.CognitiveServices/accounts/projects@2025-06-01"
  name      = "dt-agent-project"
  parent_id = azurerm_cognitive_account.foundry.id
  location  = azurerm_resource_group.main.location
  tags      = var.tags

  identity {
    type = "SystemAssigned"
  }

  body = {
    properties = {
      displayName = "Discount Tire Store Performance Advisor"
      description = "Foundry project hosting the Store Performance Advisor agent with AI Search and Fabric data."
    }
  }
}

# -----------------------------------------------------------------------------
# GPT-5.4 model deployment
# -----------------------------------------------------------------------------

resource "azapi_resource" "model_deployment" {
  type      = "Microsoft.CognitiveServices/accounts/deployments@2025-06-01"
  name      = "gpt-54"
  parent_id = azurerm_cognitive_account.foundry.id

  body = {
    sku = {
      name     = "GlobalStandard"
      capacity = var.openai_capacity
    }
    properties = {
      model = {
        format  = "OpenAI"
        name    = var.openai_model_name
        version = var.openai_model_version
      }
    }
  }
}

# -----------------------------------------------------------------------------
# Azure AI Search
# -----------------------------------------------------------------------------

resource "azurerm_search_service" "main" {
  name                          = "dt-agent-search-${random_string.suffix.result}"
  location                      = local.search_location
  resource_group_name           = azurerm_resource_group.main.name
  sku                           = "basic"
  replica_count                 = 1
  partition_count               = 1
  public_network_access_enabled = !var.enable_private_networking
  semantic_search_sku           = "free"
  tags                          = var.tags

  identity {
    type = "SystemAssigned"
  }

  authentication_failure_mode = "http401WithBearerChallenge"
}

# -----------------------------------------------------------------------------
# Microsoft Fabric capacity
# -----------------------------------------------------------------------------

resource "azapi_resource" "fabric_capacity" {
  type      = "Microsoft.Fabric/capacities@2023-11-01"
  name      = "dtagentfabric${random_string.suffix.result}"
  parent_id = azurerm_resource_group.main.id
  location  = azurerm_resource_group.main.location
  tags      = var.tags

  body = {
    sku = {
      name = var.fabric_sku
      tier = "Fabric"
    }
    properties = {
      administration = {
        members = var.fabric_admin_members
      }
    }
  }
}
