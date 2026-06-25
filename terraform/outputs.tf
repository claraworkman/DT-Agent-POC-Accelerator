# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------

output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "foundry_account_name" {
  value = azurerm_cognitive_account.foundry.name
}

output "foundry_account_endpoint" {
  value = azurerm_cognitive_account.foundry.endpoint
}

output "foundry_project_name" {
  value = azapi_resource.foundry_project.name
}

output "foundry_project_endpoint" {
  value = "https://${azurerm_cognitive_account.foundry.name}.services.ai.azure.com/api/projects/${azapi_resource.foundry_project.name}"
}

output "model_deployment_name" {
  value = azapi_resource.model_deployment.name
}

output "search_service_name" {
  value = azurerm_search_service.main.name
}

output "search_endpoint" {
  value = "https://${azurerm_search_service.main.name}.search.windows.net"
}

output "search_connection_name" {
  value = azapi_resource.search_connection.name
}

output "fabric_capacity_name" {
  value = azapi_resource.fabric_capacity.name
}

output "fabric_capacity_id" {
  value = azapi_resource.fabric_capacity.id
}
