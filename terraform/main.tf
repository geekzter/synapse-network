data http localpublicip {
# Get public IP address of the machine running this terraform template
  url                          = "http://ipinfo.io/ip"
# url                          = "https://ipapi.co/ip" 
}
data http localpublicprefix {
# Get public IP prefix of the machine running this terraform template
  url                          = "https://stat.ripe.net/data/network-info/data.json?resource=${local.publicip}"
}

locals {
  password                     = ".Az9${random_string.password.result}"
  publicip                     = chomp(data.http.localpublicip.body)
  publicprefix                 = jsondecode(chomp(data.http.localpublicprefix.body)).data.prefix
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

  count                        = var.deploy_aws_client || var.deploy_s2s_vpn ? 1 : 0
}

resource azurerm_resource_group synapse {
  name                         = "synapse-network-performance-${terraform.workspace}-${local.suffix}"
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

resource azurerm_log_analytics_workspace workspace {
  name                         = "${azurerm_resource_group.synapse.name}-loganalytics"
  location                     = azurerm_resource_group.synapse.location
  resource_group_name          = azurerm_resource_group.synapse.name
  sku                          = "Standalone"
  retention_in_days            = 90 

  tags                         = azurerm_resource_group.synapse.tags
}

resource azurerm_log_analytics_solution solutions {
  solution_name                 = each.value
  location                      = azurerm_log_analytics_workspace.workspace.location
  resource_group_name           = azurerm_log_analytics_workspace.workspace.resource_group_name
  workspace_resource_id         = azurerm_log_analytics_workspace.workspace.id
  workspace_name                = azurerm_log_analytics_workspace.workspace.name

  plan {
    publisher                   = "Microsoft"
    product                     = "OMSGallery/${each.value}"
  }

  for_each                      = toset(var.log_analytics_solutions)
} 

resource azurerm_application_insights insights {
  name                         = "${azurerm_resource_group.synapse.name}-insights"
  location                     = azurerm_log_analytics_workspace.workspace.location
  resource_group_name          = azurerm_resource_group.synapse.name
  application_type             = "web"

  tags                         = azurerm_resource_group.synapse.tags
}