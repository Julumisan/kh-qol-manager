-- Build identity and address map for KINGDOM HEARTS FINAL MIX (Steam).
-- Every RVA below was re-derived from the disassembly of this exact EXE
-- (SHA-256 D7907462...). Denhonator's KHPCSpeedrunTools calls this build
-- "SteamGlobal_1_0_0_2" even though the file metadata says 1.0.0.1.
-- Unknown builds fail closed: nothing is written unless every check passes.

local M = {}

M.expected_hash = "D790746245D26159F3EE0E1060E33B2FA2DE06941850A4AC724F598722884BAC"
M.expected_game_id = 0xAF71841E

M.addresses = {
    -- Native float multipliers recomputed by the game at 0x2A6380 whenever
    -- equipment/abilities are re-evaluated (menu close, room load, scripts).
    experience_multiplier = 0x2D5CB00, -- 1.0 + 0.2/0.3 per EXP accessory
    jackpot_multiplier = 0x2D60FA4,    -- 1.0 + 0.5 per Jackpot (orb count)
    lucky_multiplier = 0x2D60FA8,      -- 1.0 + 0.5 per Lucky Strike (item drop chance)

    -- Munny orb pickup: "mov ecx, imm32; call AddMunny" with 1 / 5 / 20.
    munny_orb_imm = { 0x2AC314, 0x2AC320, 0x2AC32C },
    munny_orb_base = { 1, 5, 20 },
    munny_pointer = 0x2E1F4D8,         -- AddMunny adds to [ptr] + 0x1C
    munny_pointer_target = 0x2DFF760,  -- the pointer's value is module base + this (verified live)
    munny_offset = 0x1C,

    -- Orb attraction radii (squared distances) loaded by 0x2AB420/0x2AC080.
    radius_near = 0x3EF6C8,            -- 80^2, only used by the two orb routines
    radius_mid = 0x3EF6CC,             -- 120^2, only used by the two orb routines
    radius_tm2 = 0x3EF6D0,             -- 400^2 (two Treasure Magnets), orb-only
    radius_tm1_shared = 0x3EDE28,      -- 200^2, shared with unrelated code: never written
    radius_tm1_loads = { 0x2AB4E1, 0x2AB539, 0x2AC145 }, -- movss xmmN,[rip+disp32], 8 bytes
    -- Zero padding past .data VirtualSize (0x2F135B8) inside the same page;
    -- nothing in the image references it. Used only by this mod.
    radius_private_slot = 0x2F13FF0,
    exp_private_slot = 0x2F13FE8,     -- base EXP bonus x multiplier
    drop_private_slot = 0x2F13FEC,    -- Lucky Strike x multiplier
    legacy_stash_exp = 0x2F13FE0,     -- used by the first revision; migrated
    legacy_stash_drop = 0x2F13FE4,
    shop_stash = 0x2F13A00,           -- "KHQS" + table pointer + 255 vanilla sell prices (to 0x2F13C0A)
    enemy_stash = 0x2F13C20,          -- 32 x int: max HP written per battle slot (enemy HP option)
    jump_stash = 0x2F13CB0,           -- "KHQJ" + param table pointer + 2 vanilla jump words (Sora)
    hp_stash = 0x2F13CC0,             -- Sora max HP: base, written
    mp_stash = 0x2F13CC8,             -- Sora max MP: base, written
    battle_params = 0x2D22D30,        -- pointer to the battle parameter table (jump words at +0x54/+0x56 + id*4)
    item_table_pointer = 0x2D22D38,   -- 255 items x 20 bytes; +0x0A = sell price (u16)

    -- Battle slot 0 (Sora) +0x08. 0x2D5CB18 (used by older maps and by the
    -- first revision) is the same field in the unused dummy block 0x2D5CB10.
    movement_speed = 0x2D5CC18,
    battle_slots = 0x2D5CC10,         -- 32 slots x 0x100; occupancy bitmask at 0x2D5CB04
    battle_slot_mask = 0x2D5CB04,
    character_records = 0x2DE9364,    -- save records (0x74 bytes); slot+0xC8 points here for party members
    legacy_dummy_speed = 0x2D5CB18,
    speed_stash = 0x2F13FD8,          -- last speed written by this mod (survives F1)
    -- Glide (0x2B2A40): cap 8.0 normal / 16.0 Superglide, acceleration 0.4.
    -- The constants are shared by 150+ instructions, so the three glide loads
    -- are redirected to private floats instead.
    glide_normal_slot = 0x2F13FD0,
    glide_super_slot = 0x2F13FD4,
    glide_accel_slot = 0x2F13FCC,
    runtime_hp = 0x2D5CC4C,            -- Sora battle slot 0x2D5CC10 + 0x3C (int)
    runtime_mp = 0x2D5CC54,
    -- Dialogue box open/close transition timer (KHPCSpeedrunTools
    -- SteamGlobal_1_0_0_2 "textTrans"; the 0x22EC194 value is the JP build).
    text_transition = 0x22EC114,
    gummi_warp_flag = 0x2689878,     -- world map: "ship has Warp gummi" (recomputed on map open)
    hud = 0x281249C,
    level = 0x2DE9364,
    max_hp = 0x2DE9366,
    current_mp = 0x2DE9367,
    max_mp = 0x2DE9368
}

