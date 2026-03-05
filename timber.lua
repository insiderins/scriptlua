-- Timber Script by Vaan
-- User-friendly UI + auto click + teleport

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local VirtualUser = game:GetService("VirtualUser")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Settings = {
    ClickDuration = 0.3,
    WaitDuration = 0.15,
    ToggleKey = Enum.KeyCode.F,
    FarmToggleKey = Enum.KeyCode.K,
    FarmTreeCooldownSeconds = 120,
    FarmNoPacketSkipSeconds = 2.2,
    FarmUiScanInterval = 0.3,
    FarmUiRefreshInterval = 0.12,
    FarmUiListMaxLines = 12,
    FarmEspRefreshInterval = 0.65,
    FarmEspMaxEntries = 30,
    FarmEspMaxDistance = 420,
    ForceTreeInfoRefreshInterval = 0.6,
    ForceTreeInfoMaxTargets = 25,
    ForceTreeInfoTriggerCooldown = 1.2,
    WeatherMutationScanInterval = 0.45,
    WeatherMutationRepeatBlockSeconds = 180,
    WeatherMutationTargetLifetimeSeconds = 420,
    FarmHpRescanInterval = 0.35,
    FarmHpProbeRetryInterval = 2.5,
    FarmPlayerNearbySkipRadius = 24,
    FarmPlayerNearbyCooldownSeconds = 30,
    FarmActionPromptSkipCooldownSeconds = 45,
    FarmRobuxPopupCooldownSeconds = 45,
    RobuxPopupScanInterval = 0.35,
    HarvestCacheResetSeconds = 300,
    HarvestPlotArrivalDistance = 24,
    HarvestPlotArrivalTimeout = 2.8,
    HarvestPostTeleportDelaySeconds = 0,
    HarvestPromptCacheInterval = 1.2,
    SellGuiHoldSeconds = 0.14,
    SellGuiCardScanInterval = 1.4,
    SellRemoteScanInterval = 24,
    SellMinIntervalWhenFarmActive = 6,
    SellPerItemDelayWhenFarmActive = 0.11,
    SellPromptCacheInterval = 3,
    TapSafePositionRefreshInterval = 0.25,
    CameraLockOnFirstChopOnly = true,
    AimNearestObject = true,
    AimMaxDistance = 180,
    AimUpdateInterval = 0.2,
    AimFallbackScanInterval = 1.5
}

local Theme = {
    Background = Color3.fromRGB(18, 23, 32),
    Header = Color3.fromRGB(14, 18, 25),
    Surface = Color3.fromRGB(29, 37, 50),
    SurfaceHover = Color3.fromRGB(39, 49, 65),
    Primary = Color3.fromRGB(80, 165, 255),
    PrimaryActive = Color3.fromRGB(58, 142, 232),
    Success = Color3.fromRGB(67, 208, 132),
    Danger = Color3.fromRGB(230, 93, 93),
    Warning = Color3.fromRGB(247, 198, 96),
    Text = Color3.fromRGB(243, 247, 252),
    MutedText = Color3.fromRGB(173, 186, 205),
    Border = Color3.fromRGB(78, 92, 112)
}

local UIState = {
    Active = false,
    Running = false,
    Minimized = false,
    CurrentTab = "Main",
    PendingCameraLock = false
}

local FarmState = {
    Active = false,
    Running = false,
    Radius = 120,
    ZoneIndex = 1,
    TreeFilter = "",
    PriorityMode = "HP",
    ScanResults = {},
    CurrentTarget = nil,
    LockedTarget = nil,
    CooldownKeys = {},
    LastCooldownSkipped = 0,
    SkipRequested = false,
    LastConflictText = "",
    LastConflictAt = 0,
    LastBusyToastScanAt = 0,
    LastBusyToastText = nil,
    LastWideScanAt = 0,
    LastWeatherMutationScanAt = 0,
    LastWeatherMutationMessageKey = nil,
    LastWeatherMutationMessageAt = 0,
    LastWeatherMutationHandledKey = nil,
    WeatherMutationEnabled = true,
    EspEnabled = false,
    ForceTreeInfoEnabled = false,
    WeatherMutationTarget = nil
}

local HarvestState = {
    Active = false,
    Running = false,
    ScanResults = {},
    CurrentTarget = nil,
    HarvestedKeys = {},
    HarvestedCount = 0,
    LastSkippedCount = 0,
    WaitingCacheReset = false,
    NextCacheResetAt = 0
}

