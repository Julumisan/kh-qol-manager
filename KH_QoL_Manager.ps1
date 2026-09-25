[CmdletBinding()]
param(
    [switch]$Install,
    [switch]$Uninstall,
    [switch]$Validate,
    [switch]$NoGui,
    [switch]$SwitchSaves,
    [ValidateSet('', 'en', 'es')][string]$Lang = ''
)

$ErrorActionPreference = 'Stop'
$gameDirectory = $PSScriptRoot
$projectRoot = Join-Path $gameDirectory 'KH_QoL'
Import-Module (Join-Path $projectRoot 'lib\Manager.Core.psm1') -Force

$loaded = Import-KHQoLSettings $projectRoot
$script:settings = $loaded.Settings
Set-KHQoLLanguage $(if ($Lang) { $Lang } else { [string]$script:settings.ui_language })

# --- UI text (English / Spanish) ------------------------------------------------
$script:UiText = @{
    window_title   = @{ en = 'KH QoL Manager {0} — KINGDOM HEARTS HD 1.5+2.5 ReMIX'; es = 'KH QoL Manager {0} — KINGDOM HEARTS HD 1.5+2.5 ReMIX' }
    header         = @{ en = 'KH QoL — independent settings for the whole collection'; es = 'KH QoL — configuración independiente para toda la colección' }
    language       = @{ en = 'Language:'; es = 'Idioma:' }
    compatible     = @{ en = 'compatible'; es = 'compatible' }
    blocked        = @{ en = 'BLOCKED'; es = 'BLOQUEADO' }
    hook_ok        = @{ en = 'LuaBackend {0} installed and verified'; es = 'LuaBackend {0} instalado y verificado' }
    hook_unknown   = @{ en = 'A hook is present but its DLL is unknown'; es = 'Hook presente pero DLL desconocida' }
    hook_missing   = @{ en = 'LuaBackend is not installed yet — press "Install / repair"'; es = 'LuaBackend no está instalado — pulsa "Instalar / reparar"' }
    status_tail    = @{ en = '. Each game keeps its own settings.'; es = '. Cada juego conserva su propia configuración.' }
    build_ok       = @{ en = 'Supported game version (Steam).'; es = 'Versión del juego compatible (Steam).' }
    build_bad      = @{ en = 'Unsupported game version (probably a game update): this game is left untouched until the mod is updated.'; es = 'Versión del juego no compatible (probablemente una actualización): no se toca este juego hasta que se actualice el mod.' }
    preset         = @{ en = 'Preset:'; es = 'Preset:' }
    vanilla_btn    = @{ en = 'Vanilla for this game'; es = 'Vanilla en este juego' }
    exp_banner     = @{ en = 'Beta: the options for this game have not been tested in play yet.'; es = 'Beta: las opciones de este juego aún no se han probado en partida.' }
    saves_btn      = @{ en = 'Saves: {0}  →  switch to {1}'; es = 'Saves: {0}  →  cambiar a {1}' }
    saves_q        = @{ en = "The current KH1 save container will be stored in profile '{0}' and '{1}' will be activated.`r`nClose Kingdom Hearts first. Other games' saves are not touched. Continue?"; es = "Se guardará el contenedor actual de KH1 en el perfil '{0}' y se activará '{1}'.`r`nCierra Kingdom Hearts antes. Los saves de otros juegos no se tocan. ¿Continuar?" }
    saves_title    = @{ en = 'KH1 saves'; es = 'Saves de KH1' }
    saves_done     = @{ en = "KH1 saves: profile '{0}' is active."; es = "Saves de KH1: perfil '{0}' activo." }
    profile_Partida = @{ en = 'Main'; es = 'Partida' }
    profile_Pruebas = @{ en = 'Testing'; es = 'Pruebas' }
    save_btn       = @{ en = 'Save all'; es = 'Guardar todos' }
    saved          = @{ en = 'Saved: each game keeps its own tab and preset.'; es = 'Guardado: cada juego conserva su pestaña y su preset.' }
    install_btn    = @{ en = 'Install / repair'; es = 'Instalar / reparar' }
    installed      = @{ en = 'LuaBackend and the four script folders were installed/verified.'; es = 'LuaBackend y las cuatro carpetas de scripts se instalaron/verificaron.' }
    uninstall_btn  = @{ en = 'Uninstall hook'; es = 'Desinstalar hook' }
    uninstall_q    = @{ en = 'Only the LuaBackend files installed by this project will be removed. Saves and other mods are not touched. Continue?'; es = 'Se quitarán sólo los archivos de LuaBackend instalados por este proyecto. No se tocarán partidas ni mods ajenos. ¿Continuar?' }
    uninstall_t    = @{ en = 'Uninstall'; es = 'Desinstalar' }
    launch_btn     = @{ en = 'Save and open Steam'; es = 'Guardar y abrir Steam' }
    launched       = @{ en = 'Settings saved. Pick any game in the collection launcher.'; es = 'Ajustes guardados. Elige cualquier juego en el launcher de la colección.' }
    footer         = @{ en = 'F2: LuaBackend console. After saving you can start the game from Steam as usual.'; es = 'F2: consola de LuaBackend. Tras guardar puedes abrir el juego desde Steam como siempre.' }
    sec_progress   = @{ en = 'Progression / grinding'; es = 'Progresión / grindeo' }
    sec_player     = @{ en = 'Player'; es = 'Jugador' }
    sec_enemies    = @{ en = 'Enemies'; es = 'Enemigos' }
    sec_comfort    = @{ en = 'Convenience'; es = 'Comodidad' }
    sec_gummi      = @{ en = 'Gummi Ship'; es = 'Nave Gummi' }
}

