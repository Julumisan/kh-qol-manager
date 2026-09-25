local A = dofile(SCRIPT_PATH .. "/io_packages/kh_qol/version.lua").addresses
local M = {}
local original_requirements, applied_multiplier = nil, nil
local last_money, self_written_money = nil, nil

local function capture_exp_table()
    if original_requirements then return true end
    local values, previous = {}, 0
    for i = 0, 98 do
        local ok, value = pcall(ReadInt, A.exp_table + (i * 4))
        if not ok or value <= previous or value > 99999999 then return false end
        values[i + 1], previous = value, value
    end
    if values[1] ~= 90 or values[99] < 10000 then return false end
    original_requirements = values
    return true
end

local function update_exp(multiplier, frame)
    if frame % 30 ~= 0 or not capture_exp_table() or applied_multiplier == multiplier then return end
    for i = 0, 98 do
        local original = original_requirements[i + 1]
        local target = multiplier == 1.0 and original or math.max(1, math.ceil(original / multiplier))
        local address = A.exp_table + (i * 4)
        if ReadInt(address) ~= target then WriteInt(address, target) end
    end
    applied_multiplier = multiplier
end

local function update_money(multiplier)
    local current = ReadInt(A.money)
    if current < 0 or current > 999999 then last_money, self_written_money = nil, nil; return end
    if self_written_money ~= nil and current == self_written_money then last_money, self_written_money = current, nil; return end
    if last_money ~= nil and current > last_money and multiplier ~= 1.0 then
        local extra = math.floor(((current - last_money) * (multiplier - 1.0)) + 0.5)
        local target = math.max(0, math.min(999999, current + extra))
        if target ~= current then WriteInt(A.money, target); last_money, self_written_money = target, target; return end
    end
    last_money, self_written_money = current, nil
end

function M.reset_transient() last_money, self_written_money = nil, nil end
function M.on_frame(config, frame) update_exp(config.exp_multiplier, frame); update_money(config.munny_multiplier) end
return M
