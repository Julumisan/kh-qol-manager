local M = {}

M.expected_hash = "9002B2DE6A1F91A790BD0673DE125D1CF833F7942BFEC827CDCF6BA64D5849ED"
M.expected_game_id = 0x431219CC
M.addresses = {
    fingerprint = 0x660EF4,
    save = 0x09A9830,
    munny = 0x09ABC70,       -- Save + 0x2440
    level = 0x09ABD2F,       -- Save + 0x24FF
    total_exp = 0x09ACF10,   -- Save + 0x36E0
    slot1 = 0x2A23518,
    btl0_pointer = 0x2AE5DD8,
    sora_level_table_offset = 0x25928
}

local authorized = false
M.last_reason = "not checked"

function M.authorize(config)
    authorized = false
    if type(config) ~= "table" or config.build_authorized ~= true then M.last_reason = "manager did not authorize hash"; return false end
    if string.upper(config.build_hash or "") ~= M.expected_hash then M.last_reason = "runtime hash mismatch"; return false end
    if GAME_ID ~= M.expected_game_id then M.last_reason = string.format("GAME_ID mismatch: 0x%X", GAME_ID or 0); return false end
    local expected = {106, 97, 112, 97, 110, 101, 115, 101}
    local ok, bytes = pcall(ReadArray, M.addresses.fingerprint, #expected)
    if not ok or (type(bytes) ~= "table" and type(bytes) ~= "userdata") then M.last_reason = "fingerprint read failed"; return false end
    for i = 1, #expected do if bytes[i] ~= expected[i] then M.last_reason = "fingerprint mismatch"; return false end end
    authorized, M.last_reason = true, "authorized"
    return true
end

function M.runtime_sanity_ok()
    if not authorized then return false end
    local ok, level = pcall(ReadByte, M.addresses.level)
    if not ok or level < 1 or level > 99 then return false end
    local munny = ReadInt(M.addresses.munny)
    local total_exp = ReadInt(M.addresses.total_exp)
    local current_hp = ReadInt(M.addresses.slot1)
    local max_hp = ReadInt(M.addresses.slot1 + 0x004)
    if munny < 0 or munny > 999999 then return false end
    if total_exp < 0 or total_exp > 99999999 then return false end
    if max_hp < 1 or max_hp > 9999 or current_hp < 0 or current_hp > max_hp then return false end
    return true
end

return M
