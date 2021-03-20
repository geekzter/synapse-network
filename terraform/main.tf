data http localpublicip {
# Get public IP address of the machine running this terraform template
  url                          = "http://ipinfo.io/ip"
# url                          = "https://ipapi.co/ip" 
}
data http localpublicprefix {
# Get public IP prefix of the machine running this terraform template
  url                          = "https://stat.ripe.net/data/network-info/data.json?resource=${local.publicip}"
}

data azurerm_client_config current {}

locals {
  password                     = ".Az9${random_string.password.result}"
  publicip                     = chomp(data.http.localpublicip.body)
  publicprefix                 = jsondecode(chomp(data.http.localpublicprefix.body)).data.prefix
  suffix                       = random_string.suffix.result
  tags                         = map(
    "application",               "Synapse Performance",
    "environment",               "dev",
    "provisioner",               "terraform",
    "repository",                "synapse-performance",
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

  count                        = var.deploy_aws_client || var.deploy_s2s_vpn ? 1 : 0
}

resource azurerm_user_assigned_identity client_identity {
  name                         = "${azurerm_resource_group.synapse.name}-client-identity"
  location                     = azurerm_resource_group.synapse.location
  resource_group_name          = azurerm_resource_group.synapse.name

  tags                         = local.tags
}


resource azurerm_resource_group synapse {
  name                         = "synapse-network-${terraform.workspace}-${local.suffix}"
  location                     = var.azure_region

  tags                         = local.tags
}

resource azurerm_storage_account automation_storage {
  name                         = "${lower(substr(replace(azurerm_resource_group.synapse.name,"/a|e|i|o|u|y|-/",""),0,20))}${local.suffix}"
  location                     = azurerm_resource_group.synapse.location
  resource_group_name          = azurerm_resource_group.synapse.name
  account_kind                 = "StorageV2"
  account_tier                 = "Standard"
  account_replication_type     = "LRS"
  allow_blob_public_access     = true
  blob_properties {
    delete_retention_policy {
      days                     = 365
    }
  }
  enable_https_traffic_only    = true

  tags                         = azurerm_resource_group.synapse.tags
}

resource azurerm_storage_container scripts {
  name                         = "scripts"
  storage_account_name         = azurerm_storage_account.automation_storage.name
  container_access_type        = "container"
}

resource azurerm_private_dns_zone sql_dns_zone {
  name                         = "privatelink.database.windows.net"
  resource_group_name          = azurerm_resource_group.synapse.name

  tags                         = azurerm_resource_group.synapse.tags
}