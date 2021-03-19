data azurerm_resource_group rg {
  name                         = var.resource_group_name
}

resource azurerm_virtual_network vnet {
  name                         = "${data.azurerm_resource_group.rg.name}-${data.azurerm_resource_group.rg.location}-network"
  location                     = data.azurerm_resource_group.rg.location
  resource_group_name          = data.azurerm_resource_group.rg.name
  address_space                = [var.address_space]

  tags                         = data.azurerm_resource_group.rg.tags
}

resource azurerm_subnet vm_subnet {
  name                         = "VmSubnet"
  resource_group_name          = data.azurerm_resource_group.rg.name
  virtual_network_name         = azurerm_virtual_network.vnet.name
  address_prefixes             = [cidrsubnet(azurerm_virtual_network.vnet.address_space[0],8,1)]
  enforce_private_link_endpoint_network_policies = true
}

resource azurerm_subnet app_service {
  name                         = "AppService"
  resource_group_name          = data.azurerm_resource_group.rg.name
  virtual_network_name         = azurerm_virtual_network.vnet.name
  address_prefixes             = [cidrsubnet(azurerm_virtual_network.vnet.address_space[0],11,0)]

  delegation {
    name                       = "appservice_delegation"

    service_delegation {
      name                     = "Microsoft.Web/serverFarms"
      actions                  = [
        "Microsoft.Network/virtualNetworks/subnets/action",
      ]
    }
  }
}

resource azurerm_nat_gateway egress {
  name                         = "${azurerm_virtual_network.vnet.name}-gw"
  location                     = data.azurerm_resource_group.rg.location
  resource_group_name          = data.azurerm_resource_group.rg.name
  sku_name                     = "Standard"

  tags                         = data.azurerm_resource_group.rg.tags
}
resource azurerm_public_ip egress {
  name                         = "${azurerm_nat_gateway.egress.name}-ip"
  location                     = data.azurerm_resource_group.rg.location
  resource_group_name          = data.azurerm_resource_group.rg.name
  allocation_method            = "Static"
  sku                          = "Standard"

  tags                         = data.azurerm_resource_group.rg.tags
}
resource azurerm_nat_gateway_public_ip_association egress {
  nat_gateway_id               = azurerm_nat_gateway.egress.id
  public_ip_address_id         = azurerm_public_ip.egress.id
}
resource azurerm_subnet_nat_gateway_association app_service {
  subnet_id                    = azurerm_subnet.app_service.id
  nat_gateway_id               = azurerm_nat_gateway.egress.id

  depends_on                   = [azurerm_nat_gateway_public_ip_association.egress]
}
resource azurerm_subnet_nat_gateway_association vm_subnet {
  subnet_id                    = azurerm_subnet.vm_subnet.id
  nat_gateway_id               = azurerm_nat_gateway.egress.id

  depends_on                   = [azurerm_nat_gateway_public_ip_association.egress]
}

# https://docs.microsoft.com/en-us/azure/vpn-gateway/vpn-gateway-peering-gateway-transit#resource-manager-to-resource-manager-peering-with-gateway-transit
resource azurerm_virtual_network_peering spoke_to_hub {
  name                         = "${azurerm_virtual_network.vnet.name}-spoke2hub"
  resource_group_name          = data.azurerm_resource_group.rg.name
  virtual_network_name         = azurerm_virtual_network.vnet.name
  remote_virtual_network_id    = var.peer_virtual_network_id

  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  allow_virtual_network_access = true
  use_remote_gateways          = false

  count                        = var.peer_virtual_network_id != null ? 1 : 0
  depends_on                   = [azurerm_virtual_network_peering.hub_to_spoke]
}
resource azurerm_virtual_network_peering hub_to_spoke {
  name                         = "${azurerm_virtual_network.vnet.name}-hub2spoke"
  resource_group_name          = data.azurerm_resource_group.rg.name
  virtual_network_name         = element(split("/",var.peer_virtual_network_id),length(split("/",var.peer_virtual_network_id))-1)
  remote_virtual_network_id    = azurerm_virtual_network.vnet.id

  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  allow_virtual_network_access = true
  use_remote_gateways          = false

  count                        = var.peer_virtual_network_id != null ? 1 : 0
}