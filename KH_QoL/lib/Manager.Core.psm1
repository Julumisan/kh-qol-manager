Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$script:LuaBackendVersion = 'v1.9.1-hook'
$script:LuaBackendDllHash = '224474E2333776627E39EB715B2EDC9AF521940C9254B8280B7D286BEA646E39'
$script:LuaBackendZipHash = '61889FF6F7AF080D9F65DB8C5DED8E3521311999AAA23E2B62D9CF172D818FD0'
$script:LuaBackendZipUrl = 'https://github.com/Sirius902/LuaBackend/releases/download/v1.9.1-hook/DBGHELP.zip'
$script:ModVersion = '0.1.0-beta'

# --- Language -----------------------------------------------------------------
$script:Lang = 'es'
$script:Messages = @{
    preset_unknown    = @{ en = 'Unknown preset: {0}'; es = 'Preset desconocido: {0}' }
    not_numeric       = @{ en = '{0} is not a number; {1} was used.'; es = '{0} no es numérico; se usó {1}.' }
    clamped           = @{ en = '{0} was limited to {1}.'; es = '{0} se limitó a {1}.' }
    missing_section   = @{ en = 'Section {0} was missing; safe values restored.'; es = 'Faltaba la sección {0}; se restauraron valores seguros.' }
    migrated          = @{ en = 'Settings migrated to the multi-game v2 format.'; es = 'Configuración migrada al formato multijuego v2.' }
    no_settings       = @{ en = 'settings.json does not exist.'; es = 'No existe settings.json.' }
    invalid_json      = @{ en = 'The settings file was invalid; safe values were restored and a copy of the broken file was kept.'; es = 'El JSON era inválido; se restauraron valores seguros y se guardó una copia del archivo defectuoso.' }
    game_running      = @{ en = 'Close Kingdom Hearts and the collection launcher first.'; es = 'Cierra Kingdom Hearts y el launcher antes de continuar.' }
    bad_builds        = @{ en = 'Unsupported game builds: {0}. The hook was not installed.'; es = 'Builds no compatibles: {0}. No se ha instalado el hook.' }
    lb_download       = @{ en = 'Could not download LuaBackend ({0}). Download DBGHELP.zip from {1} and put it in {2}, then press Install again.'; es = 'No se pudo descargar LuaBackend ({0}). Descarga DBGHELP.zip de {1}, ponlo en {2} y pulsa Instalar de nuevo.' }
    lb_zip_checksum   = @{ en = 'DBGHELP.zip does not match the official release (SHA-256 {0}); it was not used.'; es = 'DBGHELP.zip no coincide con la release oficial (SHA-256 {0}); no se ha usado.' }
    lb_dll_checksum   = @{ en = 'Unexpected LuaBackend DLL checksum: {0}'; es = 'Checksum de LuaBackend incorrecto: {0}' }
    file_changed      = @{ en = 'This file changed after installation and will not be overwritten: {0}'; es = 'El archivo cambió después de la instalación y no se sobrescribirá: {0}' }
    foreign_dll       = @{ en = 'Another DBGHELP.dll (another mod) is already present; it is left untouched to avoid conflicts.'; es = 'Ya existe un DBGHELP.dll ajeno. Se deja intacto para evitar conflictos con otro mod.' }
    un_no_manifest    = @{ en = 'No install manifest: nothing was removed.'; es = 'No existe manifiesto: no se eliminó ningún archivo.' }
    un_absent         = @{ en = 'Already absent: {0}'; es = 'Ya ausente: {0}' }
    un_kept           = @{ en = 'Kept because it changed after installation: {0}'; es = 'Conservado por haber cambiado desde la instalación: {0}' }
    un_restored       = @{ en = 'Restored: {0}'; es = 'Restaurado: {0}' }
    un_removed        = @{ en = 'Removed: {0}'; es = 'Eliminado: {0}' }
    saves_no_dir      = @{ en = 'Steam save folder not found (or there are several accounts).'; es = 'No se encontró la carpeta de saves de Steam (o hay varias cuentas).' }
    saves_verify      = @{ en = 'The profile copy could not be verified; check backup\save-switch.'; es = 'La copia del perfil no se verificó; revisa backup\save-switch.' }
}

function Get-KHDefaultLanguage {
    try { if ((Get-UICulture).TwoLetterISOLanguageName -eq 'es') { return 'es' } } catch {}
    return 'en'
}

