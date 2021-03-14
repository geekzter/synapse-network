data azurerm_resource_group rg {
  name                         = var.resource_group_name
}

resource azurerm_virtual_network vnet {
  name                         = "${data.azurerm_resource_group.rg.name}-network"
  location                     = data.azurerm_resource_group.rg.location
  resource_group_name          = data.azurerm_resource_group.rg.name
  address_space                = ["10.0.0.0/16"]

  tags                         = data.azurerm_resource_group.rg.tags
}

resource azurerm_subnet vm_subnet {
  name                         = "vm_subnet"
  resource_group_name          = data.azurerm_resource_group.rg.name
  virtual_network_name         = azurerm_virtual_network.vnet.name
  address_prefixes             = ["10.0.1.0/24"]
  enforce_private_link_endpoint_network_policies = true
}

resource azurerm_subnet app_service {
  name                         = "AppService"
  resource_group_name          = data.azurerm_resource_group.rg.name
  virtual_network_name         = azurerm_virtual_network.vnet.name
  address_prefixes             = ["10.0.3.0/24"]

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
  name                         = "${azurerm_virtual_network.vnet.name}-natgw"
  location                     = data.azurerm_resource_group.rg.location
  resource_group_name          = data.azurerm_resource_group.rg.name
  sku_name                     = "Standard"
}
resource azurerm_public_ip egress {
  name                         = "${azurerm_nat_gateway.egress.name}-ip"
  location                     = data.azurerm_resource_group.rg.location
  resource_group_name          = data.azurerm_resource_group.rg.name
  allocation_method            = "Static"
  sku                          = "Standard"
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