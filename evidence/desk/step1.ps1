$ErrorActionPreference = 'Continue'
$w = 'C:\Users\ernest.lee\scratch\fdb-seaweed'
New-Item -ItemType Directory -Force $w | Out-Null
Set-Location $w
Write-Output '== steamvr mode'
$log = Get-ChildItem 'C:\Program Files (x86)\Steam\logs\vrserver.txt' -ErrorAction SilentlyContinue
if ($log) { Select-String -Path $log.FullName -Pattern 'Using existing HMD' | Select-Object -Last 1 | ForEach-Object { $_.Line } } else { 'no vrserver.txt' }
Get-Process vrserver,vrcompositor -ErrorAction SilentlyContinue | ForEach-Object { $_.Name }
Write-Output '== disk'
Get-PSDrive -PSProvider FileSystem | ForEach-Object { "{0} {1} GB free" -f $_.Name, [int]($_.Free/1GB) }
Write-Output '== download'
$b = 'https://github.com/V-Sekai-fire/datasource-foundationdb/releases/download/7.3.79-weftspun-dev.3'
foreach ($f in 'SHA256SUMS.windows','fdbserver.windows.x86_64.exe','fdbcli.windows.x86_64.exe','fdb_c.windows.x86_64.dll','foundationdb-7.3.79-SNAPSHOT-x64.msi') {
  if (-not (Test-Path $f)) { curl.exe -sL -o $f "$b/$f" }
}
Write-Output '== verify'
foreach ($l in Get-Content SHA256SUMS.windows) {
  $h,$n = $l -split ' \*',2
  $a = (Get-FileHash $n -Algorithm SHA256).Hash.ToLower()
  "{0} {1}" -f ($(if ($a -eq $h) {'OK  '} else {'FAIL'})), $n
}
Write-Output '== msi extract (administrative image, no install)'
if (-not (Test-Path msi)) { Start-Process msiexec -ArgumentList '/a',"$w\foundationdb-7.3.79-SNAPSHOT-x64.msi",'/qn',"TARGETDIR=$w\msi" -Wait }
Get-ChildItem -Recurse msi -File | ForEach-Object { $_.FullName.Substring($w.Length+1) + '  ' + $_.Length }
