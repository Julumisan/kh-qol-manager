local Version = dofile(SCRIPT_PATH .. "/io_packages/kh_qol/version.lua")
local A = Version.addresses
local M = {}
local vanilla = {1400, 99, 60, 30, 10, 5, 1}
local original, applied_multiplier = nil, nil
local last_points, self_written_points = nil, nil

local function capture_table()
    if original then return true end
    local values = {}
    for i = 0, 6 do
        local address = A.exp_gem_table + (i * 8) + 4
        local ok, value = pcall(ReadInt, address)
        if not ok or value ~= vanilla[i + 1] then return false end
        values[i + 1] = value
    end
    original = values; return true
end

local function update_exp(multiplier, frame)
    if frame % 30 ~= 0 or not capture_table() or applied_multiplier == multiplier then return end
    for i = 0, 6 do
        local value = original[i + 1]
        local target = multiplier == 1.0 and value or math.max(1, math.floor(value / multiplier))
        local address = A.exp_gem_table + (i * 8) + 4
        if ReadInt(address) ~= target then WriteInt(address, target) end
    end
    applied_multiplier = multiplier
end

local function update_points(multiplier)
    local base = Version.battle_base(); if not base then last_points, self_written_points = nil, nil; return end
    local address = base + A.moogle_points_offset
    local current = ReadInt(address, true)
    if current < 0 or current > 99999 then last_points, self_written_points = nil, nil; return end
    if self_written_points ~= nil and current == self_written_points then last_points, self_written_points = current, nil; return end
    if last_points ~= nil and current > last_points and multiplier ~= 1.0 then
        local extra = math.floor(((current - last_points) * (multiplier - 1.0)) + 0.5)
        local target = math.max(0, math.min(99999, current + extra))
        if target ~= current then WriteInt(address, target, true); last_points, self_written_points = target, target; return end
    end
    last_points, self_written_points = current, nil
end

function M.reset_transient() last_points, self_written_points = nil, nil end
function M.on_frame(config, frame) update_exp(config.exp_multiplier, frame); update_points(config.munny_multiplier) end
return M
