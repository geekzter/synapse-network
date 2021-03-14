output azure_virtual_network_name {
  value        = azurerm_virtual_network.vnet.name
}

output azure_app_service_subnet_id {
  value        = azurerm_subnet.app_service.id
}

output azure_vm_subnet_id {
  value        = azurerm_subnet.vm_subnet.id
}