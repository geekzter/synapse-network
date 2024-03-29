module azure_network {
  source                       = "./modules/azure-network"
  resource_group_name          = azurerm_resource_group.synapse.name
  address_space                = "10.0.0.0/16"
  create_sql_server_endpoint   = var.deploy_synapse
  location                     = azurerm_resource_group.synapse.location
  private_dns_zone_id          = azurerm_private_dns_zone.sql_dns_zone.id
  sql_server_id                = var.deploy_synapse ? module.synapse.0.sql_dwh_id : null
  
  count                        = var.deploy_network ? 1 : 0
  depends_on                   = [azurerm_resource_group.synapse]
}

module azure_network_alternate_region {
  source                       = "./modules/azure-network"
  resource_group_name          = azurerm_resource_group.synapse.name
  address_space                = "10.1.0.0/16"
  create_peering               = true
  create_sql_server_endpoint   = var.deploy_synapse
  location                     = var.azure_alternate_region 
  peer_virtual_network_id      = module.azure_network[0].virtual_network_id
  private_dns_zone_id          = azurerm_private_dns_zone.sql_dns_zone.id
  sql_server_id                = var.deploy_synapse ? module.synapse.0.sql_dwh_id : null
  
  count                        = var.deploy_network && var.azure_alternate_region != null && var.azure_alternate_region != "" ? 1 : 0
  depends_on                   = [azurerm_resource_group.synapse]
}

# Credits: https://deployeveryday.com/2020/04/13/vpn-aws-azure-terraform.html
module aws_azure_vpn {
  source                       = "./modules/aws-azure-vpn"
  aws_key_name                 = aws_key_pair.pem_key[0].key_name
  azure_resource_group_name    = azurerm_resource_group.synapse.name
  azure_virtual_network_name   = module.azure_network[0].virtual_network_name
  azure_vm_subnet_id           = module.azure_network[0].vm_subnet_id
  user_name                    = var.user_name
  user_password                = local.password
  ssh_private_key              = var.ssh_private_key
  ssh_public_key               = var.ssh_public_key

  count                        = var.deploy_network && var.deploy_s2s_vpn ? 1 : 0
  depends_on                   = [azurerm_resource_group.synapse]
}

module aws_client {
  source                       = "./modules/aws-client"
  aws_key_name                 = aws_key_pair.pem_key[0].key_name
  sql_dwh_fqdn                 = var.deploy_synapse ? module.synapse[0].sql_dwh_fqdn : "yourserver.database.windows.net"
  sql_dwh_pool                 = var.deploy_synapse ? module.synapse[0].sql_dwh_pool_name : "pool"
  sql_dwh_private_ip_address   = var.deploy_synapse ? module.azure_network[0].sql_server_private_ip_address : "10.11.12.13"
  subnet_id                    = var.deploy_s2s_vpn ? module.aws_azure_vpn[0].aws_subnet_id : null
  suffix                       = local.suffix
  user_name                    = var.user_name
  vpc_id                       = var.deploy_s2s_vpn ? module.aws_azure_vpn[0].aws_vpc_id : null

  count                        = var.deploy_aws_client && var.deploy_network && var.deploy_s2s_vpn ? 1 : 0
}

module azure_client {
  source                       = "./modules/azure-client"
  resource_group_name          = azurerm_resource_group.synapse.name
  location                     = azurerm_resource_group.synapse.location
  sql_dwh_fqdn                 = var.deploy_synapse ? module.synapse[0].sql_dwh_fqdn : "yourserver.database.windows.net"
  sql_dwh_pool                 = var.deploy_synapse ? module.synapse[0].sql_dwh_pool_name : "pool"
  subnet_id                    = module.azure_network[0].vm_subnet_id
  user_assigned_identity_id    = azurerm_user_assigned_identity.client_identity.id
  user_name                    = var.user_name
  user_password                = local.password

  count                        = var.deploy_network && var.deploy_azure_client ? 1 : 0
  depends_on                   = [azurerm_resource_group.synapse]
}

module azure_client_alternate_region {
  source                       = "./modules/azure-client"
  resource_group_name          = azurerm_resource_group.synapse.name
  location                     = var.azure_alternate_region
  sql_dwh_fqdn                 = var.deploy_synapse ? module.synapse[0].sql_dwh_fqdn : "yourserver.database.windows.net"
  sql_dwh_pool                 = var.deploy_synapse ? module.synapse[0].sql_dwh_pool_name : "pool"
  subnet_id                    = module.azure_network_alternate_region[0].vm_subnet_id
  user_assigned_identity_id    = azurerm_user_assigned_identity.client_identity.id
  user_name                    = var.user_name
  user_password                = local.password

