# aws-azure-vpn
AWS-Azure Site-to-Site VPN

This repo implements the AWS - Azure S2S VPN described in this [excellent blog post](https://deployeveryday.com/2020/04/13/vpn-aws-azure-terraform.html).


## Pre-requisites
To get started you need [Git](https://git-scm.com/), [Terraform](https://www.terraform.io/downloads.html) (to get that I use [tfenv](https://github.com/tfutils/tfenv) on Linux & macOS, [Homebrew](https://github.com/hashicorp/homebrew-tap) on macOS or [chocolatey](https://chocolatey.org/packages/terraform) on Windows).

### AWS
You need an AWS account. There are (multiple ways)[https://registry.terraform.io/providers/hashicorp/aws/latest/docs] to configure the AWS Terraform provider, I tested with statis credentials:
```
AWS_ACCESS_KEY_ID="AAAAAAAAAAAAAAAAAAAA"
AWS_DEFAULT_REGION="eu-west-1"
AWS_SECRET_ACCESS_KEY="xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
```


### Azure pre-requisites
You need a Azure subscription. The identity uses needs to have subscription owner role to create resource groups.   
Authenticate using (Azure CLI)[https://www.terraform.io/docs/providers/azurerm/guides/azure_cli.html] 
```
az login
```

or define [Service Principal secrets](https://www.terraform.io/docs/providers/azurerm/guides/service_principal_client_secret.html)
```
ARM_CLIENT_ID="00000000-0000-0000-0000-000000000000"
ARM_CLIENT_SECRET="00000000-0000-0000-0000-000000000000"
```

Make sure you work with the right subscription:

```
ARM_SUBSCRIPTION_ID="00000000-0000-0000-0000-000000000000"        

```

You can then provision resources by first initializing Terraform:   
```
terraform init
```  

And then running:  
```
terraform apply
```

When you want to destroy resources, run:   
```
terraform destroy
```