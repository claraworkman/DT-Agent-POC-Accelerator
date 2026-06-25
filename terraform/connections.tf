# -----------------------------------------------------------------------------
# Foundry project -> AI Search connection
# -----------------------------------------------------------------------------

resource "azapi_resource" "search_connection" {
  type      = "Microsoft.CognitiveServices/accounts/projects/connections@2025-06-01"
  name      = "ai-search-connection"
  parent_id = azapi_resource.foundry_project.id

  body = {
    properties = {
      category      = "CognitiveSearch"
      authType      = "AAD"
      target        = "https://${azurerm_search_service.main.name}.search.windows.net"
      isSharedToAll = true
      metadata = {
        ApiType    = "Azure"
        ResourceId = azurerm_search_service.main.id
        Location   = var.location
      }
    }
  }

  depends_on = [azurerm_role_assignment.project_search_reader]
}
