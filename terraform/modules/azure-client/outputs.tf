output private_ip_address {
  value        = azurerm_network_interface.nic.private_ip_addresses[0]
}
output public_ip_address {
  value        = azurerm_public_ip.pip.ip_address
}