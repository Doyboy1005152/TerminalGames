@echo off
setlocal
title Terminal Games Connection Repair
set "TG_REPAIR_SELF=%~f0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$text=[IO.File]::ReadAllText($env:TG_REPAIR_SELF); $body=($text -split '(?m)^::TG_POWERSHELL_START\r?$',2)[1]; & ([scriptblock]::Create($body))"
if errorlevel 1 pause
exit /b
::TG_POWERSHELL_START
$ErrorActionPreference = 'Stop'
function Find-Python {
    $candidates = @()
    $py = Get-Command py.exe -ErrorAction SilentlyContinue
    if ($py) {
        try {
        $found = & $py.Source -3 -c "import sys; assert sys.version_info >= (3,9); print(sys.executable)" 2>$null
        if ($LASTEXITCODE -eq 0 -and $found) { return [string]($found | Select-Object -Last 1) }
        } catch {}
    }
    $candidates += Join-Path $env:LOCALAPPDATA 'Programs\Python\Python313\python.exe'
    $command = Get-Command python.exe -ErrorAction SilentlyContinue
    if ($command -and $command.Source -notlike '*\WindowsApps\*') { $candidates += $command.Source }
    foreach ($candidate in $candidates) {
        if (Test-Path $candidate) {
            & $candidate -c "import sys; assert sys.version_info >= (3,9)" 2>$null
            if ($LASTEXITCODE -eq 0) { return $candidate }
        }
    }
    return $null
}
Write-Host 'Terminal Games connection repair (not a reinstall).'
Read-Host 'Close Terminal Games, then press Enter'
$python = Find-Python
if (-not $python) { throw 'Could not find the Python used by your game.' }
& $python -c "import base64,zlib;exec(compile(zlib.decompress(base64.b64decode('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')),'<Terminal Games connection repair>','exec'))"
$result = $LASTEXITCODE
Read-Host 'Press Enter to close'
exit $result
