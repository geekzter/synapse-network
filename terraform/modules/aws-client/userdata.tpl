<powershell>
Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/geekzter/bootstrap-os/master/windows/bootstrap_windows.ps1'))
choco install sql-server-management-studio -r -y
Write-Output "${sql_dwh_private_ip_address} ${sql_dwh_fqdn}" | Out-File -Append -Encoding ASCII -FilePath $env:SystemRoot\system32\drivers\etc\hosts
</powershell>