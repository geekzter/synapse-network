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
    SYNAPSE_ROW_COUNT          = var.row_count
    WEBSITE_CONTENTSHARE       = "${var.resource_group_name}-top-test-content"
    WEBSITE_CONTENTAZUREFILECONNECTIONSTRING = "DefaultEndpointsProtocol=https;AccountName=${azurerm_storage_account.functions.name};AccountKey=${azurerm_storage_account.functions.primary_access_key};EndpointSuffix=core.windows.net"
    WEBSITE_DNS_SERVER         = var.configure_egress ? "168.63.129.16" : null # Private DNS
    WEBSITE_VNET_ROUTE_ALL     = var.configure_egress ? "1" : null # Force all egress via specified subnet
    # WEBSITE_RUN_FROM_PACKAGE   = 1
  }
  sql_connection_string        = "Server=tcp:${var.sql_dwh_fqdn},1433;Initial Catalog=${var.sql_dwh_pool};Persist Security Info=False;User ID=${var.user_name};Password=${var.user_password};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
}

resource azurerm_storage_account functions {
  name                         = "${lower(substr(replace(var.resource_group_name,"/a|e|i|o|u|y|-/",""),0,17))}fnc${var.suffix}"
  resource_group_name          = var.resource_group_name
  location                     = var.location
  account_tier                 = "Standard"
  account_replication_type     = "LRS"
}

resource azurerm_app_service_plan functions {
  name                         = "${var.resource_group_name}-functions"
  resource_group_name          = var.resource_group_name
  location                     = var.location
  kind                         = "FunctionApp"
  reserved                     = true

  sku {
    # VNet Integration requires standard sku
    # https://docs.microsoft.com/en-us/azure/app-service/web-sites-integrate-with-vnet
    tier                       = var.configure_egress ? "Standard" : "Dynamic"
    size                       = var.configure_egress ? "S1" : "Y1"
  }

  lifecycle {
    ignore_changes             = [
      kind
    ]
  }

  tags                         = data.azurerm_resource_group.rg.tags
}
resource azurerm_function_app top_test {
  name                         = "${var.resource_group_name}-top-test"
  resource_group_name          = var.resource_group_name
  location                     = var.location
  app_service_plan_id          = azurerm_app_service_plan.functions.id
  app_settings                 = local.app_service_settings
  site_config {
    always_on                  = true
  }
  storage_account_name         = azurerm_storage_account.functions.name
  storage_account_access_key   = azurerm_storage_account.functions.primary_access_key
  version                      = "~3"

  lifecycle {
    ignore_changes             = [
      # Ignore Visual Studio Code modifications
                                 app_settings["WEBSITE_CONTENTAZUREFILECONNECTIONSTRING"], 
                                 app_settings["WEBSITE_CONTENTSHARE"], 
                                 os_type
    ]
  }  

  tags                         = data.azurerm_resource_group.rg.tags
}
resource azurerm_app_service_virtual_network_swift_connection network {
  app_service_id               = azurerm_function_app.top_test.id
  subnet_id                    = var.egress_subnet_id

  count                        = var.configure_egress ? 1 : 0
}
resource azurerm_monitor_scheduled_query_rules_alert top_test_alert {
  name                         = "${azurerm_function_app.top_test.name}-alert"
  resource_group_name          = var.resource_group_name
  location                     = var.location

  action {
    action_group               = [var.monitor_action_group_id]
    email_subject              = "Synapse test query is taking longer than expected"
  }
  data_source_id               = var.appinsights_id
  description                  = "Alert when # low performing queries goes over threshold"
  enabled                      = true
  query                        = file("${path.root}/../kusto/alert.kql")
  severity                     = 2
  frequency                    = 5
  time_window                  = 30
  trigger {
    operator                   = "GreaterThan"
    threshold                  = 2
  }
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
  name                         = "${var.resource_group_name}-workflow"
  resource_group_name          = var.resource_group_name
  location                     = var.location

  lifecycle {
    ignore_changes             = [
      parameters
    ]
  }

  tags                         = data.azurerm_resource_group.rg.tags
}
resource azurerm_monitor_diagnostic_setting start_workflow {
  name                         = "${azurerm_logic_app_workflow.workflow.name}-logs"
  target_resource_id           = azurerm_logic_app_workflow.workflow.id
  log_analytics_workspace_id   = var.log_analytics_workspace_resource_id

  log {
    category                   = "WorkflowRuntime"
    enabled                    = true

    retention_policy {
      enabled                  = true
      days                     = 30
    }
  }
  metric {
    category                   = "AllMetrics"

    retention_policy {
      enabled                  = true
      days                     = 30
    }
  }
}