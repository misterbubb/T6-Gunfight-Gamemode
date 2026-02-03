Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Gunfight Installer" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$plutoniumPath = "$env:LOCALAPPDATA\Plutonium\storage\t6"
$modsPath = "$plutoniumPath\mods"

if (-not (Test-Path $env:LOCALAPPDATA)) {
    Write-Host "ERROR: Could not find LocalAppData folder!" -ForegroundColor Red
    pause
    exit 1
}

if (-not (Test-Path "$env:LOCALAPPDATA\Plutonium")) {
    Write-Host "ERROR: Plutonium not found! Make sure Plutonium is installed." -ForegroundColor Red
    pause
    exit 1
}

if (-not (Test-Path "$env:LOCALAPPDATA\Plutonium\storage")) {
    New-Item -ItemType Directory -Path "$env:LOCALAPPDATA\Plutonium\storage" -Force | Out-Null
}

if (-not (Test-Path $plutoniumPath)) {
    New-Item -ItemType Directory -Path $plutoniumPath -Force | Out-Null
}

if (-not (Test-Path $modsPath)) {
    New-Item -ItemType Directory -Path $modsPath -Force | Out-Null
}

Write-Host "Installing Gunfight mod..." -ForegroundColor Green

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$sourceModPath = Join-Path $scriptDir "gunfight_mp"

if (-not (Test-Path $sourceModPath)) {
    Write-Host "ERROR: gunfight_mp folder not found next to this script!" -ForegroundColor Red
    Write-Host "Make sure the gunfight_mp folder is in the same directory as this installer." -ForegroundColor Yellow
    pause
    exit 1
}

$modDestPath = "$modsPath\gunfight_mp"

try {
    if (Test-Path $modDestPath) {
        Remove-Item $modDestPath -Recurse -Force -ErrorAction Stop
    }
    Copy-Item $sourceModPath $modDestPath -Recurse -Force -ErrorAction Stop
}
catch {
    Write-Host "ERROR: Failed to copy mod files!" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    pause
    exit 1
}

if (Test-Path "$modDestPath\mod.json") {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Installation Complete!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Load the mod from the Plutonium mods menu" -ForegroundColor Yellow
}
else {
    Write-Host "ERROR: Installation may have failed - mod.json not found!" -ForegroundColor Red
}

Write-Host ""
pause
