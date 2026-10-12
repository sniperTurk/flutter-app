# SNIPER TÜRK Garmin — Windows'ta derleme yardımcısı.
# Kullanım (garmin klasöründe):  .\tools\build-windows.ps1  [-Device venu3]
# Anahtar depo dışında: %USERPROFILE%\garmin-keys\developer_key.der
param([string]$Device = "venu3")
$ErrorActionPreference = "Continue"
$jdk = Get-ChildItem "C:\Program Files\Eclipse Adoptium" -Directory -ErrorAction SilentlyContinue | Select-Object -First 1
if ($jdk) { $env:JAVA_HOME = $jdk.FullName; $env:Path = "$($jdk.FullName)\bin;$env:Path" }
$sdk = (Get-ChildItem "$env:APPDATA\Garmin\ConnectIQ\Sdks" -Directory | Sort-Object Name | Select-Object -Last 1).FullName
$key = "$env:USERPROFILE\garmin-keys\developer_key.der"
$root = Split-Path $PSScriptRoot -Parent
Set-Location $root
New-Item -ItemType Directory -Force build | Out-Null
Remove-Item build\log, build\log.zip -Recurse -Force -ErrorAction SilentlyContinue
"SDK : $sdk"
"Cihaz: $Device"
& "$sdk\bin\monkeyc.bat" -f monkey.jungle -d $Device -o build\sniperturk.prg -y $key -w --debug-log-level 3 --debug-log-output build\log.zip
if (Test-Path build\sniperturk.prg) {
  "=== DERLEME BAŞARILI: build\sniperturk.prg ==="
} else {
  "=== DERLEME BAŞARISIZ — derleyici kaydı ==="
  if (Test-Path build\log.zip) {
    Expand-Archive build\log.zip build\log -Force
    Get-ChildItem build\log -Recurse -File | Get-Content |
      Select-String "Exception|Caused by|\.mc:|at com\.garmin" | Select-Object -First 15
  }
}
