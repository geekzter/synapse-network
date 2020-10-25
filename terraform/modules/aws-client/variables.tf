variable aws_key_name {
  type         = string
}

variable sql_dwh_private_ip_address {
  type         = string
}

variable sql_dwh_fqdn {
  type         = string
}

variable subnet_id {
  type         = string
  default      = null
}

variable suffix {
  type         = string
  default      = "dflt"
}

variable user_name {
  type         = string
  default      = "sqladmin"
}

variable vpc_id {}
