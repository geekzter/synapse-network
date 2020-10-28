terraform {
  required_providers {
    aws                        = "~> 3.12"
    azurerm                    = "~> 2.33"
    null                       = "~> 3.0.0"
    random                     = "~> 3.0.0"
  }
  required_version             = "~> 0.13.5"
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