local SellState = {
    Active = false,
    Running = false,
    PassDepth = 0,
    NameFilter = "",
    CountAttr = "CurrencyPerSecond",
    MinCount = 1,
    MinWeight = 1,
    IntervalSeconds = 4,
    LastSummary = "Sell siap.",
    LastAttrPreview = "Scan attribute inventory dulu.",
    LastSellAttemptAt = 0,
    LastDialogReady = false,
    LastPromptScanAt = 0,
    CachedPrompt = nil
}

local DebugState = {
    Enabled = false,
    Logs = {},
    MaxLogs = 18,
    Values = {},
    ValueOrder = {},
    WatchedInstance = nil,
    WatchConnections = {},
    IncomingConnections = {},
    RemoteConnections = {},
    LastPacketSummary = nil,
    LastPacketAt = 0,
    LastLogAt = 0,
    MinLogInterval = 0.03
}

local FarmPacketState = {
    Running = false,
    LastByteNetAt = 0,
    ByteNetCount = 0,
    ResetMarker = 0,
    GeneralConnections = {},
    RemoteConnections = {}
}

local HP_KEYS = {"HP", "Health", "HitPoints", "Durability", "CurrentHP", "TreeHP"}
local MAX_HP_KEYS = {"MaxHP", "MaxHealth", "HealthMax", "DurabilityMax", "HPMax", "MaxBreakPoint", "BreakPointMax"}
local RARITY_KEYS = {"Rarity", "Tier", "Class", "Type"}
local MUTATION_KEYS = {"Mutation", "Mutations", "Modifier", "Modifiers", "Mutant", "Mutate"}
local OWNER_KEYS = {"Owner", "OwnerName", "Player", "PlayerName", "User", "UserId", "OwnerId"}
local INTERACT_HINTS = {"collect", "harvest", "pickup", "pick", "take", "claim", "wood", "log", "tree", "fruit"}
local PLOT_HINTS = {"plot", "base", "property", "homestead", "land"}
local FARM_OBJECT_HINTS = {"tree", "log", "wood", "chop", "stump", "trunk"}
local HEALTH_NAME_HINTS = {"hp", "health", "durability", "life", "hit"}
local MUTATION_NAME_HINTS = {"mutation", "mutations", "mutate", "modifier", "modifiers", "variant"}
local NON_FARM_HINTS = {"bound", "zone", "plot", "base", "ground", "floor", "terrain", "water", "wall", "spawn"}
local PACKET_HINTS = {"bytenet", "tree", "chop", "wood", "damage", "hit", "break", "axe", "swing", "harvest", "resource"}
local FARM_BUSY_HINTS = {"already chopping this tree", "try again in"}
local FARM_ACTION_SKIP_HINTS = {"collect", "harvest", "pickup", "claim", "tap", "interact", "gather"}
local ROBUX_POPUP_HINTS = {"robux", "buy", "purchase", "confirm", "insufficient"}
local ROBUX_CLOSE_HINTS = {"cancel", "close", "no thanks", "not now", "nevermind", "back", "decline"}
local SELL_REMOTE_HINTS = {"sell", "vendor", "merchant", "market", "shop", "trade", "exchange", "pawn"}
local SELL_DIALOG_OPTION_ONE_HINTS = {"i want to sell my inventory", "sell my inventory"}
local SELL_DIALOG_OPTION_TWO_HINTS = {"i want to sell this", "sell this"}
local TOOL_SLOT_KEYS = {"Slot", "HotbarSlot", "InventorySlot", "Index", "Order"}
local COUNT_VALUE_KEYS = {"Count", "Amount", "Qty", "Quantity", "Stack", "Stacks", "Total", "Value"}
local WEIGHT_VALUE_KEYS = {"Weight", "weight", "Mass", "Kg", "KG"}
local FARM_RARITY_WORD_SCORES = {
    common = 1,
    uncommon = 2,
    rare = 3,
    epic = 4,
    legendary = 5,
    mythic = 6,
    divine = 7,
    godly = 8,
    exotic = 9,
    unique = 10
}

