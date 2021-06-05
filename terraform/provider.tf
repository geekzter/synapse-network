terraform {
  required_providers {
    aws                        = "~> 3.34"
    azurerm                    = "~> 2.53, != 2.62"
    http                       = "~> 2.1"
    local                      = "~> 2.1"
    null                       = "~> 3.1"
    random                     = "~> 3.1"
  }
  required_version             = ">= 0.14.7"
}

provider "aws" {
  region                       = var.aws_region
}

# Microsoft Azure Resource Manager Provider
provider "azurerm" {
    features {
        virtual_machine {
            # Don't do this in production
            delete_os_disk_on_deletion = true
        }
    }
}
