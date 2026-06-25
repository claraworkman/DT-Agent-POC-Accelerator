# -----------------------------------------------------------------------------
# Role assignments
# -----------------------------------------------------------------------------

# Built-in role definition IDs
locals {
  role_cognitive_services_contributor   = "25fbc0a9-bd7c-42a3-aa1a-3b75d497ee68"
  role_cognitive_services_openai_user   = "5e0bd9bd-7b93-4f28-af87-19fc36ad61bd"
  role_search_service_contributor       = "7ca78c08-252a-4471-8644-bb5ff32d4ba0"
  role_search_index_data_contributor    = "8ebe5a00-799e-43f5-93ac-243d3dce84a7"
  role_search_index_data_reader         = "1407120a-92aa-4202-b7e9-c0e197c71c8f"
}

# --- Deploying principal -> AI Foundry ---

resource "azurerm_role_assignment" "foundry_contributor" {
  scope                = azurerm_cognitive_account.foundry.id
  role_definition_name = "Cognitive Services Contributor"
  principal_id         = var.principal_id
  principal_type       = var.principal_type
}

resource "azurerm_role_assignment" "foundry_openai_user" {
  scope                = azurerm_cognitive_account.foundry.id
  role_definition_name = "Cognitive Services OpenAI User"
  principal_id         = var.principal_id
  principal_type       = var.principal_type
}

# --- Deploying principal -> AI Search ---

resource "azurerm_role_assignment" "search_contributor" {
  scope                = azurerm_search_service.main.id
  role_definition_name = "Search Service Contributor"
  principal_id         = var.principal_id
  principal_type       = var.principal_type
}

resource "azurerm_role_assignment" "search_index_data_contributor" {
  scope                = azurerm_search_service.main.id
  role_definition_name = "Search Index Data Contributor"
  principal_id         = var.principal_id
  principal_type       = var.principal_type
}

resource "azurerm_role_assignment" "search_index_data_reader" {
  scope                = azurerm_search_service.main.id
  role_definition_name = "Search Index Data Reader"
  principal_id         = var.principal_id
  principal_type       = var.principal_type
}

# --- Foundry project MSI -> AI Search ---

resource "azurerm_role_assignment" "project_search_reader" {
  scope                = azurerm_search_service.main.id
  role_definition_name = "Search Index Data Reader"
  principal_id         = azapi_resource.foundry_project.identity[0].principal_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_role_assignment" "foundry_account_search_reader" {
  scope                = azurerm_search_service.main.id
  role_definition_name = "Search Index Data Reader"
  principal_id         = azurerm_cognitive_account.foundry.identity[0].principal_id
  principal_type       = "ServicePrincipal"
}