local connections = {}
local cameraLockConnection = nil
local previousMouseBehavior = nil
local previousMouseIconEnabled = nil
local rootFrame = nil
local cachedAimTarget = nil
local lastAimScanAt = 0
local lastAimFallbackScanAt = 0
local lastTapPositionAt = 0
local lastTapX = 640
local lastTapY = 360
local cachedPlotPart = nil
local lastPlotScanAt = 0
local worldPromptCache = {
    LastScanAt = 0,
    Prompts = {}
}
local actionPromptCache = setmetatable({}, {__mode = "k"})
local robuxPopupCache = {
    LastScanAt = 0,
    Popup = nil,
    Text = nil,
    HadPopup = false
}
local farmViewLastRefreshAt = 0
local refreshFarmUiCallback = nil
local farmEspEntries = {}
local farmEspRunning = false
local forceTreeInfoRunning = false
local forceTreeInfoTriggerMap = {}
local sellRemoteCache = {
    LastScanAt = 0,
    Remotes = {}
}
local sellGuiCardCache = {
    LastScanAt = 0,
    Cards = {}
}
local ConfigPersist = {
    DirPath = "AutoPerfectChop",
    FilePath = "AutoPerfectChop/config.json",
    SavePending = false,
    LastSerialized = ""
}

function isConfigPersistenceAvailable()
    return type(readfile) == "function" and type(writefile) == "function"
end

function ensureConfigDirectory()
    if type(isfolder) == "function" and type(makefolder) == "function" then
        local okExists, exists = pcall(function()
            return isfolder(ConfigPersist.DirPath)
        end)
        if okExists and not exists then
            pcall(function()
                makefolder(ConfigPersist.DirPath)
            end)
        end
    end
end

function clampConfigZoneIndex(zoneCount)
    local count = tonumber(zoneCount) or 0
    if count <= 0 then
        FarmState.ZoneIndex = 1
        return
    end

    local parsed = tonumber(FarmState.ZoneIndex) or 1
    FarmState.ZoneIndex = math.clamp(math.floor(parsed), 1, count)
end

function buildConfigSnapshot()
    return {
        Version = 1,
        UI = {
            CurrentTab = UIState.CurrentTab,
            Minimized = UIState.Minimized
        },
        Farm = {
            Radius = FarmState.Radius,
            ZoneIndex = FarmState.ZoneIndex,
            TreeFilter = FarmState.TreeFilter,
            PriorityMode = normalizeFarmPriorityMode(FarmState.PriorityMode),
            WeatherMutationEnabled = FarmState.WeatherMutationEnabled,
            EspEnabled = FarmState.EspEnabled
        },
        Sell = {
            NameFilter = SellState.NameFilter,
            CountAttr = SellState.CountAttr,
            MinCount = SellState.MinCount,
            MinWeight = SellState.MinWeight,
            IntervalSeconds = SellState.IntervalSeconds
        },
        Settings = {
            SellGuiHoldSeconds = Settings.SellGuiHoldSeconds,
            FarmTreeCooldownSeconds = Settings.FarmTreeCooldownSeconds,
            FarmNoPacketSkipSeconds = Settings.FarmNoPacketSkipSeconds,
            FarmPlayerNearbySkipRadius = Settings.FarmPlayerNearbySkipRadius,
            FarmPlayerNearbyCooldownSeconds = Settings.FarmPlayerNearbyCooldownSeconds,
            FarmActionPromptSkipCooldownSeconds = Settings.FarmActionPromptSkipCooldownSeconds,
            FarmRobuxPopupCooldownSeconds = Settings.FarmRobuxPopupCooldownSeconds
        }
    }
end

function syncStateFromUiForConfigSave()
    if farmRadiusInput and type(farmRadiusInput.Text) == "string" then
        local radius = tonumber(farmRadiusInput.Text)
        if radius then
            FarmState.Radius = math.clamp(radius, 20, 500)
        end
    end
    if farmTreeFilterInput and type(farmTreeFilterInput.Text) == "string" then
        local normalizedTreeFilter = normalizeFarmTreeFilterInput(farmTreeFilterInput.Text)
        FarmState.TreeFilter = normalizedTreeFilter
    end

    if sellNameFilterInput and type(sellNameFilterInput.Text) == "string" then
        SellState.NameFilter = string.gsub(sellNameFilterInput.Text or "", "^%s*(.-)%s*$", "%1")
    end
    if sellCountAttrInput and type(sellCountAttrInput.Text) == "string" then
        local countAttr = string.gsub(sellCountAttrInput.Text or "", "^%s*(.-)%s*$", "%1")
        SellState.CountAttr = (countAttr == "") and "CurrencyPerSecond" or countAttr
    end
    if sellMinCountInput and type(sellMinCountInput.Text) == "string" then
        local minCount = tonumber(sellMinCountInput.Text)
        if minCount then
            SellState.MinCount = math.max(0, math.floor(minCount))
        end
    end
    if sellKeepInput and type(sellKeepInput.Text) == "string" then
        local minWeight = tonumber(sellKeepInput.Text)
        if minWeight then
            SellState.MinWeight = math.max(0, math.floor(minWeight))
        end
    end
    if sellIntervalInput and type(sellIntervalInput.Text) == "string" then
        local interval = tonumber(sellIntervalInput.Text)
        if interval then
            SellState.IntervalSeconds = math.clamp(interval, 1, 60)
        end
    end