function L([string]$Key, [object[]]$Format = @()) {
    $entry = $script:UiText[$Key]
    if ($null -eq $entry) { return $Key }
    $text = $entry[(Get-KHQoLLanguage)]
    if ($Format.Count -gt 0) { return ($text -f $Format) }
    return $text
}

function LT($pair) { return $pair[(Get-KHQoLLanguage)] }

# --- Features ---------------------------------------------------------------------
# kind, key, caption {en, es}, min, max. Sections only appear if they have rows.
$featureRows = @(
    @('section', 'sec_progress'),
    @('number', 'exp_multiplier', @{ en = 'EXP multiplier'; es = 'Multiplicador de EXP' }, 0.1, 100.0),
    @('number', 'munny_multiplier', @{ en = 'Munny multiplier'; es = 'Multiplicador de Munny' }, 0.0, 100.0),
    @('toggle', 'multiply_shop_sales', @{ en = 'Also multiply shop sales'; es = 'Multiplicar también las ventas en tienda' }),
    @('number', 'drop_multiplier', @{ en = 'Item drop chance'; es = 'Probabilidad de drop' }, 0.0, 100.0),
    @('number', 'pickup_radius_multiplier', @{ en = 'Pickup radius'; es = 'Radio de recogida' }, 1.0, 100.0),
    @('toggle', 'automatic_pickup', @{ en = 'Automatic pickup'; es = 'Recogida automática' }),
    @('section', 'sec_player'),
    @('toggle', 'infinite_hp', @{ en = 'Infinite HP'; es = 'HP infinito' }),
    @('toggle', 'infinite_mp', @{ en = 'Infinite MP'; es = 'MP infinito' }),
    @('number', 'movement_speed_multiplier', @{ en = 'Movement speed'; es = 'Velocidad de movimiento' }, 0.5, 2.0),
    @('number', 'jump_multiplier', @{ en = 'Jump height'; es = 'Salto' }, 0.5, 3.0),
    @('number', 'player_hp_multiplier', @{ en = 'Max HP'; es = 'HP máximo' }, 0.5, 3.0),
    @('number', 'mp_multiplier', @{ en = 'Max MP'; es = 'MP máximo' }, 0.5, 3.0),
    @('section', 'sec_enemies'),
    @('number', 'enemy_hp_multiplier', @{ en = 'Enemy HP (includes bosses)'; es = 'HP de enemigos (incluye jefes)' }, 0.1, 10.0),
    @('section', 'sec_comfort'),
    @('toggle', 'faster_text', @{ en = 'Instant dialogue box transitions'; es = 'Transiciones de diálogo instantáneas' }),
    @('section', 'sec_gummi'),
    @('toggle', 'instant_gummi', @{ en = 'Instant Gummi travel (Warp Drive from the start)'; es = 'Viajes Gummi instantáneos (Warp Drive desde el principio)' })
)

