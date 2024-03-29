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
if (!(Get-Command dotnet -ErrorAction SilentlyContinue)) {
    Write-Warning ".NET (Core) SDK not found, exiting..."
    exit
}

try {
    $tfdirectory=$(Join-Path (Split-Path -Parent -Path $PSScriptRoot) "terraform")
    Push-Location $tfdirectory
    AzLogin
    
    $resourceGroupID = (GetTerraformOutput "resource_group_id")
    if (!($resourceGroupID)) {
        Write-Warning "Azure Resource Group not found, has infrastructure been provisioned?"
        exit
    }
    $subscriptionID = $resourceGroupID.split("/")[2]
    $functionNames = (GetTerraformOutput -OutputVariable "function_name" -ComplexType)  
    if (!($functionNames)) {
        Write-Warning "Azure Function not found, has infrastructure been provisioned?"
        exit
    }

    $functionDirectory=$(Join-Path (Split-Path -Parent -Path $PSScriptRoot) "functions")
    Push-Location $functionDirectory

    # Reverse the list, so we process the main region last and locally fetched settings point to that region
    [array]::Reverse($functionNames)
    foreach ($functionName in $functionNames) {
        Write-Host "`nFetching settings for function ${functionName}..."
        func azure functionapp fetch-app-settings $functionName --subscription $subscriptionID

        # Trying multiple times to cater for function warmup (SCM non-responsiveness)
        $try = 0
        do {
            $try++
            Write-Host "`nPublishing to function ${functionName} (#${try})..."
            func azure functionapp publish $functionName -b local --subscription $subscriptionID #2>&1
        } while (($LASTEXITCODE -ne 0) -and ($try -lt 25))
        Write-Host "`nListing functions in ${functionName}..."
        func azure functionapp list-functions $functionName
    }
    Pop-Location
} finally {
    Pop-Location
}
