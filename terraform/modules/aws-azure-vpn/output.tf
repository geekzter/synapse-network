output aws_linux_vm_public_ip {
  value        = aws_instance.vm.public_ip
}

output aws_linux_vm_private_ip {
  value        = aws_instance.vm.private_ip
}

output aws_subnet_id {
  value        = aws_subnet.subnet_1.id
}

output aws_vpc_id {
  value        = aws_vpc.vpc.id
}

output azure_linux_vm_public_ip {
  value        = azurerm_linux_virtual_machine.vm.public_ip_address
}

output azure_linux_vm_private_ip {
  value        = azurerm_linux_virtual_machine.vm.private_ip_address
}

output azure_subnet_id {
  value        = azurerm_subnet.subnet_1.id
}
