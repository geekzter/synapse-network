#!/usr/bin/env pwsh
<# 
.SYNOPSIS 
    Grants access to given AAD user/service principal name
#> 
#Requires -Version 7
param ( 
    [parameter(Mandatory=$false)][string]$ResourceGroup,
    [parameter(Mandatory=$false)][string]$SqlServerFQDN=$null,
    [parameter(Mandatory=$false)][string]$SqlDatabaseName=$null,
    [parameter(Mandatory=$false)][string]$SqlUser=$null,
    [parameter(Mandatory=$false)][SecureString]$SecurePassword=$null,
    [parameter(Mandatory=$false)][int]$RowCount=100,
    [parameter(Mandatory=$false)][string]$OutputFile=(New-TemporaryFile),
    [parameter(Mandatory=$false)][switch]$OpenFirewall
) 

function Open-SqlFirewall (
    [parameter(Mandatory=$true)][string]$ResourceGroup,
    [parameter(Mandatory=$true)][string]$SqlServer
) {
    $ipAddress=$(Invoke-RestMethod -Uri https://ipinfo.io/ip -MaximumRetryCount 9).Trim()
    Write-Information "Public IP address is $ipAddress"

    $existingRule = $(az sql server firewall-rule list -g aws-vpn-default-ajdi -s aws-vpn-default-ajdi-sqldwserver --query "[?startIpAddress=='$ipAddress'].name" -o tsv)
    if ($existingRule) {
        Write-Information "SQL Server Firewall rule '${existingRule}' already exists"
    } else {
        Write-Host "Adding rule for SQL Server $appSQLServer to allow address $ipAddress... "
        az sql server firewall-rule create -g $ResourceGroup -s $SqlServer -n "Cloud Shell $ipAddress" --start-ip-address $ipAddress --end-ip-address $ipAddress --query "[].name" -o tsv
    }
}


function Execute-SqlCmd (
    [parameter(Mandatory=$false)][string]$QueryFile,
    [parameter(Mandatory=$false)][string]$OutputFile,
    [parameter(Mandatory=$true)][string]$SqlServerFQDN,
    [parameter(Mandatory=$true)][string]$SqlDatabaseName,
    [parameter(Mandatory=$true)][string]$UserName,
    [parameter(Mandatory=$true)][SecureString]$SecurePassword
) {
    $sqlPassword = ConvertFrom-SecureString -SecureString $SecurePassword -AsPlainText
    $sqlRunCommand = "sqlcmd -S $SqlServerFQDN -d $SqlDatabaseName -I -U $UserName"

    $query = "select top ${RowCount} * from dbo.Trip"
    $sqlRunCommand += " -Q '${query}' -e -o ${OutputFile}"

    Write-Host "Retrieving ${RowCount} rows..."
    Write-Host "${sqlRunCommand} -P `<password`>" -ForegroundColor Green
    $stopwatch = [system.diagnostics.stopwatch]::StartNew()
    Invoke-Expression "${sqlRunCommand} -P ${sqlPassword}"
    $stopwatch.Stop()
    $stopWatch | Out-File $OutputFile -Append
    $errors = (Get-Content $OutputFile | Select-String "Error:")
    if ($errors) {
        Write-Error $errors
    } else {
        Write-Host "Retrieved ${RowCount} rows in $($stopwatch.Elapsed.ToString())"
        Write-Host "Query output and statistics written to ${OutputFile}"
    }
}

. (Join-Path $PSScriptRoot functions.ps1)

if (!(Get-Command sqlcmd -ErrorAction SilentlyContinue)) {
    Write-Warning "sqlcmd not found, exiting..."
    exit
}

try {
    $tfdirectory=$(Join-Path (Split-Path -Parent -Path $PSScriptRoot) "terraform")
    Push-Location $tfdirectory
    
    if (!$ResourceGroup) {
        $ResourceGroup = (GetTerraformOutput "azure_resource_group_name")  
    }
    if (!$SqlDatabaseName) {
        $SqlDatabaseName = (GetTerraformOutput "azure_sql_dwh_pool_name")  
    }
    if (!$SqlServerFQDN) {
        $SqlServerFQDN = (GetTerraformOutput "azure_sql_dwh_fqdn")  
    }
    if (!$SqlUser) {
        $SqlUser = (GetTerraformOutput "user_name")  
    }
    if (!$SecurePassword) {
        $SqlPassword = (GetTerraformOutput "user_password")
        $SecurePassword = ConvertTo-SecureString -String $SqlPassword -AsPlainText -Force
    }

    if ([string]::IsNullOrEmpty($SqlDatabaseName)) {
        Write-Warning "Synapse SQL Pool has not been created, nothing to do deploy to" 
        exit 
    }
} finally {
    Pop-Location
}
if ($OpenFirewall) {
    Open-SqlFirewall -ResourceGroup $ResourceGroup -SqlServer $SqlServerFQDN.split(".")[0]
}

Execute-SqlCmd -QueryFile $QueryFile -OutputFile $OutputFile -SqlDatabaseName $SqlDatabaseName -SqlServerFQDN $SqlServerFQDN -UserName $SqlUser -SecurePassword $SecurePassword
