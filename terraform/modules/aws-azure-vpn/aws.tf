resource aws_vpc vpc {
  cidr_block                   = "192.168.0.0/16"

  tags                         = data.azurerm_resource_group.vpn.tags
}

# The subnet where the Virtual Machine will live
resource aws_subnet subnet_1 {
  vpc_id                       = aws_vpc.vpc.id
  cidr_block                   = "192.168.1.0/24"

  tags                         = aws_vpc.vpc.tags
}

resource aws_internet_gateway internet_gateway {
  vpc_id                       = aws_vpc.vpc.id

  tags                         = aws_vpc.vpc.tags
}

resource aws_route_table route_table {
  vpc_id                       = aws_vpc.vpc.id

  tags                         = aws_vpc.vpc.tags
}

resource aws_route subnet_1_exit_route {
  route_table_id               = aws_route_table.route_table.id
  destination_cidr_block       = "0.0.0.0/0"
  gateway_id                   = aws_internet_gateway.internet_gateway.id
}

resource aws_route_table_association route_table_association {
  subnet_id                    = aws_subnet.subnet_1.id
  route_table_id               = aws_route_table.route_table.id
}

resource aws_customer_gateway customer_gateway_1 {
  bgp_asn                      = 65000

  ip_address                   = data.azurerm_public_ip.azure_public_ip_1.ip_address
  type                         = "ipsec.1"

  tags                         = aws_vpc.vpc.tags
}

resource aws_customer_gateway customer_gateway_2 {
  bgp_asn                      = 65000

  ip_address                   = data.azurerm_public_ip.azure_public_ip_2.ip_address
  type                         = "ipsec.1"

  tags                         = aws_vpc.vpc.tags
}

resource aws_vpn_gateway vpn_gateway {
  vpc_id                       = aws_vpc.vpc.id

  tags                         = aws_vpc.vpc.tags
}

resource aws_vpn_connection vpn_connection_1 {
  vpn_gateway_id               = aws_vpn_gateway.vpn_gateway.id
  customer_gateway_id          = aws_customer_gateway.customer_gateway_1.id
  type                         = "ipsec.1"
  static_routes_only           = true

  tags                         = aws_vpc.vpc.tags
}

resource aws_vpn_connection vpn_connection_2 {
  vpn_gateway_id               = aws_vpn_gateway.vpn_gateway.id
  customer_gateway_id          = aws_customer_gateway.customer_gateway_2.id
  type                         = "ipsec.1"
  static_routes_only           = true

  tags                         = aws_vpc.vpc.tags
}

resource aws_vpn_connection_route vpn_connection_route_1 {
  destination_cidr_block       = data.azurerm_virtual_network.vnet.address_space[0]
  vpn_connection_id            = aws_vpn_connection.vpn_connection_1.id
}

resource aws_vpn_connection_route vpn_connection_route_2 {
  destination_cidr_block       = data.azurerm_virtual_network.vnet.address_space[0]
  vpn_connection_id            = aws_vpn_connection.vpn_connection_2.id
}

resource aws_route route_to_azure {
  route_table_id               = aws_route_table.route_table.id

  destination_cidr_block       = data.azurerm_virtual_network.vnet.address_space[0]
  gateway_id                   = aws_vpn_gateway.vpn_gateway.id
}

resource aws_security_group ssh {
  vpc_id                       = aws_vpc.vpc.id

  ingress {
    from_port                  = 0
    to_port                    = 0
    protocol                   = "-1"
    cidr_blocks                = ["0.0.0.0/0"]
  }

  egress {
    from_port                  = 0
    to_port                    = 0
    protocol                   = "-1"
    cidr_blocks                = ["0.0.0.0/0"]
  }

  tags                         = aws_vpc.vpc.tags
}

data aws_ami ubuntu {
  most_recent                  = true

  filter {
    name                       = "name"
    values                     = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  owners                       = ["099720109477"] # Canonical
}

resource aws_instance vm {
  ami                          = data.aws_ami.ubuntu.id # "ami-0701e7be9b2a77600"
  instance_type                = "t2.micro"

  vpc_security_group_ids       = [aws_security_group.ssh.id]
  subnet_id                    = aws_subnet.subnet_1.id
  associate_public_ip_address  = true

  # get_password_data            = true
  key_name                     = var.aws_key_name

  tags                         = aws_vpc.vpc.tags
}
