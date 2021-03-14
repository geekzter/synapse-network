variable appinsights_instrumentation_key {}

variable configure_egress {
  type = bool
}
variable egress_subnet_id {}

variable location {}

variable log_analytics_workspace_resource_id {}

variable resource_group_name {
  type         = string
}

variable sql_dwh_fqdn {
  type         = string
}
variable sql_dwh_pool {
  type         = string
}

variable suffix {
  type         = string
}

variable user_name {
  type         = string
}
variable user_password {
  type         = string
}
