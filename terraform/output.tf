output aws_linux_vm_public_ip_address {
  value        = var.deploy_network ? module.aws_azure_vpn[0].aws_linux_vm_public_ip_address : null
}

output aws_linux_vm_private_ip_address {
  value        = var.deploy_network ? module.aws_azure_vpn[0].aws_linux_vm_private_ip_address : null
}

output aws_linux_vm_user_name {
  value        = var.deploy_network ? "ubuntu" : null
}

output aws_azure_ping_command {
  value        = var.deploy_network ? "ssh ubuntu@${module.aws_azure_vpn[0].aws_linux_vm_public_ip_address} ping ${module.aws_azure_vpn[0].azure_linux_vm_private_ip_address} -c 4" : null
}

output aws_windows_vm_encrypted_password {
  sensitive    = true
  value        = var.deploy_network && var.deploy_synapse_client ? module.synapse_client[0].vm_encrypted_password : null
}

output aws_windows_vm_password {
  sensitive    = true
  value        = var.deploy_network && var.deploy_synapse_client && fileexists(var.ssh_private_key) ? rsadecrypt(module.synapse_client[0].vm_encrypted_password,file(var.ssh_private_key)) : null
}

output azure_aws_ping_command {
  value        = var.deploy_network ? "ssh ${var.user_name}@${module.aws_azure_vpn[0].azure_linux_vm_public_ip_address} ping ${module.aws_azure_vpn[0].aws_linux_vm_private_ip_address} -c 4" : null
}

output aws_windows_vm_public_ip_address {
  value        = var.deploy_network && var.deploy_synapse_client ? module.synapse_client[0].vm_public_ip_address : null
}

output azure_linux_vm_public_ip_address {
  value        = var.deploy_network ? module.aws_azure_vpn[0].azure_linux_vm_public_ip_address : null
}

output azure_linux_vm_private_ip_address {
  value        = var.deploy_network ? module.aws_azure_vpn[0].azure_linux_vm_private_ip_address : null
}

output azure_resource_group_id {
  value        = azurerm_resource_group.vpn.id
}

output azure_resource_group_name {
  value        = azurerm_resource_group.vpn.name
}

output azure_sql_dwh_fqdn {
  value        = var.deploy_synapse ? module.synapse[0].sql_dwh_fqdn : null
}

output azure_sql_dwh_pool_name {
  value        = var.deploy_synapse ? module.synapse[0].sql_dwh_pool_name : null
}

output azure_sql_dwh_private_ip_address {
  value        = var.deploy_synapse ? module.synapse[0].sql_dwh_private_ip_address : null
}

output user_name {
  sensitive    = false
  value        = var.user_name                   
}

output user_password {
  sensitive    = true
  value        = local.password                   
}