output outbound_ip_addresses {
  # value        = sort(distinct(concat(
  #   azurerm_logic_app_workflow.workflow.connector_outbound_ip_addresses,azurerm_logic_app_workflow.workflow.workflow_outbound_ip_addresses
  # )))
  value        = azurerm_logic_app_workflow.workflow.connector_outbound_ip_addresses
}