-- Exact bytes that must be present before anything is written. They prove the
-- data addresses above are the ones this build's code actually uses.
M.signatures = {
    { name = "reset_lucky", rva = 0x2A63DE, hex = "C7 05 C0 AB AB 02 00 00 80 3F" },
    { name = "reset_jackpot", rva = 0x2A63E8, hex = "C7 05 B2 AB AB 02 00 00 80 3F" },
    { name = "reset_exp", rva = 0x2A63F2, hex = "C7 05 04 67 AB 02 00 00 80 3F" },
    { name = "munny_ptr", rva = 0x2E7E22, hex = "48 8B 05 AF 76 B3 02" },
    { name = "r_near_a", rva = 0x2AB4AA, hex = "F3 0F 10 35 16 42 14 00" },
    { name = "r_mid_a", rva = 0x2AB50F, hex = "F3 0F 10 35 B5 41 14 00" },
    { name = "r_tm2_a", rva = 0x2AB543, hex = "F3 0F 10 35 85 41 14 00" },
    { name = "r_near_b", rva = 0x2AC13C, hex = "F3 44 0F 10 15 83 35 14 00" },
    { name = "r_mid_b", rva = 0x2AC14D, hex = "F3 44 0F 10 35 76 35 14 00" },
    { name = "r_tm2_b", rva = 0x2AC156, hex = "F3 44 0F 10 1D 71 35 14 00" },
    { name = "const_tm1_shared", rva = 0x3EDE28, hex = "00 40 1C 47" },
    { name = "item_table_ptr", rva = 0x28F976, hex = "48 8B 05 BB 33 A9 02" },
    { name = "item_sell_field", rva = 0x2E8A29, hex = "0F B7 40 0A" },
    { name = "jump_params_ptr", rva = 0x2A653A, hex = "48 8B 05 EF C7 A7 02" },
    { name = "jump_read_56", rva = 0x2A6557, hex = "0F B7 4C B0 56" },
    { name = "jump_read_54", rva = 0x2A655E, hex = "0F B7 4C B0 54" },
    { name = "jump_store", rva = 0x2A657C, hex = "F3 0F 11 70 10" }
}

-- Sites that the mod may rewrite; each accepts the vanilla bytes (and, in the
-- owning module, the bytes it wrote itself).
M.patch_sites = {
    glide_cap_super = { rva = 0x2B2A7F, hex = "F3 44 0F 10 05 DC CE 17 00" },
    glide_cap_normal = { rva = 0x2B2AAB, hex = "F3 44 0F 10 05 98 CE 17 00" },
    glide_accel = { rva = 0x2B2AD9, hex = "F3 0F 59 05 E7 76 13 00" },
    -- Every instruction outside the recompute routine that reads the EXP or
    -- Lucky Strike float (full disassembly scan of this build).
    exp_read_1 = { rva = 0x2A4FB8, hex = "F3 0F 59 0D 40 7B AB 02" },
    exp_read_2 = { rva = 0x2A50AB, hex = "F3 0F 59 0D 4D 7A AB 02" },
    lucky_read_enemy = { rva = 0x2ABB58, hex = "F3 0F 59 0D 48 54 AB 02" },
    lucky_read_object = { rva = 0x2ABE50, hex = "F3 0F 10 35 50 51 AB 02" },
    munny_orb_1 = { rva = 0x2AC313, hex = "B9 01 00 00 00" },
    munny_orb_5 = { rva = 0x2AC31F, hex = "B9 05 00 00 00" },
    munny_orb_20 = { rva = 0x2AC32B, hex = "B9 14 00 00 00" },
    r_tm1_a1 = { rva = 0x2AB4E1, hex = "F3 0F 10 35 3F 29 14 00" },
    r_tm1_a2 = { rva = 0x2AB539, hex = "F3 0F 10 35 E7 28 14 00" },
    r_tm1_b = { rva = 0x2AC145, hex = "F3 0F 10 3D DB 1C 14 00" },
    const_near = { rva = 0x3EF6C8, hex = "00 00 C8 45" },
    const_mid = { rva = 0x3EF6CC, hex = "00 00 61 46" },
    const_tm2 = { rva = 0x3EF6D0, hex = "00 40 1C 48" }
}

