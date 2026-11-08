$ErrorActionPreference = 'Continue'
$w = 'C:\Users\ernest.lee\scratch\fdb-seaweed'
Set-Location $w
$env:Path = "C:\Users\ernest.lee\scoop\shims;" + $env:Path
Write-Output '== scoop go + llvm-mingw'
if (-not (Get-Command go -ErrorAction SilentlyContinue)) { scoop install go 2>&1 | Select-Object -Last 3 }
if (-not (Get-Command x86_64-w64-mingw32-clang -ErrorAction SilentlyContinue)) { scoop bucket add main 2>&1 | Out-Null; scoop install llvm-mingw 2>&1 | Select-Object -Last 3 }
go version
(Get-Command x86_64-w64-mingw32-clang -ErrorAction SilentlyContinue).Source
Write-Output '== sources'
if (-not (Test-Path fdbfork)) {
  git clone -q --depth 1 --branch 7.3.79-weftspun-dev.3 --filter=blob:none --sparse https://github.com/V-Sekai-fire/datasource-foundationdb.git fdbfork 2>&1 | Select-Object -Last 3
  git -C fdbfork sparse-checkout set bindings/go 2>&1 | Select-Object -Last 3
}
Get-ChildItem fdbfork\bindings\go | ForEach-Object { $_.Name }
if (-not (Test-Path seaweedfs)) { git clone -q --depth 1 --branch 4.52 https://github.com/seaweedfs/seaweedfs.git seaweedfs 2>&1 | Select-Object -Last 3 }
git -C seaweedfs describe --tags 2>&1
Write-Output '== go.mod of binding'
if (Test-Path fdbfork\bindings\go\go.mod) { Get-Content fdbfork\bindings\go\go.mod } else { 'NO go.mod in fork bindings/go' }
