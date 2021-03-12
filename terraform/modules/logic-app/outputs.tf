locals {
  # All outbound IP adresses & prefixes (connector_outbound_ip_addresses mixes both in a single attribute)
  raw_logic_outbound_addresses = concat(azurerm_logic_app_workflow.workflow.connector_outbound_ip_addresses,azurerm_logic_app_workflow.workflow.workflow_outbound_ip_addresses)
  outbound_ip_addresses        = [for ip in local.raw_logic_outbound_addresses : ip if !can(regex("/",ip))]
  outbound_ip_prefixes1        = [for prefix in local.raw_logic_outbound_addresses : prefix if can(regex("/",prefix))]
  # Create prefixes from IP addresses
  outbound_ip_prefixes2        = [for ip in local.outbound_ip_addresses : "${ip}/32"]
}


output outbound_ip_prefixes {
  value                        = sort(distinct(concat(
    local.outbound_ip_prefixes1,
    local.outbound_ip_prefixes2,
  )))
}