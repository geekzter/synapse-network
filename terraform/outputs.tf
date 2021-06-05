output application_insights_instrumentation_key {
  sensitive    = true
  value        = azurerm_application_insights.insights.instrumentation_key
}

output aws_linux_vm_public_ip_address {
  value        = var.deploy_s2s_vpn ? module.aws_azure_vpn.0.aws_linux_vm_public_ip_address : null
}

output aws_linux_vm_private_ip_address {
  value        = var.deploy_s2s_vpn ? module.aws_azure_vpn.0.aws_linux_vm_private_ip_address : null
}

output aws_linux_vm_user_name {
  value        = var.deploy_s2s_vpn ? "ubuntu" : null
}

output aws_azure_ping_command {
  value        = var.deploy_s2s_vpn ? "ssh ubuntu@${module.aws_azure_vpn.0.aws_linux_vm_public_ip_address} ping ${module.aws_azure_vpn.0.azure_linux_vm_private_ip_address} -c 4" : null
}

output aws_windows_vm_encrypted_password {
  sensitive    = true
  value        = var.deploy_s2s_vpn && var.deploy_aws_client ? module.aws_client.0.vm_encrypted_password : null
}

output aws_windows_vm_password {
  sensitive    = true
  value        = var.deploy_s2s_vpn && var.deploy_aws_client && fileexists(var.ssh_private_key) ? rsadecrypt(module.aws_client.0.vm_encrypted_password,file(var.ssh_private_key)) : null
}

output azure_aws_ping_command {
  value        = var.deploy_s2s_vpn ? "ssh ${var.user_name}@${module.aws_azure_vpn.0.azure_linux_vm_public_ip_address} ping ${module.aws_azure_vpn.0.aws_linux_vm_private_ip_address} -c 4" : null
}

output aws_windows_vm_public_ip_address {
  value        = var.deploy_s2s_vpn && var.deploy_aws_client ? module.aws_client.0.vm_public_ip_address : null
}

output azure_linux_vm_public_ip_address {
  value        = var.deploy_s2s_vpn ? module.aws_azure_vpn.0.azure_linux_vm_public_ip_address : null
}

output azure_linux_vm_private_ip_address {
  value        = var.deploy_s2s_vpn ? module.aws_azure_vpn.0.azure_linux_vm_private_ip_address : null
}

output connection_string {
  value        = var.deploy_synapse ? module.synapse.0.connection_string : null
}
output connection_string_legacy {
  value        = var.deploy_synapse ? module.synapse.0.connection_string_legacy : null
}

output function_name {
  value        = concat(
    var.deploy_serverless && var.deploy_synapse ? [module.serverless.0.function_name] : [],
    var.deploy_serverless && var.deploy_synapse && var.azure_alternate_region != null && var.azure_alternate_region != "" ? [module.serverless_alternate_region.0.function_name] : []
  )
}

output log_analytics_workspace_id {
  value        = azurerm_log_analytics_workspace.workspace.id
}

output managed_identity_id {
  value        = azurerm_user_assigned_identity.client_identity.id
}
output managed_identity_name {
  value        = azurerm_user_assigned_identity.client_identity.name
}
output managed_identity_object_id {
  description  = "The Object ID / Principal ID of the Service Principal created as User Assigned Identity"
  value        = azurerm_user_assigned_identity.client_identity.principal_id
}
output managed_identity_client_id {
  description  = "The App ID / Client ID of the Service Principal created as User Assigned Identity"
  value        = azurerm_user_assigned_identity.client_identity.client_id
}

output resource_group_id {
  value        = azurerm_resource_group.synapse.id
}

output resource_group_name {
  value        = azurerm_resource_group.synapse.name
}

output sql_dwh_fqdn {
  value        = var.deploy_synapse ? module.synapse.0.sql_dwh_fqdn : null
}

output sql_dwh_pool_name {
  value        = var.deploy_synapse ? module.synapse.0.sql_dwh_pool_name : null
}

output sql_dwh_private_ip_address {
  value        = var.azure_alternate_region != null && var.azure_alternate_region != "" ? {
    (var.azure_region) = var.deploy_network && var.deploy_synapse ? module.azure_network.0.sql_server_private_ip_address : null
    (var.azure_alternate_region) = var.deploy_network && var.deploy_synapse ? module.azure_network_alternate_region.0.sql_server_private_ip_address : null
   } : {
    (var.azure_region) = var.deploy_network && var.deploy_synapse ? module.azure_network.0.sql_server_private_ip_address : null
   }
}

output user_name {
  sensitive    = false
  value        = var.user_name                   
}

output user_password {
  sensitive    = true
  value        = local.password                   
}

output windows_vm_public_ip_address {
  value        = var.azure_alternate_region != null && var.azure_alternate_region != "" ? {
    (var.azure_region) = var.deploy_network && var.deploy_azure_client ? module.azure_client.0.public_ip_address : null,
    (var.azure_alternate_region) = var.deploy_network && var.deploy_azure_client ? module.azure_client_alternate_region.0.public_ip_address : null,
  } : {
    (var.azure_region) = var.deploy_network && var.deploy_azure_client ? module.azure_client.0.public_ip_address : null
  }
}