# Only implemented options are listed per game; everything that was researched
# and left out is documented in KH_QoL\docs\FEATURE_RESEARCH.md.
$enabledFeatures = @{
    kh1   = @('exp_multiplier','munny_multiplier','multiply_shop_sales','drop_multiplier','pickup_radius_multiplier','automatic_pickup','infinite_hp','infinite_mp','movement_speed_multiplier','jump_multiplier','player_hp_multiplier','mp_multiplier','enemy_hp_multiplier','faster_text','instant_gummi')
    kh2   = @('exp_multiplier','munny_multiplier','infinite_hp','infinite_mp')
    bbs   = @('exp_multiplier','munny_multiplier','infinite_hp')
    recom = @('exp_multiplier','munny_multiplier','infinite_hp')
}

function D([string]$En, [string]$Es) { return @{ en = $En; es = $Es } }
# One short description per option: what it does, nothing else.
$featureStatus = @{
    kh1 = @{
        exp_multiplier            = D 'Multiplies the EXP you earn.' 'Multiplica la EXP que ganas.'
        munny_multiplier          = D 'Multiplies the value of munny orbs.' 'Multiplica el valor de los orbes de munny.'
        multiply_shop_sales       = D 'Items sell for more, using the munny multiplier.' 'Los objetos se venden más caros, con el multiplicador de munny.'
        drop_multiplier           = D 'Multiplies each enemy''s item drop chance (max. 100%).' 'Multiplica la probabilidad de que cada enemigo suelte objetos (máx. 100 %).'
        pickup_radius_multiplier  = D 'Orbs are pulled in from farther away.' 'Los orbes se atraen desde más lejos.'
        automatic_pickup          = D 'Orbs are collected from almost anywhere nearby.' 'Los orbes se recogen desde casi cualquier sitio cercano.'
        infinite_hp               = D 'HP refills instantly.' 'El HP se rellena al instante.'
        infinite_mp               = D 'MP refills instantly.' 'El MP se rellena al instante.'
        movement_speed_multiplier = D 'Sora, party members and gliding move faster.' 'Sora, los compañeros y el planeo van más rápido.'
        jump_multiplier           = D 'Sora jumps higher.' 'Sora salta más alto.'
        player_hp_multiplier      = D 'Raises Sora''s maximum HP.' 'Aumenta el HP máximo de Sora.'
        mp_multiplier             = D 'Raises Sora''s maximum MP.' 'Aumenta el MP máximo de Sora.'
        enemy_hp_multiplier       = D 'Enemies spawn with more or less HP (bosses too).' 'Los enemigos aparecen con más o menos HP (también los jefes).'
        faster_text               = D 'Dialogue boxes open and close without animation.' 'Los cuadros de diálogo se abren y cierran sin animación.'
        instant_gummi             = D 'Warp to worlds you have already flown to. The first trip to each world is still required.' 'Viaja al instante a mundos ya visitados. El primer viaje a cada mundo sigue siendo obligatorio.'
    }
    kh2 = @{
        exp_multiplier   = D 'Multiplies the EXP you earn.' 'Multiplica la EXP que ganas.'
        munny_multiplier = D 'Multiplies the munny you earn (shop sales too).' 'Multiplica el munny que ganas (también las ventas).'
        infinite_hp      = D 'HP refills instantly.' 'El HP se rellena al instante.'
        infinite_mp      = D 'MP refills instantly.' 'El MP se rellena al instante.'
    }
    bbs = @{
        exp_multiplier   = D 'Multiplies the EXP you earn.' 'Multiplica la EXP que ganas.'
        munny_multiplier = D 'Multiplies the munny you earn (shop sales too).' 'Multiplica el munny que ganas (también las ventas).'
        infinite_hp      = D 'HP refills instantly.' 'El HP se rellena al instante.'
    }
    recom = @{
        exp_multiplier   = D 'Multiplies the EXP you earn.' 'Multiplica la EXP que ganas.'
        munny_multiplier = D 'Multiplies the moogle points you earn (sales too).' 'Multiplica los puntos Moguri que ganas (también las ventas).'
        infinite_hp      = D 'HP refills instantly.' 'El HP se rellena al instante.'
    }
}

