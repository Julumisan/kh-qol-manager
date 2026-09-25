[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$gameDirectory = (Resolve-Path -LiteralPath $PSScriptRoot).Path
$projectRoot = (Resolve-Path -LiteralPath (Join-Path $gameDirectory 'KH_QoL')).Path
if ([IO.Path]::GetFileName($projectRoot) -ne 'KH_QoL' -or (Split-Path -Parent $projectRoot) -ne $gameDirectory) {
    throw "Ruta de proyecto inesperada; no se eliminará nada: $projectRoot"
}
if (-not (Test-Path -LiteralPath (Join-Path $gameDirectory 'KINGDOM HEARTS FINAL MIX.exe'))) {
    throw 'No se reconoce la carpeta del juego; no se eliminará nada.'
}

Import-Module (Join-Path $projectRoot 'lib\Manager.Core.psm1') -Force
$result = Uninstall-KHQoL -Root $projectRoot -GameDirectory $gameDirectory
$result.Messages | ForEach-Object { Write-Host $_ }
if (@($result.Kept).Count -gt 0) {
    throw 'Some files changed after installation and need review; KH_QoL and its backups are kept. / Hay archivos cambiados que requieren revisión; se conserva KH_QoL y sus backups.'
}

# Save containers kept by the KH1 save profiles (and their rotating copies)
# are moved next to the Steam saves before anything is deleted.
$keep = @((Join-Path $projectRoot 'save_profiles'), (Join-Path $projectRoot 'backup\save-switch')) |
    Where-Object { (Test-Path -LiteralPath $_) -and @(Get-ChildItem -LiteralPath $_ -Recurse -File).Count -gt 0 }
if ($keep.Count -gt 0) {
    $saveDir = Get-KHSaveDirectory
    if (-not $saveDir) { throw 'KH1 save profiles exist but the Steam save folder was not found; KH_QoL is kept. / Hay perfiles de saves pero no se encontró la carpeta de saves; se conserva KH_QoL.' }
    $target = Join-Path (Split-Path -Parent $saveDir) ('KH_QoL_saves_' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
    New-Item -ItemType Directory -Force -Path $target | Out-Null
    foreach ($dir in $keep) { Copy-Item -LiteralPath $dir -Destination $target -Recurse -Force }
    Write-Host "KH1 save profiles kept in / Perfiles de saves guardados en: $target"
}

# Todos los destinos han sido eliminados o restaurados por hash. Sólo quedan
# archivos propiedad del proyecto dentro de la ruta exacta validada.
Remove-Item -LiteralPath $projectRoot -Recurse -Force
foreach ($name in @('KH_QoL_Manager.ps1','KH_QoL_Manager.cmd','Uninstall_KH_QoL.cmd')) {
    $path = Join-Path $gameDirectory $name
    if (Test-Path -LiteralPath $path) { Remove-Item -LiteralPath $path -Force }
}
Write-Host 'KH QoL was fully uninstalled; saves and other mods were not touched. / KH QoL se desinstaló por completo; no se tocaron partidas ni mods ajenos.'
Remove-Item -LiteralPath $PSCommandPath -Force
