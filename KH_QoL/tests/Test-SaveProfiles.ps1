$ErrorActionPreference = 'Stop'
Import-Module (Join-Path (Split-Path -Parent $PSScriptRoot) 'lib\Manager.Core.psm1') -Force
$script:passed = 0; $script:failed = 0
function Assert-True([bool]$c,[string]$n) { if ($c) { Write-Host "PASS  $n" -ForegroundColor Green; $script:passed++ } else { Write-Host "FAIL  $n" -ForegroundColor Red; $script:failed++ } }

$tmp = Join-Path $env:TEMP ('khqol_saveprof_' + [guid]::NewGuid().ToString('N'))
try {
    $root = Join-Path $tmp 'KH_QoL'; New-Item -ItemType Directory -Force -Path $root | Out-Null
    $docs = Join-Path $tmp 'docs'
    $saveDir = Join-Path $docs 'My Games\KINGDOM HEARTS HD 1.5+2.5 ReMIX\Steam\76561198000000001'
    New-Item -ItemType Directory -Force -Path $saveDir | Out-Null
    $live = Join-Path $saveDir 'KHFM_WW.png'
    Set-Content -LiteralPath $live -Value 'REAL-1' -NoNewline
    Set-Content -LiteralPath (Join-Path $saveDir 'KHIIFM_WW.png') -Value 'KH2' -NoNewline

    Assert-True ((Get-Item -LiteralPath (Get-KHSaveDirectory $docs)).FullName -eq (Get-Item -LiteralPath $saveDir).FullName) 'Detecta la carpeta de saves por SteamID'
    $st = Get-KHSaveProfileStatus $root $saveDir
    Assert-True ($st.Active -eq 'Partida' -and -not $st.OtherHasFile) 'Estado inicial: Partida activa, Pruebas vacío'

    $st = Switch-KHSaveProfile $root $saveDir -SkipProcessCheck
    Assert-True ($st.Active -eq 'Pruebas') 'Cambio a Pruebas'
    Assert-True (-not (Test-Path -LiteralPath $live)) 'Perfil nuevo: se quita el contenedor para que el juego cree uno limpio'
    Assert-True ((Get-Content -LiteralPath (Join-Path $root 'save_profiles\Partida\KHFM_WW.png') -Raw) -eq 'REAL-1') 'La partida real queda guardada en su perfil'

    Set-Content -LiteralPath $live -Value 'TEST-1' -NoNewline   # the game creates/saves the test container
    $st = Switch-KHSaveProfile $root $saveDir -SkipProcessCheck
    Assert-True ($st.Active -eq 'Partida' -and (Get-Content -LiteralPath $live -Raw) -eq 'REAL-1') 'Vuelta a Partida restaura la partida real'
    Assert-True ((Get-Content -LiteralPath (Join-Path $root 'save_profiles\Pruebas\KHFM_WW.png') -Raw) -eq 'TEST-1') 'El progreso de pruebas se conserva'

    Set-Content -LiteralPath $live -Value 'REAL-2' -NoNewline   # real progress continues
    $st = Switch-KHSaveProfile $root $saveDir -SkipProcessCheck
    Assert-True ((Get-Content -LiteralPath $live -Raw) -eq 'TEST-1') 'Pruebas recupera su contenedor'
    $st = Switch-KHSaveProfile $root $saveDir -SkipProcessCheck
    Assert-True ((Get-Content -LiteralPath $live -Raw) -eq 'REAL-2') 'La partida real conserva su último progreso'
    Assert-True ((Get-Content -LiteralPath (Join-Path $saveDir 'KHIIFM_WW.png') -Raw) -eq 'KH2') 'Los saves de otros juegos no se tocan'
    Assert-True (@(Get-ChildItem -LiteralPath (Join-Path $root 'backup\save-switch')).Count -ge 3) 'Copias de seguridad rotativas creadas'
    for ($i = 0; $i -lt 8; $i++) { Switch-KHSaveProfile $root $saveDir -SkipProcessCheck | Out-Null; Start-Sleep -Milliseconds 1100 }
    Assert-True (@(Get-ChildItem -LiteralPath (Join-Path $root 'backup\save-switch')).Count -le 6) 'Rotación: como máximo 6 copias'
} finally {
    Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Host ''; Write-Host "Resultado: $script:passed aprobadas, $script:failed fallidas."
if ($script:failed -gt 0) { exit 1 }
