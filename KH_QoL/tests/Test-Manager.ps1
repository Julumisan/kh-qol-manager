$ErrorActionPreference = 'Stop'
$module = Join-Path (Split-Path -Parent $PSScriptRoot) 'lib\Manager.Core.psm1'
Import-Module $module -Force

$script:passed = 0; $script:failed = 0
function Assert-True([bool]$Condition,[string]$Name) {
    if ($Condition) { Write-Host "PASS  $Name" -ForegroundColor Green; $script:passed++ }
    else { Write-Host "FAIL  $Name" -ForegroundColor Red; $script:failed++ }
}
function Assert-Equal($Expected,$Actual,[string]$Name) { Assert-True ($Expected -eq $Actual) "$Name (esperado=$Expected, real=$Actual)" }

$projectRoot = Split-Path -Parent $PSScriptRoot
$gameRoot = Split-Path -Parent $projectRoot

try {
    $loaded = Import-KHQoLSettings $projectRoot
    Assert-Equal 2 $loaded.Settings.schema_version 'Esquema multijuego v2'
    Assert-Equal 'Dad Mode' $loaded.Settings.kh1.preset 'Preset independiente de KH1'
    Assert-Equal 'Vanilla' $loaded.Settings.kh2.preset 'Preset independiente de KH2'
    Assert-Equal 2.0 $loaded.Settings.kh1.exp_multiplier 'Parseo numérico de EXP'

    $dad = Get-PresetData 'Dad Mode' $projectRoot
    Assert-Equal 3.0 $dad.munny_multiplier 'Lectura de preset Dad Mode'
    $vanilla = Get-PresetData 'Vanilla' $projectRoot
    Assert-Equal 1.0 $vanilla.exp_multiplier 'Preset Vanilla'

    $bad = New-DefaultSettings
    $bad.kh1.exp_multiplier = 'no-es-numero'; $bad.kh1.munny_multiplier = 500
    $validated = Test-AndNormalizeSettings ([pscustomobject]$bad)
    Assert-Equal 1.0 $validated.Settings.kh1.exp_multiplier 'Número inválido vuelve al valor seguro por juego'
    Assert-Equal 100.0 $validated.Settings.kh1.munny_multiplier 'Rango superior se limita'
    Assert-True ($validated.Warnings.Count -ge 2) 'Se registran advertencias de validación'

    $legacy = [pscustomobject]@{ schema_version=1; preset='Light QoL'; kh1=[pscustomobject]@{ exp_multiplier=1.5 } }
    $migrated = Test-AndNormalizeSettings $legacy
    Assert-Equal 2 $migrated.Settings.schema_version 'Migración de esquema antiguo'
    Assert-Equal 'Light QoL' $migrated.Settings.kh1.preset 'Migración conserva preset de KH1'
    Assert-Equal 'Vanilla' $migrated.Settings.kh2.preset 'Migración inicializa KH2 en Vanilla'

    $expectedHashes = [ordered]@{
        kh1='D790746245D26159F3EE0E1060E33B2FA2DE06941850A4AC724F598722884BAC'
        kh2='9002B2DE6A1F91A790BD0673DE125D1CF833F7942BFEC827CDCF6BA64D5849ED'
        bbs='375A811243F1F95F786F00318E2E1210DD5881B25BBF0912A0AD8F81650C976C'
        recom='ACF42E96A168C73301F5C2CC2915D07E6C420F56A59C6286655C970BFEE36BBF'
    }
    $builds = Get-AllGameBuildInfo $gameRoot
    foreach ($id in $expectedHashes.Keys) {
        Assert-True $builds[$id].Supported "Detección de build soportada: $id"
        Assert-Equal $expectedHashes[$id] $builds[$id].Hash "SHA-256 exacto: $id"
    }

    $runtimes = Export-KHQoLRuntimeConfig $loaded.Settings $projectRoot $gameRoot
    Assert-Equal 4 $runtimes.Count 'Se generan cuatro configuraciones runtime'
    foreach ($id in $expectedHashes.Keys) {
        $runtime = Get-Content -Raw -LiteralPath $runtimes[$id]
        Assert-True ($runtime.Contains('build_authorized = true') -and $runtime.Contains($expectedHashes[$id])) "Runtime autorizado y exacto: $id"
    }

    $tempBase = Join-Path ([IO.Path]::GetTempPath()) ('KHQoLTests-' + [Guid]::NewGuid().ToString('N'))
    $tempRoot = Join-Path $tempBase 'KH_QoL'; $tempGame = Join-Path $tempBase 'Game'
    New-Item -ItemType Directory -Path (Join-Path $tempRoot 'config'),(Join-Path $tempRoot 'vendor\LuaBackend-v1.9.1-hook\extracted'),$tempGame -Force | Out-Null
    Copy-Item (Join-Path $projectRoot 'config\settings.json') (Join-Path $tempRoot 'config\settings.json')
    Copy-Item (Join-Path $projectRoot 'config\presets.json') (Join-Path $tempRoot 'config\presets.json')
    Copy-Item (Join-Path $projectRoot 'vendor\LuaBackend-v1.9.1-hook\extracted\DBGHELP.dll') (Join-Path $tempRoot 'vendor\LuaBackend-v1.9.1-hook\extracted\DBGHELP.dll')

    Set-Content -LiteralPath (Join-Path $tempRoot 'config\settings.json') -Value '{ JSON roto' -Encoding UTF8
    $recovered = Import-KHQoLSettings $tempRoot
    Assert-Equal 'Dad Mode' $recovered.Settings.kh1.preset 'Recuperación de JSON inválido'
    Assert-True ((Get-ChildItem (Join-Path $tempRoot 'config') -Filter 'settings.invalid-*.json').Count -eq 1) 'Copia del JSON inválido'
    Save-KHQoLSettings $recovered.Settings $tempRoot $tempGame | Out-Null

    $first = Install-KHQoL $tempRoot $tempGame -SkipBuildCheck
    Assert-True ($first.Installed -and $first.DllKnown) 'Instalación temporal verificada'
    $toml = Get-Content -Raw (Join-Path $tempGame 'LuaBackend.toml')
    foreach ($id in $expectedHashes.Keys) { Assert-True ($toml.Contains("[$id]") -and $toml.Contains("scripts\\$id")) "TOML activa scripts de $id" }
    $manifest1 = Get-Content -Raw (Join-Path $tempRoot 'uninstall\install-manifest.json') | ConvertFrom-Json
    $second = Install-KHQoL $tempRoot $tempGame -SkipBuildCheck
    $manifest2 = Get-Content -Raw (Join-Path $tempRoot 'uninstall\install-manifest.json') | ConvertFrom-Json
    Assert-True ($second.Installed -and $second.DllKnown) 'Segunda instalación idempotente'
    Assert-True (-not [bool]$manifest2.files[0].existed_before) 'Reinstalación conserva estado original'
    Assert-Equal $manifest1.files[0].original_hash $manifest2.files[0].original_hash 'Reinstalación conserva hash original'

    $removed = Uninstall-KHQoL $tempRoot $tempGame
    Assert-True $removed.Changed 'Desinstalador ejecutado'
    Assert-True (-not (Test-Path (Join-Path $tempGame 'DBGHELP.dll'))) 'Desinstalador elimina sólo el DLL propio'
    Assert-True (-not (Test-Path (Join-Path $tempGame 'LuaBackend.toml'))) 'Desinstalador elimina sólo el TOML propio'
}
finally {
    if ($tempBase -and (Test-Path -LiteralPath $tempBase)) { Remove-Item -LiteralPath $tempBase -Recurse -Force }
}

Write-Host "`nResultado: $script:passed aprobadas, $script:failed fallidas."
if ($script:failed -gt 0) { exit 1 }
exit 0
