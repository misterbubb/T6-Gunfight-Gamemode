$plutoniumPath = "$env:LOCALAPPDATA\Plutonium\storage\t6"
$rawPath = "$plutoniumPath\raw\maps\mp\gametypes"
$modsPath = "$plutoniumPath\mods"

Write-Host "Installing Gunfight..."
Write-Host ""

New-Item -ItemType Directory -Path $rawPath -Force | Out-Null
New-Item -ItemType Directory -Path $modsPath -Force | Out-Null

$sdPath = "$rawPath\sd.gsc"
if (Test-Path $sdPath) {
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    Copy-Item $sdPath "$rawPath\sd_backup_$timestamp.gsc"
    Write-Host "Backed up original S&D"
}

Copy-Item ".\gunfight_mp\maps\mp\gametypes\sd.gsc" $sdPath -Force
Write-Host "Installed gametype"

$modDestination = "$modsPath\gunfight_mp"
if (Test-Path $modDestination) {
    Remove-Item $modDestination -Recurse -Force
}
Copy-Item ".\gunfight_mp" $modDestination -Recurse -Force
Write-Host "Installed mod files"

Write-Host ""
Write-Host "Done! Load Search & Destroy in Custom Games to play Gunfight."
Write-Host ""
Write-Host "To restore S&D, delete: $sdPath"
Write-Host ""
Read-Host "Press Enter to close"
