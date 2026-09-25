-- Gummi Ship options for KH1 Final Mix (Steam).
--
-- Instant travel: when the world map opens, 0x1F375A stores
-- "ship has the Warp gummi" (0x20CBF0: ship data byte +0x9AA9 > 0) in
-- [0x2689878]. The course menu (0x1EF170) offers the native Warp Drive only
-- if that flag is set AND the destination's route state byte
-- ([0x506F10 + world] bit 2) says its route was already flown. Forcing the
-- flag therefore behaves like owning Warp-G from the start: worlds whose
-- route you have not flown yet still require the normal flight, so story
-- unlocks are respected by the game itself. Nothing else is changed.

local Version = dofile(SCRIPT_PATH .. "/io_packages/kh_qol/version.lua")
local A = Version.addresses
local M = {}

local log = function() end
local checked = nil
local announced = false

function M.init(logger)
    log = logger
end

local function code_ok()
    if checked == nil then
        checked = Version.matches(0x1F375A, "89 0D 18 61 49 02")   -- store of the warp flag
            and Version.matches(0x1EF278, "39 35 FA A5 49 02")     -- course menu check
            and Version.matches(0x20CC18, "80 B8 A9 9A 00 00 00")  -- Warp gummi test
        if not checked then log("ERROR", "Gummi: firmas de código distintas; viaje instantáneo desactivado") end
    end
    return checked
end

-- Runs every frame while the build is authorized (the world map has no HUD,
-- so it cannot depend on the loaded-save check).
function M.on_frame(config)
    if not config.instant_gummi or not code_ok() then return end
    if ReadInt(A.gummi_warp_flag) == 0 then
        WriteInt(A.gummi_warp_flag, 1)
        if not announced then
            announced = true
            log("INFO", "Gummi: Warp Drive disponible para rutas ya voladas")
        end
    end
end

return M
