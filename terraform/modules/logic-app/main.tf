data azurerm_resource_group rg {
  name                         = var.resource_group_name
}

locals {
  app_service_settings         = {
    APPINSIGHTS_INSTRUMENTATIONKEY = var.appinsights_instrumentation_key
    APPLICATIONINSIGHTS_CONNECTION_STRING = "InstrumentationKey=${var.appinsights_instrumentation_key}"
    # FUNCTIONS_EXTENSION_VERSION = "~3"
    FUNCTIONS_WORKER_RUNTIME   = "dotnet"
    SYNAPSE_CONNECTION_STRING  = local.sql_connection_string
    WEBSITE_CONTENTSHARE       = "${data.azurerm_resource_group.rg.name}-top-test-content"
    WEBSITE_CONTENTAZUREFILECONNECTIONSTRING = "DefaultEndpointsProtocol=https;AccountName=${azurerm_storage_account.functions.name};AccountKey=${azurerm_storage_account.functions.primary_access_key};EndpointSuffix=core.windows.net"
    WEBSITE_DNS_SERVER         = var.configure_egress ? "168.63.129.16" : null # Private DNS
    WEBSITE_VNET_ROUTE_ALL     = var.configure_egress ? "1" : null # Force all egress via specified subnet
    # WEBSITE_RUN_FROM_PACKAGE   = 1
  }
  sql_connection_string        = "Server=tcp:${var.sql_dwh_fqdn},1433;Initial Catalog=${var.sql_dwh_pool};Persist Security Info=False;User ID=${var.user_name};Password=${var.user_password};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
}

resource azurerm_storage_account functions {
  name                         = "${lower(substr(replace(var.resource_group_name,"/a|e|i|o|u|y|-/",""),0,17))}fnc${data.azurerm_resource_group.rg.tags["suffix"]}"
  resource_group_name          = data.azurerm_resource_group.rg.name
  location                     = data.azurerm_resource_group.rg.location
  account_tier                 = "Standard"
  account_replication_type     = "LRS"
}

resource azurerm_app_service_plan functions {
  name                         = "${data.azurerm_resource_group.rg.name}-functions"
  resource_group_name          = data.azurerm_resource_group.rg.name
  location                     = data.azurerm_resource_group.rg.location
  kind                         = "FunctionApp"
  reserved                     = true

  sku {
    # VNet Integration requires standard sku
    # https://docs.microsoft.com/en-us/azure/app-service/web-sites-integrate-with-vnet
    # tier                       = var.configure_egress ? "Standard" : "Dynamic"
    # size                       = var.configure_egress ? "S1" : "Y1"
    tier                       = "Standard"
    size                       = "S1"
    # tier                       = "Dynamic"
    # size                       = "Y1"
  }
}
resource azurerm_function_app top_test {
  name                         = "${data.azurerm_resource_group.rg.name}-top-test"
  resource_group_name          = data.azurerm_resource_group.rg.name
  location                     = data.azurerm_resource_group.rg.location
  app_service_plan_id          = azurerm_app_service_plan.functions.id
  app_settings                 = local.app_service_settings
  storage_account_name         = azurerm_storage_account.functions.name
  storage_account_access_key   = azurerm_storage_account.functions.primary_access_key
  version                      = "~3"

  # lifecycle {
  #   ignore_changes             = [
  #     # Ignore Visual Studio Code modifications
  #                                app_settings["AzureWebJobsDashboard"], 
  #                                app_settings["AzureWebJobsStorage"], 
  #                                app_settings["WEBSITE_CONTENTAZUREFILECONNECTIONSTRING"], 
  #                                app_settings["WEBSITE_CONTENTSHARE"], 
  #   ]
  # }  
}
resource azurerm_app_service_virtual_network_swift_connection network {
  app_service_id               = azurerm_function_app.top_test.id
  subnet_id                    = var.egress_subnet_id

  count                        = var.configure_egress ? 1 : 0
}
resource azurerm_monitor_diagnostic_setting function_logs {
  name                         = "Function_Logs"
  target_resource_id           = azurerm_function_app.top_test.id
  log_analytics_workspace_id   = var.log_analytics_workspace_resource_id

  log {
    category                   = "FunctionAppLogs"
    enabled                    = true

    retention_policy {
      enabled                  = false
    }
  }
  metric {
    category                   = "AllMetrics"

    retention_policy {
      enabled                  = false
    }
  }
}

resource azurerm_logic_app_workflow workflow {
  name                         = "${data.azurerm_resource_group.rg.name}-workflow"
  resource_group_name          = data.azurerm_resource_group.rg.name
  location                     = data.azurerm_resource_group.rg.location

  lifecycle {
    ignore_changes             = [
      parameters
    ]
  }
}