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
    
    $functionName = (GetTerraformOutput "function_name")  
    if (!($functionName)) {
        Write-Warning "Azure Function not found, has infrastructure been provisioned?"
        exit
    }

    $functionDirectory=$(Join-Path (Split-Path -Parent -Path $PSScriptRoot) "functions")
    Push-Location $functionDirectory

    # func azure functionapp publish $functionName -b local --list-included-files
    func azure functionapp publish $functionName 
    Pop-Location
} finally {
    Pop-Location
}
