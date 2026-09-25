local Version = dofile(SCRIPT_PATH .. "/io_packages/kh_qol/version.lua")
local Native = dofile(SCRIPT_PATH .. "/io_packages/kh_qol/native.lua")
local A = Version.addresses
local M = {}
local last_speed = nil
local log = function() end
local glide = {}
local glide_applied = nil
local glide_broken = false

function M.init(logger)
    log = logger
    local P = Version.patch_sites
    local defs = {
        { key = "glide_cap_normal", slot = A.glide_normal_slot, base = 8.0 },
        { key = "glide_cap_super", slot = A.glide_super_slot, base = 16.0 },
        { key = "glide_accel", slot = A.glide_accel_slot, base = 0.4 }
    }
    for _, d in ipairs(defs) do
        local patch, ours = Native.rip_redirect(d.key, P[d.key].rva, P[d.key].hex, d.slot, log)
        glide[#glide + 1] = { patch = patch, ours = ours, slot = d.slot, base = d.base }
    end
end

-- Glide speed follows the movement multiplier. Static code patch: applied on
-- config change, independent of the loaded save.
function M.apply_static(config)
    if glide_broken then return end
    local m = config.movement_speed_multiplier
    if glide_applied == m then return end
    local ok = true
    if m == 1.0 then
        for _, g in ipairs(glide) do ok = g.patch:restore() and ok end
    else
        for _, g in ipairs(glide) do WriteFloat(g.slot, g.base * m) end
        for _, g in ipairs(glide) do ok = ok and g.patch:set(g.ours) end
        if not ok then for _, g in ipairs(glide) do g.patch:restore() end end
    end
    if ok then
        glide_applied = m
        if m ~= 1.0 then log("INFO", string.format("Planeo acorde a la velocidad: x%.2f", m)) end
    else
        glide_broken = true
        log("ERROR", "Planeo: no se pudo redirigir de forma verificada; restaurado y desactivado")
    end
end

function M.on_config_changed()
    -- Preserve whether a non-vanilla value was written so switching back to
    -- Vanilla can restore 8.0 exactly once.
end

local function update_health(config)
    if not config.infinite_hp then return end
    local maximum = ReadByte(A.runtime_hp + 4)
    local current = ReadByte(A.runtime_hp)
    if maximum >= 1 and maximum <= 255 and current > 0 and current < maximum then
        WriteByte(A.runtime_hp, maximum)
    end
end

-- Runtime battle slot: MP at +0x44, max MP (with bonuses) at +0x48. The save
-- record byte at 0x2DE9368 is NOT the effective maximum (it read 8 while the
-- real maximum was 15), so only the runtime pair is used.
local function update_magic(config)
    if not config.infinite_mp then return end
    local maximum = ReadInt(A.runtime_mp + 4)
    local current = ReadInt(A.runtime_mp)
    if maximum >= 1 and maximum <= 255 and current >= 0 and current < maximum then
        WriteInt(A.runtime_mp, maximum)
    end
end

local VANILLA_SPEED = 8.0
local legacy_cleaned = false

-- Party members (Sora, Donald, Goofy, world guests) are the occupied battle
-- slots whose +0xC8 points into the character save records (Version.battle_slots);
-- enemies have no record. Only the normal ground speed (8.0) or the value this
-- mod wrote is rescaled; any other value is a contextual speed set by the game.
local function party_slots()
    local slots = {}
    local party = Version.battle_slots()
    for _, entry in ipairs(party) do slots[#slots + 1] = entry.slot end
    return slots
end

local function update_movement(config, frame)
    if frame % 15 ~= 0 then return end
    if not legacy_cleaned then
        local old = ReadFloat(A.legacy_dummy_speed)
        if old ~= VANILLA_SPEED and old >= 4.0 and old <= 16.0 then WriteFloat(A.legacy_dummy_speed, VANILLA_SPEED) end
        legacy_cleaned = true
    end
    local m = config.movement_speed_multiplier
    if last_speed == nil then
        local stashed = ReadFloat(A.speed_stash)
        if stashed >= 4.0 and stashed <= 16.0 then last_speed = stashed end
    end
    if m == 1.0 and last_speed == nil then return end
    local target = VANILLA_SPEED * m
    for _, slot in ipairs(party_slots()) do
        local current = ReadFloat(slot + 8)
        local ours = last_speed ~= nil and math.abs(current - last_speed) < 0.001
        if (math.abs(current - VANILLA_SPEED) < 0.001 or ours) and math.abs(current - target) > 0.001 then
            WriteFloat(slot + 8, target)
        end
    end
    last_speed = (m ~= 1.0) and target or nil
    WriteFloat(A.speed_stash, last_speed or 0.0)
end

-- Instant dialogue boxes: finish the open/close transition as soon as it
-- starts. The global timestep (0x233FBDC) is never touched. Called outside the
-- loaded-save gate because the HUD (part of that gate) is hidden in dialogues.
function M.update_text(config)
    if not config.faster_text then return end
    local value = ReadFloat(A.text_transition)
    if value > 0.0 and value < 1000.0 then WriteFloat(A.text_transition, 0.0) end
end

-- ---------------------------------------------------------------------------
-- Jump (Sora). 0x2A6380 copies the jump height into slot+0x10 from the battle
-- parameter table [0x2D22D30] (+0x54, or +0x56 in some states, + id*4) every
-- time it recomputes bonuses, so the table words are scaled (vanilla values
-- mirrored in A.jump_stash) and the live slot value is updated right away.
local JUMP_MAGIC = 0x4A514B48 -- "HKQJ"
local jump = { ptr = nil, orig = nil, applied = nil, blocked = false }

local function round_u16(value)
    value = math.floor(value + 0.5)
    if value < 1 then value = 1 end
    if value > 65535 then value = 65535 end
    return value
end

local function update_jump(config, frame)
    if jump.blocked or frame % 30 ~= 0 then return end
    local m = config.jump_multiplier or 1.0
    if m == 1.0 and jump.ptr == nil and ReadInt(A.jump_stash) ~= JUMP_MAGIC then return end
    local ok, ptr = pcall(ReadLong, A.battle_params)
    if not ok or ptr == nil or ptr == 0 then return end
    local sora = A.battle_slots -- slot 0
    if jump.ptr ~= ptr then
        jump.orig = nil
        if ReadInt(A.jump_stash) == JUMP_MAGIC and ReadLong(A.jump_stash + 4) == ptr then
            jump.orig = { ReadShort(A.jump_stash + 12), ReadShort(A.jump_stash + 14) }
        else
            local w54, w56 = ReadShortA(ptr + 0x54), ReadShortA(ptr + 0x56)
            local live = ReadFloat(sora + 0x10)
            -- Sanity: Sora's current jump must come from one of these words.
            if math.abs(live - w54) > 0.5 and math.abs(live - w56) > 0.5 then return end
            jump.orig = { w54, w56 }
            WriteInt(A.jump_stash, 0)
            WriteLong(A.jump_stash + 4, ptr)
            WriteShort(A.jump_stash + 12, w54)
            WriteShort(A.jump_stash + 14, w56)
            WriteInt(A.jump_stash, JUMP_MAGIC)
        end
        jump.ptr = ptr
        jump.applied = nil
    end
    local offsets = { 0x54, 0x56 }
    for i, off in ipairs(offsets) do
        local want = round_u16(jump.orig[i] * m)
        local previous = jump.applied and round_u16(jump.orig[i] * jump.applied) or nil
        local now = ReadShortA(ptr + off)
        if now ~= want and (now == jump.orig[i] or now == previous) then WriteShortA(ptr + off, want) end
        local live = ReadFloat(sora + 0x10)
        if math.abs(live - jump.orig[i]) < 0.5 or (previous and math.abs(live - previous) < 0.5) then
            if math.abs(live - want) > 0.5 then WriteFloat(sora + 0x10, want) end
        end
    end
    if jump.applied ~= m then
        log("INFO", string.format("Salto de Sora x%.2f (%d/%d)", m, round_u16(jump.orig[1] * m), round_u16(jump.orig[2] * m)))
        jump.applied = m
    end
end

-- ---------------------------------------------------------------------------
-- Max HP / max MP (Sora, runtime only). The game rewrites the maximum when it
-- recomputes stats (level up, equipment, rooms); a value different from the
-- one this mod wrote is taken as the new base. Base and written value are
-- mirrored in A.hp_stash / A.mp_stash so F1 never compounds them.
local MAX_CAP = 999

local function scale_max(field, current_field, stash, m)
    local sora = A.battle_slots
    local now = ReadInt(sora + field)
    if now < 1 or now > 99999 then return end
    local base, written = ReadInt(stash), ReadInt(stash + 4)
    if written == 0 or now ~= written then
        if m == 1.0 and written == 0 then return end
        base = now
    end
    if m == 1.0 then
        if written ~= 0 and now == written then
            WriteInt(sora + field, base)
            if ReadInt(sora + current_field) > base then WriteInt(sora + current_field, base) end
        end
        WriteInt(stash, 0); WriteInt(stash + 4, 0)
        return
    end
    local target = math.floor(base * m + 0.5)
    if target < 1 then target = 1 end
    if target > MAX_CAP then target = MAX_CAP end
    if now ~= target then WriteInt(sora + field, target) end
    if ReadInt(sora + current_field) > target then WriteInt(sora + current_field, target) end
    WriteInt(stash, base); WriteInt(stash + 4, target)
end

local function update_max_stats(config, frame)
    if frame % 15 ~= 0 then return end
    scale_max(0x40, 0x3C, A.hp_stash, config.player_hp_multiplier or 1.0)
    scale_max(0x48, 0x44, A.mp_stash, config.mp_multiplier or 1.0)
end

function M.on_frame(config, frame)
    update_health(config)
    update_magic(config)
    update_movement(config, frame)
    update_jump(config, frame)
    update_max_stats(config, frame)
end

return M