function Set-KHQoLLanguage {
    param([string]$Language)
    if ($Language -eq 'en' -or $Language -eq 'es') { $script:Lang = $Language } else { $script:Lang = Get-KHDefaultLanguage }
}

function Get-KHQoLLanguage { return $script:Lang }

function Get-KHText {
    param([Parameter(Mandatory=$true)][string]$Key, [object[]]$Format = @())
    $entry = $script:Messages[$Key]
    if ($null -eq $entry) { return $Key }
    $text = $entry[$script:Lang]
    if ($Format.Count -gt 0) { return ($text -f $Format) }
    return $text
}

function Get-KHQoLModVersion { return $script:ModVersion }
$script:GameCatalog = [ordered]@{
    kh1 = [ordered]@{ Name='Kingdom Hearts Final Mix'; ShortName='KH1 Final Mix'; Exe='KINGDOM HEARTS FINAL MIX.exe'; Hash='D790746245D26159F3EE0E1060E33B2FA2DE06941850A4AC724F598722884BAC'; Version='Steam Global 1.0.0.1 (mapa 1.0.0.2 de KHPCSpeedrunTools)'; GameId='0xAF71841E' }
    kh2 = [ordered]@{ Name='Kingdom Hearts II Final Mix'; ShortName='KH2 Final Mix'; Exe='KINGDOM HEARTS II FINAL MIX.exe'; Hash='9002B2DE6A1F91A790BD0673DE125D1CF833F7942BFEC827CDCF6BA64D5849ED'; Version='Steam Global 1.0.0.2'; GameId='0x431219CC' }
    bbs = [ordered]@{ Name='Kingdom Hearts Birth by Sleep Final Mix'; ShortName='Birth by Sleep'; Exe='KINGDOM HEARTS Birth by Sleep FINAL MIX.exe'; Hash='375A811243F1F95F786F00318E2E1210DD5881B25BBF0912A0AD8F81650C976C'; Version='Steam Global 1.0.0.1'; GameId='0xBED4B944' }
    recom = [ordered]@{ Name='Kingdom Hearts Re:Chain of Memories'; ShortName='Re:Chain of Memories'; Exe='KINGDOM HEARTS Re_Chain of Memories.exe'; Hash='ACF42E96A168C73301F5C2CC2915D07E6C420F56A59C6286655C970BFEE36BBF'; Version='Steam Global 1.0.0.1'; GameId='0x9E3134F5' }
}

function Get-KHFileSha256 {
    # .NET instead of Get-FileHash: works in restricted/partial PowerShell hosts too.
    param([Parameter(Mandatory=$true)][string]$Path)
    $sha = [Security.Cryptography.SHA256]::Create()
    $stream = [IO.File]::OpenRead($Path)
    try { return ([BitConverter]::ToString($sha.ComputeHash($stream)) -replace '-', '') }
    finally { $stream.Dispose(); $sha.Dispose() }
}

function Get-KHQoLRoot { return (Split-Path -Parent $PSScriptRoot) }

function Get-KHQoLGameCatalog {
    $copy = [ordered]@{}
    foreach ($entry in $script:GameCatalog.GetEnumerator()) { $copy[$entry.Key] = [pscustomobject]$entry.Value }
    return $copy
}