function Get-FeatureCaption([string]$gameId, [string]$key, $caption) {
    if ($gameId -eq 'recom' -and $key -eq 'munny_multiplier') { return (LT @{ en = 'Moogle points multiplier'; es = 'Multiplicador de puntos Moguri' }) }
    return (LT $caption)
}

function Get-ProfileName([string]$profile) { return (L ('profile_' + $profile)) }

# --- Window -----------------------------------------------------------------------
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[Windows.Forms.Application]::EnableVisualStyles()

$script:catalog = Get-KHQoLGameCatalog
$form = New-Object Windows.Forms.Form
$form.Size = New-Object Drawing.Size(1080, 820)
$form.MinimumSize = New-Object Drawing.Size(1000, 720)
$form.StartPosition = 'CenterScreen'
$form.Font = New-Object Drawing.Font('Segoe UI', 9)

function Set-Message([string]$text, [bool]$ok = $true) {
    $script:message.ForeColor = if ($ok) { [Drawing.Color]::DarkGreen } else { [Drawing.Color]::Firebrick }
    $script:message.Text = $text
}

function Update-StatusText {
    $script:builds = Get-AllGameBuildInfo $gameDirectory
    $hook = Get-LuaBackendStatus $gameDirectory
    $parts = foreach ($id in $script:catalog.Keys) {
        '{0}: {1}' -f $script:catalog[$id].ShortName, $(if ($script:builds[$id].Supported) { L 'compatible' } else { L 'blocked' })
    }
    $hookText = if ($hook.Installed -and $hook.DllKnown) { L 'hook_ok' @($hook.Version) } elseif ($hook.Installed) { L 'hook_unknown' } else { L 'hook_missing' }
    $script:status.Text = ($parts -join '  |  ') + "`r`n" + $hookText + (L 'status_tail')
    $allGood = @($script:builds.Values | Where-Object { -not $_.Supported }).Count -eq 0
    $script:status.BackColor = if ($allGood -and $hook.Installed -and $hook.DllKnown) { [Drawing.Color]::Honeydew } else { [Drawing.Color]::MistyRose }
}

function Update-SaveButton {
    if (-not $script:saveButton) { return }
    $st = Get-KHSaveProfileStatus -Root $projectRoot
    $script:saveButton.Text = L 'saves_btn' @((Get-ProfileName $st.Active), (Get-ProfileName $st.Other))
}

function Set-UiPreset([string]$gameId, [string]$name) {
    if ($name -eq 'Custom') { return }
    $ui = $script:gameUi[$gameId]
    $preset = Get-PresetData $name $projectRoot
    foreach ($prop in $preset.PSObject.Properties) {
        if (-not $ui.Controls.ContainsKey($prop.Name)) { continue }
        $control = $ui.Controls[$prop.Name]
        if ($control -is [Windows.Forms.NumericUpDown]) {
            $value = [decimal]$prop.Value
            if ($value -lt $control.Minimum) { $value = $control.Minimum }; if ($value -gt $control.Maximum) { $value = $control.Maximum }
            $control.Value = $value
        } elseif ($control -is [Windows.Forms.CheckBox]) { $control.Checked = [bool]$prop.Value }
    }
    $ui.Preset.SelectedItem = $name
}

