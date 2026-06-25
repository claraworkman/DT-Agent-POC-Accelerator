# -----------------------------------------------------------------------------
# Private networking (optional — gated on var.enable_private_networking)
# -----------------------------------------------------------------------------

# --- VNet ---

resource "azurerm_virtual_network" "main" {
  count               = var.enable_private_networking ? 1 : 0
  name                = "dt-agent-vnet"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = ["10.0.0.0/16"]
  tags                = var.tags
}

resource "azurerm_subnet" "private_endpoints" {
  count                             = var.enable_private_networking ? 1 : 0
  name                              = "private-endpoints"
  resource_group_name               = azurerm_resource_group.main.name
  virtual_network_name              = azurerm_virtual_network.main[0].name
  address_prefixes                  = ["10.0.1.0/24"]
  private_endpoint_network_policies = "Disabled"
}

# --- Private DNS zones ---

resource "azurerm_private_dns_zone" "cognitive" {
  count               = var.enable_private_networking ? 1 : 0
  name                = "privatelink.cognitiveservices.azure.com"
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags
}

resource "azurerm_private_dns_zone" "openai" {
  count               = var.enable_private_networking ? 1 : 0
  name                = "privatelink.openai.azure.com"
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags
}

resource "azurerm_private_dns_zone" "search" {
  count               = var.enable_private_networking ? 1 : 0
  name                = "privatelink.search.windows.net"
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags
}

# --- VNet links ---

resource "azurerm_private_dns_zone_virtual_network_link" "cognitive" {
  count                 = var.enable_private_networking ? 1 : 0
  name                  = "cognitive-link"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.cognitive[0].name
  virtual_network_id    = azurerm_virtual_network.main[0].id
  registration_enabled  = false
}

resource "azurerm_private_dns_zone_virtual_network_link" "openai" {
  count                 = var.enable_private_networking ? 1 : 0
  name                  = "openai-link"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.openai[0].name
  virtual_network_id    = azurerm_virtual_network.main[0].id
  registration_enabled  = false
}

resource "azurerm_private_dns_zone_virtual_network_link" "search" {
  count                 = var.enable_private_networking ? 1 : 0
  name                  = "search-link"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.search[0].name
  virtual_network_id    = azurerm_virtual_network.main[0].id
  registration_enabled  = false
}

# --- Private endpoint: AI Foundry ---

resource "azurerm_private_endpoint" "foundry" {
  count               = var.enable_private_networking ? 1 : 0
  name                = "pe-dt-agent-ai"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.private_endpoints[0].id
  tags                = var.tags

  private_service_connection {
    name                           = "pe-dt-agent-ai"
    private_connection_resource_id = azurerm_cognitive_account.foundry.id
    subresource_names              = ["account"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name = "default"
    private_dns_zone_ids = [
      azurerm_private_dns_zone.cognitive[0].id,
      azurerm_private_dns_zone.openai[0].id,
    ]
  }
}

# --- Private endpoint: AI Search ---

resource "azurerm_private_endpoint" "search" {
  count               = var.enable_private_networking ? 1 : 0
  name                = "pe-dt-agent-search"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.private_endpoints[0].id
  tags                = var.tags

  private_service_connection {
    name                           = "pe-dt-agent-search"
    private_connection_resource_id = azurerm_search_service.main.id
    subresource_names              = ["searchService"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name = "default"
    private_dns_zone_ids = [
      azurerm_private_dns_zone.search[0].id,
    ]
  }
}
