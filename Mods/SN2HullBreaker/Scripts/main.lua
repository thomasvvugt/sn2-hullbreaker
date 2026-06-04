-- ============================================================================
-- Hull Breaker — Subnautica 2 Mod (sn2-hullbreaker)
-- Version: 1.0.0
--
-- Removes the per-vehicle limit on Strike Armour (Hull Reinforcements)
-- for the Tadpole, allowing multiple to be equipped in the upgrade slots.
--
-- HOW IT WORKS:
--   The UWEInventoryComponent (Unknown Worlds' inventory framework) has a
--   BoolProperty called "bAllowMultipleUnique". When false (the default),
--   the inventory rejects duplicate unique items like Strike Armour. This mod
--   sets it to true on every Tadpole's UpgradeInventoryComponent.
--
-- CONFIGURATION:
--   Edit the Config table below to change behaviour.
-- ============================================================================

local MOD_NAME = "HullBreaker"
local VERSION = "1.0.0"

-- ---------------------------------------------------------------------------
-- Configuration (edit these to customise)
-- ---------------------------------------------------------------------------
local Config = {
    -- Set to true to allow multiple of the same unique upgrade item.
    -- This is the main fix for the Strike Armour restriction.
    AllowMultipleUnique = true,

    -- How many upgrade slots the Tadpole should have.
    -- Default is 4. Change only if you want more/fewer slots.
    -- Set to nil to leave the value unchanged.
    MaxItems = nil,

    -- Log level: 0 = silent, 1 = normal, 2 = verbose
    LogLevel = 1,

    -- Delay (seconds) before auto-patching after game loads.
    -- Gives the game time to spawn actors.
    AutoPatchDelay = 10,

    -- Interval (seconds) between periodic re-scans for new Tadpoles.
    -- Set to 0 to disable periodic scanning.
    RescanInterval = 30,
}

-- ---------------------------------------------------------------------------
-- Logging
-- ---------------------------------------------------------------------------
local function Log(level, message)
    if Config.LogLevel >= level then
        print(string.format("[%s] %s\n", MOD_NAME, message))
    end
end

-- ---------------------------------------------------------------------------
-- Internal state
-- ---------------------------------------------------------------------------
local patchedAddresses = {}

-- ---------------------------------------------------------------------------
-- Patch a single Tadpole's UpgradeInventoryComponent
-- Returns: true if patched, false if skipped or failed
-- ---------------------------------------------------------------------------
local function PatchTadpole(tadpole)
    if not tadpole or not tadpole:IsValid() then
        return false
    end

    -- Avoid re-patching the same instance
    local addr = tadpole:GetAddress()
    if patchedAddresses[addr] then
        return false
    end

    local upgradeInv = tadpole.UpgradeInventoryComponent
    if not upgradeInv or not upgradeInv:IsValid() then
        Log(2, string.format("UpgradeInventoryComponent not valid on %s",
            tadpole:GetFName():ToString()))
        return false
    end

    -- Read current state
    local currentAllowMultiple = upgradeInv.bAllowMultipleUnique
    local currentMaxItems = upgradeInv.MaxItems

    local needsPatch = false

    -- Check bAllowMultipleUnique
    if Config.AllowMultipleUnique and currentAllowMultiple ~= true then
        needsPatch = true
    end

    -- Check MaxItems override
    if Config.MaxItems and currentMaxItems ~= Config.MaxItems then
        needsPatch = true
    end

    if not needsPatch then
        Log(2, string.format("Already patched: %s", tadpole:GetFName():ToString()))
        patchedAddresses[addr] = true
        return false
    end

    -- Apply patches
    Log(1, string.format("Patching %s", tadpole:GetFName():ToString()))
    Log(2, string.format("  Before: bAllowMultipleUnique=%s, MaxItems=%s",
        tostring(currentAllowMultiple), tostring(currentMaxItems)))

    if Config.AllowMultipleUnique then
        upgradeInv.bAllowMultipleUnique = true
    end

    if Config.MaxItems then
        upgradeInv.MaxItems = Config.MaxItems
    end

    -- Verify
    local newAllowMultiple = upgradeInv.bAllowMultipleUnique
    local newMaxItems = upgradeInv.MaxItems

    Log(2, string.format("  After:  bAllowMultipleUnique=%s, MaxItems=%s",
        tostring(newAllowMultiple), tostring(newMaxItems)))

    if Config.AllowMultipleUnique and newAllowMultiple ~= true then
        Log(1, "  WARNING: bAllowMultipleUnique did not stick - will retry")
        return false
    end

    Log(1, "  OK")
    patchedAddresses[addr] = true
    return true
end

-- ---------------------------------------------------------------------------
-- Scan for all Tadpoles and patch them
-- ---------------------------------------------------------------------------
local function PatchAllTadpoles()
    local patched = 0

    -- Native class instances
    local tadpoles = FindAllOf("SN2Tadpole")
    if tadpoles then
        for _, t in ipairs(tadpoles) do
            if PatchTadpole(t) then
                patched = patched + 1
            end
        end
    end

    -- Blueprint class instances (same actors, different lookup)
    local bpTadpoles = FindAllOf("BP_Tadpole_C")
    if bpTadpoles then
        for _, t in ipairs(bpTadpoles) do
            if PatchTadpole(t) then
                patched = patched + 1
            end
        end
    end

    return patched
end

-- ---------------------------------------------------------------------------
-- Watch for newly spawned Tadpoles (deployed from builder, undocked, etc.)
-- ---------------------------------------------------------------------------
NotifyOnNewObject("/Script/Subnautica2.SN2Tadpole", function(tadpole)
    if tadpole and tadpole:IsValid() then
        Log(2, string.format("New Tadpole spawned: %s", tadpole:GetFName():ToString()))
        ExecuteWithDelay(2000, function()
            PatchTadpole(tadpole)
        end)
    end
end)

-- ---------------------------------------------------------------------------
-- Console commands
-- ---------------------------------------------------------------------------

-- Manually patch all Tadpoles
RegisterConsoleCommandGlobalHandler("HB_Patch", function()
    local count = PatchAllTadpoles()
    Log(1, string.format("Patched %d Tadpole(s)", count))
    return true
end)

-- Show current state of all Tadpoles
RegisterConsoleCommandGlobalHandler("HB_Status", function()
    local tadpoles = FindAllOf("SN2Tadpole") or FindAllOf("BP_Tadpole_C") or {}
    if #tadpoles == 0 then
        Log(1, "No Tadpoles found in the world")
        return true
    end

    for i, t in ipairs(tadpoles) do
        if t:IsValid() then
            local inv = t.UpgradeInventoryComponent
            if inv and inv:IsValid() then
                Log(1, string.format("Tadpole #%d: bAllowMultipleUnique=%s, MaxItems=%s",
                    i, tostring(inv.bAllowMultipleUnique), tostring(inv.MaxItems)))
            else
                Log(1, string.format("Tadpole #%d: inventory not available", i))
            end
        end
    end
    return true
end)

-- Show mod version and config
RegisterConsoleCommandGlobalHandler("HB_Info", function()
    Log(1, string.format("Hull Breaker v%s", VERSION))
    Log(1, string.format("  AllowMultipleUnique = %s", tostring(Config.AllowMultipleUnique)))
    Log(1, string.format("  MaxItems = %s", tostring(Config.MaxItems)))
    Log(1, string.format("  LogLevel = %d", Config.LogLevel))
    Log(1, string.format("  Patched Tadpoles: %d", #patchedAddresses))
    return true
end)

-- ---------------------------------------------------------------------------
-- Startup
-- ---------------------------------------------------------------------------
Log(1, string.format("Hull Breaker v%s loaded", VERSION))
Log(2, "Commands: HB_Patch, HB_Status, HB_Info")

-- Auto-patch after delay
ExecuteWithDelay(Config.AutoPatchDelay * 1000, function()
    Log(1, "Auto-patching Tadpoles...")
    local count = PatchAllTadpoles()
    Log(1, string.format("Patched %d Tadpole(s)", count))
end)

-- Periodic rescan (catches Tadpoles spawned after load)
if Config.RescanInterval > 0 then
    LoopAsync(Config.RescanInterval * 1000, function()
        PatchAllTadpoles()
        return false
    end)
end