function Read-AllControls {
    $result = New-DefaultSettings
    $result.ui_language = [string]$script:settings.ui_language
    foreach ($gameId in $script:catalog.Keys) {
        $ui = $script:gameUi[$gameId]
        # Start from the stored values so options hidden in the GUI are preserved.
        $result[$gameId] = New-GameSettings ([string]$ui.Preset.SelectedItem)
        foreach ($k in @($script:settings[$gameId].Keys)) { if ($k -ne 'preset') { $result[$gameId][$k] = $script:settings[$gameId][$k] } }
        foreach ($key in $ui.Controls.Keys) {
            $control = $ui.Controls[$key]
            if ($control -is [Windows.Forms.NumericUpDown]) { $result[$gameId][$key] = [double]$control.Value }
            elseif ($control -is [Windows.Forms.CheckBox]) { $result[$gameId][$key] = [bool]$control.Checked }
        }
    }
    return $result
}

function Add-GameTab([string]$gameId) {
    $game = $script:catalog[$gameId]
    $tab = New-Object Windows.Forms.TabPage
    $tab.Text = $game.ShortName
    $tab.AutoScroll = $true
    $script:tabs.TabPages.Add($tab)

    $buildLabel = New-Object Windows.Forms.Label
    $buildLabel.Location = New-Object Drawing.Point(16, 12); $buildLabel.Size = New-Object Drawing.Size(970, 22)
    $supported = $script:builds[$gameId].Supported
    $buildLabel.Text = if ($supported) { L 'build_ok' } else { L 'build_bad' }
    $buildLabel.ForeColor = if ($supported) { [Drawing.Color]::DarkGreen } else { [Drawing.Color]::Firebrick }
    $tab.Controls.Add($buildLabel)

    $presetLabel = New-Object Windows.Forms.Label
    $presetLabel.Location = New-Object Drawing.Point(18, 48); $presetLabel.Size = New-Object Drawing.Size(75, 24); $presetLabel.Text = L 'preset'
    $tab.Controls.Add($presetLabel)
    $presetBox = New-Object Windows.Forms.ComboBox
    $presetBox.Location = New-Object Drawing.Point(95, 44); $presetBox.Size = New-Object Drawing.Size(230, 28); $presetBox.DropDownStyle = 'DropDownList'
    [void]$presetBox.Items.AddRange(@('Vanilla', 'Light QoL', 'Dad Mode', 'Chaos / Sandbox', 'Custom'))
    $selectedPreset = [string]$script:settings[$gameId].preset
    $presetBox.SelectedItem = if ($presetBox.Items.Contains($selectedPreset)) { $selectedPreset } else { 'Custom' }
    $tab.Controls.Add($presetBox)

    $vanillaTab = New-Object Windows.Forms.Button
    $vanillaTab.Location = New-Object Drawing.Point(340, 43); $vanillaTab.Size = New-Object Drawing.Size(145, 30); $vanillaTab.Text = L 'vanilla_btn'; $vanillaTab.Tag = $gameId
    $vanillaTab.Add_Click({ Set-UiPreset ([string]$this.Tag) 'Vanilla' })
    $tab.Controls.Add($vanillaTab)

    if ($gameId -eq 'kh1') {
        $saveButton = New-Object Windows.Forms.Button
        $saveButton.Location = New-Object Drawing.Point(495, 43); $saveButton.Size = New-Object Drawing.Size(250, 30)
        $script:saveButton = $saveButton
        Update-SaveButton
        $saveButton.Add_Click({
            $st = Get-KHSaveProfileStatus -Root $projectRoot
            $question = L 'saves_q' @((Get-ProfileName $st.Active), (Get-ProfileName $st.Other))
            if ([Windows.Forms.MessageBox]::Show($question, (L 'saves_title'), [Windows.Forms.MessageBoxButtons]::YesNo, [Windows.Forms.MessageBoxIcon]::Question) -eq [Windows.Forms.DialogResult]::Yes) {
                try { $r = Switch-KHSaveProfile -Root $projectRoot; Update-SaveButton; Set-Message (L 'saves_done' @((Get-ProfileName $r.Active))) }
                catch { Set-Message $_.Exception.Message $false }
            }
        })
        $tab.Controls.Add($saveButton)
    }

    $y = 86
    if ($gameId -ne 'kh1') {
        $banner = New-Object Windows.Forms.Label
        $banner.Location = New-Object Drawing.Point(14, $y); $banner.Size = New-Object Drawing.Size(970, 26)
        $banner.Text = L 'exp_banner'; $banner.BackColor = [Drawing.Color]::LemonChiffon; $banner.ForeColor = [Drawing.Color]::SaddleBrown
        $banner.Padding = New-Object Windows.Forms.Padding(6, 4, 6, 4)
        $tab.Controls.Add($banner); $y += 34
    }

    $rowsForGame = New-Object System.Collections.ArrayList
    $pendingSection = $null
    foreach ($row in $featureRows) {
        if ($row[0] -eq 'section') { $pendingSection = $row; continue }
        if ($enabledFeatures[$gameId] -notcontains $row[1]) { continue }
        if ($pendingSection) { [void]$rowsForGame.Add($pendingSection); $pendingSection = $null }
        [void]$rowsForGame.Add($row)
    }

    $controls = @{}
    foreach ($row in $rowsForGame) {
        if ($row[0] -eq 'section') {
            $label = New-Object Windows.Forms.Label
            $label.Location = New-Object Drawing.Point(14, $y); $label.Size = New-Object Drawing.Size(970, 26); $label.Text = L $row[1]
            $label.Font = New-Object Drawing.Font('Segoe UI', 10, [Drawing.FontStyle]::Bold); $label.BackColor = [Drawing.Color]::Gainsboro; $label.Padding = New-Object Windows.Forms.Padding(4, 2, 0, 0)
            $tab.Controls.Add($label); $y += 31; continue
        }
        $kind = $row[0]; $key = $row[1]; $caption = Get-FeatureCaption $gameId $key $row[2]
        if ($kind -eq 'number') {
            $label = New-Object Windows.Forms.Label
            $label.Location = New-Object Drawing.Point(28, ($y + 4)); $label.Size = New-Object Drawing.Size(280, 24); $label.Text = $caption; $tab.Controls.Add($label)
            $control = New-Object Windows.Forms.NumericUpDown
            $control.Location = New-Object Drawing.Point(315, $y); $control.Size = New-Object Drawing.Size(110, 26); $control.DecimalPlaces = 1; $control.Increment = [decimal]0.5
            $control.Minimum = [decimal]$row[3]; $control.Maximum = [decimal]$row[4]
            $value = [decimal]$script:settings[$gameId][$key]
            if ($value -lt $control.Minimum) { $value = $control.Minimum }; if ($value -gt $control.Maximum) { $value = $control.Maximum }
            $control.Value = $value; $control.Tag = $presetBox
            $control.Add_ValueChanged({ $this.Tag.SelectedItem = 'Custom' }); $tab.Controls.Add($control)
        } else {
            $control = New-Object Windows.Forms.CheckBox
            $control.Location = New-Object Drawing.Point(28, $y); $control.Size = New-Object Drawing.Size(397, 26); $control.Text = $caption
            $control.Checked = [bool]$script:settings[$gameId][$key]; $control.Tag = $presetBox
            $control.Add_CheckedChanged({ $this.Tag.SelectedItem = 'Custom' }); $tab.Controls.Add($control)
        }
        $descLabel = New-Object Windows.Forms.Label
        $descLabel.Location = New-Object Drawing.Point(445, ($y + 4)); $descLabel.Size = New-Object Drawing.Size(525, 24)
        $descLabel.Text = LT $featureStatus[$gameId][$key]; $descLabel.ForeColor = [Drawing.Color]::DimGray
        $tab.Controls.Add($descLabel)
        $controls[$key] = $control; $y += 30
    }
    $tab.AutoScrollMinSize = New-Object Drawing.Size(980, ($y + 20))
    $script:gameUi[$gameId] = [pscustomobject]@{ Tab = $tab; Preset = $presetBox; Controls = $controls }
    $presetBox.Tag = [pscustomobject]@{ GameId = $gameId }
    $presetBox.Add_SelectedIndexChanged({
        $name = [string]$this.SelectedItem
        if ($name -ne 'Custom') { Set-UiPreset ([string]$this.Tag.GameId) $name }
    })
}

