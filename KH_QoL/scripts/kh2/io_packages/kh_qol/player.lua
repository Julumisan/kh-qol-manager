local A = dofile(SCRIPT_PATH .. "/io_packages/kh_qol/version.lua").addresses
local M = {}

local function replenish(address, maximum_address)
    local current, maximum = ReadInt(address), ReadInt(maximum_address)
    if maximum >= 1 and maximum <= 9999 and current > 0 and current < maximum then WriteInt(address, maximum) end
end

function M.on_frame(config)
    if config.infinite_hp then replenish(A.slot1, A.slot1 + 0x004) end
    if config.infinite_mp then replenish(A.slot1 + 0x180, A.slot1 + 0x184) end
end
return M
