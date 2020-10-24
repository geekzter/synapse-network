variable aws_region {
  type         = string
  default      = "eu-west-1" # Dublin
}

variable azure_region {
  type         = string
  default      = "westeurope" # Amsterdam
}

variable ssh_public_key {
  type         = string
  default      = "~/.ssh/id_rsa.pub"
}

variable user_name {
  type         = string
  default      = "vpnadmin"
}

