
resource null_resource aws_to_azure_ping {
  triggers                     = {
    always                     = timestamp()
  }

  provisioner remote-exec {
    inline                     = [
      "ping ${azurerm_linux_virtual_machine.vm.private_ip_address} -c 4"
    ]

    connection {
      type                     = "ssh"
      user                     = "ubuntu"
      private_key              = file(var.ssh_private_key)
      host                     = aws_instance.vm.public_ip
    }
  }

  depends_on                   = [
    aws_vpn_connection_route.vpn_connection_route_1,
    aws_vpn_connection_route.vpn_connection_route_2,
    aws_route.route_to_azure,
    azurerm_virtual_network_gateway_connection.aws_connection_1_tunnel1,
    azurerm_virtual_network_gateway_connection.aws_connection_1_tunnel2,
    azurerm_virtual_network_gateway_connection.aws_connection_2_tunnel1,
    azurerm_virtual_network_gateway_connection.aws_connection_2_tunnel2,
  ]

  count                        = fileexists(var.ssh_private_key) ? 1 : 0
}

resource null_resource azure_to_aws_ping {
  triggers                     = {
    always                     = timestamp()
  }

  provisioner remote-exec {
    inline                     = [
      "ping ${aws_instance.vm.private_ip} -c 4"
    ]

    connection {
      type                     = "ssh"
      user                     = var.user_name
      password                 = var.user_password
      host                     = azurerm_linux_virtual_machine.vm.public_ip_address
    }
  }

  depends_on                   = [
    aws_vpn_connection_route.vpn_connection_route_1,
    aws_vpn_connection_route.vpn_connection_route_2,
    aws_route.route_to_azure,
    azurerm_virtual_network_gateway_connection.aws_connection_1_tunnel1,
    azurerm_virtual_network_gateway_connection.aws_connection_1_tunnel2,
    azurerm_virtual_network_gateway_connection.aws_connection_2_tunnel1,
    azurerm_virtual_network_gateway_connection.aws_connection_2_tunnel2,
  ]
}