  count                        = var.deploy_network && var.deploy_azure_client && var.azure_alternate_region != null && var.azure_alternate_region != "" ? 1 : 0
  depends_on                   = [azurerm_resource_group.synapse]
}

module serverless {
  source                       = "./modules/serverless"
  appinsights_id               = azurerm_application_insights.insights.id
  appinsights_instrumentation_key = azurerm_application_insights.insights.instrumentation_key
  configure_egress             = true
  connection_string            = var.deploy_synapse ? module.synapse[0].connection_string : ""
  egress_subnet_id             = var.deploy_network ? module.azure_network[0].app_service_subnet_id : null
  location                     = var.azure_region
  log_analytics_workspace_resource_id = azurerm_log_analytics_workspace.workspace.id
  monitor_action_group_id      = azurerm_monitor_action_group.arm_roles.id
  resource_group_name          = azurerm_resource_group.synapse.name
  row_count                    = var.serverless_row_count
  sql_dwh_fqdn                 = var.deploy_synapse ? module.synapse[0].sql_dwh_fqdn : "yourserver.database.windows.net"
  sql_dwh_pool                 = var.deploy_synapse ? module.synapse[0].sql_dwh_pool_name : "pool"
  suffix                       = local.suffix
  user_assigned_identity_client_id = var.use_managed_identity ? azurerm_user_assigned_identity.client_identity.client_id : null
  user_assigned_identity_id    = azurerm_user_assigned_identity.client_identity.id
  user_name                    = var.user_name
  user_password                = local.password

  count                        = var.deploy_serverless && var.deploy_synapse ? 1 : 0
  depends_on                   = [module.azure_network]
}

module serverless_alternate_region {
  source                       = "./modules/serverless"
  appinsights_id               = azurerm_application_insights.insights.id
  appinsights_instrumentation_key = azurerm_application_insights.insights.instrumentation_key
  configure_egress             = true
  connection_string            = var.deploy_synapse ? module.synapse[0].connection_string : ""
  egress_subnet_id             = var.deploy_network ? module.azure_network_alternate_region[0].app_service_subnet_id : null
  location                     = var.azure_alternate_region
  log_analytics_workspace_resource_id = azurerm_log_analytics_workspace.workspace.id
  monitor_action_group_id      = azurerm_monitor_action_group.arm_roles.id
  resource_group_name          = azurerm_resource_group.synapse.name
  row_count                    = var.serverless_row_count
  sql_dwh_fqdn                 = var.deploy_synapse ? module.synapse[0].sql_dwh_fqdn : "yourserver.database.windows.net"
  sql_dwh_pool                 = var.deploy_synapse ? module.synapse[0].sql_dwh_pool_name : "pool"
  suffix                       = local.suffix
  user_assigned_identity_client_id = var.use_managed_identity ? azurerm_user_assigned_identity.client_identity.client_id : null
  user_assigned_identity_id    = azurerm_user_assigned_identity.client_identity.id
  user_name                    = var.user_name
  user_password                = local.password

  count                        = var.deploy_serverless && var.deploy_synapse && var.azure_alternate_region != null && var.azure_alternate_region != "" ? 1 : 0
  depends_on                   = [module.azure_network]
}

module synapse {
  source                       = "./modules/synapse"
  region                       = var.azure_region
  resource_group_name          = azurerm_resource_group.synapse.name
  admin_object_id              = data.azurerm_client_config.current.object_id
  # admin_object_id              = azurerm_user_assigned_identity client_identity.principal_id
  client_ip_prefixes           = [local.publicprefix]
  dwu                          = var.azure_sql_dwh_dwu
  grant_database_access        = var.use_managed_identity
  log_analytics_workspace_resource_id = azurerm_log_analytics_workspace.workspace.id
  private_dns_zone_id          = azurerm_private_dns_zone.sql_dns_zone.id
  user_assigned_identity_name  = azurerm_user_assigned_identity.client_identity.name
  user_name                    = var.user_name
  user_password                = local.password

  count                        = var.deploy_synapse ? 1 : 0
  depends_on                   = [azurerm_resource_group.synapse]
}