output aws_linux_vm_public_ip {
  value        = aws_instance.vm.public_ip
}

output aws_linux_vm_private_ip {
  value        = aws_instance.vm.private_ip
}

output azure_linux_vm_public_ip {
  value        = azurerm_linux_virtual_machine.vm.public_ip_address
}

output azure_linux_vm_private_ip {
  value        = azurerm_linux_virtual_machine.vm.private_ip_address
}

output user_password {
  sensitive    = true
  value        = local.password                   
}