local Version = dofile(SCRIPT_PATH .. "/io_packages/kh_qol/version.lua")
local A = Version.addresses
local M = {}

function M.on_frame(config)
    if not config.infinite_hp then return end
    local base = Version.battle_base(); if not base then return end
    local hp_address, maximum_address = base + A.current_hp_offset, base + A.max_hp_offset
    local current, maximum = ReadInt(hp_address, true), ReadInt(maximum_address, true)
    if maximum >= 1 and maximum <= 9999 and current > 0 and current < maximum then WriteInt(hp_address, maximum, true) end
end
return M
