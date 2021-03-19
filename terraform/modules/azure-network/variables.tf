variable address_space {}

variable create_peering {
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