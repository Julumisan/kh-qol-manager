-- Enemy HP for KH1 Final Mix (Steam).
--
-- Enemies live in the same 32-slot battle pool as the party (0x2D5CC10,
-- occupancy mask 0x2D5CB04; HP +0x3C, max HP +0x40) but have no character
-- save record at +0xC8. When a new non-party slot appears at full HP, its
-- current and max HP are scaled once. The max HP written per slot is mirrored
-- in A.enemy_stash so a slot is never scaled twice (also across F1 reloads).
-- Bosses cannot be told apart reliably, so they are included: the GUI says so.
-- Enemies already scaled keep their HP when the value changes; at 1x nothing
-- is written.

local Version = dofile(SCRIPT_PATH .. "/io_packages/kh_qol/version.lua")
local A = Version.addresses
local M = {}

local HP_CAP = 999999
local log = function() end
local announced = nil

function M.init(logger)
    log = logger
end

function M.on_frame(config, frame)
    local m = config.enemy_hp_multiplier or 1.0
    if m == 1.0 then
        -- Nothing to do. Marks stay so a still-alive scaled enemy is not scaled
        -- again if the option is switched back on; freed slots are cleared below
        -- the next time the option is active.
        announced = m
        return
    end
    local _, others, mask = Version.battle_slots()
    if mask == nil then return end
    local seen = {}
    for _, entry in ipairs(others) do
        seen[entry.index] = true
        local stash = A.enemy_stash + entry.index * 4
        local written = ReadInt(stash)
        local max = ReadInt(entry.slot + 0x40)
        local cur = ReadInt(entry.slot + 0x3C)
        if max > 0 and max <= HP_CAP and max ~= written then
            if cur == max then
                local target = math.floor(max * m + 0.5)
                if target < 1 then target = 1 end
                if target > HP_CAP then target = HP_CAP end
                WriteInt(entry.slot + 0x40, target)
                WriteInt(entry.slot + 0x3C, target)
                WriteInt(stash, target)
            else
                WriteInt(stash, max) -- seen at vanilla (or already damaged): leave it
            end
        end
    end
    -- Freed slots forget their mark.
    for i = 0, 31 do
        if not seen[i] and ReadInt(A.enemy_stash + i * 4) ~= 0 then WriteInt(A.enemy_stash + i * 4, 0) end
    end
    if announced ~= m then
        announced = m
        if m ~= 1.0 then log("INFO", string.format("HP de enemigos x%.2f para los que aparezcan a partir de ahora", m)) end
    end
end

return M