function Build-Window([int]$selectedTab = 0) {
    $form.SuspendLayout()
    $form.Controls.Clear()
    $script:gameUi = [ordered]@{}
    $script:saveButton = $null
    $form.Text = L 'window_title' @((Get-KHQoLModVersion))

    $title = New-Object Windows.Forms.Label
    $title.Location = New-Object Drawing.Point(18, 14); $title.Size = New-Object Drawing.Size(800, 30)
    $title.Font = New-Object Drawing.Font('Segoe UI', 15, [Drawing.FontStyle]::Bold); $title.Text = L 'header'
    $form.Controls.Add($title)

    $langLabel = New-Object Windows.Forms.Label
    $langLabel.Location = New-Object Drawing.Point(820, 20); $langLabel.Size = New-Object Drawing.Size(90, 22); $langLabel.Text = L 'language'
    $langLabel.TextAlign = 'MiddleRight'; $langLabel.Anchor = 'Top,Right'
    $form.Controls.Add($langLabel)
    $langBox = New-Object Windows.Forms.ComboBox
    $langBox.Location = New-Object Drawing.Point(915, 18); $langBox.Size = New-Object Drawing.Size(130, 26); $langBox.DropDownStyle = 'DropDownList'; $langBox.Anchor = 'Top,Right'
    [void]$langBox.Items.AddRange(@('English', 'Español'))
    $langBox.SelectedIndex = if ((Get-KHQoLLanguage) -eq 'es') { 1 } else { 0 }
    $langBox.Add_SelectedIndexChanged({
        $new = if ($this.SelectedIndex -eq 1) { 'es' } else { 'en' }
        if ($new -eq (Get-KHQoLLanguage)) { return }
        # Keep unsaved edits, remember the language, rebuild in place.
        $current = $script:tabs.SelectedIndex
        $script:settings = Read-AllControls
        $script:settings.ui_language = $new
        Set-KHQoLLanguage $new
        try {
            $stored = (Import-KHQoLSettings $projectRoot).Settings
            $stored.ui_language = $new
            Save-KHQoLSettings $stored $projectRoot $gameDirectory | Out-Null
        } catch {}
        Build-Window $current
    })
    $form.Controls.Add($langBox)

    $script:status = New-Object Windows.Forms.Label
    $script:status.Location = New-Object Drawing.Point(20, 50); $script:status.Size = New-Object Drawing.Size(1025, 68); $script:status.Anchor = 'Top,Left,Right'
    $script:status.BorderStyle = 'FixedSingle'; $script:status.Padding = New-Object Windows.Forms.Padding(6)
    $form.Controls.Add($script:status)
    Update-StatusText

    $script:tabs = New-Object Windows.Forms.TabControl
    $script:tabs.Location = New-Object Drawing.Point(20, 128); $script:tabs.Size = New-Object Drawing.Size(1025, 560); $script:tabs.Anchor = 'Top,Bottom,Left,Right'
    $form.Controls.Add($script:tabs)
    foreach ($gameId in $script:catalog.Keys) { Add-GameTab $gameId }
    if ($selectedTab -ge 0 -and $selectedTab -lt $script:tabs.TabCount) { $script:tabs.SelectedIndex = $selectedTab }

    $script:message = New-Object Windows.Forms.Label
    $script:message.Location = New-Object Drawing.Point(20, 698); $script:message.Size = New-Object Drawing.Size(1025, 28); $script:message.Anchor = 'Bottom,Left,Right'; $script:message.ForeColor = [Drawing.Color]::DarkGreen
    $form.Controls.Add($script:message)

    $save = New-Object Windows.Forms.Button
    $save.Location = New-Object Drawing.Point(20, 732); $save.Size = New-Object Drawing.Size(160, 34); $save.Anchor = 'Bottom,Left'; $save.Text = L 'save_btn'
    $save.Add_Click({
        try { $script:settings = (Save-KHQoLSettings (Read-AllControls) $projectRoot $gameDirectory).Settings; Set-Message (L 'saved') }
        catch { Set-Message $_.Exception.Message $false }
    })
    $form.Controls.Add($save)

    $repair = New-Object Windows.Forms.Button
    $repair.Location = New-Object Drawing.Point(190, 732); $repair.Size = New-Object Drawing.Size(160, 34); $repair.Anchor = 'Bottom,Left'; $repair.Text = L 'install_btn'
    $repair.Add_Click({
        try { $form.Cursor = 'WaitCursor'; Install-KHQoL $projectRoot $gameDirectory | Out-Null; Update-StatusText; Set-Message (L 'installed') }
        catch { Set-Message $_.Exception.Message $false }
        finally { $form.Cursor = 'Default' }
    })
    $form.Controls.Add($repair)

    $remove = New-Object Windows.Forms.Button
    $remove.Location = New-Object Drawing.Point(360, 732); $remove.Size = New-Object Drawing.Size(160, 34); $remove.Anchor = 'Bottom,Left'; $remove.Text = L 'uninstall_btn'
    $remove.Add_Click({
        $answer = [Windows.Forms.MessageBox]::Show((L 'uninstall_q'), (L 'uninstall_t'), [Windows.Forms.MessageBoxButtons]::YesNo, [Windows.Forms.MessageBoxIcon]::Warning)
        if ($answer -eq [Windows.Forms.DialogResult]::Yes) {
            try { $r = Uninstall-KHQoL $projectRoot $gameDirectory; Update-StatusText; Set-Message ($r.Messages -join ' | ') }
            catch { Set-Message $_.Exception.Message $false }
        }
    })
    $form.Controls.Add($remove)

    $launch = New-Object Windows.Forms.Button
    $launch.Location = New-Object Drawing.Point(530, 732); $launch.Size = New-Object Drawing.Size(200, 34); $launch.Anchor = 'Bottom,Left'; $launch.Text = L 'launch_btn'; $launch.BackColor = [Drawing.Color]::LightSteelBlue
    $launch.Add_Click({
        try { $script:settings = (Save-KHQoLSettings (Read-AllControls) $projectRoot $gameDirectory).Settings; Start-Process 'steam://rungameid/2552430'; Set-Message (L 'launched') }
        catch { Set-Message $_.Exception.Message $false }
    })
    $form.Controls.Add($launch)

    $footer = New-Object Windows.Forms.Label
    $footer.Location = New-Object Drawing.Point(745, 729); $footer.Size = New-Object Drawing.Size(300, 42); $footer.Anchor = 'Bottom,Right'; $footer.Text = L 'footer'; $footer.ForeColor = [Drawing.Color]::DimGray
    $form.Controls.Add($footer)
    $form.ResumeLayout()
}

