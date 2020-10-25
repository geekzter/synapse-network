variable aws_key_name {
  type         = string
}

variable azure_region {
  type         = string
  default      = "westeurope" # Amsterdam
}

variable azure_resource_group_name {
  type         = string
}

variable ssh_public_key {
  type         = string
  default      = "~/.ssh/id_rsa.pub"
}

variable suffix {
  type         = string
  default      = "dflt"
}

variable user_name {
  type         = string
  default      = "vpnadmin"
}

variable user_password {
  type         = string
}
