-- Optional: multiply shop sell prices for KH1 Final Mix (Steam).
--
-- Selling an item pays  sell_price(item) * quantity  (0x301440), where the
-- sell price is the u16 at +0x0A of the item's 20-byte entry in the table
-- pointed to by [0x2D22D38] (accessor 0x2E8A20). Only shop code reads that
-- field (0x2FF6C0, 0x301440, 0x3017C0), so scaling it multiplies sales and the
-- shop shows the multiplied price. Buy prices (+0x08) are untouched.
-- Gummi block sales use a different, widely shared table and are not scaled.
--
-- The vanilla prices are mirrored in zero padding past .data so a LuaBackend
-- script reload never mistakes already scaled prices for vanilla ones.

local Version = dofile(SCRIPT_PATH .. "/io_packages/kh_qol/version.lua")
local A = Version.addresses
local M = {}

local ITEMS = 255
local STRIDE = 20
local SELL_OFFSET = 0x0A
local MAGIC = 0x5351484B -- "KHQS"

local log = function() end
local originals = nil
local table_ptr = nil
local applied = nil
local broken = false

function M.init(logger)
    log = logger
end

local function stash_load(ptr)
    if ReadInt(A.shop_stash) ~= MAGIC then return nil end
    if ReadLong(A.shop_stash + 4) ~= ptr then return nil end
    local values = {}
    for i = 1, ITEMS do values[i] = ReadShort(A.shop_stash + 12 + (i - 1) * 2) end
    return values
end

local function stash_save(ptr, values)
    WriteInt(A.shop_stash, 0)
    WriteLong(A.shop_stash + 4, ptr)
    for i = 1, ITEMS do WriteShort(A.shop_stash + 12 + (i - 1) * 2, values[i]) end
    WriteInt(A.shop_stash, MAGIC)
end

local function stash_area_free()
    if ReadInt(A.shop_stash) == MAGIC then return true end
    local bytes = Version.read_bytes(A.shop_stash, 12 + ITEMS * 2)
    if bytes == nil then return false end
    for _, b in ipairs(bytes) do if b ~= 0 then return false end end
    return true
end

local function price_address(i)
    return table_ptr + (i - 1) * STRIDE + SELL_OFFSET
end

local function target_price(original, multiplier)
    local value = math.floor(original * multiplier + 0.5)
    if value < 0 then value = 0 end
    if value > 65535 then value = 65535 end
    return value
end

function M.effective_multiplier(config)
    if config.multiply_shop_sales then return config.munny_multiplier end
    return 1.0
end

-- Runs every 30 frames while a save is loaded; cheap when nothing changed.
function M.on_frame(config, frame)
    if broken or frame % 30 ~= 0 then return end
    local m = M.effective_multiplier(config)
    -- Never touched and not requested: no reads of the table, no writes.
    if m == 1.0 and table_ptr == nil and ReadInt(A.shop_stash) ~= MAGIC then return end
    local ok, ptr = pcall(ReadLong, A.item_table_pointer)
    if not ok or ptr == nil or ptr == 0 then return end

    if ptr ~= table_ptr then
        -- First run or the table was reallocated: take the vanilla snapshot.
        if not stash_area_free() then
            broken = true
            log("ERROR", "Ventas: la ranura privada no está vacía; función desactivada")
            return
        end
        table_ptr = ptr
        originals = stash_load(ptr)
        if originals == nil then
            originals = {}
            for i = 1, ITEMS do originals[i] = ReadShortA(price_address(i)) end
            stash_save(ptr, originals)
        end
        applied = nil
    end

    local changed = 0
    for i = 1, ITEMS do
        local want = target_price(originals[i], m)
        local now = ReadShortA(price_address(i))
        if now ~= want then
            local previous = applied and target_price(originals[i], applied) or nil
            if now == originals[i] or now == previous then
                WriteShortA(price_address(i), want)
                changed = changed + 1
            end
        end
    end
    if applied ~= m then
        if m == 1.0 then
            log("INFO", "Ventas en tienda: precios vanilla")
        else
            log("INFO", string.format("Ventas en tienda: precio de venta x%.2f (%d objetos)", m, changed))
        end
        applied = m
    end
end

return M
