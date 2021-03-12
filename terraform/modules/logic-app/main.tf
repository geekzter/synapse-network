data azurerm_resource_group rg {
  name                         = var.resource_group_name
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