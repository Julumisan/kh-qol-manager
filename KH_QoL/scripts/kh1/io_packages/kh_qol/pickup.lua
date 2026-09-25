-- Orb attraction radius for KH1 Final Mix (Steam).
--
-- 0x2AB420 and 0x2AC080 compare the squared distance between an orb and each
-- party member against a radius chosen by Treasure Magnet count / pickup mode:
--   80^2 [0x3EF6C8], 120^2 [0x3EF6CC], 200^2 [0x3EDE28], 400^2 [0x3EF6D0].
-- The three orb-only constants are scaled by m^2. The 200^2 constant is shared
-- with unrelated code, so it is never written: its three orb loads are pointed
-- at a private float instead. Everything is restored at 1x.

local Version = dofile(SCRIPT_PATH .. "/io_packages/kh_qol/version.lua")
local Native = dofile(SCRIPT_PATH .. "/io_packages/kh_qol/native.lua")
local A = Version.addresses
local M = {}

local log = function() end
local constants = {}
local loads = {}
local applied = nil
local disabled = false
local AUTO_PICKUP_MULTIPLIER = 50.0

local function disp_bytes(site_rva, insn_len, target_rva)
    return Native.le32(target_rva - (site_rva + insn_len))
end

function M.init(logger)
    log = logger
    local positive = function(now)
        local value = string.unpack("<f", string.char(now[1], now[2], now[3], now[4]))
        return value >= 1.0 and value < 1.0e12
    end
    constants = {
        { patch = Native.patch("radius_near", A.radius_near, Version.patch_sites.const_near.hex, log, positive), base = 6400.0 },
        { patch = Native.patch("radius_mid", A.radius_mid, Version.patch_sites.const_mid.hex, log, positive), base = 14400.0 },
        { patch = Native.patch("radius_tm2", A.radius_tm2, Version.patch_sites.const_tm2.hex, log, positive), base = 160000.0 }
    }
    local keys = { "r_tm1_a1", "r_tm1_a2", "r_tm1_b" }
    for i, key in ipairs(keys) do
        local site = Version.patch_sites[key]
        local vanilla = Version.parse_hex(site.hex)
        local ours = { vanilla[1], vanilla[2], vanilla[3], vanilla[4] }
        for _, b in ipairs(disp_bytes(site.rva, 8, A.radius_private_slot)) do ours[#ours + 1] = b end
        loads[i] = {
            patch = Native.patch(key, site.rva, site.hex, log, function(now) return Version.bytes_equal(now, ours) end),
            ours = ours
        }
    end
end

local function slot_usable()
    local value = ReadFloat(A.radius_private_slot)
    local extra = Version.read_bytes(A.radius_private_slot + 4, 12)
    if extra == nil then return false end
    for _, b in ipairs(extra) do if b ~= 0 then return false end end
    return value == 0.0 or (value >= 40000.0 and value < 1.0e12)
end

function M.effective_multiplier(config)
    local m = config.pickup_radius_multiplier
    if config.automatic_pickup and m < AUTO_PICKUP_MULTIPLIER then m = AUTO_PICKUP_MULTIPLIER end
    return m
end

local function restore_all()
    local ok = true
    for _, entry in ipairs(loads) do ok = entry.patch:restore() and ok end
    for _, entry in ipairs(constants) do ok = entry.patch:restore() and ok end
    return ok
end

function M.apply_static(config)
    if disabled then return end
    local m = M.effective_multiplier(config)
    if applied == m then return end
    local ok
    if m == 1.0 then
        ok = restore_all()
    else
        if not slot_usable() then
            disabled = true
            log("ERROR", "Radio de recogida: la ranura privada no está vacía; función desactivada")
            return
        end
        local scale = m * m
        -- Private copy first, then redirect the loads, then scale constants.
        WriteFloat(A.radius_private_slot, 40000.0 * scale)
        ok = ReadFloat(A.radius_private_slot) == string.unpack("<f", string.pack("<f", 40000.0 * scale))
        for _, entry in ipairs(loads) do ok = ok and entry.patch:set(entry.ours) end
        for _, entry in ipairs(constants) do ok = ok and entry.patch:set(Native.float_bytes(entry.base * scale)) end
        if not ok then restore_all() end
    end
    if ok then
        applied = m
        log("INFO", string.format("Radio de recogida %.2fx aplicado", m))
    else
        disabled = true
        log("ERROR", "Radio de recogida: no se pudo aplicar de forma verificada; restaurado y desactivado")
    end
end

function M.on_frame(config, frame) end

return M
