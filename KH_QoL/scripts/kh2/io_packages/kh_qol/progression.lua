local Version = dofile(SCRIPT_PATH .. "/io_packages/kh_qol/version.lua")
local A = Version.addresses
local M = {}
local last_munny, self_written_munny = nil, nil
local table_address, original_requirements, applied_multiplier = nil, nil, nil

local function absolute_pointer(address)
    local ok, value = pcall(ReadLong, address)
    if not ok or type(value) ~= "number" or value < 0x10000 then return nil end
    return value
end

local function capture_level_table()
    local btl0 = absolute_pointer(A.btl0_pointer)
    if not btl0 then return nil end
    local base = btl0 + A.sora_level_table_offset
    if table_address == base and original_requirements then return base end
    local values, previous = {}, -1
    for i = 0, 98 do
        local ok, value = pcall(ReadInt, base + (i * 0x10), true)
        if not ok or value < 0 or value > 99999999 or value < previous then return nil end
        values[i + 1], previous = value, value
    end
    if values[99] < 10000 then return nil end
    table_address, original_requirements, applied_multiplier = base, values, nil
    return base
end

local function update_exp(multiplier, frame)
    if frame % 30 ~= 0 then return end
    local base = capture_level_table()
    if not base or applied_multiplier == multiplier then return end
    for i = 0, 98 do
        local original = original_requirements[i + 1]
        local target = multiplier == 1.0 and original or math.max(0, math.ceil(original / multiplier))
        if ReadInt(base + (i * 0x10), true) ~= target then WriteInt(base + (i * 0x10), target, true) end
    end
    applied_multiplier = multiplier
end

local function update_munny(multiplier)
    local current = ReadInt(A.munny)
    if current < 0 or current > 999999 then last_munny, self_written_munny = nil, nil; return end
    if self_written_munny ~= nil and current == self_written_munny then
        last_munny, self_written_munny = current, nil
        return
    end
    if last_munny ~= nil and current > last_munny and multiplier ~= 1.0 then
        local gain = current - last_munny
        local extra = math.floor((gain * (multiplier - 1.0)) + 0.5)
        local target = math.max(0, math.min(999999, current + extra))
        if target ~= current then
            WriteInt(A.munny, target)
            last_munny, self_written_munny = target, target
            return
        end
    end
    last_munny, self_written_munny = current, nil
end

function M.reset_transient() last_munny, self_written_munny = nil, nil end
function M.on_frame(config, frame)
    update_exp(config.exp_multiplier, frame)
    update_munny(config.munny_multiplier)
end
return M
