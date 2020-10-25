output vm_encrypted_password {
  value        = aws_instance.windows_vm.password_data
}

output vm_public_ip_address {
  value        = aws_instance.windows_vm.public_ip
}

output vm_user_data {
  value        = local.user_data
}