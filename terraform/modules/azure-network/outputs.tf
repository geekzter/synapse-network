output azure_virtual_network_name {
  value        = azurerm_virtual_network.vnet.name
}

output azure_subnet_id {
  value        = azurerm_subnet.subnet_1.id
}