function Write-KHQoLLog {
    param([Parameter(Mandatory=$true)][string]$Message, [string]$Level = 'INFO', [string]$Root = (Get-KHQoLRoot))
    $logDir = Join-Path $Root 'logs'
    if (-not (Test-Path -LiteralPath $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
    $line = '{0} [{1}] {2}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Level.ToUpperInvariant(), $Message
    Add-Content -LiteralPath (Join-Path $logDir ('manager-{0}.log' -f (Get-Date -Format 'yyyyMMdd'))) -Value $line -Encoding UTF8
}

function Get-GameBuildInfo {
    param([string]$GameDirectory = (Split-Path -Parent (Get-KHQoLRoot)), [ValidateSet('kh1','kh2','bbs','recom')][string]$GameId = 'kh1')
    $game = $script:GameCatalog[$GameId]
    $exe = Join-Path $GameDirectory $game.Exe
    if (-not (Test-Path -LiteralPath $exe -PathType Leaf)) {
        return [pscustomobject]@{ Id=$GameId; Name=$game.Name; Exists=$false; Supported=$false; Path=$exe; Hash=$null; ExpectedHash=$game.Hash; Size=$null; FileVersion=$null; ProductVersion=$null; Reason="No se encontró el ejecutable de $($game.ShortName)." }
    }
    $item = Get-Item -LiteralPath $exe
    $hash = (Get-KHFileSha256 $exe)
    $supported = $hash -eq $game.Hash
    [pscustomobject]@{
        Id=$GameId; Name=$game.Name; Exists=$true; Supported=$supported; Path=$exe; Hash=$hash; ExpectedHash=$game.Hash; Size=$item.Length
        FileVersion=$item.VersionInfo.FileVersion; ProductVersion=$item.VersionInfo.ProductVersion
        Reason=$(if ($supported) { "$($game.Version) compatible." } else { 'Hash desconocido: los parches quedan desactivados.' })
    }
}

function Get-AllGameBuildInfo {
    param([string]$GameDirectory = (Split-Path -Parent (Get-KHQoLRoot)))
    $result = [ordered]@{}
    foreach ($id in $script:GameCatalog.Keys) { $result[$id] = Get-GameBuildInfo $GameDirectory $id }
    return $result
}

function New-GameSettings {
    param([string]$Preset = 'Vanilla')
    [ordered]@{
        preset = $Preset
        exp_multiplier = 1.0; munny_multiplier = 1.0; drop_multiplier = 1.0; pickup_radius_multiplier = 1.0
        player_hp_multiplier = 1.0; mp_multiplier = 1.0; player_damage_multiplier = 1.0; damage_received_multiplier = 1.0
        enemy_hp_multiplier = 1.0; boss_hp_multiplier = 1.0; enemy_damage_multiplier = 1.0
        movement_speed_multiplier = 1.0; jump_multiplier = 1.0
        infinite_hp = $false; infinite_mp = $false; one_hit_enemies = $false; one_hit_bosses = $false
        invulnerability = $false; save_anywhere = $false; instant_retry = $false; faster_text = $false; automatic_pickup = $false
        multiply_shop_sales = $false; instant_gummi = $false
    }
}

function New-DefaultSettings {
    $kh1 = New-GameSettings 'Dad Mode'
    $kh1.exp_multiplier = 2.0; $kh1.munny_multiplier = 3.0; $kh1.drop_multiplier = 3.0; $kh1.pickup_radius_multiplier = 3.0
    $kh1.movement_speed_multiplier = 1.5; $kh1.faster_text = $true
    [ordered]@{ schema_version=2; ui_language=''; kh1=$kh1; kh2=(New-GameSettings); bbs=(New-GameSettings); recom=(New-GameSettings) }
}

function Get-PresetData {
    param([Parameter(Mandatory=$true)][string]$Name, [string]$Root = (Get-KHQoLRoot))
    $path = Join-Path $Root 'config\presets.json'
    $all = Get-Content -Raw -LiteralPath $path | ConvertFrom-Json
    $preset = $all.presets.PSObject.Properties | Where-Object { $_.Name -eq $Name } | Select-Object -First 1
    if ($null -eq $preset) { throw (Get-KHText 'preset_unknown' @($Name)) }
    return $preset.Value
}

function Get-ObjectValue {
    param($Object,[string]$Name,$Default)
    if ($Object -is [Collections.IDictionary] -and $Object.Contains($Name)) { return $Object[$Name] }
    if ($null -ne $Object) { $prop = $Object.PSObject.Properties[$Name]; if ($null -ne $prop) { return $prop.Value } }
    return $Default
}

function ConvertTo-SafeDouble {
    param($Value, [double]$Default, [double]$Minimum, [double]$Maximum, [string]$Name, [System.Collections.Generic.List[string]]$Warnings)
    $number = 0.0; $styles = [Globalization.NumberStyles]::Float; $ok = $false
    if ($Value -is [ValueType]) { try { $number = [Convert]::ToDouble($Value, [Globalization.CultureInfo]::InvariantCulture); $ok = $true } catch {} }
    if (-not $ok -and $null -ne $Value) {
        $ok = [double]::TryParse([string]$Value, $styles, [Globalization.CultureInfo]::InvariantCulture, [ref]$number)
        if (-not $ok) { $ok = [double]::TryParse([string]$Value, $styles, [Globalization.CultureInfo]::CurrentCulture, [ref]$number) }
    }
    if (-not $ok -or [double]::IsNaN($number) -or [double]::IsInfinity($number)) { $Warnings.Add((Get-KHText 'not_numeric' @($Name, $Default))); return $Default }
    if ($number -lt $Minimum) { $Warnings.Add((Get-KHText 'clamped' @($Name, $Minimum))); return $Minimum }
    if ($number -gt $Maximum) { $Warnings.Add((Get-KHText 'clamped' @($Name, $Maximum))); return $Maximum }
    return $number
}

function ConvertTo-SafeBool {
    param($Value, [bool]$Default=$false)
    if ($Value -is [bool]) { return $Value }
    $parsed = $false
    if ($null -ne $Value -and [bool]::TryParse([string]$Value, [ref]$parsed)) { return $parsed }
    return $Default
}

function Test-AndNormalizeSettings {
    param([Parameter(Mandatory=$true)]$Settings)
    $warnings = New-Object 'System.Collections.Generic.List[string]'
    $result = New-DefaultSettings
    $schema = Get-ObjectValue $Settings 'schema_version' 1
    $legacyPreset = Get-ObjectValue $Settings 'preset' 'Dad Mode'
    $ranges = [ordered]@{
        exp_multiplier=@(0.1,100.0); munny_multiplier=@(0.0,100.0); drop_multiplier=@(0.0,100.0); pickup_radius_multiplier=@(1.0,100.0)
        player_hp_multiplier=@(0.5,3.0); mp_multiplier=@(0.5,3.0); player_damage_multiplier=@(0.0,100.0); damage_received_multiplier=@(0.0,100.0)
        enemy_hp_multiplier=@(0.1,10.0); boss_hp_multiplier=@(0.1,100.0); enemy_damage_multiplier=@(0.0,100.0); movement_speed_multiplier=@(0.5,2.0); jump_multiplier=@(0.5,3.0)
    }
    $bools = @('infinite_hp','infinite_mp','one_hit_enemies','one_hit_bosses','invulnerability','save_anywhere','instant_retry','faster_text','automatic_pickup','multiply_shop_sales','instant_gummi')
    foreach ($id in $script:GameCatalog.Keys) {
        $defaults = New-GameSettings $(if ($id -eq 'kh1') { 'Dad Mode' } else { 'Vanilla' })
        $source = Get-ObjectValue $Settings $id $null
        if ($null -eq $source) { $source = [pscustomobject]$defaults; $warnings.Add((Get-KHText 'missing_section' @($id))) }
        $presetFallback = if ([int]$schema -lt 2 -and $id -eq 'kh1') { [string]$legacyPreset } else { [string]$defaults.preset }
        $result[$id].preset = [string](Get-ObjectValue $source 'preset' $presetFallback)
        foreach ($name in $ranges.Keys) {
            $value = Get-ObjectValue $source $name $defaults[$name]
            $result[$id][$name] = ConvertTo-SafeDouble $value $defaults[$name] $ranges[$name][0] $ranges[$name][1] "$id.$name" $warnings
        }
        foreach ($name in $bools) { $result[$id][$name] = ConvertTo-SafeBool (Get-ObjectValue $source $name $defaults[$name]) }
    }
    $language = [string](Get-ObjectValue $Settings 'ui_language' '')
    $result.ui_language = if ($language -eq 'en' -or $language -eq 'es') { $language } else { '' }
    if ([int]$schema -lt 2) { $warnings.Add((Get-KHText 'migrated')) }
    [pscustomobject]@{ Settings=$result; Warnings=$warnings.ToArray() }
}

function Import-KHQoLSettings {
    param([string]$Root = (Get-KHQoLRoot))
    $path = Join-Path $Root 'config\settings.json'
    try {
        if (-not (Test-Path -LiteralPath $path)) { throw (Get-KHText 'no_settings') }
        return (Test-AndNormalizeSettings (Get-Content -Raw -LiteralPath $path | ConvertFrom-Json))
    } catch {
        $configDir = Split-Path -Parent $path
        if (-not (Test-Path -LiteralPath $configDir)) { New-Item -ItemType Directory -Path $configDir -Force | Out-Null }
        if (Test-Path -LiteralPath $path) { Copy-Item -LiteralPath $path -Destination (Join-Path $configDir ('settings.invalid-{0}.json' -f (Get-Date -Format 'yyyyMMdd-HHmmss-fff'))) }
        Write-KHQoLLog "Configuración inválida; restaurados valores seguros. $($_.Exception.Message)" 'WARN' $Root
        return [pscustomobject]@{ Settings=(New-DefaultSettings); Warnings=@((Get-KHText 'invalid_json')) }
    }
}

function ConvertTo-LuaLiteral {
    param($Value)
    if ($Value -is [bool]) { if ($Value) { return 'true' } else { return 'false' } }
    if ($Value -is [string]) { return '"' + ($Value.Replace('\','\\').Replace('"','\"')) + '"' }
    return ([Convert]::ToDouble($Value, [Globalization.CultureInfo]::InvariantCulture)).ToString('0.########', [Globalization.CultureInfo]::InvariantCulture)
}

function Export-KHQoLRuntimeConfig {
    param([Parameter(Mandatory=$true)]$Settings, [string]$Root = (Get-KHQoLRoot), [string]$GameDirectory = (Split-Path -Parent (Get-KHQoLRoot)))
    $paths = [ordered]@{}
    foreach ($id in $script:GameCatalog.Keys) {
        $build = Get-GameBuildInfo $GameDirectory $id
        $path = Join-Path $Root "scripts\$id\io_packages\kh_qol\runtime.lua"
        $dir = Split-Path -Parent $path
        if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
        $lines = New-Object 'System.Collections.Generic.List[string]'
        $lines.Add('-- Generated by KH QoL Manager. Edit config/settings.json through the manager.')
        $lines.Add('return {'); $lines.Add('  schema_version = 2,'); $lines.Add(('  game = {0},' -f (ConvertTo-LuaLiteral $id)))
        $lines.Add(('  preset = {0},' -f (ConvertTo-LuaLiteral ([string]$Settings[$id].preset))))
        $lines.Add(('  build_hash = {0},' -f (ConvertTo-LuaLiteral ([string]$build.Hash))))
        $lines.Add(('  build_authorized = {0},' -f (ConvertTo-LuaLiteral ([bool]$build.Supported))))
        foreach ($p in $Settings[$id].GetEnumerator()) { if ($p.Key -ne 'preset') { $lines.Add(('  {0} = {1},' -f $p.Key, (ConvertTo-LuaLiteral $p.Value))) } }
        $lines.Add('}')
        [IO.File]::WriteAllLines($path, $lines.ToArray(), (New-Object Text.UTF8Encoding($false)))
        $paths[$id] = $path
    }
    return $paths
}

function Save-KHQoLSettings {
    param([Parameter(Mandatory=$true)]$Settings, [string]$Root = (Get-KHQoLRoot), [string]$GameDirectory = (Split-Path -Parent (Get-KHQoLRoot)))
    $validation = Test-AndNormalizeSettings ([pscustomobject]$Settings)
    $path = Join-Path $Root 'config\settings.json'; $dir = Split-Path -Parent $path
    if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $temp = "$path.tmp"
    $validation.Settings | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $temp -Encoding UTF8
    Move-Item -LiteralPath $temp -Destination $path -Force
    $runtimes = Export-KHQoLRuntimeConfig $validation.Settings $Root $GameDirectory
    $summary = ($script:GameCatalog.Keys | ForEach-Object { "$_=$($validation.Settings[$_].preset)" }) -join '; '
    Write-KHQoLLog "Configuración multijuego guardada: $summary" 'INFO' $Root
    [pscustomobject]@{ Settings=$validation.Settings; Warnings=$validation.Warnings; Path=$path; RuntimePaths=$runtimes; RuntimePath=$runtimes.kh1 }
}

function Get-LuaBackendStatus {
    param([string]$GameDirectory = (Split-Path -Parent (Get-KHQoLRoot)))
    $dll = Join-Path $GameDirectory 'DBGHELP.dll'; $toml = Join-Path $GameDirectory 'LuaBackend.toml'
    $dllHash = if (Test-Path -LiteralPath $dll) { (Get-KHFileSha256 $dll) } else { $null }
    [pscustomobject]@{ Installed=((Test-Path -LiteralPath $dll) -and (Test-Path -LiteralPath $toml)); DllKnown=($dllHash -eq $script:LuaBackendDllHash); DllHash=$dllHash; DllPath=$dll; ConfigPath=$toml; Version=$script:LuaBackendVersion }
}

function Test-GameNotRunning {
    $names = @('KINGDOM HEARTS FINAL MIX','KINGDOM HEARTS II FINAL MIX','KINGDOM HEARTS Birth by Sleep FINAL MIX','KINGDOM HEARTS Re_Chain of Memories','KINGDOM HEARTS HD 1.5+2.5 Launcher','KINGDOM HEARTS HD 1.5+2.5 ReMIX')
    foreach ($name in $names) { if (Get-Process -Name $name -ErrorAction SilentlyContinue) { throw (Get-KHText 'game_running') } }
}

function ConvertTo-TomlPath { param([string]$Path) return $Path.Replace('\','\\').Replace('"','\"') }

# Official LuaBackend release asset: taken from KH_QoL\vendor if present,
# otherwise downloaded from the GitHub release. Both the ZIP and the DLL must
# match the published SHA-256; LuaBackend (GPL-3.0) is never bundled.
function Get-LuaBackendDll {
    param([string]$Root = (Get-KHQoLRoot))
    $vendorDir = Join-Path $Root 'vendor\LuaBackend-v1.9.1-hook'
    $zip = Join-Path $vendorDir 'DBGHELP.zip'
    $dll = Join-Path $vendorDir 'extracted\DBGHELP.dll'
    if ((Test-Path -LiteralPath $dll) -and (Get-KHFileSha256 $dll) -eq $script:LuaBackendDllHash) { return $dll }
    New-Item -ItemType Directory -Force -Path $vendorDir | Out-Null
    if (-not (Test-Path -LiteralPath $zip)) {
        $temp = "$zip.download"
        try {
            [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
            Invoke-WebRequest -Uri $script:LuaBackendZipUrl -OutFile $temp -UseBasicParsing
        } catch {
            if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Force }
            throw (Get-KHText 'lb_download' @($_.Exception.Message, $script:LuaBackendZipUrl, $vendorDir))
        }
        Move-Item -LiteralPath $temp -Destination $zip -Force
    }
    $zipHash = Get-KHFileSha256 $zip
    if ($zipHash -ne $script:LuaBackendZipHash) {
        Remove-Item -LiteralPath $zip -Force
        throw (Get-KHText 'lb_zip_checksum' @($zipHash))
    }
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $archive = [IO.Compression.ZipFile]::OpenRead($zip)
    try {
        $entry = $archive.Entries | Where-Object { $_.Name -eq 'DBGHELP.dll' } | Select-Object -First 1
        if ($null -eq $entry) { throw (Get-KHText 'lb_zip_checksum' @($zipHash)) }
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dll) | Out-Null
        [IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $dll, $true)
    } finally { $archive.Dispose() }
    $dllHash = Get-KHFileSha256 $dll
    if ($dllHash -ne $script:LuaBackendDllHash) { Remove-Item -LiteralPath $dll -Force; throw (Get-KHText 'lb_dll_checksum' @($dllHash)) }
    return $dll
}

function Install-KHQoL {
    param([string]$Root = (Get-KHQoLRoot), [string]$GameDirectory = (Split-Path -Parent (Get-KHQoLRoot)), [switch]$SkipBuildCheck)
    Test-GameNotRunning
    $builds = Get-AllGameBuildInfo $GameDirectory
    if (-not $SkipBuildCheck) {
        $bad = @($builds.GetEnumerator() | Where-Object { -not $_.Value.Supported })
        if ($bad.Count -gt 0) { throw (Get-KHText 'bad_builds' @((($bad | ForEach-Object { $_.Value.Name }) -join ', '))) }
    }
    $vendorDll = Get-LuaBackendDll $Root
    $backupDir = Join-Path $Root 'backup\original'; $manifestDir = Join-Path $Root 'uninstall'
    New-Item -ItemType Directory -Path $backupDir,$manifestDir -Force | Out-Null
    $manifestPath = Join-Path $manifestDir 'install-manifest.json'
    $previousManifest = if (Test-Path -LiteralPath $manifestPath) { Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json } else { $null }
    $records = New-Object 'System.Collections.Generic.List[object]'
    $dllTarget = Join-Path $GameDirectory 'DBGHELP.dll'; $tomlTarget = Join-Path $GameDirectory 'LuaBackend.toml'
    foreach ($target in @($dllTarget,$tomlTarget)) {
        $exists = Test-Path -LiteralPath $target; $originalHash = if ($exists) { (Get-KHFileSha256 $target) } else { $null }
        $old = if ($null -ne $previousManifest) { $previousManifest.files | Where-Object { [string]$_.target -eq $target } | Select-Object -First 1 } else { $null }
        if ($null -ne $old) {
            if ($exists -and $originalHash -ne ([string]$old.installed_hash).ToUpperInvariant()) { throw (Get-KHText 'file_changed' @($target)) }
            $records.Add([ordered]@{ target=$target; existed_before=[bool]$old.existed_before; original_hash=$old.original_hash; backup=$old.backup; installed_hash=$null })
        } else {
            $backup = Join-Path $backupDir ([IO.Path]::GetFileName($target))
            if ($exists -and $target -eq $dllTarget -and $originalHash -ne $script:LuaBackendDllHash) { throw (Get-KHText 'foreign_dll') }
            if ($exists -and -not (Test-Path -LiteralPath $backup)) { Copy-Item -LiteralPath $target -Destination $backup }
            $records.Add([ordered]@{ target=$target; existed_before=[bool]$exists; original_hash=$originalHash; backup=$(if ($exists) {$backup} else {$null}); installed_hash=$null })
        }
    }
    Copy-Item -LiteralPath $vendorDll -Destination $dllTarget -Force
    $sections = New-Object 'System.Collections.Generic.List[string]'
    foreach ($id in $script:GameCatalog.Keys) {
        $g = $script:GameCatalog[$id]; $scriptPath = ConvertTo-TomlPath (Join-Path $Root "scripts\$id")
        $sections.Add("[$id]`nscripts = [{ path = `"$scriptPath`", relative = false }]`nexe = `"$($g.Exe)`"`ngame_docs = `"My Games/KINGDOM HEARTS HD 1.5+2.5 ReMIX`"")
    }
    $sections.Add("[kh3d]`nscripts = []`nexe = `"KINGDOM HEARTS Dream Drop Distance.exe`"`ngame_docs = `"My Games/KINGDOM HEARTS HD 2.8 Final Chapter Prologue`"")
    [IO.File]::WriteAllText($tomlTarget, ($sections -join "`n`n") + "`n", (New-Object Text.UTF8Encoding($false)))
    foreach ($record in $records) { $record.installed_hash = (Get-KHFileSha256 $record.target) }
    $hashes = [ordered]@{}; foreach ($id in $script:GameCatalog.Keys) { $hashes[$id] = $builds[$id].Hash }
    $manifest = [ordered]@{ schema_version=2; installed_at=(Get-Date).ToString('o'); luabackend_version=$script:LuaBackendVersion; game_hashes=$hashes; files=$records.ToArray() }
    $manifest | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $manifestPath -Encoding UTF8
    $loaded = Import-KHQoLSettings $Root; Save-KHQoLSettings $loaded.Settings $Root $GameDirectory | Out-Null
    Write-KHQoLLog "Instalado LuaBackend $script:LuaBackendVersion para kh1, kh2, bbs y recom." 'INFO' $Root
    return Get-LuaBackendStatus $GameDirectory
}

function Uninstall-KHQoL {
    param([string]$Root = (Get-KHQoLRoot), [string]$GameDirectory = (Split-Path -Parent (Get-KHQoLRoot)))
    Test-GameNotRunning
    $manifestPath = Join-Path $Root 'uninstall\install-manifest.json'
    if (-not (Test-Path -LiteralPath $manifestPath)) { return [pscustomobject]@{ Changed=$false; Kept=@(); Messages=@((Get-KHText 'un_no_manifest')) } }
    $manifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json; $messages = New-Object 'System.Collections.Generic.List[string]'; $kept = New-Object 'System.Collections.Generic.List[string]'
    foreach ($file in $manifest.files) {
        $target = [string]$file.target
        if (-not (Test-Path -LiteralPath $target)) { $messages.Add((Get-KHText 'un_absent' @($target))); continue }
        $current = (Get-KHFileSha256 $target)
        if ($current -ne ([string]$file.installed_hash).ToUpperInvariant()) { $messages.Add((Get-KHText 'un_kept' @($target))); $kept.Add($target); continue }
        if ([bool]$file.existed_before -and $file.backup -and (Test-Path -LiteralPath ([string]$file.backup))) { Copy-Item -LiteralPath ([string]$file.backup) -Destination $target -Force; $messages.Add((Get-KHText 'un_restored' @($target))) }
        else { Remove-Item -LiteralPath $target -Force; $messages.Add((Get-KHText 'un_removed' @($target))) }
    }
    Write-KHQoLLog ('Desinstalación: ' + ($messages -join ' | ')) 'INFO' $Root
    [pscustomobject]@{ Changed=$true; Kept=$kept.ToArray(); Messages=$messages.ToArray() }
}

# --- KH1 save profiles (Partida / Pruebas) -----------------------------------
# Only the KH1 container is switched; other games' saves are never touched.
$script:SaveProfiles = @('Partida','Pruebas')
$script:SaveFileName = 'KHFM_WW.png'

function Get-KHSaveDirectory {
    param([string]$Documents = ([Environment]::GetFolderPath('MyDocuments')))
    $steamRoot = Join-Path $Documents 'My Games\KINGDOM HEARTS HD 1.5+2.5 ReMIX\Steam'
    if (-not (Test-Path -LiteralPath $steamRoot)) { return $null }
    $ids = @(Get-ChildItem -LiteralPath $steamRoot -Directory | Where-Object { $_.Name -match '^7656119\d{10}$' })
    if ($ids.Count -ne 1) { return $null }
    return $ids[0].FullName
}

function Get-KHSaveProfileStatus {
    param([string]$Root = (Get-KHQoLRoot), [string]$SaveDir = (Get-KHSaveDirectory))
    $profileRoot = Join-Path $Root 'save_profiles'
    $activeFile = Join-Path $profileRoot 'active.txt'
    $active = 'Partida'
    if (Test-Path -LiteralPath $activeFile) {
        $value = (Get-Content -LiteralPath $activeFile -Raw -Encoding UTF8).Trim()
        if ($script:SaveProfiles -contains $value) { $active = $value }
    }
    $other = @($script:SaveProfiles | Where-Object { $_ -ne $active })[0]
    [pscustomobject]@{
        Active = $active; Other = $other; SaveDir = $SaveDir; ProfileRoot = $profileRoot
        OtherHasFile = (Test-Path -LiteralPath (Join-Path (Join-Path $profileRoot $other) $script:SaveFileName))
    }
}

function Switch-KHSaveProfile {
    param([string]$Root = (Get-KHQoLRoot), [string]$SaveDir = (Get-KHSaveDirectory), [switch]$SkipProcessCheck)
    if (-not $SaveDir -or -not (Test-Path -LiteralPath $SaveDir)) { throw (Get-KHText 'saves_no_dir') }
    if (-not $SkipProcessCheck) { Test-GameNotRunning }
    $status = Get-KHSaveProfileStatus $Root $SaveDir
    $live = Join-Path $SaveDir $script:SaveFileName
    $activeDir = Join-Path $status.ProfileRoot $status.Active
    $targetFile = Join-Path (Join-Path $status.ProfileRoot $status.Other) $script:SaveFileName
    New-Item -ItemType Directory -Force -Path $activeDir | Out-Null

    if (Test-Path -LiteralPath $live) {
        # Rotating safety copy, then keep the current progress in its profile.
        $backupDir = Join-Path $Root 'backup\save-switch'
        New-Item -ItemType Directory -Force -Path $backupDir | Out-Null
        Copy-Item -LiteralPath $live -Destination (Join-Path $backupDir ('KHFM_WW_{0}_{1}.png' -f $status.Active, (Get-Date -Format 'yyyyMMdd-HHmmss-fff')))
        Get-ChildItem -LiteralPath $backupDir -Filter 'KHFM_WW_*.png' | Sort-Object LastWriteTime -Descending | Select-Object -Skip 6 | Remove-Item -Force
        Copy-Item -LiteralPath $live -Destination (Join-Path $activeDir $script:SaveFileName) -Force
    }
    if (Test-Path -LiteralPath $targetFile) {
        Copy-Item -LiteralPath $targetFile -Destination $live -Force
        if ((Get-KHFileSha256 $live) -ne (Get-KHFileSha256 $targetFile)) { throw (Get-KHText 'saves_verify') }
    } elseif (Test-Path -LiteralPath $live) {
        # New profile: the game creates a fresh container on its next start.
        Remove-Item -LiteralPath $live -Force
    }
    Set-Content -LiteralPath (Join-Path $status.ProfileRoot 'active.txt') -Value $status.Other -Encoding UTF8
    Write-KHQoLLog ("Saves de KH1: perfil '{0}' activo (antes '{1}')" -f $status.Other, $status.Active) 'INFO' $Root
    return (Get-KHSaveProfileStatus $Root $SaveDir)
}

# Default language: the Windows UI language (the GUI may override it).
Set-KHQoLLanguage ''

Export-ModuleMember -Function Get-KHDefaultLanguage,Set-KHQoLLanguage,Get-KHQoLLanguage,Get-KHText,Get-KHQoLModVersion,Get-LuaBackendDll,Get-KHFileSha256,Get-KHQoLRoot,Get-KHQoLGameCatalog,Write-KHQoLLog,Get-GameBuildInfo,Get-AllGameBuildInfo,New-GameSettings,New-DefaultSettings,Get-PresetData,Test-AndNormalizeSettings,Import-KHQoLSettings,Save-KHQoLSettings,Export-KHQoLRuntimeConfig,Get-LuaBackendStatus,Install-KHQoL,Uninstall-KHQoL,Get-KHSaveDirectory,Get-KHSaveProfileStatus,Switch-KHSaveProfile
