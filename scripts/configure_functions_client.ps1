#!/usr/bin/env pwsh
<# 
.SYNOPSIS 
    Grants access to given AAD user/service principal name
#> 
#Requires -Version 7

. (Join-Path $PSScriptRoot functions.ps1)

if (!(Get-Command func -ErrorAction SilentlyContinue)) {
    Write-Warning "Azure Function Tools not found, exiting..."
    exit
}

try {
    $tfdirectory=$(Join-Path (Split-Path -Parent -Path $PSScriptRoot) "terraform")
    Push-Location $tfdirectory
    
    $connectionString = (GetTerraformOutput "connection_string_legacy")  
    if (!($connectionString)) {
        Write-Warning "Connection string not in Terraform output, has Synapse been provisioned yet?"
        exit
    }
    $functionName = (GetTerraformOutput "function_name")  
    if (!($functionName)) {
        Write-Warning "Azure Function not found, has infrastructure been provisioned?"
        exit
    }

    $functionDirectory=$(Join-Path (Split-Path -Parent -Path $PSScriptRoot) "functions")
    Push-Location $functionDirectory

    func azure functionapp fetch-app-settings $functionName

    $localSettingsFile = (Join-Path $functionDirectory "local.settings.json")
    if (Test-Path $localSettingsFile) {
        $localSettings = (Get-Content ./local.settings.json | ConvertFrom-Json -AsHashtable)
        $localSettings.Values.Remove("APP_CLIENT_ID")
        $localSettings.Values["SYNAPSE_CONNECTION_STRING"] = $connectionString
        $localSettings | ConvertTo-Json | Out-File $localSettingsFile
    } else {
        Write-Warning "${localSettingsFile} not found"
    }
    
    Pop-Location
} finally {
    Pop-Location
}