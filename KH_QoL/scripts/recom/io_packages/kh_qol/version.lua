local M = {}
M.expected_hash = "ACF42E96A168C73301F5C2CC2915D07E6C420F56A59C6286655C970BFEE36BBF"
M.expected_game_id = 0x9E3134F5
M.addresses = {
    fingerprint = 0x705248,
    exp_gem_table = 0x7C2C78,
    battle_pointer = 0x87B390,
    status_pointer = 0x87CBF8,
    current_hp_offset = 0x42C,
    max_hp_offset = 0x430,
    experience_offset = 0x440,
    moogle_points_offset = 0x448,
    level_offset = 0x1C
}
local authorized = false
M.last_reason = "not checked"

function M.authorize(config)
    authorized = false
    if type(config) ~= "table" or config.build_authorized ~= true then M.last_reason = "manager did not authorize hash"; return false end
    if string.upper(config.build_hash or "") ~= M.expected_hash then M.last_reason = "runtime hash mismatch"; return false end
    if GAME_ID ~= M.expected_game_id then M.last_reason = string.format("GAME_ID mismatch: 0x%X", GAME_ID or 0); return false end
    local expected = {106, 97, 112, 97, 110, 84, 111, 111}
    local ok, bytes = pcall(ReadArray, M.addresses.fingerprint, #expected)
    if not ok or (type(bytes) ~= "table" and type(bytes) ~= "userdata") then M.last_reason = "fingerprint read failed"; return false end
    for i = 1, #expected do if bytes[i] ~= expected[i] then M.last_reason = "fingerprint mismatch"; return false end end
    authorized, M.last_reason = true, "authorized"; return true
end

local function read_pointer(address)
    -- ReadLong is safe while the title screen keeps this pointer at zero;
    -- GetPointer would attempt to follow it inside native code.
    local ok, base = pcall(ReadLong, address)
    if not ok or type(base) ~= "number" or base < 0x10000 then return nil end
    return base
end

function M.status_base() return read_pointer(M.addresses.status_pointer) end
function M.battle_base() return read_pointer(M.addresses.battle_pointer) end

function M.runtime_sanity_ok()
    if not authorized then return false end
    local status, battle = M.status_base(), M.battle_base()
    if not status or not battle then return false end
    local ok, level = pcall(ReadInt, status + M.addresses.level_offset, true)
    if not ok or level < 1 or level > 99 then return false end
    local hp = ReadInt(battle + M.addresses.current_hp_offset, true)
    local maximum = ReadInt(battle + M.addresses.max_hp_offset, true)
    local points = ReadInt(battle + M.addresses.moogle_points_offset, true)
    return maximum >= 1 and maximum <= 9999 and hp >= 0 and hp <= maximum and points >= 0 and points <= 99999
end
return M