# --- Command line -------------------------------------------------------------------
if ($Install) {
    $status = Install-KHQoL -Root $projectRoot -GameDirectory $gameDirectory
    Write-Host "LuaBackend $($status.Version): installed=$($status.Installed); verified DLL=$($status.DllKnown)"
    exit 0
}
if ($Uninstall) {
    $result = Uninstall-KHQoL -Root $projectRoot -GameDirectory $gameDirectory
    $result.Messages | ForEach-Object { Write-Host $_ }
    exit 0
}
if ($Validate) {
    $builds = Get-AllGameBuildInfo $gameDirectory
    $hook = Get-LuaBackendStatus $gameDirectory
    [pscustomobject]@{ Version = (Get-KHQoLModVersion); Builds = $builds; LuaBackend = $hook; Schema = $script:settings.schema_version; Warnings = $loaded.Warnings } | ConvertTo-Json -Depth 7
    $allSupported = @($builds.Values | Where-Object { -not $_.Supported }).Count -eq 0
    if (-not $allSupported -or -not $hook.Installed -or -not $hook.DllKnown) { exit 1 }
    exit 0
}
if ($SwitchSaves) {
    $result = Switch-KHSaveProfile -Root $projectRoot
    Write-Host (L 'saves_done' @((Get-ProfileName $result.Active)))
    exit 0
}
if ($NoGui) { exit 0 }

Build-Window
[void]$form.ShowDialog()
