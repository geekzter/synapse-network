locals {
  password                     = ".Az9${random_string.password.result}"
  suffix                       = random_string.suffix.result
  tags                         = map(
    "application",               "AWS-Azure VPN",
    "environment",               "dev",
    "provisioner",               "terraform",
    "suffix",                    local.suffix,
    "workspace",                 terraform.workspace
  )
}

# Random resource suffix, this will prevent name collisions when creating resources in parallel
resource random_string suffix {
  length                       = 4
  upper                        = false
  lower                        = true
  number                       = false
  special                      = false
}

# Random password generator
resource random_string password {
  length                       = 12
  upper                        = true
  lower                        = true
  number                       = true
  special                      = true
# override_special             = "!@#$%&*()-_=+[]{}<>:?" # default
# Avoid characters that may cause shell scripts to break
  override_special             = "!@#%*)(-_=+][]}{:?"
}

resource aws_key_pair pem_key {
  key_name                     = "azure-vpn-${terraform.workspace}-${local.suffix}"
  public_key                   = file(var.ssh_public_key)

  tags                         = local.tags
}

resource azurerm_resource_group vpn {
  name                         = "aws-vpn-${terraform.workspace}-${local.suffix}"
  location                     = var.azure_region

  tags                         = local.tags
}

# Credits: https://deployeveryday.com/2020/04/13/vpn-aws-azure-terraform.html
module aws_azure_vpn {
  source                       = "./modules/aws-azure-vpn"
  aws_key_name                 = aws_key_pair.pem_key.key_name
  azure_region                 = var.azure_region
  azure_resource_group_name    = azurerm_resource_group.vpn.name
  user_name                    = var.user_name
  user_password                = local.password
  ssh_private_key              = var.ssh_private_key
  ssh_public_key               = var.ssh_public_key

  count                        = var.deploy_network ? 1 : 0
}

module synapse_client {
  source                       = "./modules/aws-client"
  aws_key_name                 = aws_key_pair.pem_key.key_name
  sql_dwh_private_ip_address   = var.deploy_synapse ? module.synapse[0].sql_dwh_private_ip_address : "10.11.12.13"
  sql_dwh_fqdn                 = var.deploy_synapse ? module.synapse[0].sql_dwh_fqdn : "yourserver.database.windows.net"
  sql_dwh_pool                 = var.deploy_synapse ? module.synapse[0].sql_dwh_pool_name : "pool"
  subnet_id                    = var.deploy_network ? module.aws_azure_vpn[0].aws_subnet_id : null
  suffix                       = local.suffix
  user_name                    = var.user_name
  vpc_id                       = var.deploy_network ? module.aws_azure_vpn[0].aws_vpc_id : null

  count                        = var.deploy_network && var.deploy_synapse_client ? 1 : 0
}

module synapse {
  source                       = "./modules/synapse"
  region                       = var.azure_region
  resource_group_name          = azurerm_resource_group.vpn.name
  dwu                          = var.azure_sql_dwh_dwu
  user_name                    = var.user_name
  user_password                = local.password
  create_network_resources     = var.deploy_network
  subnet_id                    = var.deploy_network ? module.aws_azure_vpn[0].azure_subnet_id : null

  count                        = var.deploy_synapse ? 1 : 0
}