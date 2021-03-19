output virtual_network_id {
  value        = azurerm_virtual_network.vnet.id
}

output virtual_network_name {
  value        = azurerm_virtual_network.vnet.name
}

output app_service_subnet_id {
  value        = azurerm_subnet.app_service.id
}

output vm_subnet_id {
  value        = azurerm_subnet.vm_subnet.id
}