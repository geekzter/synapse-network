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
    [parameter(Mandatory=$false)][switch]$OpenFirewall
) 

function Open-SqlFirewall (
    [parameter(Mandatory=$true)][string]$ResourceGroup,
    [parameter(Mandatory=$true)][string]$SqlServer
) {
    $ipAddress=$(Invoke-RestMethod -Uri https://ipinfo.io/ip -MaximumRetryCount 9).Trim()
    Write-Information "Public IP address is $ipAddress"

    $existingRule = $(az sql server firewall-rule list -g $ResourceGroup -s $SqlServer --query "[?startIpAddress=='$ipAddress'].name" -o tsv)
    if ($existingRule) {
        Write-Information "SQL Server Firewall rule '${existingRule}' already exists"
    } else {
        Write-Host "Adding rule for SQL Server ${SqlServer} to allow address $ipAddress... "
        az sql server firewall-rule create -g $ResourceGroup -s $SqlServer -n "Cloud Shell $ipAddress" --start-ip-address $ipAddress --end-ip-address $ipAddress --query "[].name" -o tsv
    }
}

function Execute-SqlCmd (
    [parameter(Mandatory=$false)][string]$QueryFile,
    [parameter(Mandatory=$false)][string]$OutputFile,
    [parameter(Mandatory=$true)][string]$SqlServerFQDN,
    [parameter(Mandatory=$true)][string]$SqlDatabaseName,
    [parameter(Mandatory=$true)][string]$UserName,
    [parameter(Mandatory=$true)][SecureString]$SecurePassword,
    [parameter(Mandatory=$false)][int]$RowCount
) {
    $outputFile = (New-TemporaryFile)

    if ($RowCount -gt 10000000) {
        Write-Warning "You're requesting ${RowCount} rows, this may take a while"
    }

    $sqlPassword = ConvertFrom-SecureString -SecureString $SecurePassword -AsPlainText

    # Substitute with [int] parameters only
    $query = "select top ${RowCount} * from dbo.Trip"

    Write-Host "Retrieving ${RowCount} rows from ${SqlServerFQDN}/${SqlDatabaseName}..."
    $stopwatch = [system.diagnostics.stopwatch]::StartNew()
    Invoke-Sqlcmd -ServerInstance $SqlServerFQDN -Database $SqlDatabaseName -Query $query -Username $UserName -Password $sqlPassword -OutputSqlErrors $True | Format-Table | Out-File $OutputFile -Force
    $stopwatch.Stop()
    $stopWatch | Out-File $OutputFile -Append
    $errors = (Get-Content $OutputFile | Select-String "Error:")
    if ($errors) {
        Write-Error $errors
    } else {
        Write-Host "Retrieved ${RowCount} rows in $($stopwatch.Elapsed.ToString())"
        Write-Host "Query output and statistics written to ${outputFile}"
    }
}

. (Join-Path $PSScriptRoot functions.ps1)

if (!(Get-Command Invoke-Sqlcmd -ErrorAction SilentlyContinue)) {
    Write-Warning "Invoke-Sqlcmd not found. Run 'Install-Module -Name SqlServer' to get it. Exiting..."
    exit
}

try {
    $tfdirectory=$(Join-Path (Split-Path -Parent -Path $PSScriptRoot) "terraform")
    Push-Location $tfdirectory
    
    if (!$ResourceGroup) {
        $ResourceGroup = (GetTerraformOutput "resource_group_name")  
    }
    if (!$SqlDatabaseName) {
        $SqlDatabaseName = (GetTerraformOutput "sql_dwh_pool_name")  
    }
    if (!$SqlServerFQDN) {
        $SqlServerFQDN = (GetTerraformOutput "sql_dwh_fqdn")  
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

Execute-SqlCmd -QueryFile $QueryFile -SqlDatabaseName $SqlDatabaseName -SqlServerFQDN $SqlServerFQDN -UserName $SqlUser -SecurePassword $SecurePassword -RowCount $RowCount