end

function saveConfigNow()
    if not isConfigPersistenceAvailable() then
        return false
    end

    syncStateFromUiForConfigSave()
    ensureConfigDirectory()

    local okEncode, serialized = pcall(function()
        return HttpService:JSONEncode(buildConfigSnapshot())
    end)
    if not okEncode or type(serialized) ~= "string" then
        return false
    end

    if serialized == ConfigPersist.LastSerialized then
        return true
    end

    local okWrite = pcall(function()
        writefile(ConfigPersist.FilePath, serialized)
    end)
    if not okWrite then
        return false
    end

    ConfigPersist.LastSerialized = serialized
    return true
end

function requestConfigSave()
    if not isConfigPersistenceAvailable() then
        return
    end
    if ConfigPersist.SavePending then
        return
    end

    ConfigPersist.SavePending = true
    task.delay(0.2, function()
        ConfigPersist.SavePending = false
        saveConfigNow()
    end)
end

function loadConfigFromDisk()
    if not isConfigPersistenceAvailable() then
        return false
    end

    if type(isfile) == "function" then
        local okExists, exists = pcall(function()
            return isfile(ConfigPersist.FilePath)
        end)
        if okExists and not exists then
            return false
        end
    end

    local okRead, content = pcall(function()
        return readfile(ConfigPersist.FilePath)
    end)
    if not okRead or type(content) ~= "string" or content == "" then
        return false
    end

    local okDecode, config = pcall(function()
        return HttpService:JSONDecode(content)
    end)
    if not okDecode or type(config) ~= "table" then
        return false
    end

    local uiConfig = config.UI
    if type(uiConfig) == "table" then
        local tab = tostring(uiConfig.CurrentTab or "")
        if tab == "Main" or tab == "Teleport" or tab == "Farm" or tab == "Harvest" or tab == "Sell" or tab == "About" then
            UIState.CurrentTab = tab
        end
        if type(uiConfig.Minimized) == "boolean" then
            UIState.Minimized = uiConfig.Minimized
        end
    end

    local farmConfig = config.Farm
    if type(farmConfig) == "table" then
        local radius = tonumber(farmConfig.Radius)
        if radius then
            FarmState.Radius = math.clamp(radius, 20, 500)
        end
        local zoneIndex = tonumber(farmConfig.ZoneIndex)
        if zoneIndex then
            FarmState.ZoneIndex = math.max(1, math.floor(zoneIndex))
        end
        if type(farmConfig.TreeFilter) == "string" then
            FarmState.TreeFilter = normalizeFarmTreeFilterInput(farmConfig.TreeFilter)
        end
        if type(farmConfig.PriorityMode) == "string" then
            FarmState.PriorityMode = farmConfig.PriorityMode
        end
        if type(farmConfig.WeatherMutationEnabled) == "boolean" then
            FarmState.WeatherMutationEnabled = farmConfig.WeatherMutationEnabled
        end
        if type(farmConfig.EspEnabled) == "boolean" then
            FarmState.EspEnabled = farmConfig.EspEnabled
        end
    end
    FarmState.ForceTreeInfoEnabled = false
    FarmState.PriorityMode = normalizeFarmPriorityMode(FarmState.PriorityMode)

    local sellConfig = config.Sell
    if type(sellConfig) == "table" then
        if type(sellConfig.NameFilter) == "string" then
            SellState.NameFilter = sellConfig.NameFilter
        end
        if type(sellConfig.CountAttr) == "string" and sellConfig.CountAttr ~= "" then
            SellState.CountAttr = sellConfig.CountAttr
        end
        local minCount = tonumber(sellConfig.MinCount)
        if minCount then
            SellState.MinCount = math.max(0, math.floor(minCount))
        end
        local minWeight = tonumber(sellConfig.MinWeight)
        if minWeight then
            SellState.MinWeight = math.max(0, math.floor(minWeight))
        end
        local interval = tonumber(sellConfig.IntervalSeconds)
        if interval then
            SellState.IntervalSeconds = math.clamp(interval, 1, 60)
        end
    end

    local settingConfig = config.Settings
    if type(settingConfig) == "table" then
        local sellHold = tonumber(settingConfig.SellGuiHoldSeconds)
        if sellHold then
            Settings.SellGuiHoldSeconds = math.clamp(sellHold, 0.06, 1.2)
        end

        local farmTreeCooldown = tonumber(settingConfig.FarmTreeCooldownSeconds)
        if farmTreeCooldown then
            Settings.FarmTreeCooldownSeconds = math.clamp(farmTreeCooldown, 5, 600)
        end
        local noPacketSkip = tonumber(settingConfig.FarmNoPacketSkipSeconds)
        if noPacketSkip then
            Settings.FarmNoPacketSkipSeconds = math.clamp(noPacketSkip, 0.5, 10)
        end
        local nearbyRadius = tonumber(settingConfig.FarmPlayerNearbySkipRadius)
        if nearbyRadius then
            Settings.FarmPlayerNearbySkipRadius = math.clamp(nearbyRadius, 5, 80)
        end
        local nearbyCooldown = tonumber(settingConfig.FarmPlayerNearbyCooldownSeconds)
        if nearbyCooldown then
            Settings.FarmPlayerNearbyCooldownSeconds = math.clamp(nearbyCooldown, 5, 300)
        end
        local actionSkipCooldown = tonumber(settingConfig.FarmActionPromptSkipCooldownSeconds)
        if actionSkipCooldown then
            Settings.FarmActionPromptSkipCooldownSeconds = math.clamp(actionSkipCooldown, 5, 300)
        end
        local robuxSkipCooldown = tonumber(settingConfig.FarmRobuxPopupCooldownSeconds)
        if robuxSkipCooldown then
            Settings.FarmRobuxPopupCooldownSeconds = math.clamp(robuxSkipCooldown, 5, 300)
        end
    end

    ConfigPersist.LastSerialized = content
    return true
