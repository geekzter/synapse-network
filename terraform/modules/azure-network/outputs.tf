output virtual_network_id {
  value        = azurerm_virtual_network.vnet.id
}

output virtual_network_name {
  value        = azurerm_virtual_network.vnet.name
}

output app_service_subnet_id {
  value        = azurerm_subnet.app_service.id
}

output sql_server_private_ip_address {
  value        = var.sql_server_id != null ? azurerm_private_endpoint.sql_server_endpoint.0.private_service_connection[0].private_ip_address : null
}

output vm_subnet_id {
  value        = azurerm_subnet.vm_subnet.id
}