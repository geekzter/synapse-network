locals {
  connection_string_legacy     = "Server=tcp:${azurerm_sql_server.sql_dwh.fully_qualified_domain_name },1433;Initial Catalog=${azurerm_sql_database.sql_dwh.name};Persist Security Info=False;User ID=${var.user_name};Password=${var.user_password};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
  connection_string_msi        = "Server=tcp:${azurerm_sql_server.sql_dwh.fully_qualified_domain_name },1433;Database=${azurerm_sql_database.sql_dwh.name};"
  connection_string            = var.grant_database_access ? local.connection_string_msi : local.connection_string_legacy
  publicip                     = chomp(data.http.localpublicip.body)
  publicprefix                 = jsondecode(chomp(data.http.localpublicprefix.body)).data.prefix
  subnet_name                  = var.create_network_resources ? element(split("/",var.subnet_id),length(split("/",var.subnet_id))-1) : null
  virtual_network_id           = var.create_network_resources ? replace(var.subnet_id,"/subnets/${local.subnet_name}","") : null
  virtual_network_name         = var.create_network_resources ? element(split("/",local.virtual_network_id),length(split("/",local.virtual_network_id))-1) : null
}

data azurerm_client_config current {}
data azurerm_resource_group rg {
  name                         = var.resource_group_name
}

resource azurerm_sql_server sql_dwh {
  name                         = "${var.resource_group_name}-sqldwserver"
  resource_group_name          = var.resource_group_name
  location                     = var.region
  version                      = "12.0"
  administrator_login          = var.user_name
  administrator_login_password = var.user_password

  tags                         = data.azurerm_resource_group.rg.tags
}
resource azurerm_sql_active_directory_administrator dba {
  server_name                  = azurerm_sql_server.sql_dwh.name
  resource_group_name          = azurerm_sql_server.sql_dwh.resource_group_name
  login                        = var.admin_object_id
  object_id                    = var.admin_object_id
  tenant_id                    = data.azurerm_client_config.current.tenant_id
} 

data http localpublicip {
# Get public IP address of the machine running this terraform template
  url                          = "http://ipinfo.io/ip"
# url                          = "https://ipapi.co/ip" 
}
data http localpublicprefix {
# Get public IP prefix of the machine running this terraform template
  url                          = "https://stat.ripe.net/data/network-info/data.json?resource=${local.publicip}"
}
resource azurerm_sql_firewall_rule client_prefixes {
  name                         = "ClientRule${count.index+1}"
  resource_group_name          = var.resource_group_name
  server_name                  = azurerm_sql_server.sql_dwh.name
  start_ip_address             = cidrhost(var.client_ip_prefixes[count.index],0)
  end_ip_address               = cidrhost(
    var.client_ip_prefixes[count.index],
    pow(
      2,
      32-split(
        "/",
        var.client_ip_prefixes[count.index]
        )[1]
      )-1
    )

  count                        = length(var.client_ip_prefixes)
  # HACK: We know there are 40
  # count                        = 40
}

resource azurerm_sql_database sql_dwh {
  name                         = "${var.resource_group_name}-sqldw"
  resource_group_name          = var.resource_group_name
  location                     = var.region
  server_name                  = azurerm_sql_server.sql_dwh.name

  edition                      = "DataWarehouse"
  requested_service_objective_name = var.dwu

  tags                         = data.azurerm_resource_group.rg.tags
}
resource azurerm_monitor_diagnostic_setting sql_dwh_logs {
  name                         = "Synapse_Logs"
  target_resource_id           = azurerm_sql_database.sql_dwh.id
  log_analytics_workspace_id   = var.log_analytics_workspace_resource_id

  log {
    category                   = "DmsWorkers"
    enabled                    = true

    retention_policy {
      enabled                  = false
    }
  }
  log {
    category                   = "ExecRequests"
    enabled                    = true

    retention_policy {
      enabled                  = false
    }
  }
  log {
    category                   = "RequestSteps"
    enabled                    = true

    retention_policy {
      enabled                  = false
    }
  }
  log {
    category                   = "SqlRequests"
    enabled                    = true

    retention_policy {
      enabled                  = false
    }
  }
  log {
    category                   = "Waits"
    enabled                    = true

    retention_policy {
      enabled                  = false
    }
  }

  metric {
    category                   = "Basic"

    retention_policy {
      enabled                  = false
    }
  } 
  metric {
    category                   = "InstanceAndAppAdvanced"

    retention_policy {
      enabled                  = false
    }
  } 
  metric {
    category                   = "WorkloadManagement"

    retention_policy {
      enabled                  = false
    }
  } 
}

resource null_resource grant_sql_access {
  # Add App Service MSI and DBA to Database
  provisioner "local-exec" {
    command                    = "../scripts/grant_database_access.ps1 -MSIName ${var.user_assigned_identity_name} -SqlDatabaseName ${azurerm_sql_database.sql_dwh.name} -SqlServerFQDN ${azurerm_sql_server.sql_dwh.fully_qualified_domain_name}"
    interpreter                = ["pwsh", "-nop", "-Command"]
  }

  count                        = var.grant_database_access ? 1 : 0
  # Terraform change scripts require Terraform to be the AAD DBA
  depends_on                   = [azurerm_sql_active_directory_administrator.dba]
}

resource azurerm_private_dns_zone sql_dns_zone {
  name                         = "privatelink.database.windows.net"
  resource_group_name          = var.resource_group_name

  tags                         = data.azurerm_resource_group.rg.tags

  count                        = var.create_network_resources ? 1 : 0
}

resource azurerm_private_dns_zone_virtual_network_link sql {
  name                         = "${local.virtual_network_name}-sql-link"
  resource_group_name          = var.resource_group_name
  private_dns_zone_name        = azurerm_private_dns_zone.sql_dns_zone[0].name
  virtual_network_id           = local.virtual_network_id

  count                        = var.create_network_resources ? 1 : 0
}

resource azurerm_private_endpoint sql_dwh_endpoint {
  name                         = "${azurerm_sql_database.sql_dwh.name}-${var.region}-endpoint"
  resource_group_name          = var.resource_group_name
  location                     = var.region
  
  subnet_id                    = var.subnet_id

  private_dns_zone_group {
    name                       = azurerm_private_dns_zone.sql_dns_zone[0].name
    private_dns_zone_ids       = [azurerm_private_dns_zone.sql_dns_zone[0].id]
  }

  private_service_connection {
    is_manual_connection       = false
    name                       = "${azurerm_sql_server.sql_dwh.name}-${var.region}-endpoint-connection"
    private_connection_resource_id = azurerm_sql_server.sql_dwh.id
    subresource_names          = ["sqlServer"]
  }

  tags                         = data.azurerm_resource_group.rg.tags

  count                        = var.create_network_resources ? 1 : 0
 }
