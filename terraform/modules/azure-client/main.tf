data azurerm_resource_group rg {
  name                         = var.resource_group_name
}

data azurerm_client_config current {}

locals {
  vm_name                      = "${data.azurerm_resource_group.rg.name}-${var.location}-vm"
}

resource random_string pip_domain_name_label {
  length                      = 16
  upper                       = false
  lower                       = true
  number                      = false
  special                     = false
}
resource azurerm_public_ip pip {
  name                         = "${local.vm_name}-pip"
  location                     = var.location
  resource_group_name          = data.azurerm_resource_group.rg.name
  allocation_method            = "Static"
  sku                          = "Standard"
  domain_name_label            = random_string.pip_domain_name_label.result

  tags                         = data.azurerm_resource_group.rg.tags
}

resource azurerm_network_interface nic {
  name                         = "${local.vm_name}-nic"
  location                     = var.location
  resource_group_name          = data.azurerm_resource_group.rg.name

  ip_configuration {
    name                       = "ipconfig"
    subnet_id                  = var.subnet_id
    public_ip_address_id       = azurerm_public_ip.pip.id
    private_ip_address_allocation = "dynamic"
  }
  enable_accelerated_networking = true

  tags                         = data.azurerm_resource_group.rg.tags
}

resource azurerm_network_security_group nsg {
  name                         = "${data.azurerm_resource_group.rg.name}-${var.location}-vm-nsg"
  location                     = var.location
  resource_group_name          = data.azurerm_resource_group.rg.name
  tags                         = data.azurerm_resource_group.rg.tags
}

resource azurerm_network_security_rule rdp {
  name                         = "ClientRDP"
  priority                     = 201
  direction                    = "Inbound"
  access                       = "Allow"
  protocol                     = "Tcp"
  source_port_range            = "*"
  destination_port_range       = "3389"
  source_address_prefix        = "*"
  destination_address_prefix   = "*"
  resource_group_name          = azurerm_network_security_group.nsg.resource_group_name
  network_security_group_name  = azurerm_network_security_group.nsg.name
}

resource azurerm_network_interface_security_group_association nic_nsg {
  network_interface_id         = azurerm_network_interface.nic.id
  network_security_group_id    = azurerm_network_security_group.nsg.id
}

data azurerm_storage_container scripts {
  name                         = split("/",var.scripts_storage_container_id)[3]
  storage_account_name         = split(".",split("/",var.scripts_storage_container_id)[2])[0]
}

resource azurerm_storage_blob setup_windows_vm_ps1 {
  name                         = "setup_windows_vm_${var.location}.ps1"
  storage_account_name         = data.azurerm_storage_container.scripts.storage_account_name
  storage_container_name       = data.azurerm_storage_container.scripts.name

  type                         = "Block"
  source_content               = templatefile("${path.module}/setup_windows_vm.ps1", { 
    sql_dwh_fqdn               = var.sql_dwh_fqdn
    sql_dwh_pool               = var.sql_dwh_pool
    user_name                  = var.user_name
  })
}

resource azurerm_windows_virtual_machine vm {
  name                         = local.vm_name
  computer_name                = lower(substr(replace("synapseclient${var.location}","/a|e|i|o|u|y|-/",""),0,15))
  # computer_name                = "azsynapseclient"
  location                     = var.location
  resource_group_name          = data.azurerm_resource_group.rg.name
  network_interface_ids        = [azurerm_network_interface.nic.id]
  size                         = "Standard_D2s_v4"
  admin_username               = var.user_name
  admin_password               = var.user_password
  enable_automatic_updates     = true

  os_disk {
    caching                    = "ReadWrite"
    storage_account_type       = "Premium_LRS"
  }

  source_image_reference {
    publisher                  = "MicrosoftWindowsServer"
    offer                      = "WindowsServer"
    sku                        = "2019-Datacenter"
    version                    = "latest"
  }

  additional_unattend_content {
    setting                    = "AutoLogon"
    content                    = templatefile("${path.module}/AutoLogon.xml", { 
      count                    = 99, 
      username                 = var.user_name, 
      password                 = var.user_password, 
    })
  }
  additional_unattend_content {
    setting                    = "FirstLogonCommands"
    content                    = templatefile("${path.module}/FirstLogonCommands.xml", { 
      scripturl                = azurerm_storage_blob.setup_windows_vm_ps1.url
    })
  }

  identity {
    type                       = "UserAssigned"
    identity_ids               = [var.user_assigned_identity_id]
  }

  tags                         = data.azurerm_resource_group.rg.tags
}

resource azurerm_virtual_machine_extension bginfo {
  name                         = "BGInfo"
  virtual_machine_id           = azurerm_windows_virtual_machine.vm.id
  publisher                    = "Microsoft.Compute"
  type                         = "BGInfo"
  type_handler_version         = "2.1"
  auto_upgrade_minor_version   = true

  tags                         = data.azurerm_resource_group.rg.tags
}

resource local_file rdp_file {
  content                      = templatefile("${path.module}/rdp.tpl",
  {
    host                       = azurerm_public_ip.pip.ip_address
    username                   = var.user_name
  })
  filename                     = "${path.root}/../data/${terraform.workspace}/azure-client-${var.location}.rdp"
}