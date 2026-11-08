$t='xrwin-fdbsw-build'
Unregister-ScheduledTask $t -Confirm:$false -ErrorAction SilentlyContinue
$a = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument '-NoProfile -ExecutionPolicy Bypass -File C:\Users\ernest.lee\scratch\step3.ps1'
$s = New-ScheduledTaskSettingsSet -Priority 7 -ExecutionTimeLimit (New-TimeSpan -Hours 1)
Register-ScheduledTask $t -Action $a -Settings $s -RunLevel Highest -Force | Out-Null
Start-ScheduledTask $t
'started'
