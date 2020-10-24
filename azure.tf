resource azurerm_resource_group vpn {
  name                         = "aws-vpn-${terraform.workspace}-${local.suffix}"
  location                     = var.azure_region

  tags                         = local.tags
}

resource azurerm_virtual_network vnet {
  name                         = "${azurerm_resource_group.vpn.name}-network"
  location                     = azurerm_resource_group.vpn.location
  resource_group_name          = azurerm_resource_group.vpn.name
  address_space                = ["10.0.0.0/16"]

  tags                         = azurerm_resource_group.vpn.tags
}

resource azurerm_subnet subnet_1 {
  name                         = "subnet_1"
  resource_group_name          = azurerm_resource_group.vpn.name
  virtual_network_name         = azurerm_virtual_network.vnet.name
  address_prefixes             = ["10.0.1.0/24"]
}

# The subnet where the VPN tunnel will live
resource azurerm_subnet subnet_gateway {
  name                         = "GatewaySubnet"
  resource_group_name          = azurerm_resource_group.vpn.name
  virtual_network_name         = azurerm_virtual_network.vnet.name
  address_prefixes             = ["10.0.2.0/24"]
}

resource azurerm_public_ip public_ip_1 {
  name                         = "${azurerm_resource_group.vpn.name}-pip1"
  location                     = azurerm_resource_group.vpn.location
  resource_group_name          = azurerm_resource_group.vpn.name

  allocation_method            = "Dynamic"

  tags                         = azurerm_resource_group.vpn.tags
}

resource azurerm_public_ip public_ip_2 {
  name                         = "${azurerm_resource_group.vpn.name}-pip2"
  location                     = azurerm_resource_group.vpn.location
  resource_group_name          = azurerm_resource_group.vpn.name

  allocation_method            = "Dynamic"

  tags                         = azurerm_resource_group.vpn.tags
}

resource azurerm_virtual_network_gateway virtual_network_gateway {
  name                         = "${azurerm_resource_group.vpn.name}-gateway"
  location                     = azurerm_resource_group.vpn.location
  resource_group_name          = azurerm_resource_group.vpn.name

  type                         = "Vpn"
  vpn_type                     = "RouteBased"

  active_active                = true
  sku                          = "VpnGw1"

  # Configuring the two previously created public IP Addresses
  ip_configuration {
    name                       = azurerm_public_ip.public_ip_1.name
    public_ip_address_id       = azurerm_public_ip.public_ip_1.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                  = azurerm_subnet.subnet_gateway.id
  }

  ip_configuration {
    name                       = azurerm_public_ip.public_ip_2.name
    public_ip_address_id       = azurerm_public_ip.public_ip_2.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                  = azurerm_subnet.subnet_gateway.id
  }

  tags                         = azurerm_resource_group.vpn.tags
}

data azurerm_public_ip azure_public_ip_1 {
  name                         = azurerm_public_ip.public_ip_1.name
  resource_group_name          = azurerm_resource_group.vpn.name

  depends_on                   = [azurerm_virtual_network_gateway.virtual_network_gateway]
}

data azurerm_public_ip azure_public_ip_2 {
  name                         = azurerm_public_ip.public_ip_2.name
  resource_group_name          = azurerm_resource_group.vpn.name

  depends_on                   = [azurerm_virtual_network_gateway.virtual_network_gateway]
}

resource azurerm_local_network_gateway local_network_gateway_1_tunnel1 {
  name                         = "${azurerm_resource_group.vpn.name}-gateway1-tunnel1"
  location                     = azurerm_resource_group.vpn.location
  resource_group_name          = azurerm_resource_group.vpn.name

  gateway_address              = aws_vpn_connection.vpn_connection_1.tunnel1_address

  address_space                = [
    aws_vpc.vpc.cidr_block
  ]

  tags                         = azurerm_resource_group.vpn.tags
}

resource azurerm_virtual_network_gateway_connection virtual_network_gateway_connection_1_tunnel1 {
  name                         = "${azurerm_resource_group.vpn.name}-connection1-tunnel1"
  location                     = azurerm_resource_group.vpn.location
  resource_group_name          = azurerm_resource_group.vpn.name

  type                         = "IPsec"
  virtual_network_gateway_id   = azurerm_virtual_network_gateway.virtual_network_gateway.id
  local_network_gateway_id     = azurerm_local_network_gateway.local_network_gateway_1_tunnel1.id

  shared_key                   = aws_vpn_connection.vpn_connection_1.tunnel1_preshared_key

  tags                         = azurerm_resource_group.vpn.tags
}

resource azurerm_local_network_gateway local_network_gateway_1_tunnel2 {
  name                         = "${azurerm_resource_group.vpn.name}-gateway1-tunnel2"
  location                     = azurerm_resource_group.vpn.location
  resource_group_name          = azurerm_resource_group.vpn.name

  gateway_address              = aws_vpn_connection.vpn_connection_1.tunnel2_address

  address_space                = [
    aws_vpc.vpc.cidr_block
  ]

  tags                         = azurerm_resource_group.vpn.tags
}

