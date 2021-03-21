output connection_string {
  value                        = local.connection_string
}
output connection_string_legacy {
  value                        = local.connection_string_legacy
}

output sql_dwh_id {
  value        = azurerm_sql_server.sql_dwh.id
}
output sql_dwh_fqdn {
  value        = azurerm_sql_server.sql_dwh.fully_qualified_domain_name 
}
output sql_dwh_pool_name {
  value        = azurerm_sql_database.sql_dwh.name
}