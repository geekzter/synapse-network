variable admin_object_id {}

variable create_network_resources {
  type         = bool
  default      = false
}

variable dwu {
  type         = string
  default      = "DW100c"
}

variable client_ip_prefixes {
  type         = list
  default      = []
}

variable log_analytics_workspace_resource_id {}

variable region {
  type         = string
}

variable subnet_id {
  type         = string
  default      = null
}

variable resource_group_name {
  type         = string
}

variable user_name {
  type         = string
  default      = "sqladmin"
}

variable user_password {
  type         = string
}