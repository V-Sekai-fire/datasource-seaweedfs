$ErrorActionPreference = 'Continue'
$w = 'C:\Users\ernest.lee\scratch\fdb-seaweed'
Set-Location $w
$log = "$w\step3.log"; $ex = "$w\step3.exit"
Remove-Item $ex -ErrorAction SilentlyContinue
& {
  if (-not (Test-Path llvm-mingw)) {
    curl.exe -sL -o llvm.zip https://github.com/mstorsjo/llvm-mingw/releases/download/20261104/llvm-mingw-20261104-ucrt-x86_64.zip
    Expand-Archive llvm.zip -DestinationPath llvm-x -Force
    Move-Item (Get-ChildItem llvm-x -Directory | Select-Object -First 1).FullName llvm-mingw
  }
  $env:Path = "$w\llvm-mingw\bin;C:\Users\ernest.lee\scoop\apps\go\current\bin;" + $env:Path
  $inc = "$w\msi\PFiles\foundationdb\include"
  $lib = "$w\msi\PFiles\foundationdb\lib\foundationdb"
  $bin = "$w\msi\PFiles\foundationdb\bin"
  $env:CGO_ENABLED = '1'
  $env:CC = 'x86_64-w64-mingw32-clang'
  $env:CGO_CFLAGS = "-I$inc"
  $env:CGO_LDFLAGS = "-L$lib -lfdb_c"
  Write-Output "== clang"; & $env:CC --version | Select-Object -First 1
  Set-Location "$w\seaweedfs"
  $fork = "$w\fdbfork\bindings\go" -replace '\\','/'
  go mod edit "-replace=github.com/apple/foundationdb/bindings/go=$fork"
  Write-Output "== build (lib attempt 1: MSVC import lib)"
  go build -p 4 -tags foundationdb -o "$w\weed.exe" ./weed 2>&1 | Select-Object -Last 30
  if (-not (Test-Path "$w\weed.exe")) {
    Write-Output "== attempt 2: dlltool import lib from fdb_c.dll"
    Set-Location $w
    llvm-readobj --coff-exports "$bin\fdb_c.dll" 2>&1 | Select-String 'Name:' | ForEach-Object { $_.Line.Trim() -replace '^Name:\s*','' } | Sort-Object -Unique | Set-Content syms.txt
    ("LIBRARY fdb_c.dll`nEXPORTS`n" + ((Get-Content syms.txt) -join "`n")) | Set-Content fdb_c.def
    New-Item -ItemType Directory -Force "$w\mingwlib" | Out-Null
    llvm-dlltool -m i386:x86-64 -d fdb_c.def -l "$w\mingwlib\libfdb_c.a" 2>&1
    $env:CGO_LDFLAGS = "-L$w\mingwlib -lfdb_c"
    Set-Location "$w\seaweedfs"
    go build -p 4 -tags foundationdb -o "$w\weed.exe" ./weed 2>&1 | Select-Object -Last 30
  }
  Set-Location $w
  if (Test-Path weed.exe) { Copy-Item "$bin\fdb_c.dll" $w -Force; Get-Item weed.exe | ForEach-Object { "weed.exe {0} bytes" -f $_.Length }; .\weed.exe version 2>&1 | Select-Object -First 3 }
  else { 'BUILD FAILED' }
} *> $log
Set-Content $ex ($(if (Test-Path "$w\weed.exe") {'0'} else {'1'}))
