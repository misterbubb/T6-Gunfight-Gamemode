# Gunfight Gamemode - Automated Installer
# This script automatically installs the Gunfight mod to your Plutonium T6 directory

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Gunfight Gamemode Installer for T6  " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Define paths
$plutoniumPath = "$env:LOCALAPPDATA\Plutonium\storage\t6"
$modsPath = "$plutoniumPath\mods"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$modFolder = Join-Path $scriptDir "gunfight_mp"

# Check if Plutonium T6 directory exists
if (-not (Test-Path $plutoniumPath)) {
    Write-Host "[ERROR] Plutonium T6 directory not found!" -ForegroundColor Red
    Write-Host "Expected location: $plutoniumPath" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Please make sure Plutonium is installed and you've launched T6 at least once." -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "[OK] Found Plutonium T6 directory" -ForegroundColor Green

# Check if mods folder exists, create if not
if (-not (Test-Path $modsPath)) {
    Write-Host "[INFO] Mods folder not found, creating it..." -ForegroundColor Yellow
    try {
        New-Item -ItemType Directory -Path $modsPath -Force | Out-Null
        Write-Host "[OK] Created mods folder" -ForegroundColor Green
    }
    catch {
        Write-Host "[ERROR] Failed to create mods folder: $_" -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }
}
else {
    Write-Host "[OK] Mods folder exists" -ForegroundColor Green
}

# Check if mod folder exists in current directory
if (-not (Test-Path $modFolder)) {
    Write-Host "[ERROR] gunfight_mp folder not found!" -ForegroundColor Red
    Write-Host "Make sure this script is in the same folder as gunfight_mp" -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "[OK] Found gunfight_mp folder" -ForegroundColor Green

# Define destination path
$destinationPath = Join-Path $modsPath "gunfight_mp"

# Check if mod is already installed
if (Test-Path $destinationPath) {
    Write-Host ""
    Write-Host "[WARNING] Gunfight mod is already installed!" -ForegroundColor Yellow
    $overwrite = Read-Host "Do you want to overwrite it? (y/n)"
    
    if ($overwrite -ne "y" -and $overwrite -ne "Y") {
        Write-Host "[INFO] Installation cancelled" -ForegroundColor Yellow
        Read-Host "Press Enter to exit"
        exit 0
    }
    
    Write-Host "[INFO] Removing old installation..." -ForegroundColor Yellow
    try {
        Remove-Item -Path $destinationPath -Recurse -Force
        Write-Host "[OK] Removed old installation" -ForegroundColor Green
    }
    catch {
        Write-Host "[ERROR] Failed to remove old installation: $_" -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }
}

# Copy mod folder to mods directory
Write-Host ""
Write-Host "[INFO] Installing Gunfight mod..." -ForegroundColor Cyan
try {
    Copy-Item -Path $modFolder -Destination $modsPath -Recurse -Force
    Write-Host "[OK] Successfully installed Gunfight mod!" -ForegroundColor Green
}
catch {
    Write-Host "[ERROR] Failed to install mod: $_" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Success message
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Installation Complete!               " -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "The Gunfight mod has been installed to:" -ForegroundColor White
Write-Host "$destinationPath" -ForegroundColor Cyan
Write-Host ""
Write-Host "To play:" -ForegroundColor White
Write-Host "1. Launch Plutonium T6" -ForegroundColor White
Write-Host "2. Go to Mods menu" -ForegroundColor White
Write-Host "3. Load 'gunfight_mp'" -ForegroundColor White
Write-Host "4. Start a private match with Search & Destroy" -ForegroundColor White
Write-Host ""
Read-Host "Press Enter to exit"
