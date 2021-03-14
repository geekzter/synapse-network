data azurerm_resource_group rg {
  name                         = var.resource_group_name
}

locals {
  app_service_settings         = {
    APPINSIGHTS_INSTRUMENTATIONKEY = var.appinsights_instrumentation_key
    APPLICATIONINSIGHTS_CONNECTION_STRING = "InstrumentationKey=${var.appinsights_instrumentation_key}"
    SYNAPSE_CONNECTION_STRING  = local.sql_connection_string
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
    tier                       = "Dynamic"
    size                       = "Y1"
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

  lifecycle {
    ignore_changes             = [
      # Ignore Visual Studio Code modifications
                                 app_settings["WEBSITE_CONTENTAZUREFILECONNECTIONSTRING"], 
                                 app_settings["WEBSITE_CONTENTSHARE"], 
    ]
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