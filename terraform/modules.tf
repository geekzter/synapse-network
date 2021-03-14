# Credits: https://deployeveryday.com/2020/04/13/vpn-aws-azure-terraform.html
module aws_azure_vpn {
  source                       = "./modules/aws-azure-vpn"
  aws_key_name                 = aws_key_pair.pem_key[0].key_name
  azure_resource_group_name    = azurerm_resource_group.synapse.name
  azure_virtual_network_name   = module.azure_network[0].azure_virtual_network_name
  azure_vm_subnet_id           = module.azure_network[0].azure_subnet_id
  user_name                    = var.user_name
  user_password                = local.password
  ssh_private_key              = var.ssh_private_key
  ssh_public_key               = var.ssh_public_key

  count                        = var.deploy_network && var.deploy_s2s_vpn ? 1 : 0
}

module aws_client {
  source                       = "./modules/aws-client"
  aws_key_name                 = aws_key_pair.pem_key[0].key_name
  sql_dwh_fqdn                 = var.deploy_synapse ? module.synapse[0].sql_dwh_fqdn : "yourserver.database.windows.net"
  sql_dwh_pool                 = var.deploy_synapse ? module.synapse[0].sql_dwh_pool_name : "pool"
  sql_dwh_private_ip_address   = var.deploy_synapse ? module.synapse[0].sql_dwh_private_ip_address : "10.11.12.13"
  subnet_id                    = var.deploy_s2s_vpn ? module.aws_azure_vpn[0].aws_subnet_id : null
  suffix                       = local.suffix
  user_name                    = var.user_name
  vpc_id                       = var.deploy_s2s_vpn ? module.aws_azure_vpn[0].aws_vpc_id : null

  count                        = var.deploy_aws_client && var.deploy_network && var.deploy_s2s_vpn ? 1 : 0
}

module azure_client {
  source                       = "./modules/azure-client"
  scripts_storage_container_id = azurerm_storage_container.scripts.id
  resource_group_name          = azurerm_resource_group.synapse.name
  sql_dwh_fqdn                 = var.deploy_synapse ? module.synapse[0].sql_dwh_fqdn : "yourserver.database.windows.net"
  sql_dwh_pool                 = var.deploy_synapse ? module.synapse[0].sql_dwh_pool_name : "pool"
  sql_dwh_private_ip_address   = var.deploy_synapse ? module.synapse[0].sql_dwh_private_ip_address : "10.11.12.13"
  subnet_id                    = module.azure_network[0].azure_subnet_id
  user_name                    = var.user_name
  user_password                = local.password

  count                        = var.deploy_network && var.deploy_azure_client ? 1 : 0
}

module logic_app {
  source                       = "./modules/logic-app"
  appinsights_instrumentation_key = azurerm_application_insights.insights.instrumentation_key
  resource_group_name          = azurerm_resource_group.synapse.name
  sql_dwh_fqdn                 = var.deploy_synapse ? module.synapse[0].sql_dwh_fqdn : "yourserver.database.windows.net"
  sql_dwh_pool                 = var.deploy_synapse ? module.synapse[0].sql_dwh_pool_name : "pool"
  user_name                    = var.user_name
  user_password                = local.password

  count                        = var.deploy_logic_app && var.deploy_synapse ? 1 : 0
}

locals {
  fixed_prefix_list           = [
    local.publicprefix,
    local.publicprefix,
    local.publicprefix,
    local.publicprefix,
    local.publicprefix,
    local.publicprefix,
    local.publicprefix,
    local.publicprefix,
    local.publicprefix,
    local.publicprefix,
    local.publicprefix,
    local.publicprefix,
    local.publicprefix,
    local.publicprefix,
    local.publicprefix,
    local.publicprefix,
    local.publicprefix,
    local.publicprefix,
    local.publicprefix,
    local.publicprefix,
    local.publicprefix,
    local.publicprefix,
    local.publicprefix,
    local.publicprefix,
    local.publicprefix,
    local.publicprefix,
    local.publicprefix,
    local.publicprefix,
    local.publicprefix,
    local.publicprefix,
    local.publicprefix,
    local.publicprefix,
  ]
  # HACK: Terraform needs to know the # of list elements before apply, so create a fixed length list that contains everything
  concat_prefix_list           = var.deploy_logic_app ? slice(concat(module.logic_app[0].outbound_ip_prefixes,local.fixed_prefix_list),0,length(local.fixed_prefix_list)) : local.fixed_prefix_list
  
}
module synapse {
  source                       = "./modules/synapse"
  region                       = var.azure_region
  resource_group_name          = azurerm_resource_group.synapse.name
  client_ip_prefixes           = local.concat_prefix_list
  dwu                          = var.azure_sql_dwh_dwu
  user_name                    = var.user_name
  user_password                = local.password
  create_network_resources     = var.deploy_network
  subnet_id                    = var.deploy_network ? module.azure_network[0].azure_subnet_id : null

  count                        = var.deploy_synapse ? 1 : 0
}