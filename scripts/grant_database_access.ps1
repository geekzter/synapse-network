#!/usr/bin/env pwsh
<# 
.SYNOPSIS 
    Grants access to given AAD user/service principal name
#> 
#Requires -Version 7

### Arguments
param ( 
    [parameter(Mandatory=$false)][string]$MSIName,
    [parameter(Mandatory=$false)][string]$SqlDatabaseName,
    [parameter(Mandatory=$false)][string]$SqlServerFQDN
) 

. (Join-Path $PSScriptRoot functions.ps1)

# Gather data from Terraform
try {
    $tfdirectory=$(Join-Path (Split-Path -Parent -Path $PSScriptRoot) "terraform")
    Push-Location $tfdirectory
    
    if (!$MSIName) {
        $MSIName = (GetTerraformOutput "managed_identity_name")  
    }
    if (!$SqlDatabaseName) {
        $SqlDatabaseName = (GetTerraformOutput "azure_sql_dwh_pool_name")  
    }
    if (!$SqlServerFQDN) {
        $SqlServerFQDN = (GetTerraformOutput "azure_sql_dwh_fqdn")  
    }

    if ([string]::IsNullOrEmpty($SqlDatabaseName)) {
        Write-Warning "Synapse SQL Pool has not been created, nothing to do deploy to"
        exit 
    }

    $msiSqlParameters = @{msi_name=$MSIName}
    $msiSqlScript = (Join-Path $PSScriptRoot "grant-msi-database-access.sql")
    Execute-Sql -QueryFile $msiSqlScript -Parameters $msiSqlParameters -SqlDatabaseName $SqlDatabaseName -SqlServerFQDN $SqlServerFQDN -UserName $UserName -SecurePassword $SecurePassword
    
} finally {
    Pop-Location
}