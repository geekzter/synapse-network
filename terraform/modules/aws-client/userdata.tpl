<powershell>
Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/geekzter/bootstrap-os/master/windows/bootstrap_windows.ps1'))
choco install sql-server-management-studio -r -y
Write-Output "${sql_dwh_private_ip_address} ${sql_dwh_fqdn}" | Out-File -Append -Encoding ASCII -FilePath $env:SystemRoot\system32\drivers\etc\hosts

$wsh = New-Object -ComObject WScript.Shell

$hostsshortcutFile = "$($env:USERPROFILE)\Desktop\hosts.lnk"
$hostsShortcut = $wsh.CreateShortcut($hostsshortcutFile)
$hostsShortcut.TargetPath = "$($env:SystemRoot)\system32\notepad.exe"
$hostsShortcut.WorkingDirectory = "$($env:SystemRoot)\system32\drivers\etc"
$hostsShortcut.Arguments = "hosts"
$hostsShortcut.Save()

$ssmsshortcutFile = "$($env:USERPROFILE)\Desktop\${sql_dwh_pool}.lnk"
$ssmsShortcut = $wsh.CreateShortcut($ssmsshortcutFile)
#$ssmsShortcut.TargetPath = "$\{env:ProgramFiles(x86)\}\Microsoft SQL Server Management Studio 18\Common7\IDE\Ssms.exe"
$ssmsShortcut.TargetPath = "C:\Program Files (x86)\Microsoft SQL Server Management Studio 18\Common7\IDE\Ssms.exe"
$ssmsShortcut.Arguments = "-S ${sql_dwh_fqdn} -d ${sql_dwh_pool} -U ${user_name}"
$ssmsShortcut.Save()

</powershell>