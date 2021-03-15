
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
data azurerm_role_definition contributor {
  name                         = "Contributor"
}
data azurerm_role_definition owner {
  name                         = "Owner"
}
resource azurerm_monitor_action_group arm_roles {
  name                         = "${azurerm_resource_group.synapse.name}-alert-group"
  resource_group_name          = azurerm_resource_group.synapse.name
  short_name                   = "Contributors"

  # Azure RBAC contributor roles relative to the resource
  arm_role_receiver {
    name                       = data.azurerm_role_definition.contributor.name
    role_id                    = split("/",data.azurerm_role_definition.contributor.id)[4]
    use_common_alert_schema    = true
  }
  arm_role_receiver {
    name                       = data.azurerm_role_definition.owner.name
    role_id                    = split("/",data.azurerm_role_definition.owner.id)[4]
    use_common_alert_schema    = true
  }

/*
  # Push notification via Azure mobile app
  azure_app_push_receiver {
    name                       = "pushtoadmin"
    email_address              = "admin@contoso.com"
  }

  # Plain old email
  email_receiver {
    name                       = "sendtodevops"
    email_address              = "devops@contoso.com"
    use_common_alert_schema    = true
  }

  # ITSM e.g. ServiceNow
  itsm_receiver {
    name                       = "createorupdateticket"
    workspace_id               = azurerm_log_analytics_workspace.workspace.id
    connection_id              = "00000000-0000-0000-0000-000000000000"
    ticket_configuration       = "{}"
    region                     = azurerm_log_analytics_workspace.workspace.location
  }  
  */
}