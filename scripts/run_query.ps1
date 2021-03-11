#!/usr/bin/env pwsh
<# 
.SYNOPSIS 
    Grants access to given AAD user/service principal name
#> 
#Requires -Version 7
param ( 
    [parameter(Mandatory=$false)][string]$SqlServerFQDN=$null,
    [parameter(Mandatory=$false)][string]$SqlDatabaseName=$null,
    [parameter(Mandatory=$false)][string]$SqlUser=$null,
    [parameter(Mandatory=$false)][SecureString]$SecurePassword=$null,
    [parameter(Mandatory=$false)][int]$Rows=100,
    [parameter(Mandatory=$false)][string]$OutputFile=(New-TemporaryFile)
) 

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

    $query = "select top ${Rows} * from dbo.Trip"
    $sqlRunCommand += " -Q '${query}' -e -o ${OutputFile}"

    Write-Host "${sqlRunCommand} -P `<password`>" -ForegroundColor Green
    $stopwatch = [system.diagnostics.stopwatch]::StartNew()
    Invoke-Expression "${sqlRunCommand} -P ${sqlPassword}"
    $stopwatch.Stop()
    $stopWatch | Out-File $OutputFile -Append
    Write-Host "Query time: $($stopwatch.Elapsed.ToString())"
    Write-Host "Query output and statistics written to ${OutputFile}"
}

. (Join-Path $PSScriptRoot functions.ps1)

if (!(Get-Command sqlcmd -ErrorAction SilentlyContinue)) {
    Write-Warning "sqlcmd not found, exiting..."
}

try {
    $tfdirectory=$(Join-Path (Split-Path -Parent -Path $PSScriptRoot) "terraform")
    Push-Location $tfdirectory
    
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
Execute-SqlCmd -QueryFile $QueryFile -OutputFile $OutputFile -SqlDatabaseName $SqlDatabaseName -SqlServerFQDN $SqlServerFQDN -UserName $SqlUser -SecurePassword $SecurePassword
