Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Gunfight Installer" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$modsPath = "$env:LOCALAPPDATA\Plutonium\storage\t6\mods"

if (-not (Test-Path "$env:LOCALAPPDATA\Plutonium\storage\t6")) {
    Write-Host "ERROR: Plutonium T6 directory not found!" -ForegroundColor Red
    pause
    exit 1
}

Write-Host "Installing Gunfight mod..." -ForegroundColor Green

if (-not (Test-Path $modsPath)) {
    New-Item -ItemType Directory -Path $modsPath -Force | Out-Null
}

$modDestPath = "$modsPath\gunfight_mp"
if (Test-Path $modDestPath) {
    Remove-Item $modDestPath -Recurse -Force
}

Copy-Item "gunfight_mp" $modDestPath -Recurse -Force

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Installation Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Load the mod from the Plutonium mods menu" -ForegroundColor Yellow
Write-Host ""
pause
