local A = dofile(SCRIPT_PATH .. "/io_packages/kh_qol/version.lua").addresses
local M = {}

local function stat_address(final_offset)
    local ok, root = pcall(ReadInt, A.battle_unit_pointer)
    if not ok or root == 0 then return nil end
    local ok1, p1 = pcall(GetPointer, A.battle_unit_pointer, 0x118)
    if not ok1 or not p1 then return nil end
    local ok2, p2 = pcall(GetPointer, p1, 0x398, true)
    if not ok2 or not p2 then return nil end
    local ok3, result = pcall(GetPointer, p2, final_offset, true)
    if not ok3 then return nil end
    return result
end

function M.on_frame(config)
    if not config.infinite_hp then return end
    local current_address, maximum_address = stat_address(0xA0), stat_address(0xA4)
    if not current_address or not maximum_address then return end
    local current, maximum = ReadShort(current_address, true), ReadShort(maximum_address, true)
    if maximum >= 1 and maximum <= 9999 and current > 0 and current < maximum then WriteShort(current_address, maximum, true) end
end
return M
