-- Helpers shared by the KH1 modules:
--  * Redirect: scales a float the game recomputes itself (EXP bonus, Lucky
--    Strike) without ever writing it. The instructions that READ the float
--    are pointed at a private float holding base * multiplier, so the game can
--    recompute its value at any moment (menus, room loads, scripts) and the
--    multiplier is still applied on that same frame.
--  * Patch: a reversible byte patch that only writes over the exact vanilla
--    bytes (or its own previous bytes) and verifies every write.

local Version = dofile(SCRIPT_PATH .. "/io_packages/kh_qol/version.lua")
local M = {}

local function float_bits(value)
    return string.unpack("<I4", string.pack("<f", value))
end

local function as_float(value)
    return string.unpack("<f", string.pack("<f", value))
end

-- Earlier builds of this mod wrote a tagged value (low mantissa byte 0x5A)
-- straight into the game's float and mirrored the base in a stash slot.
function M.is_legacy_tagged(value)
    return (float_bits(value) & 0xFF) == 0x5A
end

function M.le32(value)
    value = value & 0xFFFFFFFF
    return { value & 0xFF, (value >> 8) & 0xFF, (value >> 16) & 0xFF, (value >> 24) & 0xFF }
end

function M.float_bytes(value)
    return { string.byte(string.pack("<f", value), 1, 4) }
end

-- ---------------------------------------------------------------------------

local Patch = {}
Patch.__index = Patch

-- `own` (optional) recognises bytes this mod wrote in an earlier script
-- instance, e.g. after a LuaBackend reload.
function M.patch(name, rva, vanilla_hex, log, own)
    return setmetatable({ name = name, rva = rva, vanilla = Version.parse_hex(vanilla_hex),
        current = nil, broken = false, log = log, own = own }, Patch)
end

-- Writes `bytes` (full-length table) if the site still holds vanilla bytes or
-- our own previous bytes. Anything else means a foreign modification: abort.
function Patch:set(bytes)
    if self.broken then return false end
    local now = Version.read_bytes(self.rva, #self.vanilla)
    local target = bytes or self.vanilla
    if Version.bytes_equal(now, target) then self.current = target; return true end
    local ours = Version.bytes_equal(now, self.current) or (self.own ~= nil and now ~= nil and self.own(now))
    if not Version.bytes_equal(now, self.vanilla) and not ours then
        self.broken = true
        self.log("ERROR", self.name .. ": bytes inesperados; parche bloqueado para esta sesión")
        return false
    end
    WriteArray(self.rva, target)
    if Version.bytes_equal(Version.read_bytes(self.rva, #target), target) then
        self.current = target
        return true
    end
    self.broken = true
    self.log("ERROR", self.name .. ": verificación de escritura fallida; parche bloqueado")
    return false
end

function Patch:restore()
    return self:set(nil)
end

-- Instruction `vanilla_hex` (length n) whose last 4 bytes are a RIP-relative
-- disp32; returns a Patch plus the bytes that make it read `slot` instead.
function M.rip_redirect(name, rva, vanilla_hex, slot, log)
    local vanilla = Version.parse_hex(vanilla_hex)
    local n = #vanilla
    local ours = {}
    for i = 1, n - 4 do ours[i] = vanilla[i] end
    for _, b in ipairs(M.le32(slot - (rva + n))) do ours[#ours + 1] = b end
    local patch = M.patch(name, rva, vanilla_hex, log, function(now) return Version.bytes_equal(now, ours) end)
    return patch, ours
end

-- ---------------------------------------------------------------------------

local Redirect = {}
Redirect.__index = Redirect

-- sites: list of { name, rva, hex } instructions that read `game_rva`.
function M.redirect(name, game_rva, slot, sites, base_low, base_high, log, legacy_stash)
    local self = setmetatable({ name = name, game = game_rva, slot = slot, low = base_low,
        high = base_high, log = log, legacy_stash = legacy_stash, sites = {},
        base = nil, applied = nil, broken = false }, Redirect)
    for _, site in ipairs(sites) do
        local patch, ours = M.rip_redirect(site.name, site.rva, site.hex, slot, log)
        self.sites[#self.sites + 1] = { patch = patch, ours = ours }
    end
    return self
end

function Redirect:restore_sites()
    local ok = true
    for _, site in ipairs(self.sites) do ok = site.patch:restore() and ok end
    return ok
end

function Redirect:migrate_legacy(current)
    if not M.is_legacy_tagged(current) or self.legacy_stash == nil then return current end
    local stashed = ReadFloat(self.legacy_stash)
    if stashed >= self.low and stashed <= self.high then
        WriteFloat(self.game, stashed)
        WriteFloat(self.legacy_stash, 0.0)
        self.log("INFO", self.name .. ": valor de una versión anterior del mod restaurado a " .. tostring(stashed))
        return stashed
    end
    return current
end

-- Called every frame while a save is loaded.
function Redirect:update(multiplier)
    if self.broken then return end
    local base = ReadFloat(self.game)
    if base ~= base then return end
    base = self:migrate_legacy(base)
    if base < self.low or base > self.high then return end

    if multiplier == 1.0 then
        if self.applied ~= 1.0 then
            if self:restore_sites() then
                self.applied = 1.0
            else
                self.broken = true
                self.log("ERROR", self.name .. ": no se pudo restaurar; función bloqueada")
            end
        end
        return
    end

    local target = as_float(base * multiplier)
    if self.applied == multiplier and self.base == base then return end
    -- Private value first, then point the readers at it.
    WriteFloat(self.slot, target)
    if ReadFloat(self.slot) ~= target then
        self.broken = true
        self:restore_sites()
        self.log("ERROR", self.name .. ": verificación de la ranura privada fallida; restaurado")
        return
    end
    local ok = true
    for _, site in ipairs(self.sites) do ok = site.patch:set(site.ours) and ok end
    if not ok then
        self.broken = true
        self:restore_sites()
        self.log("ERROR", self.name .. ": no se pudo redirigir de forma verificada; restaurado")
        return
    end
    if self.applied ~= multiplier then
        self.log("INFO", string.format("%s: base %.2f × %.2f = %.2f", self.name, base, multiplier, target))
    end
    self.base = base
    self.applied = multiplier
end

function Redirect:slot_value()
    return ReadFloat(self.slot)
end

return M
