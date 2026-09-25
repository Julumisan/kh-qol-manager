-- KH QoL for Birth by Sleep Final Mix (Steam Global).
local module_path = SCRIPT_PATH .. "/io_packages/kh_qol/"
local Version = dofile(module_path .. "version.lua")
local Progression = dofile(module_path .. "progression.lua")
local Player = dofile(module_path .. "player.lua")
local state = { config = nil, config_text = nil, frame = 0, authorized = false, waiting_logged = false }
local log_path = SCRIPT_PATH .. "/../../logs/bbs-runtime.log"

local function log(level, message)
    pcall(ConsolePrint, "[KH QoL/BBS] " .. message)
    local file = io.open(log_path, "a")
    if file then file:write(string.format("%s [%s] %s\n", os.date("%Y-%m-%d %H:%M:%S"), level, message)); file:close() end
end

local function read_all(path)
    local file = io.open(path, "rb"); if not file then return nil end
    local text = file:read("*a"); file:close(); return text
end

local function clamp(value, low, high, fallback)
    value = tonumber(value)
    if value == nil or value ~= value or value == math.huge or value == -math.huge then return fallback end
    return math.max(low, math.min(high, value))
end

local function validate(raw)
    if type(raw) ~= "table" then return nil end
    return {
        preset = tostring(raw.preset or "Custom"), build_hash = tostring(raw.build_hash or ""),
        build_authorized = raw.build_authorized == true,
        exp_multiplier = clamp(raw.exp_multiplier, 0.1, 100.0, 1.0),
        munny_multiplier = clamp(raw.munny_multiplier, 0.0, 100.0, 1.0),
        infinite_hp = raw.infinite_hp == true
    }
end

local function reload_config(force)
    local path = module_path .. "runtime.lua"; local text = read_all(path)
    if not text then if force then log("ERROR", "No se pudo leer runtime.lua") end; return false end
    if not force and text == state.config_text then return true end
    local ok, raw = pcall(dofile, path)
    if not ok then log("ERROR", "Configuración rechazada: " .. tostring(raw)); return false end
    local config = validate(raw); if not config then log("ERROR", "runtime.lua no devolvió una tabla"); return false end
    state.config, state.config_text = config, text
    state.authorized = Version.authorize(config)
    Progression.reset_transient()
    if state.authorized then
        log("INFO", string.format("Configuración activa: %s; EXP %.2fx; Munny %.2fx; HP∞=%s",
            config.preset, config.exp_multiplier, config.munny_multiplier, tostring(config.infinite_hp)))
    else log("ERROR", "Build no autorizada; sin escrituras: " .. tostring(Version.last_reason)) end
    return true
end

function _OnInit()
    log("INFO", "KH QoL iniciado; GAME_ID=" .. string.format("0x%X", GAME_ID or 0))
    reload_config(true)
end

function _OnFrame()
    state.frame = state.frame + 1
    if state.frame % 120 == 0 then reload_config(false) end
    if not state.authorized or not state.config then return end
    if not Version.runtime_sanity_ok() then
        Progression.reset_transient()
        if state.frame > 300 and not state.waiting_logged then log("INFO", "Esperando una partida BBS cargada; no se escribe memoria"); state.waiting_logged = true end
        return
    end
    state.waiting_logged = false
    Progression.on_frame(state.config, state.frame)
    Player.on_frame(state.config)
end
