
#!/usr/bin/env pwsh
<# 
.SYNOPSIS 
    Grants access to given AAD user/service principal name
#> 
#Requires -Version 7

. (Join-Path $PSScriptRoot functions.ps1)

function ImportDatabase (
    [parameter(Mandatory=$true)][string]$SqlDatabaseName,
    [parameter(Mandatory=$false)][string]$SqlServer=$SqlServerFQDN.Split(".")[0],
    [parameter(Mandatory=$true)][string]$SqlServerFQDN,
    [parameter(Mandatory=$true)][string]$ResourceGroup,
    [parameter(Mandatory=$true)][string]$UserName,
    [parameter(Mandatory=$true)][SecureString]$Password
) {
    if ([string]::IsNullOrEmpty($SqlServerFQDN)) {
        Write-Error "No SQL Server specified" -ForeGroundColor Red
        return 
    }
    $sqlQueryFile = (Join-Path $PSScriptRoot "check-database-contents.sql")
    $sqlLoadFile = (Join-Path $PSScriptRoot "load-data.sql")
 
    # https://aka.ms/azuresqlconnectivitysettings
    # Enable Public Network Access
    $sqlPublicNetworkAccess = $(az sql server show -n $SqlServer -g $ResourceGroup --query "publicNetworkAccess" -o tsv)
    Write-Information "Enabling Public Network Access for ${SqlServer} ..."
    Write-Verbose "az sql server update -n $SqlServer -g $ResourceGroup --set publicNetworkAccess=`"Enabled`" --query `"publicNetworkAccess`""
    az sql server update -n $SqlServer -g $ResourceGroup --set publicNetworkAccess="Enabled" --query "publicNetworkAccess" -o tsv

    # Create SQL Firewall rule for query
    $ipAddress=$(Invoke-RestMethod -Uri https://ipinfo.io/ip -MaximumRetryCount 9).Trim()
    az sql server firewall-rule create -g $ResourceGroup -s $SqlServer -n "ImportQuery $ipAddress" --start-ip-address $ipAddress --end-ip-address $ipAddress -o none

    # Check whether we need to import
    # $schemaExists = Execute-Sql -QueryFile $sqlQueryFile -SqlDatabaseName $SqlDatabaseName -SqlServerFQDN $SqlServerFQDN -UserName $UserName -SecurePassword $Password

    # if ($schemaExists -eq 0) {
        Write-Host "Database ${SqlServer}/${SqlDatabaseName}: loading data..."
        Execute-Sql -QueryFile $sqlLoadFile -SqlDatabaseName $SqlDatabaseName -SqlServerFQDN $SqlServerFQDN -UserName $UserName -SecurePassword $Password
    #   } else {
    #     Write-Host "Database ${SqlServer}/${SqlDatabaseName} is not empty, skipping data load"
    # }

    # Reset Public Network Access to what it was before
    az sql server update -n $SqlServer -g $ResourceGroup --set publicNetworkAccess="$sqlPublicNetworkAccess" -o none

    if ($sqlPublicNetworkAccess -ieq "Disabled") {
        # Clean up all FW rules
        $sqlFWIds = $(az sql server firewall-rule list -g $ResourceGroup -s $SqlServer --query "[].id" -o tsv)
    } else {
        # Clean up just the all Azure rule
        $sqlFWIds = $(az sql server firewall-rule list -g $ResourceGroup -s $SqlServer --query "[?startIpAddress=='0.0.0.0'].id" -o tsv)
    }
    if ($sqlFWIds) {
        Write-Verbose "Removing SQL Server ${SqlServer} Firewall rules $sqlFWIds ..."
        az sql server firewall-rule delete --ids $sqlFWIds -o none
    }
}


# Gather data from Terraform
try {
    $tfdirectory=$(Join-Path (Split-Path -Parent -Path $PSScriptRoot) "terraform")
    Push-Location $tfdirectory
    
    Invoke-Command -ScriptBlock {
        $Private:ErrorActionPreference = "Continue"

        # Set only if null
        $script:ResourceGroup          ??= (GetTerraformOutput "resource_group_name")
        $script:SqlDatabaseName        ??= (GetTerraformOutput "sql_dwh_pool_name")
        $script:SqlServerFQDN          ??= (GetTerraformOutput "sql_dwh_fqdn")
        $script:SqlPassword            ??= (GetTerraformOutput "user_password")
        $script:SqlUser                ??= (GetTerraformOutput "user_name")
    }

    if ([string]::IsNullOrEmpty($SqlDatabaseName)) {
        Write-Warning "Synapse SQL Pool has not been created, nothing to do deploy to"
        exit 
    }
} finally {
    Pop-Location
}

$securePassword = ConvertTo-SecureString $SqlPassword -AsPlainText -Force
$securePassword.MakeReadOnly()

ImportDatabase -SqlDatabaseName $SqlDatabaseName -SqlServerFQDN $SqlServerFQDN -ResourceGroup $ResourceGroup -UserName $SqlUser -Password $securePassword 