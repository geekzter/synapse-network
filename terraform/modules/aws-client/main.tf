data aws_vpc vpc {
  id                           = var.vpc_id
}

data aws_ami windows_2019 {
  most_recent                  = true
  filter {
    name                       = "name"
    values                     = ["Windows_Server-2019-English-Full-Base-*"]
  }
  owners                       = ["amazon"]
}

resource aws_security_group client {
  vpc_id                       = data.aws_vpc.vpc.id

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

  tags                         = data.aws_vpc.vpc.tags
}

locals {
  user_data                    = templatefile("${path.module}/userdata.tpl",
    {
      sql_dwh_private_ip_address= var.sql_dwh_private_ip_address
      sql_dwh_fqdn             = var.sql_dwh_fqdn
    })
}

resource aws_instance windows_vm {
  ami                          = data.aws_ami.windows_2019.id
  instance_type                = "t3.large"

  vpc_security_group_ids       = [aws_security_group.client.id]
  subnet_id                    = var.subnet_id
  associate_public_ip_address  = true

  get_password_data            = true
  key_name                     = var.aws_key_name
  user_data_base64             = base64encode(local.user_data)

  root_block_device {
    volume_size                = 100
  }

  tags                         = data.aws_vpc.vpc.tags
}