local authorized = false
M.last_reason = "not checked"

function M.parse_hex(hex)
    local out = {}
    for byte in string.gmatch(hex, "%x%x") do out[#out + 1] = tonumber(byte, 16) end
    return out
end

function M.read_bytes(rva, count)
    local ok, data = pcall(ReadArray, rva, count)
    if not ok or data == nil then return nil end
    local out = {}
    for i = 1, count do
        local value = data[i]
        if value == nil then return nil end
        out[i] = value
    end
    return out
end

function M.bytes_equal(a, b)
    if a == nil or b == nil or #a ~= #b then return false end
    for i = 1, #a do if a[i] ~= b[i] then return false end end
    return true
end

function M.matches(rva, hex)
    local expected = M.parse_hex(hex)
    return M.bytes_equal(M.read_bytes(rva, #expected), expected)
end

function M.authorize(config)
    authorized = false
    if type(config) ~= "table" or config.build_authorized ~= true then M.last_reason = "manager did not authorize hash"; return false end
    if string.upper(config.build_hash or "") ~= M.expected_hash then M.last_reason = "runtime hash mismatch"; return false end
    if GAME_ID ~= M.expected_game_id then M.last_reason = string.format("GAME_ID mismatch: 0x%X", GAME_ID or 0); return false end
    -- Denhonator's public version markers for this build.
    if not M.matches(0x4698D2, "6A 61 70 61 6E 65 73 65") then M.last_reason = "version marker 0x4698D2 mismatch"; return false end
    if not M.matches(0x26E20C, "09") then M.last_reason = "version marker 0x26E20C mismatch"; return false end
    for _, sig in ipairs(M.signatures) do
        if not M.matches(sig.rva, sig.hex) then M.last_reason = "code signature mismatch: " .. sig.name; return false end
    end
    authorized = true
    M.last_reason = "authorized"
    return true
end

function M.is_authorized()
    return authorized
end

-- Module base derived from the munny pointer (value = base + munny_pointer_target).
-- Returns nil unless the result is 64 KiB aligned, i.e. the layout is as expected.
function M.module_base()
    local ok, pointer = pcall(ReadLong, M.addresses.munny_pointer)
    if not ok or pointer == nil or pointer == 0 then return nil end
    local base = pointer - M.addresses.munny_pointer_target
    if base & 0xFFFF ~= 0 then return nil end
    return base
end

-- Occupied battle slots, split into party members (slot+0xC8 points into the
-- character save records) and the rest (enemies, summons, objects).
function M.battle_slots()
    local party, others = {}, {}
    local base = M.module_base()
    if base == nil then return party, others end
    local first = base + M.addresses.character_records
    local last = first + 0x74 * 16
    local mask = ReadInt(M.addresses.battle_slot_mask)
    for i = 0, 31 do
        if (mask >> i) & 1 == 1 then
            local slot = M.addresses.battle_slots + i * 0x100
            local record = ReadLong(slot + 0xC8)
            if record >= first and record < last and (record - first) % 0x74 == 0 then
                party[#party + 1] = { index = i, slot = slot }
            else
                others[#others + 1] = { index = i, slot = slot }
            end
        end
    end
    return party, others, mask
end

function M.munny_address()
    local ok, pointer = pcall(ReadLong, M.addresses.munny_pointer)
    if not ok or pointer == nil or pointer == 0 then return nil end
    return pointer + M.addresses.munny_offset
end

function M.runtime_sanity_ok()
    if not authorized then return false end
    local ok, max_hp = pcall(ReadByte, M.addresses.max_hp)
    if not ok or max_hp < 1 or max_hp > 255 then return false end
    local hp = ReadInt(M.addresses.runtime_hp)
    local level = ReadByte(M.addresses.level)
    local hud = ReadFloat(M.addresses.hud)
    if hp < 0 or hp > 255 then return false end
    if level < 1 or level > 100 then return false end
    if hud <= 0.0 or hud > 10.0 then return false end
    if M.munny_address() == nil then return false end
    return true
end

return M
