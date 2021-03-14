locals {
  publicip                     = chomp(data.http.localpublicip.body)
  publicprefix                 = jsondecode(chomp(data.http.localpublicprefix.body)).data.prefix
  subnet_name                  = var.create_network_resources ? element(split("/",var.subnet_id),length(split("/",var.subnet_id))-1) : null
  virtual_network_id           = var.create_network_resources ? replace(var.subnet_id,"/subnets/${local.subnet_name}","") : null
  virtual_network_name         = var.create_network_resources ? element(split("/",local.virtual_network_id),length(split("/",local.virtual_network_id))-1) : null
}

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

data http localpublicip {
# Get public IP address of the machine running this terraform template
  url                          = "http://ipinfo.io/ip"
# url                          = "https://ipapi.co/ip" 
}
data http localpublicprefix {
# Get public IP prefix of the machine running this terraform template
  url                          = "https://stat.ripe.net/data/network-info/data.json?resource=${local.publicip}"
}
resource azurerm_sql_firewall_rule terraform_client_ip {
  name                         = "TerraformClientIpRule"
  resource_group_name          = var.resource_group_name
  server_name                  = azurerm_sql_server.sql_dwh.name
  start_ip_address             = local.publicip
  end_ip_address               = local.publicip
}
resource azurerm_sql_firewall_rule terraform_client_ip_prefix {
  name                         = "TerraformClientIpPrefixRule"
  resource_group_name          = var.resource_group_name
  server_name                  = azurerm_sql_server.sql_dwh.name
  start_ip_address             = cidrhost(local.publicprefix,0)
  end_ip_address               = cidrhost(local.publicprefix,pow(2,32-split("/",local.publicprefix)[1])-1)
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

  # count                        = length(var.client_ip_prefixes)
  # HACK: We know there are 40
  count                        = 40
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
  name                         = "${azurerm_sql_database.sql_dwh.name}-endpoint"
  resource_group_name          = var.resource_group_name
  location                     = var.region
  
  subnet_id                    = var.subnet_id

  private_dns_zone_group {
    name                       = azurerm_private_dns_zone.sql_dns_zone[0].name
    private_dns_zone_ids       = [azurerm_private_dns_zone.sql_dns_zone[0].id]
  }

  private_service_connection {
    is_manual_connection       = false
    name                       = "${azurerm_sql_server.sql_dwh.name}-endpoint-connection"
    private_connection_resource_id = azurerm_sql_server.sql_dwh.id
    subresource_names          = ["sqlServer"]
  }

  tags                         = data.azurerm_resource_group.rg.tags

  count                        = var.create_network_resources ? 1 : 0
 }
