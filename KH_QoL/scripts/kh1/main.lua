-- KH QoL for Kingdom Hearts Final Mix (Steam). LuaBackend entry point.
-- All writes are gated by the manager's SHA-256 authorization and an in-memory
-- version fingerprint. Unknown builds fail closed.

local module_path = SCRIPT_PATH .. "/io_packages/kh_qol/"
local Version = dofile(module_path .. "version.lua")
local Progression = dofile(module_path .. "progression.lua")
local Player = dofile(module_path .. "player.lua")
local Enemies = dofile(module_path .. "enemies.lua")
local Pickup = dofile(module_path .. "pickup.lua")
local Shop = dofile(module_path .. "shop.lua")
local Gummi = dofile(module_path .. "gummi.lua")

local state = {
    config = nil,
    config_text = nil,
    frame = 0,
    authorized = false,
    announced_wait = false
}

local log_path = SCRIPT_PATH .. "/../../logs/kh1-runtime.log"

local function log(level, message)
    local line = string.format("%s [%s] %s", os.date("%Y-%m-%d %H:%M:%S"), level, message)
    pcall(ConsolePrint, "[KH QoL] " .. message)
    local file = io.open(log_path, "a")
    if file then
        file:write(line .. "\n")
        file:close()
    end
end

local function read_all(path)
    local file = io.open(path, "rb")
    if not file then return nil end
    local text = file:read("*a")
    file:close()
    return text
end

local function clamp(value, low, high, fallback)
    value = tonumber(value)
    if value == nil or value ~= value or value == math.huge or value == -math.huge then return fallback end
    if value < low then return low end
    if value > high then return high end
    return value
end

local function validate(raw)
    if type(raw) ~= "table" then return nil, "runtime.lua no devolvió una tabla" end
    local c = {}
    c.preset = tostring(raw.preset or "Custom")
    c.build_hash = tostring(raw.build_hash or "")
    c.build_authorized = raw.build_authorized == true
    c.exp_multiplier = clamp(raw.exp_multiplier, 0.1, 100.0, 1.0)
    c.munny_multiplier = clamp(raw.munny_multiplier, 0.0, 100.0, 1.0)
    c.movement_speed_multiplier = clamp(raw.movement_speed_multiplier, 0.5, 2.0, 1.0)
    c.jump_multiplier = clamp(raw.jump_multiplier, 0.5, 3.0, 1.0)
    c.player_hp_multiplier = clamp(raw.player_hp_multiplier, 0.5, 3.0, 1.0)
    c.mp_multiplier = clamp(raw.mp_multiplier, 0.5, 3.0, 1.0)
    c.enemy_hp_multiplier = clamp(raw.enemy_hp_multiplier, 0.1, 10.0, 1.0)
    c.infinite_hp = raw.infinite_hp == true
    c.infinite_mp = raw.infinite_mp == true
    c.drop_multiplier = clamp(raw.drop_multiplier, 0.0, 100.0, 1.0)
    c.pickup_radius_multiplier = clamp(raw.pickup_radius_multiplier, 1.0, 100.0, 1.0)
    c.automatic_pickup = raw.automatic_pickup == true
    c.multiply_shop_sales = raw.multiply_shop_sales == true
    c.faster_text = raw.faster_text == true
    c.instant_gummi = raw.instant_gummi == true
    return c
end

local function reload_config(force)
    local path = module_path .. "runtime.lua"
    local text = read_all(path)
    if not text then
        if force then log("ERROR", "No se pudo leer runtime.lua; no se aplicará ningún parche") end
        return false
    end
    if not force and text == state.config_text then return true end
    local ok, raw = pcall(dofile, path)
    if not ok then log("ERROR", "Configuración rechazada: " .. tostring(raw)); return false end
    local config, err = validate(raw)
    if not config then log("ERROR", "Configuración rechazada: " .. tostring(err)); return false end
    state.config = config
    state.config_text = text
    state.authorized = Version.authorize(config)
    Progression.reset()
    Player.on_config_changed()
    if state.authorized then
        log("INFO", string.format("Configuración activa: %s; EXP %.2fx; Munny %.2fx%s; Drop %.2fx; Recogida %.2fx%s; HP∞=%s; MP∞=%s; Vel %.2fx",
            config.preset, config.exp_multiplier, config.munny_multiplier,
            config.multiply_shop_sales and " (+ventas)" or "", config.drop_multiplier,
            config.pickup_radius_multiplier, config.automatic_pickup and " (auto)" or "",
            tostring(config.infinite_hp), tostring(config.infinite_mp), config.movement_speed_multiplier))
        Progression.apply_static(config)
        Pickup.apply_static(config)
        Player.apply_static(config)
    else
        log("ERROR", "Build no autorizada; todos los parches permanecen desactivados: " .. tostring(Version.last_reason))
    end
    return true
end

function _OnInit()
    log("INFO", "KH QoL iniciado con LuaBackend; GAME_ID=" .. string.format("0x%X", GAME_ID or 0))
    Progression.init(log)
    Pickup.init(log)
    Shop.init(log)
    Player.init(log)
    Gummi.init(log)
    Enemies.init(log)
    reload_config(true)
end

function _OnFrame()
    state.frame = state.frame + 1
    if state.frame % 120 == 0 then reload_config(false) end
    if not state.authorized or not state.config then return end
    Player.update_text(state.config)
    Gummi.on_frame(state.config)
    if not Version.runtime_sanity_ok() then
        if not state.announced_wait and state.frame > 300 then
            log("INFO", "Esperando una partida cargada antes de escribir memoria")
            state.announced_wait = true
        end
        Progression.reset_transient()
        return
    end
    if not state.detected_logged then
        state.detected_logged = true
        log("INFO", "Partida detectada; multiplicadores nativos activos")
    end
    Progression.on_frame(state.config, state.frame)
    Player.on_frame(state.config, state.frame)
    Enemies.on_frame(state.config, state.frame)
    Pickup.on_frame(state.config, state.frame)
    Shop.on_frame(state.config, state.frame)
end
