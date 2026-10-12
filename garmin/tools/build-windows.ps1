# SNIPER TURK Garmin - Windows derleme yardimcisi.
# Kullanim (garmin klasorunde):  .\tools\build-windows.ps1  [-Device venu3]
# Anahtar depo disinda: %USERPROFILE%\garmin-keys\developer_key.der
param([string]$Device = "venu3")
$ErrorActionPreference = "Continue"
$jdk = Get-ChildItem "C:\Program Files\Eclipse Adoptium" -Directory -ErrorAction SilentlyContinue | Select-Object -First 1
if ($jdk) { $env:JAVA_HOME = $jdk.FullName; $env:Path = "$($jdk.FullName)\bin;$env:Path" }
# SDK Manager'da "Use this SDK" ile secilen surum (yoksa en yenisi).
$cfg = "$env:APPDATA\Garmin\ConnectIQ\current-sdk.cfg"
# Turkce Windows'ta Java "bitor"/"private" gibi kelimeleri buyuk harfe
# cevirirken noktali I (I-with-dot) uretir; derleyici bunlari tanimaz ve
# "critical error" ile coker. Derleyiciyi Ingilizce yerel ayarla calistir.
$env:JAVA_TOOL_OPTIONS = "-Duser.language=en -Duser.country=US"
$sdk = $null
if (Test-Path $cfg) { $sdk = (Get-Content $cfg -Raw).Trim().TrimEnd('\') }
if (-not $sdk -or -not (Test-Path "$sdk\bin\monkeyc.bat")) {
  $sdk = (Get-ChildItem "$env:APPDATA\Garmin\ConnectIQ\Sdks" -Directory | Sort-Object Name | Select-Object -Last 1).FullName
}
$key = "$env:USERPROFILE\garmin-keys\developer_key.der"
$root = Split-Path $PSScriptRoot -Parent
Set-Location $root
New-Item -ItemType Directory -Force build | Out-Null
Remove-Item build\log, build\log.zip -Recurse -Force -ErrorAction SilentlyContinue
"SDK : $sdk"
"Cihaz: $Device"
& "$sdk\bin\monkeyc.bat" -f monkey.jungle -d $Device -o build\sniperturk.prg -y $key -w
if (-not (Test-Path build\sniperturk.prg)) {
  # Ayrintili kayit yalnizca hata olursa (eski SDK bu secenekleri bilmeyebilir).
  & "$sdk\bin\monkeyc.bat" -f monkey.jungle -d $Device -o build\sniperturk.prg -y $key --debug-log-level 3 --debug-log-output build\log.zip 2>$null | Out-Null
}
if (Test-Path build\sniperturk.prg) {
  "=== DERLEME BASARILI: build\sniperturk.prg ==="
} else {
  "=== DERLEME BASARISIZ - derleyici kaydi ==="
  if (Test-Path build\log.zip) {
    Expand-Archive build\log.zip build\log -Force
    Get-ChildItem build\log -Recurse -File | Get-Content |
      Select-String "Exception|Caused by|\.mc:|at com\.garmin" | Select-Object -First 15
  }
}
