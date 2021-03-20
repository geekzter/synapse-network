variable address_space {}

variable create_peering {
  type         = bool
  default      = false
}

variable create_sql_server_endpoint {
  type         = bool
  default      = false
}

variable location {}

variable peer_virtual_network_id {
  default      = null
}

variable private_dns_zone_id {}

variable resource_group_name {
  type         = string
}

variable sql_server_id {
  default      = null
}