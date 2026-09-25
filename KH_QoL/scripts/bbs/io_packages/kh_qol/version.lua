local M = {}
M.expected_hash = "375A811243F1F95F786F00318E2E1210DD5881B25BBF0912A0AD8F81650C976C"
M.expected_game_id = 0xBED4B944
M.addresses = {
    fingerprint = 0x726464,
    exp_table = 0x649604,
    save = 0x10FA0870,
    character = 0x10FA6240, -- Save + 0x59D0
    experience = 0x10FA6240,
    money = 0x10FA6244,
    level = 0x10FA624C,
    battle_unit_pointer = 0x10F9EE40
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
    authorized, M.last_reason = true, "authorized"; return true
end

function M.runtime_sanity_ok()
    if not authorized then return false end
    local ok, level = pcall(ReadShort, M.addresses.level)
    if not ok or level < 1 or level > 99 then return false end
    local money, experience = ReadInt(M.addresses.money), ReadInt(M.addresses.experience)
    if money < 0 or money > 999999 or experience < 0 or experience > 99999999 then return false end
    return true
end
return M