resource azurerm_virtual_network_gateway_connection virtual_network_gateway_connection_1_tunnel2 {
  name                         = "${azurerm_resource_group.vpn.name}-connection1-tunnel2"
  location                     = azurerm_resource_group.vpn.location
  resource_group_name          = azurerm_resource_group.vpn.name

  type                         = "IPsec"
  virtual_network_gateway_id   = azurerm_virtual_network_gateway.virtual_network_gateway.id
  local_network_gateway_id     = azurerm_local_network_gateway.local_network_gateway_1_tunnel2.id

  shared_key = aws_vpn_connection.vpn_connection_1.tunnel2_preshared_key

  tags                         = azurerm_resource_group.vpn.tags
}

resource azurerm_local_network_gateway local_network_gateway_2_tunnel1 {
  name                         = "${azurerm_resource_group.vpn.name}-gateway2-tunnel1"
  location                     = azurerm_resource_group.vpn.location
  resource_group_name          = azurerm_resource_group.vpn.name

  gateway_address              = aws_vpn_connection.vpn_connection_2.tunnel1_address

  address_space                = [
    aws_vpc.vpc.cidr_block
  ]

  tags                         = azurerm_resource_group.vpn.tags
}

resource azurerm_virtual_network_gateway_connection virtual_network_gateway_connection_2_tunnel1 {
  name                         = "${azurerm_resource_group.vpn.name}-connection2-tunnel1"
  location                     = azurerm_resource_group.vpn.location
  resource_group_name          = azurerm_resource_group.vpn.name

  type                         = "IPsec"
  virtual_network_gateway_id   = azurerm_virtual_network_gateway.virtual_network_gateway.id
  local_network_gateway_id     = azurerm_local_network_gateway.local_network_gateway_2_tunnel1.id

  shared_key                   = aws_vpn_connection.vpn_connection_2.tunnel1_preshared_key

  tags                         = azurerm_resource_group.vpn.tags
}

resource azurerm_local_network_gateway local_network_gateway_2_tunnel2 {
  name                         = "${azurerm_resource_group.vpn.name}-gateway2-tunnel2"
  location                     = azurerm_resource_group.vpn.location
  resource_group_name          = azurerm_resource_group.vpn.name

  gateway_address              = aws_vpn_connection.vpn_connection_2.tunnel2_address

  address_space                = [
    aws_vpc.vpc.cidr_block
  ]

  tags                         = azurerm_resource_group.vpn.tags
}

resource azurerm_virtual_network_gateway_connection virtual_network_gateway_connection_2_tunnel2 {
  name                         = "${azurerm_resource_group.vpn.name}-connection2-tunnel2"
  location                     = azurerm_resource_group.vpn.location
  resource_group_name          = azurerm_resource_group.vpn.name

  type                         = "IPsec"
  virtual_network_gateway_id   = azurerm_virtual_network_gateway.virtual_network_gateway.id
  local_network_gateway_id     = azurerm_local_network_gateway.local_network_gateway_2_tunnel2.id

  shared_key                   = aws_vpn_connection.vpn_connection_2.tunnel2_preshared_key

  tags                         = azurerm_resource_group.vpn.tags
}

resource azurerm_public_ip public_ip_vm {
  name                         = "${azurerm_resource_group.vpn.name}-linux-vm-pip"
  location                     = azurerm_resource_group.vpn.location
  resource_group_name          = azurerm_resource_group.vpn.name

  allocation_method            = "Static"

  tags                         = azurerm_resource_group.vpn.tags
}

resource "azurerm_network_interface" "network_interface_vm" {
  name                         = "${azurerm_resource_group.vpn.name}-linux-vm-nic"
  location                     = azurerm_resource_group.vpn.location
  resource_group_name          = azurerm_resource_group.vpn.name

  ip_configuration {
    name                       = "internal"
    subnet_id                  = azurerm_subnet.subnet_1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id       = azurerm_public_ip.public_ip_vm.id
  }

  tags                         = azurerm_resource_group.vpn.tags
}

resource azurerm_linux_virtual_machine vm {
  name                         = "${azurerm_resource_group.vpn.name}-linux-vm"
  computer_name                = "azurelinuxvm"
  location                     = azurerm_resource_group.vpn.location
  resource_group_name          = azurerm_resource_group.vpn.name
  size                         = "Standard_F2"
  admin_username               = var.user_name
  admin_password               = local.password
  disable_password_authentication = false

  network_interface_ids        = [
    azurerm_network_interface.network_interface_vm.id,
  ]

  os_disk {
    caching                    = "ReadWrite"
    storage_account_type       = "Standard_LRS"
  }

  admin_ssh_key {
    username                   = var.user_name
    public_key                 = file(var.ssh_public_key)
  }

  source_image_reference {
    publisher                  = "Canonical"
    offer                      = "UbuntuServer"
    sku                        = "18.04-LTS"
    version                    = "latest"
  }

  tags                         = azurerm_resource_group.vpn.tags
}

