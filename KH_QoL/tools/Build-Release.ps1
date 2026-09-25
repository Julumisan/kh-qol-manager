# Builds the release ZIP from an explicit list of files (never the whole dev
# folder). Output: KH_QoL\dist\KH_QoL_Manager_<version>.zip + a SHA-256 manifest.
# Usage: powershell -ExecutionPolicy Bypass -File KH_QoL\tools\Build-Release.ps1
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$gameDirectory = Split-Path -Parent $projectRoot
Import-Module (Join-Path $projectRoot 'lib\Manager.Core.psm1') -Force
$version = Get-KHQoLModVersion

$files = New-Object System.Collections.Generic.List[string]
foreach ($f in 'KH_QoL_Manager.cmd', 'KH_QoL_Manager.ps1', 'Uninstall_KH_QoL.cmd', 'Uninstall_KH_QoL.ps1') { $files.Add($f) }
foreach ($f in 'README.md', 'LICENSE', 'THIRD_PARTY_NOTICES.md', 'CHANGELOG.md', 'lib\Manager.Core.psm1', 'config\presets.json') { $files.Add("KH_QoL\$f") }
foreach ($game in 'kh1', 'kh2', 'bbs', 'recom') {
    $files.Add("KH_QoL\scripts\$game\main.lua")
    Get-ChildItem -LiteralPath (Join-Path $projectRoot "scripts\$game\io_packages\kh_qol") -Filter '*.lua' |
        Where-Object { $_.Name -ne 'runtime.lua' } |   # generated per user; never shipped
        Sort-Object Name | ForEach-Object { $files.Add("KH_QoL\scripts\$game\io_packages\kh_qol\$($_.Name)") }
}

$dist = Join-Path $projectRoot 'dist'
$stage = Join-Path $dist "stage-$version"
if (Test-Path -LiteralPath $stage) { Remove-Item -LiteralPath $stage -Recurse -Force }
New-Item -ItemType Directory -Force -Path $stage | Out-Null

$manifest = New-Object System.Collections.Generic.List[string]
foreach ($rel in $files) {
    $src = Join-Path $gameDirectory $rel
    if (-not (Test-Path -LiteralPath $src)) { throw "Missing file for the package: $rel" }
    $dst = Join-Path $stage $rel
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dst) | Out-Null
    Copy-Item -LiteralPath $src -Destination $dst
    $manifest.Add(('{0}  {1}' -f (Get-KHFileSha256 $dst), ($rel -replace '\\', '/')))
}
[IO.File]::WriteAllLines((Join-Path $stage 'KH_QoL\MANIFEST.sha256'), $manifest.ToArray(), (New-Object Text.UTF8Encoding($false)))

$zip = Join-Path $dist "KH_QoL_Manager_$version.zip"
if (Test-Path -LiteralPath $zip) { Remove-Item -LiteralPath $zip -Force }
Add-Type -AssemblyName System.IO.Compression.FileSystem
[IO.Compression.ZipFile]::CreateFromDirectory($stage, $zip, [IO.Compression.CompressionLevel]::Optimal, $false)
Remove-Item -LiteralPath $stage -Recurse -Force

Write-Host "Package: $zip"
Write-Host "Files:   $($files.Count + 1)"
Write-Host "SHA-256: $(Get-KHFileSha256 $zip)"
