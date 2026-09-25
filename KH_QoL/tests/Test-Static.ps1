$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$main = Get-Content -Raw (Join-Path $root 'scripts\kh1\main.lua')
$version = Get-Content -Raw (Join-Path $root 'scripts\kh1\io_packages\kh_qol\version.lua')
$progression = Get-Content -Raw (Join-Path $root 'scripts\kh1\io_packages\kh_qol\progression.lua')
$manager = Get-Content -Raw (Join-Path (Split-Path -Parent $root) 'KH_QoL_Manager.ps1')

$checks = [ordered]@{
    'Entrada KH1 _OnInit' = $main.Contains('function _OnInit()')
    'Entrada KH1 _OnFrame' = $main.Contains('function _OnFrame()')
    'Autorización SHA en KH1' = $version.Contains('build_authorized') -and $version.Contains('expected_hash')
    'Marcadores de versión KH1 (Steam 1.0.0.2)' = $version.Contains('0x4698D2, "6A 61 70 61 6E 65 73 65"') -and $version.Contains('0x26E20C, "09"')
    'Firmas de código KH1 antes de escribir' = $version.Contains('M.signatures') -and $version.Contains('code signature mismatch')
    'KH1 fail closed' = $main.Contains('if not state.authorized')
    'EXP escala el multiplicador nativo' = $progression.Contains('A.experience_multiplier') -and $progression.Contains('exp_redirect:update')
    'Drop escala Lucky Strike' = $progression.Contains('A.lucky_multiplier') -and $progression.Contains('drop_redirect:update')
    'Munny sólo en orbes' = $progression.Contains('munny_orb_base') -and -not $progression.Contains('last_munny')
    'Radio no escribe la constante compartida' = (Get-Content -Raw (Join-Path $root 'scripts\kh1\io_packages\kh_qol\pickup.lua')).Contains('radius_private_slot') -and -not (Get-Content -Raw (Join-Path $root 'scripts\kh1\io_packages\kh_qol\pickup.lua')).Contains('WriteFloat(A.radius_tm1_shared')
    'GUI contiene pestañas' = $manager.Contains('Windows.Forms.TabControl') -and $manager.Contains('configuración independiente')
}
foreach ($id in @('kh2','bbs','recom')) {
    $content = Get-Content -Raw (Join-Path $root "scripts\$id\main.lua")
    $gameVersion = Get-Content -Raw (Join-Path $root "scripts\$id\io_packages\kh_qol\version.lua")
    $gameProgression = Get-Content -Raw (Join-Path $root "scripts\$id\io_packages\kh_qol\progression.lua")
    $gamePlayer = Get-Content -Raw (Join-Path $root "scripts\$id\io_packages\kh_qol\player.lua")
    $checks["$id tiene entrada segura"] = $content.Contains('function _OnInit()') -and $content.Contains('if not state.authorized')
    $checks["$id autentica hash, GAME_ID y huella"] = $gameVersion.Contains('expected_hash') -and $gameVersion.Contains('expected_game_id') -and $gameVersion.Contains('fingerprint')
    $checks["$id bloquea escrituras sin partida válida"] = $content.Contains('Version.runtime_sanity_ok()') -and $gameVersion.Contains('if not authorized then return false end')
    $checks["$id implementa EXP reversible"] = $gameProgression.Contains('applied_multiplier') -and $gameProgression.Contains('multiplier == 1.0 and') -and $gameProgression.Contains('WriteInt')
    $checks["$id multiplica sólo ganancias de moneda"] = $gameProgression.Contains('self_written_') -and $gameProgression.Contains('(multiplier - 1.0)')
    $checks["$id implementa HP sin resurrección"] = $gamePlayer.Contains('current > 0 and current < maximum') -and ($gamePlayer -match '\bWrite(Int|Short)\s*\(')
}
$checks['KH2 implementa MP sin alterar máximo'] = (Get-Content -Raw (Join-Path $root 'scripts\kh2\io_packages\kh_qol\player.lua')).Contains('config.infinite_mp')
$checks['GUI habilita progreso en los cuatro juegos'] = $manager.Contains("kh2   = @('exp_multiplier','munny_multiplier','infinite_hp','infinite_mp')") -and $manager.Contains("bbs   = @('exp_multiplier','munny_multiplier','infinite_hp')") -and $manager.Contains("recom = @('exp_multiplier','munny_multiplier','infinite_hp')")
$checks['GUI nombra puntos Moguri correctamente'] = $manager.Contains('Multiplicador de puntos Moguri')
$failed = 0
foreach ($entry in $checks.GetEnumerator()) {
    if ($entry.Value) { Write-Host "PASS  $($entry.Key)" -ForegroundColor Green }
    else { Write-Host "FAIL  $($entry.Key)" -ForegroundColor Red; $failed++ }
}
if ($failed -gt 0) { exit 1 }