end

function trackConnection(connection)
    table.insert(connections, connection)
    return connection
end

function pushDebugLog(message)
    local timestamp = os.date("%H:%M:%S")
    table.insert(DebugState.Logs, 1, string.format("[%s] %s", timestamp, message))
    while #DebugState.Logs > DebugState.MaxLogs do
        table.remove(DebugState.Logs)
    end
    if refreshFarmUiCallback then
        refreshFarmUiCallback()
    end
end

function safeInstancePath(instance)
    if typeof(instance) ~= "Instance" then
        return tostring(instance)
    end

    local path = instance.Name
    pcall(function()
        path = instance:GetFullName()
    end)

    if #path > 90 then
        path = "..." .. string.sub(path, -87)
    end

    return path
end

function setDebugValue(key, value)
    if not key or key == "" then
        return
    end

    if value == nil then
        if DebugState.Values[key] ~= nil then
            DebugState.Values[key] = nil
            for i = #DebugState.ValueOrder, 1, -1 do
                if DebugState.ValueOrder[i] == key then
                    table.remove(DebugState.ValueOrder, i)
                    break
                end
            end
        end
        return
    end

    if DebugState.Values[key] == nil then
        table.insert(DebugState.ValueOrder, key)
    end
    DebugState.Values[key] = tostring(value)
end

function clearDebugValues()
    DebugState.Values = {}
    DebugState.ValueOrder = {}
end

function clearDebugTargetWatch()
    for _, connection in ipairs(DebugState.WatchConnections) do
        if connection and connection.Connected then
            connection:Disconnect()
        end
    end
    DebugState.WatchConnections = {}
    DebugState.WatchedInstance = nil
end

function clearIncomingPacketWatch()
    for _, connection in ipairs(DebugState.IncomingConnections) do
        if connection and connection.Connected then
            connection:Disconnect()
        end
    end
    DebugState.IncomingConnections = {}

    for _, connection in pairs(DebugState.RemoteConnections) do
        if connection and connection.Connected then
            connection:Disconnect()
        end
    end
    DebugState.RemoteConnections = {}
end

function formatDebugValue(value, depth)
    depth = depth or 0
    local valueType = typeof(value)

    if valueType == "Instance" then
        return "Inst(" .. safeInstancePath(value) .. ")"
    end
    if valueType == "string" then
        local compact = value:gsub("%s+", " ")
        if #compact > 34 then
            compact = string.sub(compact, 1, 31) .. "..."
        end
        return string.format("%q", compact)
    end
    if valueType == "number" or valueType == "boolean" then
        return tostring(value)
    end
    if valueType == "Vector3" then
        return string.format("Vector3(%.1f, %.1f, %.1f)", value.X, v
