-- EXP, item-drop chance and Munny for KH1 Final Mix (Steam).
--
-- EXP  : the award code does  gain = trunc(base_exp * [0x2D5CB00] + 0.5).
-- Drops: enemy death does     drop if trunc(chance% * [0x2D60FA8]) > trunc(rand * 100)
--        (objects: chance * [0x2D60FA8] > rand). [0x2D60FA8] is the Lucky Strike
--        multiplier, so scaling it yields min(chance * m, 100%) with the normal
--        loot table untouched.
-- Both floats are recomputed by the game at any time, so they are never
-- written: their readers are redirected to private floats (see native.lua).
-- Munny: orb pickup calls AddMunny(1 / 5 / 20). The immediates are scaled,
--        so only munny from orbs changes; shop sales and event rewards do not.

local Version = dofile(SCRIPT_PATH .. "/io_packages/kh_qol/version.lua")
local Native = dofile(SCRIPT_PATH .. "/io_packages/kh_qol/native.lua")
local A = Version.addresses
local M = {}

local log = function() end
local exp_redirect, drop_redirect
local munny_patches = {}
local munny_applied = nil
local munny_clamp_warned = false
local MUNNY_CAP = 99999

function M.init(logger)
    log = logger
    local P = Version.patch_sites
    exp_redirect = Native.redirect("EXP", A.experience_multiplier, A.exp_private_slot, {
        { name = "exp_read_1", rva = P.exp_read_1.rva, hex = P.exp_read_1.hex },
        { name = "exp_read_2", rva = P.exp_read_2.rva, hex = P.exp_read_2.hex }
    }, 1.0, 8.0, log, A.legacy_stash_exp)
    drop_redirect = Native.redirect("Drop", A.lucky_multiplier, A.drop_private_slot, {
        { name = "lucky_read_enemy", rva = P.lucky_read_enemy.rva, hex = P.lucky_read_enemy.hex },
        { name = "lucky_read_object", rva = P.lucky_read_object.rva, hex = P.lucky_read_object.hex }
    }, 1.0, 10.0, log, A.legacy_stash_drop)
    local sites = { "munny_orb_1", "munny_orb_5", "munny_orb_20" }
    for i, key in ipairs(sites) do
        local site = Version.patch_sites[key]
        -- Any "mov ecx, imm32" at this site is ours to rewrite.
        munny_patches[i] = Native.patch(key, site.rva, site.hex, log, function(now) return now[1] == 0xB9 end)
    end
end

-- Config changes need no reset: the next update rescales (or restores at 1x).
function M.reset() end
function M.reset_transient() end

local function orb_value(base, multiplier)
    local value = math.floor(base * multiplier + 0.5)
    if value < 0 then value = 0 end
    if value > 100000 then value = 100000 end
    return value
end

-- Code patches are static and valid even outside a loaded save.
function M.apply_static(config)
    local m = config.munny_multiplier
    if munny_applied == m then return end
    local ok = true
    for i, patch in ipairs(munny_patches) do
        if m == 1.0 then
            ok = patch:restore() and ok
        else
            local imm = Native.le32(orb_value(A.munny_orb_base[i], m))
            ok = patch:set({ 0xB9, imm[1], imm[2], imm[3], imm[4] }) and ok
        end
    end
    if ok then
        munny_applied = m
        if m == 1.0 then
            log("INFO", "Munny: orbes en valores vanilla (1/5/20)")
        else
            log("INFO", string.format("Munny: orbes ahora valen %d/%d/%d", orb_value(1, m), orb_value(5, m), orb_value(20, m)))
        end
    end
end

local function clamp_munny(config)
    if config.munny_multiplier <= 1.0 then return end
    local address = Version.munny_address()
    if address == nil then return end
    local munny = ReadIntA(address)
    if munny > MUNNY_CAP and munny < MUNNY_CAP + 2000000 then
        WriteIntA(address, MUNNY_CAP)
        if not munny_clamp_warned then
            munny_clamp_warned = true
            log("INFO", "Munny limitado a 99.999 tras una recogida multiplicada")
        end
    end
end

function M.on_frame(config, frame)
    exp_redirect:update(config.exp_multiplier)
    drop_redirect:update(config.drop_multiplier)
    if frame % 30 == 0 then clamp_munny(config) end
end

function M.status()
    return {
        exp_base = exp_redirect and exp_redirect.base,
        drop_base = drop_redirect and drop_redirect.base
    }
end

return M
