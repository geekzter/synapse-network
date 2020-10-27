variable aws_region {
  type         = string
  default      = "eu-west-1" # Dublin
}

variable azure_region {
  type         = string
  default      = "westeurope" # Amsterdam
}

variable azure_sql_dwh_dwu {
  type         = string
  default      = "DW100c"
}

variable deploy_network {
  type         = bool
  default      = true
}

variable deploy_synapse_client {
  type         = bool
  default      = true
}

variable deploy_synapse {
  type         = bool
  default      = true
}

# Used to decrypt EC2 passwords
variable ssh_private_key {
  type         = string
  default      = "~/.ssh/id_rsa"
}

variable ssh_public_key {
  type         = string
  default      = "~/.ssh/id_rsa.pub"
}

variable user_name {
  type         = string
  default      = "vpnadmin"
}