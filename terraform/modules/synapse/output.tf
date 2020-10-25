output sql_dwh_fqdn {
  value        = azurerm_sql_server.sql_dwh.fully_qualified_domain_name 
}

output sql_dwh_pool_name {
  value        = azurerm_sql_database.sql_dwh.name
}

output sql_dwh_private_ip_address {
  value        = var.create_network_resources ? azurerm_private_endpoint.sql_dwh_endpoint.0.private_service_connection[0].private_ip_address : null
}
