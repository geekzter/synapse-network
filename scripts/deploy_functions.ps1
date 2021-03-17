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

    func azure functionapp publish $functionName -b
} finally {
    Pop-Location
}


# dotnet clean /property:GenerateFullPaths=true /consoleloggerparameters:NoSummary 
# dotnet build /property:GenerateFullPaths=true /consoleloggerparameters:NoSummary

# dotnet publish --configuration Release /property:GenerateFullPaths=true /consoleloggerparameters:NoSummary