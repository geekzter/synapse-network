data azurerm_resource_group vpn {
  name                         = var.resource_group_name
}

resource azurerm_virtual_network vnet {
  name                         = "${data.azurerm_resource_group.vpn.name}-network"
  location                     = data.azurerm_resource_group.vpn.location
  resource_group_name          = data.azurerm_resource_group.vpn.name
  address_space                = ["10.0.0.0/16"]

  tags                         = data.azurerm_resource_group.vpn.tags
}

resource azurerm_subnet subnet_1 {
  name                         = "subnet_1"
  resource_group_name          = data.azurerm_resource_group.vpn.name
  virtual_network_name         = azurerm_virtual_network.vnet.name
  address_prefixes             = ["10.0.1.0/24"]
  enforce_private_link_endpoint_network_policies = true
}