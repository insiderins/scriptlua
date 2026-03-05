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
    TapUseOffscreenPosition = true,
    TapOffscreenX = -32000,
    TapOffscreenY = -32000,
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
            EspEnabled = FarmState.EspEnabled,
            ForceTreeInfoEnabled = FarmState.ForceTreeInfoEnabled
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
        if type(farmConfig.ForceTreeInfoEnabled) == "boolean" then
            FarmState.ForceTreeInfoEnabled = farmConfig.ForceTreeInfoEnabled
        end
    end
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
        return string.format("Vector3(%.1f, %.1f, %.1f)", value.X, value.Y, value.Z)
    end
    if valueType == "CFrame" then
        return "CFrame(...)"
    end
    if valueType == "buffer" then
        local okLen, length = pcall(function()
            return buffer.len(value)
        end)
        if okLen and type(length) == "number" then
            local bytes = {}
            local previewCount = math.min(length, 6)
            for i = 0, previewCount - 1 do
                local okByte, byteValue = pcall(function()
                    return buffer.readu8(value, i)
                end)
                if not okByte then
                    break
                end
                bytes[#bytes + 1] = string.format("%02X", byteValue)
            end

            if #bytes > 0 then
                local suffix = (length > previewCount) and " ..." or ""
                return string.format("buffer[%d](%s%s)", length, table.concat(bytes, " "), suffix)
            end

            return string.format("buffer[%d]", length)
        end

        return "buffer(...)"
    end
    if valueType == "table" then
        if depth >= 1 then
            return "{...}"
        end

        local chunks = {}
        local count = 0
        for _, child in pairs(value) do
            count = count + 1
            if count > 4 then
                chunks[#chunks + 1] = "..."
                break
            end
            chunks[#chunks + 1] = formatDebugValue(child, depth + 1)
        end
        return "{" .. table.concat(chunks, ", ") .. "}"
    end

    return tostring(value)
end

function getArgCount(args)
    return args.n or #args
end

function scanDebugArgs(args, predicate)
    local visited = {}

    local function walk(value, depth)
        if depth > 3 then
            return false
        end
        if predicate(value) then
            return true
        end

        if typeof(value) == "table" and not visited[value] then
            visited[value] = true
            local count = 0
            for _, child in pairs(value) do
                count = count + 1
                if count > 10 then
                    break
                end
                if walk(child, depth + 1) then
                    return true
                end
            end
        end

        return false
    end

    for i = 1, getArgCount(args) do
        local value = args[i]
        if walk(value, 0) then
            return true
        end
    end

    return false
end

function formatDebugArgs(args)
    if getArgCount(args) == 0 then
        return "args: none"
    end

    local parts = {}
    local maxArgs = math.min(getArgCount(args), 5)
    for i = 1, maxArgs do
        parts[#parts + 1] = string.format("#%d=%s", i, formatDebugValue(args[i], 0))
    end
    if getArgCount(args) > maxArgs then
        parts[#parts + 1] = "...(+" .. tostring(getArgCount(args) - maxArgs) .. ")"
    end

    return table.concat(parts, " | ")
end

function matchesHint(text, hints)
    local lower = string.lower(text or "")
    for _, hint in ipairs(hints) do
        if string.find(lower, hint, 1, true) then
            return true
        end
    end
    return false
end

function shouldTrackIncomingPacket(remote, args)
    if not remote then
        return false
    end

    if matchesHint(remote.Name, PACKET_HINTS) then
        return true
    end

    local target = FarmState.CurrentTarget and FarmState.CurrentTarget.instance or DebugState.WatchedInstance
    if target and target.Parent then
        local targetNameLower = string.lower(target.Name or "")
        if scanDebugArgs(args, function(value)
            local valueType = typeof(value)
            if valueType == "Instance" then
                local okCall, result = pcall(function()
                    return value == target or value:IsDescendantOf(target) or target:IsDescendantOf(value)
                end)
                return okCall and result or false
            end
            if valueType == "string" and targetNameLower ~= "" then
                local lowerValue = string.lower(value)
                return string.find(lowerValue, targetNameLower, 1, true) ~= nil
            end
            return false
        end) then
            return true
        end
    end

    local treesFolder = workspace:FindFirstChild("Trees")
    if treesFolder and scanDebugArgs(args, function(value)
        if typeof(value) == "Instance" then
            local okCall, result = pcall(function()
                return value:IsDescendantOf(treesFolder)
            end)
            return okCall and result or false
        end
        return false
    end) then
        return true
    end

    return false
end

function isIncomingRemote(instance)
    if not instance or typeof(instance) ~= "Instance" then
        return false
    end

    if instance:IsA("RemoteEvent") then
        return true
    end

    local okUnreliable, isUnreliable = pcall(function()
        return instance:IsA("UnreliableRemoteEvent")
    end)
    if okUnreliable and isUnreliable then
        return true
    end

    return false
end

function clearFarmPacketWatch()
    for _, connection in ipairs(FarmPacketState.GeneralConnections) do
        if connection and connection.Connected then
            connection:Disconnect()
        end
    end
    FarmPacketState.GeneralConnections = {}

    for _, connection in pairs(FarmPacketState.RemoteConnections) do
        if connection and connection.Connected then
            connection:Disconnect()
        end
    end
    FarmPacketState.RemoteConnections = {}
    FarmPacketState.Running = false
end

function bindFarmPacketRemote(remote)
    if not isIncomingRemote(remote) then
        return false
    end
    if FarmPacketState.RemoteConnections[remote] then
        return false
    end

    local okConn, connOrErr = pcall(function()
        return remote.OnClientEvent:Connect(function(...)
            if not FarmState.Active then
                return
            end
            if matchesHint(remote.Name, {"bytenet"}) then
                FarmPacketState.LastByteNetAt = os.clock()
                FarmPacketState.ByteNetCount = (FarmPacketState.ByteNetCount or 0) + 1
            end
        end)
    end)

    if not okConn then
        return false
    end

    FarmPacketState.RemoteConnections[remote] = connOrErr
    return true
end

function startFarmPacketWatch()
    if FarmPacketState.Running then
        return
    end

    clearFarmPacketWatch()
    FarmPacketState.Running = true
    FarmPacketState.LastByteNetAt = os.clock()
    FarmPacketState.ByteNetCount = 0
    FarmPacketState.ResetMarker = 0

    for _, obj in ipairs(game:GetDescendants()) do
        bindFarmPacketRemote(obj)
    end

    table.insert(FarmPacketState.GeneralConnections, game.DescendantAdded:Connect(function(obj)
        bindFarmPacketRemote(obj)
    end))
end

function resetFarmPacketTimer()
    FarmPacketState.LastByteNetAt = os.clock()
    FarmPacketState.ResetMarker = FarmPacketState.ByteNetCount or 0
end

function secondsSinceFarmPacket()
    if not FarmPacketState.LastByteNetAt or FarmPacketState.LastByteNetAt <= 0 then
        return math.huge
    end
    return os.clock() - FarmPacketState.LastByteNetAt
end

function hasFarmPacketSinceReset()
    return (FarmPacketState.ByteNetCount or 0) > (FarmPacketState.ResetMarker or 0)
end

function bindIncomingRemote(remote)
    if not isIncomingRemote(remote) then
        return false
    end
    if DebugState.RemoteConnections[remote] then
        return false
    end

    local okConn, connOrErr = pcall(function()
        return remote.OnClientEvent:Connect(function(...)
            if not DebugState.Enabled then
                return
            end

            local args = table.pack(...)
            if not shouldTrackIncomingPacket(remote, args) then
                return
            end

            local now = os.clock()
            if now - DebugState.LastLogAt < DebugState.MinLogInterval then
                return
            end
            DebugState.LastLogAt = now

            local compact = formatDebugArgs(args)
            if #compact > 100 then
                compact = string.sub(compact, 1, 97) .. "..."
            end
            DebugState.LastPacketSummary = string.format("%s | %s", remote.Name, compact)
            DebugState.LastPacketAt = now
            pushDebugLog(string.format("IN %s | %s", remote.Name, compact))
        end)
    end)

    if not okConn then
        return false
    end

    DebugState.RemoteConnections[remote] = connOrErr
    return true
end

function startIncomingPacketWatch()
    clearIncomingPacketWatch()

    local boundCount = 0
    for _, obj in ipairs(game:GetDescendants()) do
        if bindIncomingRemote(obj) then
            boundCount = boundCount + 1
        end
    end

    table.insert(DebugState.IncomingConnections, game.DescendantAdded:Connect(function(obj)
        if bindIncomingRemote(obj) then
            boundCount = boundCount + 1
            if DebugState.Enabled and matchesHint(obj.Name, PACKET_HINTS) then
                pushDebugLog("Incoming remote baru: " .. obj.Name)
            end
        end
    end))

    pushDebugLog("Incoming monitor aktif (" .. tostring(boundCount) .. " remote)")
end

function watchDebugTargetInstance(instance)
    clearDebugTargetWatch()
    clearDebugValues()
    setDebugValue("Watch.State", "Waiting target")
    if not DebugState.Enabled or not instance then
        return
    end

    DebugState.WatchedInstance = instance
    setDebugValue("Watch.Target", instance.Name)
    pushDebugLog("Watch target: " .. instance.Name)

    local function addWatch(connection)
        table.insert(DebugState.WatchConnections, connection)
    end

    local function shouldTrackAttribute(attributeName, value)
        if type(value) == "number" then
            return true
        end
        local lowerName = string.lower(tostring(attributeName or ""))
        return string.find(lowerName, "hp", 1, true)
            or string.find(lowerName, "health", 1, true)
            or string.find(lowerName, "durability", 1, true)
            or string.find(lowerName, "break", 1, true)
            or string.find(lowerName, "seed", 1, true)
            or string.find(lowerName, "type", 1, true)
    end

    local boundAttributes = {}
    local function bindAttributeWatcher(attributeName)
        if not attributeName or boundAttributes[attributeName] then
            return
        end
        boundAttributes[attributeName] = true

        local signalOk, signal = pcall(function()
            return instance:GetAttributeChangedSignal(attributeName)
        end)
        if signalOk and signal then
            addWatch(signal:Connect(function()
                local value = instance:GetAttribute(attributeName)
                if shouldTrackAttribute(attributeName, value) then
                    setDebugValue("Attr." .. tostring(attributeName), value)
                    pushDebugLog(string.format("Attr %s -> %s", attributeName, tostring(value)))
                end
            end))
        end
    end

    for attributeName, value in pairs(instance:GetAttributes()) do
        if shouldTrackAttribute(attributeName, value) then
            setDebugValue("Attr." .. tostring(attributeName), value)
            bindAttributeWatcher(attributeName)
        end
    end

    local function valueKeyFor(valueObj)
        local parentName = valueObj.Parent and valueObj.Parent.Name or "?"
        return string.format("Value.%s@%s", valueObj.Name, parentName)
    end

    local function bindValueObject(valueObj)
        local key = valueKeyFor(valueObj)
        setDebugValue(key, valueObj.Value)
        addWatch(valueObj:GetPropertyChangedSignal("Value"):Connect(function()
            setDebugValue(key, valueObj.Value)
            pushDebugLog(string.format("Value %s -> %s", valueObj.Name, tostring(valueObj.Value)))
        end))
    end

    for _, obj in ipairs(instance:GetDescendants()) do
        if obj:IsA("NumberValue") or obj:IsA("IntValue") then
            bindValueObject(obj)
        end
    end

    addWatch(instance.DescendantAdded:Connect(function(obj)
        if obj:IsA("NumberValue") or obj:IsA("IntValue") then
            bindValueObject(obj)
        end
    end))

    addWatch(instance.AncestryChanged:Connect(function(_, parent)
        if not parent then
            pushDebugLog("Target hilang dari workspace.")
            clearDebugTargetWatch()
            setDebugValue("Watch.State", "Target removed")
        end
    end))
end

function refreshDebugTargetWatch()
    if not DebugState.Enabled then
        return
    end

    local target = FarmState.CurrentTarget or FarmState.ScanResults[1]
    local targetInstance = target and target.instance or nil
    if targetInstance ~= DebugState.WatchedInstance then
        watchDebugTargetInstance(targetInstance)
        if not targetInstance then
            pushDebugLog("Belum ada target, scan dulu.")
        end
    end
end

function setDebugWatchEnabled(enabled)
    if DebugState.Enabled == enabled then
        return
    end

    DebugState.Enabled = enabled
    if enabled then
        DebugState.Logs = {}
        clearDebugValues()
        DebugState.LastPacketSummary = nil
        DebugState.LastPacketAt = 0
        DebugState.LastLogAt = 0
        startIncomingPacketWatch()
        pushDebugLog("Debug value: ON")
        refreshDebugTargetWatch()
    else
        clearDebugTargetWatch()
        clearIncomingPacketWatch()
        clearDebugValues()
        DebugState.LastPacketSummary = nil
        DebugState.LastPacketAt = 0
        DebugState.Logs = {}
    end
end

function addCorner(object, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = object
end

function addStroke(object, color, thickness, transparency)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color
    stroke.Thickness = thickness
    stroke.Transparency = transparency or 0
    stroke.Parent = object
end

function styleTextLabel(label, size, color, bold, alignment)
    label.TextSize = size
    label.TextColor3 = color
    label.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
    label.TextXAlignment = alignment or Enum.TextXAlignment.Left
    label.BackgroundTransparency = 1
end

function setButtonStyle(button, normalColor)
    button.BackgroundColor3 = normalColor
    button.TextColor3 = Theme.Text
    button.AutoButtonColor = false
    button.Font = Enum.Font.GothamBold
    button.TextSize = 14
    button.BorderSizePixel = 0
    addCorner(button, 10)
end

function attachHover(button, normalColor, hoverColor)
    button.MouseEnter:Connect(function()
        button.BackgroundColor3 = hoverColor
    end)

    button.MouseLeave:Connect(function()
        button.BackgroundColor3 = normalColor
    end)
end

function isAimCandidatePart(part)
    if not part or not part:IsA("BasePart") then
        return false
    end

    if player.Character and part:IsDescendantOf(player.Character) then
        return false
    end

    if part.Transparency >= 1 then
        return false
    end

    if part.Size.Magnitude < 0.75 then
        return false
    end

    return true
end

function findNearestObjectPart()
    local character = player.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if not hrp then
        return nil
    end

    local nearestPart = nil
    local nearestDistance = Settings.AimMaxDistance
    local nearbyParts = nil

    local gotNearby = pcall(function()
        local overlapParams = OverlapParams.new()
        overlapParams.FilterType = Enum.RaycastFilterType.Exclude
        overlapParams.FilterDescendantsInstances = character and {character} or {}
        nearbyParts = workspace:GetPartBoundsInRadius(hrp.Position, Settings.AimMaxDistance, overlapParams)
    end)

    if not gotNearby or not nearbyParts then
        if os.clock() - lastAimFallbackScanAt < Settings.AimFallbackScanInterval then
            return nil
        end
        lastAimFallbackScanAt = os.clock()
        nearbyParts = workspace:GetDescendants()
    end

    for _, candidate in ipairs(nearbyParts) do
        if candidate:IsA("BasePart") and isAimCandidatePart(candidate) then
            local distance = (candidate.Position - hrp.Position).Magnitude
            if distance < nearestDistance then
                nearestDistance = distance
                nearestPart = candidate
            end
        end
    end

    return nearestPart
end

function enforceCameraLock()
    UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
    UserInputService.MouseIconEnabled = false

    if not Settings.AimNearestObject then
        return
    end

    local camera = workspace.CurrentCamera
    if not camera then
        return
    end

    local now = os.clock()
    if now - lastAimScanAt >= Settings.AimUpdateInterval or not cachedAimTarget or not cachedAimTarget.Parent then
        cachedAimTarget = findNearestObjectPart()
        lastAimScanAt = now
    end

    if cachedAimTarget and cachedAimTarget.Parent then
        camera.CFrame = CFrame.lookAt(camera.CFrame.Position, cachedAimTarget.Position)
    end
end

function setCameraLock(enabled)
    if enabled then
        if cameraLockConnection then
            return
        end

        previousMouseBehavior = UserInputService.MouseBehavior
        previousMouseIconEnabled = UserInputService.MouseIconEnabled
        cachedAimTarget = nil
        lastAimScanAt = 0
        lastAimFallbackScanAt = 0
        cameraLockConnection = RunService.RenderStepped:Connect(enforceCameraLock)
        enforceCameraLock()
        return
    end

    if cameraLockConnection then
        cameraLockConnection:Disconnect()
        cameraLockConnection = nil
    end

    UserInputService.MouseBehavior = previousMouseBehavior or Enum.MouseBehavior.Default
    UserInputService.MouseIconEnabled = previousMouseIconEnabled ~= false
    previousMouseBehavior = nil
    previousMouseIconEnabled = nil
    cachedAimTarget = nil
    lastAimScanAt = 0
    lastAimFallbackScanAt = 0
end

function triggerOneShotCameraLock()
    local camera = workspace.CurrentCamera
    if not camera then
        return
    end

    if Settings.AimNearestObject then
        local target = findNearestObjectPart()
        if target and target.Parent then
            camera.CFrame = CFrame.lookAt(camera.CFrame.Position, target.Position)
            return
        end
    end

    local lookTarget = camera.CFrame.Position + camera.CFrame.LookVector * 24
    camera.CFrame = CFrame.lookAt(camera.CFrame.Position, lookTarget)
end

function isPointInsideGui(x, y)
    if not rootFrame or not rootFrame.Visible then
        return false
    end

    local pos = rootFrame.AbsolutePosition
    local size = rootFrame.AbsoluteSize
    return x >= pos.X and x <= (pos.X + size.X) and y >= pos.Y and y <= (pos.Y + size.Y)
end

function isGuiObjectTapBlocker(obj)
    if not obj or not obj.Visible then
        return false
    end
    if screenGui and obj:IsDescendantOf(screenGui) then
        return false
    end

    if obj:IsA("GuiButton") or obj:IsA("TextBox") or obj:IsA("ScrollingFrame") then
        return true
    end

    local isActive = false
    pcall(function()
        isActive = obj.Active == true
    end)
    if isActive then
        return true
    end

    local isModal = false
    pcall(function()
        isModal = obj.Modal == true
    end)
    if isModal then
        return true
    end

    -- Treat visible foreign GUI surfaces as blockers so auto tap never clicks through them.
    local size = obj.AbsoluteSize
    if size and size.X >= 24 and size.Y >= 24 then
        local bgTransparency = 1
        pcall(function()
            bgTransparency = obj.BackgroundTransparency
        end)
        if type(bgTransparency) == "number" and bgTransparency < 0.98 then
            return true
        end

        if obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
            local imageTransparency = 1
            pcall(function()
                imageTransparency = obj.ImageTransparency
            end)
            if type(imageTransparency) == "number" and imageTransparency < 0.98 then
                return true
            end
        end
    end

    return false
end

function isPointBlockedByGameGui(x, y)
    if isPointInsideGui(x, y) then
        return true
    end

    local function hasBlockerAt(layer)
        if not layer then
            return false
        end
        local ok, objects = pcall(function()
            return layer:GetGuiObjectsAtPosition(x, y)
        end)
        if not ok or type(objects) ~= "table" then
            return false
        end

        for _, obj in ipairs(objects) do
            if isGuiObjectTapBlocker(obj) then
                return true
            end
        end
        return false
    end

    if hasBlockerAt(playerGui) then
        return true
    end

    local coreBlocked = false
    pcall(function()
        local coreGui = game:GetService("CoreGui")
        coreBlocked = hasBlockerAt(coreGui)
    end)
    if coreBlocked then
        return true
    end

    if type(gethui) == "function" then
        local huiBlocked = false
        pcall(function()
            huiBlocked = hasBlockerAt(gethui())
        end)
        if huiBlocked then
            return true
        end
    end

    return false
end

function getTapPosition(forceRefresh)
    local camera = workspace.CurrentCamera
    local now = os.clock()
    local refreshInterval = Settings.TapSafePositionRefreshInterval or 0.25
    if not forceRefresh and now - (lastTapPositionAt or 0) < refreshInterval then
        if not isPointBlockedByGameGui(lastTapX, lastTapY) then
            return lastTapX, lastTapY
        end
    end

    if camera then
        local viewport = camera.ViewportSize
        local candidates = {
            {math.floor(viewport.X * 0.5), math.floor(viewport.Y * 0.5)},
            {math.max(35, viewport.X - 45), math.floor(viewport.Y * 0.5)},
            {45, math.floor(viewport.Y * 0.5)},
            {math.floor(viewport.X * 0.5), math.max(45, viewport.Y - 85)},
            {math.max(35, viewport.X - 70), math.max(55, viewport.Y - 120)},
            {70, math.max(55, viewport.Y - 120)},
            {math.floor(viewport.X * 0.5), 55},
            {math.max(35, viewport.X - 55), 55}
        }

        for _, point in ipairs(candidates) do
            if not isPointBlockedByGameGui(point[1], point[2]) then
                lastTapX = point[1]
                lastTapY = point[2]
                lastTapPositionAt = now
                return point[1], point[2]
            end
        end

        return nil, nil
    end

    return nil, nil
end

function getOffscreenTapPosition()
    if Settings.TapUseOffscreenPosition ~= true then
        return nil, nil
    end

    local offscreenX = tonumber(Settings.TapOffscreenX)
    local offscreenY = tonumber(Settings.TapOffscreenY)
    if offscreenX and offscreenY then
        return math.floor(offscreenX), math.floor(offscreenY)
    end

    local camera = workspace.CurrentCamera
    if camera then
        local viewport = camera.ViewportSize
        return math.floor(viewport.X + 240), math.floor(viewport.Y + 240)
    end

    return -32000, -32000
end

function sendTap(isDown, x, y, useOffscreen)
    local tapX, tapY = x, y
    if useOffscreen then
        local offX, offY = getOffscreenTapPosition()
        if offX and offY then
            tapX, tapY = offX, offY
        end
    end

    if not tapX or not tapY then
        tapX, tapY = getTapPosition(false)
    end
    if not tapX or not tapY then
        return false
    end

    if not useOffscreen and isPointBlockedByGameGui(tapX, tapY) then
        return false
    end

    local ok = pcall(function()
        VirtualInputManager:SendMouseButtonEvent(tapX, tapY, 0, isDown, game, 0)
    end)

    if ok then
        return true
    end

    pcall(function()
        if isDown then
            VirtualUser:Button1Down(Vector2.new(tapX, tapY), workspace.CurrentCamera and workspace.CurrentCamera.CFrame or CFrame.new())
        else
            VirtualUser:Button1Up(Vector2.new(tapX, tapY), workspace.CurrentCamera and workspace.CurrentCamera.CFrame or CFrame.new())
        end
    end)
    return true
end

function performTapCycle()
    local useOffscreenTap = Settings.TapUseOffscreenPosition == true
    local tapX, tapY = nil, nil
    if useOffscreenTap then
        tapX, tapY = getOffscreenTapPosition()
    else
        tapX, tapY = getTapPosition(false)
    end
    if not tapX or not tapY then
        task.wait(math.max(Settings.WaitDuration or 0.15, 0.08))
        return
    end

    local pressed = sendTap(true, tapX, tapY, useOffscreenTap)
    if not pressed then
        task.wait(math.max(Settings.WaitDuration or 0.15, 0.08))
        return
    end

    task.wait(Settings.ClickDuration)
    sendTap(false, tapX, tapY, useOffscreenTap)
    task.wait(Settings.WaitDuration)
end

function collectInventoryTools()
    local tools = {}
    local seen = {}

    local backpack = player:FindFirstChildOfClass("Backpack")
    if backpack then
        for _, item in ipairs(backpack:GetChildren()) do
            if item:IsA("Tool") and not seen[item] then
                seen[item] = true
                table.insert(tools, item)
            end
        end
    end

    local character = player.Character
    if character then
        for _, item in ipairs(character:GetChildren()) do
            if item:IsA("Tool") and not seen[item] then
                seen[item] = true
                table.insert(tools, item)
            end
        end
    end

    return tools
end

function parseCompactNumber(value)
    if type(value) == "number" then
        return value
    end
    if type(value) ~= "string" then
        return nil
    end

    local cleaned = string.gsub(string.lower(value), "[,%s]", "")
    if cleaned == "" then
        return nil
    end

    local suffix = string.sub(cleaned, -1)
    local factor = 1
    if suffix == "k" then
        factor = 1e3
        cleaned = string.sub(cleaned, 1, -2)
    elseif suffix == "m" then
        factor = 1e6
        cleaned = string.sub(cleaned, 1, -2)
    elseif suffix == "b" then
        factor = 1e9
        cleaned = string.sub(cleaned, 1, -2)
    end

    local numeric = tonumber(cleaned)
    if not numeric then
        return nil
    end
    return numeric * factor
end

function readNumericValue(container, keyName)
    if not container or not keyName or keyName == "" then
        return nil
    end

    local direct = container:GetAttribute(keyName)
    local parsedDirect = parseCompactNumber(direct)
    if parsedDirect then
        return parsedDirect
    end

    local valueObj = container:FindFirstChild(keyName, true)
    if valueObj then
        if valueObj:IsA("IntValue") or valueObj:IsA("NumberValue") then
            return tonumber(valueObj.Value)
        end
        if valueObj:IsA("StringValue") then
            return parseCompactNumber(valueObj.Value)
        end
    end

    return nil
end

function getToolSlotIndex(tool)
    if not tool then
        return nil
    end

    for _, keyName in ipairs(TOOL_SLOT_KEYS) do
        local indexValue = readNumericValue(tool, keyName)
        if indexValue then
            return math.floor(indexValue)
        end
    end

    return nil
end

function findFirstBackpackTool()
    local backpack = player:FindFirstChildOfClass("Backpack")
    if not backpack then
        return nil
    end

    for _, item in ipairs(backpack:GetChildren()) do
        if item:IsA("Tool") then
            return item
        end
    end

    return nil
end

function findSlotOneTool()
    local tools = collectInventoryTools()
    if #tools == 0 then
        return nil
    end

    local exactSlotOne = nil
    local smallestIndexedTool = nil
    local smallestIndex = math.huge
    for _, tool in ipairs(tools) do
        local slotIndex = getToolSlotIndex(tool)
        if slotIndex == 1 then
            exactSlotOne = tool
            break
        end
        if slotIndex and slotIndex > 0 and slotIndex < smallestIndex then
            smallestIndex = slotIndex
            smallestIndexedTool = tool
        end
    end

    if exactSlotOne then
        return exactSlotOne
    end
    if smallestIndexedTool then
        return smallestIndexedTool
    end

    return findFirstBackpackTool() or tools[1]
end

function tapKeyboardKey(keyCode)
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
    end)
    task.wait(0.03)
    pcall(function()
        VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
    end)
end

function equipToolSlotOne()
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return false
    end

    local targetTool = findSlotOneTool()
    if not targetTool then
        return false
    end

    local equipped = character:FindFirstChildWhichIsA("Tool")
    if equipped == targetTool then
        return true
    end

    if UserInputService.KeyboardEnabled then
        tapKeyboardKey(Enum.KeyCode.One)
        local keyEquipped = character:FindFirstChildWhichIsA("Tool")
        if keyEquipped == targetTool then
            return true
        end
    end

    if equipped and equipped ~= targetTool then
        pcall(function()
            humanoid:UnequipTools()
        end)
        task.wait(0.02)
    end

    if targetTool.Parent ~= character then
        pcall(function()
            humanoid:EquipTool(targetTool)
        end)
    end

    local finalEquipped = character:FindFirstChildWhichIsA("Tool")
    return finalEquipped == targetTool
end

function unequipAllTools()
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        pcall(function()
            humanoid:UnequipTools()
        end)
    end
end

function lowerContainsHint(text, hints)
    local lowerText = string.lower(text or "")
    for _, hint in ipairs(hints) do
        if string.find(lowerText, hint, 1, true) then
            return true
        end
    end
    return false
end

function normalizeFarmTreeText(value)
    local text = tostring(value or "")
    text = string.lower(text)
    text = string.gsub(text, "_", " ")
    text = string.gsub(text, "%s+", " ")
    text = string.gsub(text, "^%s*(.-)%s*$", "%1")
    return text
end

function normalizeFarmPriorityMode(mode)
    local normalized = normalizeFarmTreeText(mode)
    if normalized == "rarity" or normalized == "highest rarity" then
        return "RARITY"
    end
    return "HP"
end

function getFarmPriorityModeLabel(mode)
    local normalized = normalizeFarmPriorityMode(mode)
    if normalized == "RARITY" then
        return "Highest Rarity"
    end
    return "Highest HP"
end

function parseFarmRarityScore(rarityText)
    if rarityText == nil then
        return 0
    end

    local text = cleanGuiText(tostring(rarityText))
    if text == "" then
        return 0
    end

    local numeric = parseCurrencyPerSecondText(text)
    if not numeric then
        local token = string.match(string.lower(text), "([%d%.,]+[kmb]?)")
        if token then
            numeric = parseCompactNumber(token)
        end
    end
    if numeric and numeric > 0 then
        return numeric
    end

    local lowerText = normalizeFarmTreeText(text)
    local bestWordScore = 0
    for rarityWord, rarityScore in pairs(FARM_RARITY_WORD_SCORES) do
        if string.find(lowerText, rarityWord, 1, true) then
            if rarityScore > bestWordScore then
                bestWordScore = rarityScore
            end
        end
    end
    return bestWordScore
end

function compareFarmTargets(a, b)
    local priorityMode = normalizeFarmPriorityMode(FarmState.PriorityMode)
    if priorityMode == "RARITY" then
        local aRarityScore = parseFarmRarityScore(a and a.rarity)
        local bRarityScore = parseFarmRarityScore(b and b.rarity)
        if aRarityScore ~= bRarityScore then
            return aRarityScore > bRarityScore
        end
    end

    local aHp = tonumber(a and a.hp) or 0
    local bHp = tonumber(b and b.hp) or 0
    if aHp ~= bHp then
        return aHp > bHp
    end

    local aDistance = tonumber(a and a.distance) or math.huge
    local bDistance = tonumber(b and b.distance) or math.huge
    return aDistance < bDistance
end

function normalizeFarmTreeFilterInput(rawFilter)
    local sourceText = tostring(rawFilter or "")
    sourceText = string.gsub(sourceText, "[\r\n]+", ",")

    local displayTokens = {}
    local seenNormalized = {}
    for token in string.gmatch(sourceText, "([^,;|]+)") do
        local trimmed = string.gsub(token, "^%s*(.-)%s*$", "%1")
        local normalized = normalizeFarmTreeText(trimmed)
        if normalized ~= ""
            and normalized ~= "all"
            and normalized ~= "semua"
            and not seenNormalized[normalized] then
            seenNormalized[normalized] = true
            table.insert(displayTokens, trimmed)
        end
    end

    return table.concat(displayTokens, ", ")
end

function getNormalizedFarmTreeFilters(rawFilter)
    local normalizedInput = normalizeFarmTreeFilterInput(rawFilter)
    if normalizedInput == "" then
        return {}
    end

    local normalizedFilters = {}
    for token in string.gmatch(normalizedInput, "([^,]+)") do
        local normalized = normalizeFarmTreeText(token)
        if normalized ~= "" then
            table.insert(normalizedFilters, normalized)
        end
    end

    return normalizedFilters
end

function getToolCountValue(tool, preferredKey)
    if not tool then
        return nil
    end

    if preferredKey and preferredKey ~= "" then
        local preferredValue = readNumericValue(tool, preferredKey)
        if preferredValue then
            return preferredValue
        end
    end

    for _, keyName in ipairs(COUNT_VALUE_KEYS) do
        local value = readNumericValue(tool, keyName)
        if value then
            return value
        end
    end

    return nil
end

function getToolCurrencyPerSecond(tool)
    local preferredKey = SellState.CountAttr
    if preferredKey == nil or preferredKey == "" then
        preferredKey = "CurrencyPerSecond"
    end

    local currency = getToolCountValue(tool, preferredKey)
    if currency then
        return currency
    end

    return getToolCountValue(tool, "CurrencyPerSecond")
end

function getToolWeightValue(tool)
    if not tool then
        return nil
    end

    for _, keyName in ipairs(WEIGHT_VALUE_KEYS) do
        local value = readNumericValue(tool, keyName)
        if value then
            return value
        end
    end

    return nil
end

function cleanGuiText(text)
    if type(text) ~= "string" then
        return ""
    end

    local cleaned = string.gsub(text, "[\r\n]+", " ")
    cleaned = string.gsub(cleaned, "<.->", " ")
    cleaned = string.gsub(cleaned, "%s+", " ")
    cleaned = string.gsub(cleaned, "^%s*(.-)%s*$", "%1")
    return cleaned
end

function normalizeNameForMatch(text)
    local cleaned = cleanGuiText(text)
    if cleaned == "" then
        return ""
    end

    local lowerText = string.lower(cleaned)
    lowerText = string.gsub(lowerText, "[_%-%./]+", " ")
    lowerText = string.gsub(lowerText, "[^%a%d%s]+", " ")
    lowerText = string.gsub(lowerText, "%s+", " ")
    lowerText = string.gsub(lowerText, "^%s*(.-)%s*$", "%1")
    lowerText = string.gsub(lowerText, "%f[%d]%d+%f[%D]", "")
    lowerText = string.gsub(lowerText, "%s+", " ")
    lowerText = string.gsub(lowerText, "^%s*(.-)%s*$", "%1")
    return lowerText
end

function buildTokenSet(text)
    local tokens = {}
    for token in string.gmatch(text or "", "[%a%d]+") do
        if #token >= 3 then
            tokens[token] = true
        end
    end
    return tokens
end

function countSharedTokens(textA, textB)
    local tokenA = buildTokenSet(textA)
    local tokenB = buildTokenSet(textB)
    local shared = 0
    for token in pairs(tokenA) do
        if tokenB[token] then
            shared = shared + 1
        end
    end
    return shared
end

function parseCurrencyPerSecondText(text)
    local cleaned = cleanGuiText(text)
    if cleaned == "" then
        return nil
    end

    local lowerText = string.lower(cleaned)
    local token = string.match(lowerText, "([%d%.,]+[kmb]?)%s*[¢c$]?%s*/%s*s")
    if not token then
        token = string.match(lowerText, "([%d%.,]+[kmb]?)%s*cps")
    end
    if not token then
        token = string.match(lowerText, "([%d%.,]+[kmb]?)%s*c/s")
    end
    if not token then
        return nil
    end

    return parseCompactNumber(token)
end

function parseWeightText(text)
    local cleaned = cleanGuiText(text)
    if cleaned == "" then
        return nil
    end

    local lowerText = string.lower(cleaned)

    local tonToken = string.match(lowerText, "([%d%.,]+)%s*tons?")
    if tonToken then
        local tonValue = parseCompactNumber(tonToken)
        if tonValue then
            return tonValue * 1000
        end
    end

    local kgToken = string.match(lowerText, "([%d%.,]+)%s*kg")
    if kgToken then
        return parseCompactNumber(kgToken)
    end

    return nil
end

function collectGuiTexts(root, maxTexts)
    local texts = {}
    if not root then
        return texts
    end

    local limit = maxTexts or 16

    if (root:IsA("TextLabel") or root:IsA("TextButton")) and root.Visible then
        local selfText = cleanGuiText(root.Text or "")
        if selfText ~= "" then
            texts[#texts + 1] = selfText
        end
    end

    for _, desc in ipairs(root:GetDescendants()) do
        if #texts >= limit then
            break
        end

        if (desc:IsA("TextLabel") or desc:IsA("TextButton")) and desc.Visible then
            local text = cleanGuiText(desc.Text or "")
            if text ~= "" then
                texts[#texts + 1] = text
            end
        end
    end

    return texts
end

function inferGuiCardName(texts)
    local best = nil
    for _, text in ipairs(texts or {}) do
        local cleaned = cleanGuiText(text)
        local lowerText = string.lower(cleaned)
        if cleaned ~= ""
            and string.find(cleaned, "%a")
            and #cleaned >= 3
            and #cleaned <= 44
            and not string.find(lowerText, "/s", 1, true)
            and not string.find(lowerText, "kg", 1, true)
            and not string.find(lowerText, "ton", 1, true)
            and not string.find(lowerText, "inventory", 1, true)
            and not string.find(lowerText, "press and hold", 1, true)
            and not string.find(lowerText, "sell", 1, true)
            and not string.find(lowerText, "trees", 1, true)
            and not string.find(lowerText, "axes", 1, true)
            and not string.find(lowerText, "skins", 1, true)
            and not string.find(lowerText, "items", 1, true) then
            if not best or #cleaned > #best then
                best = cleaned
            end
        end
    end

    return best
end

function getInventoryGuiCards(forceRefresh)
    local now = os.clock()
    local cacheInterval = Settings.SellGuiCardScanInterval or 1.4
    if not forceRefresh and now - sellGuiCardCache.LastScanAt < cacheInterval then
        for _, card in ipairs(sellGuiCardCache.Cards) do
            card.used = false
        end
        return sellGuiCardCache.Cards
    end

    local cards = {}
    local seenKeys = {}

    for _, obj in ipairs(playerGui:GetDescendants()) do
        if obj:IsA("GuiObject")
            and obj.Visible
            and obj.AbsoluteSize.X >= 95
            and obj.AbsoluteSize.Y >= 80
            and obj.AbsoluteSize.X <= 420
            and obj.AbsoluteSize.Y <= 420
            and not obj:IsA("TextLabel")
            and not obj:IsA("TextButton")
            and not (screenGui and obj:IsDescendantOf(screenGui)) then
            local texts = collectGuiTexts(obj, 18)
            if #texts >= 2 then
                local cpsValue = nil
                local weightValue = nil
                for _, text in ipairs(texts) do
                    if not cpsValue then
                        cpsValue = parseCurrencyPerSecondText(text)
                    end
                    if not weightValue then
                        weightValue = parseWeightText(text)
                    end
                    if cpsValue and weightValue then
                        break
                    end
                end

                if cpsValue and weightValue then
                    local itemName = inferGuiCardName(texts)
                    if itemName then
                        local uniqueKey = safeInstancePath(obj)
                        if not seenKeys[uniqueKey] then
                            seenKeys[uniqueKey] = true
                            local normalizedName = normalizeNameForMatch(itemName)
                            cards[#cards + 1] = {
                                object = obj,
                                name = itemName,
                                nameLower = string.lower(itemName),
                                normalizedName = normalizedName,
                                currencyPerSecond = cpsValue,
                                weight = weightValue,
                                used = false
                            }
                        end
                    end
                end
            end
        end
    end

    table.sort(cards, function(a, b)
        if a.currencyPerSecond == b.currencyPerSecond then
            return a.weight > b.weight
        end
        return a.currencyPerSecond > b.currencyPerSecond
    end)

    sellGuiCardCache.LastScanAt = now
    sellGuiCardCache.Cards = cards
    return cards
end

function buildInventoryGuiMetricMap(cards)
    local metrics = {}
    local function pushMetric(nameKey, card)
        if not nameKey or nameKey == "" then
            return
        end

        local entry = metrics[nameKey]
        if not entry then
            metrics[nameKey] = {
                CurrencyPerSecond = card.currencyPerSecond or 0,
                Weight = card.weight or 0,
                Count = 1
            }
            return
        end

        if (card.currencyPerSecond or 0) > (entry.CurrencyPerSecond or 0) then
            entry.CurrencyPerSecond = card.currencyPerSecond
        end
        if (card.weight or 0) > (entry.Weight or 0) then
            entry.Weight = card.weight
        end
        entry.Count = (entry.Count or 0) + 1
    end

    for _, card in ipairs(cards or {}) do
        local nameKey = card.nameLower or string.lower(card.name or "")
        local normalizedKey = card.normalizedName or normalizeNameForMatch(card.name or "")

        pushMetric(nameKey, card)
        if normalizedKey ~= nameKey then
            pushMetric(normalizedKey, card)
        end
    end

    return metrics
end

function getGuiMetricForToolName(toolName, guiMetricMap)
    local directKey = string.lower(toolName or "")
    if directKey ~= "" then
        local directEntry = guiMetricMap[directKey]
        if directEntry then
            return directEntry
        end
    end

    local normalizedToolName = normalizeNameForMatch(toolName or "")
    if normalizedToolName ~= "" then
        local normalizedEntry = guiMetricMap[normalizedToolName]
        if normalizedEntry then
            return normalizedEntry
        end
    end

    local best = nil
    local bestScore = 0
    for key, entry in pairs(guiMetricMap or {}) do
        if key ~= "" then
            local score = 0
            if normalizedToolName ~= "" then
                if key == normalizedToolName then
                    score = score + 10
                elseif string.find(key, normalizedToolName, 1, true) or string.find(normalizedToolName, key, 1, true) then
                    score = score + 7
                else
                    score = score + (countSharedTokens(key, normalizedToolName) * 2)
                end
            end
            if score > bestScore then
                bestScore = score
                best = entry
            end
        end
    end

    if bestScore > 0 then
        return best
    end

    return nil
end

function scanInventoryAttributePreview()
    local tools = collectInventoryTools()
    local guiCards = getInventoryGuiCards(true)
    if #tools == 0 and #guiCards == 0 then
        return "Inventory kosong."
    end

    local numericAttrFrequency = {}
    for _, tool in ipairs(tools) do
        for key, value in pairs(tool:GetAttributes()) do
            if type(value) == "number" then
                numericAttrFrequency[key] = (numericAttrFrequency[key] or 0) + 1
            end
        end
    end

    local numericCandidates = {}
    for key, freq in pairs(numericAttrFrequency) do
        numericCandidates[#numericCandidates + 1] = {key = key, freq = freq}
    end
    table.sort(numericCandidates, function(a, b)
        if a.freq == b.freq then
            return a.key < b.key
        end
        return a.freq > b.freq
    end)

    local candidateParts = {}
    for i = 1, math.min(4, #numericCandidates) do
        local item = numericCandidates[i]
        candidateParts[#candidateParts + 1] = string.format("%s(%d)", item.key, item.freq)
    end
    local candidateText = (#candidateParts > 0) and table.concat(candidateParts, ", ") or "-"

    local lines = {}
    local maxTools = math.min(6, #tools)
    for i = 1, maxTools do
        local tool = tools[i]
        local attrs = tool:GetAttributes()
        local attrParts = {}
        local attrCount = 0
        for key, value in pairs(attrs) do
            attrCount = attrCount + 1
            if attrCount > 5 then
                attrParts[#attrParts + 1] = "..."
                break
            end
            attrParts[#attrParts + 1] = string.format("%s=%s", tostring(key), tostring(value))
        end

        if #attrParts == 0 then
            attrParts[#attrParts + 1] = "no attrs"
        end

        lines[#lines + 1] = string.format(
            "%d) %s | CPS=%s | Weight=%s | %s",
            i,
            tool.Name,
            tostring(getToolCurrencyPerSecond(tool) or "-"),
            tostring(getToolWeightValue(tool) or "-"),
            table.concat(attrParts, ", ")
        )
    end

    local guiLines = {}
    local maxGuiCards = math.min(6, #guiCards)
    for i = 1, maxGuiCards do
        local card = guiCards[i]
        guiLines[#guiLines + 1] = string.format(
            "%d) %s | CPS=%s | Weight=%s",
            i,
            card.name,
            tostring(card.currencyPerSecond),
            tostring(card.weight)
        )
    end

    local toolSection = (#lines > 0) and table.concat(lines, "\n") or "-"
    local guiSection = (#guiLines > 0) and table.concat(guiLines, "\n") or "-"

    return string.format(
        "Tools Obj: %d | GUI Cards: %d | Numeric Attr Candidate: %s\nFilter Metric: CurrencyPerSecond + Weight\nTool Data:\n%s\n\nGUI Data:\n%s",
        #tools,
        #guiCards,
        candidateText,
        toolSection,
        guiSection
    )
end

function isSellRemoteCandidate(remote)
    if not remote then
        return false
    end

    local isRemoteLike = false
    if remote:IsA("RemoteFunction") then
        isRemoteLike = true
    elseif isIncomingRemote(remote) then
        isRemoteLike = true
    end

    if not isRemoteLike then
        return false
    end

    local ancestryName = remote.Name
    local parent = remote.Parent
    local depth = 0
    while parent and depth < 3 do
        ancestryName = ancestryName .. " " .. parent.Name
        parent = parent.Parent
        depth = depth + 1
    end

    return lowerContainsHint(ancestryName, SELL_REMOTE_HINTS)
end

function getSellRemoteCandidates(forceRefresh)
    local now = os.clock()
    local cacheInterval = Settings.SellRemoteScanInterval or 24
    if not forceRefresh and now - sellRemoteCache.LastScanAt < cacheInterval then
        return sellRemoteCache.Remotes
    end

    local remotes = {}
    local seen = {}
    local function pushRemote(obj)
        if obj and not seen[obj] and isSellRemoteCandidate(obj) then
            seen[obj] = true
            remotes[#remotes + 1] = obj
        end
    end

    local roots = {}
    pcall(function()
        local replicatedStorage = game:GetService("ReplicatedStorage")
        if replicatedStorage then
            roots[#roots + 1] = replicatedStorage
        end
    end)
    pcall(function()
        local replicatedFirst = game:GetService("ReplicatedFirst")
        if replicatedFirst then
            roots[#roots + 1] = replicatedFirst
        end
    end)

    for _, root in ipairs(roots) do
        for _, obj in ipairs(root:GetDescendants()) do
            pushRemote(obj)
        end
    end

    if #remotes == 0 or forceRefresh then
        for _, obj in ipairs(game:GetDescendants()) do
            pushRemote(obj)
        end
    end

    sellRemoteCache.LastScanAt = now
    sellRemoteCache.Remotes = remotes
    return remotes
end

function getGuiObjectTextBlob(guiObject, maxPieces)
    if not guiObject then
        return ""
    end

    local pieces = {}
    local limit = maxPieces or 20
    local function pushText(value)
        local text = cleanGuiText(value)
        if text ~= "" then
            pieces[#pieces + 1] = text
        end
    end

    pushText(guiObject.Name or "")
    if guiObject:IsA("TextLabel") or guiObject:IsA("TextButton") then
        pushText(guiObject.Text or "")
    end

    for _, desc in ipairs(guiObject:GetDescendants()) do
        if #pieces >= limit then
            break
        end
        if desc:IsA("TextLabel") or desc:IsA("TextButton") then
            pushText(desc.Text or "")
            pushText(desc.Name or "")
        end
    end

    return table.concat(pieces, " ")
end

function isSellDialogVisible()
    for _, obj in ipairs(playerGui:GetDescendants()) do
        if obj:IsA("TextLabel") or obj:IsA("TextButton") then
            if obj.Visible then
                local text = cleanGuiText(obj.Text or "")
                if text ~= "" then
                    if lowerContainsHint(text, SELL_DIALOG_OPTION_ONE_HINTS)
                        or lowerContainsHint(text, SELL_DIALOG_OPTION_TWO_HINTS) then
                        return true
                    end
                end
            end
        elseif obj:IsA("GuiButton") and obj.Visible then
            local sourceText = getGuiObjectTextBlob(obj, 14)
            if sourceText ~= "" then
                if lowerContainsHint(sourceText, SELL_DIALOG_OPTION_ONE_HINTS)
                    or lowerContainsHint(sourceText, SELL_DIALOG_OPTION_TWO_HINTS) then
                    return true
                end
            end
        end
    end

    return false
end

function scanSellPromptCandidates(forceRefresh)
    local now = os.clock()
    if not forceRefresh and (now - (SellState.LastPromptScanAt or 0) < 2.5) and not SellState.CachedPrompt then
        return {}
    end
    if not forceRefresh and SellState.CachedPrompt and SellState.CachedPrompt.Parent and (now - (SellState.LastPromptScanAt or 0) < 8) then
        return {{
            prompt = SellState.CachedPrompt,
            score = 999,
            distance = 0
        }}
    end

    local character = player.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    local sellHints = {"sell", "shop", "merchant", "vendor", "trade", "pawn", "market", "store"}
    local npcHints = {"perry", "merchant", "vendor", "shopkeeper", "trader"}

    local candidates = {}
    local prompts = getWorkspacePromptList(forceRefresh, Settings.SellPromptCacheInterval)
    for _, obj in ipairs(prompts) do
        if obj and obj.Parent and obj.Enabled then
            local part = getPromptPart(obj)
            local model = obj:FindFirstAncestorOfClass("Model")
            local contextText = string.format(
                "%s %s %s %s %s %s",
                obj.Name or "",
                obj.ActionText or "",
                obj.ObjectText or "",
                obj.Parent and obj.Parent.Name or "",
                part and part.Name or "",
                model and model.Name or ""
            )

            local score = 0
            if lowerContainsHint(contextText, sellHints) then
                score = score + 5
            end
            if lowerContainsHint(contextText, npcHints) then
                score = score + 4
            end

            local lowerContext = string.lower(contextText)
            if string.find(lowerContext, "perry", 1, true) then
                score = score + 8
            end

            if score > 0 then
                local distance = math.huge
                if hrp and part then
                    distance = (part.Position - hrp.Position).Magnitude
                end
                candidates[#candidates + 1] = {
                    prompt = obj,
                    score = score,
                    distance = distance
                }
            end
        end
    end

    table.sort(candidates, function(a, b)
        if a.score == b.score then
            return a.distance < b.distance
        end
        return a.score > b.score
    end)

    SellState.LastPromptScanAt = now
    SellState.CachedPrompt = candidates[1] and candidates[1].prompt or nil
    return candidates
end

function triggerSellNpcPrompt(forceRefresh)
    local candidates = scanSellPromptCandidates(forceRefresh)
    if #candidates == 0 then
        return false
    end

    for i = 1, math.min(3, #candidates) do
        local prompt = candidates[i].prompt
        if prompt and prompt.Parent then
            local ok = sendInteractAction(prompt)
            if ok then
                task.wait(0.16)
                if isSellDialogVisible() then
                    return true
                end
            end
        end
    end

    return false
end

function ensureSellDialogReady()
    if isSellDialogVisible() then
        SellState.LastDialogReady = true
        return true
    end

    if triggerSellNpcPrompt(false) then
        SellState.LastDialogReady = true
        return true
    end

    if triggerSellNpcPrompt(true) then
        SellState.LastDialogReady = true
        return true
    end

    sendInteractAction(nil)
    task.wait(0.1)
    SellState.LastDialogReady = isSellDialogVisible()
    return SellState.LastDialogReady
end

function attemptSellTool(tool, remoteList)
    if not tool or not tool.Parent then
        return false
    end

    local function stillOwnedByPlayer()
        if not tool or not tool.Parent then
            return false
        end

        local backpack = player:FindFirstChildOfClass("Backpack")
        local character = player.Character
        if backpack and tool:IsDescendantOf(backpack) then
            return true
        end
        if character and tool:IsDescendantOf(character) then
            return true
        end
        return false
    end

    local function soldStateChanged(previousCount)
        if not stillOwnedByPlayer() then
            return true
        end

        if previousCount then
            local currentCount = getToolCountValue(tool, nil)
            if currentCount and currentCount < previousCount then
                return true
            end
        end

        return false
    end

    local function waitForSold(previousCount)
        local startAt = os.clock()
        while os.clock() - startAt < 0.28 do
            if soldStateChanged(previousCount) then
                return true
            end
            task.wait(0.03)
        end
        return soldStateChanged(previousCount)
    end

    local remotes = remoteList or getSellRemoteCandidates(false)
    if #remotes == 0 then
        return false
    end

    ensureSellDialogReady()

    local payloads = {
        tool,
        tool.Name,
        "I want to sell this.",
        "SellThis",
        {Option = 2},
        {tool},
        {Tool = tool},
        {Item = tool},
        {Name = tool.Name},
        {ItemName = tool.Name},
        {tool.Name, 1},
        {tool, 1}
    }

    for _, remote in ipairs(remotes) do
        local isUnreliable = false
        local okUnrel, unrelResult = pcall(function()
            return remote:IsA("UnreliableRemoteEvent")
        end)
        if okUnrel and unrelResult then
            isUnreliable = true
        end

        if remote:IsA("RemoteEvent") or isUnreliable then
            for _, payload in ipairs(payloads) do
                local beforeCount = getToolCountValue(tool, nil)
                local ok = pcall(function()
                    remote:FireServer(payload)
                end)
                if ok and waitForSold(beforeCount) then
                    return true
                end
            end
        elseif remote:IsA("RemoteFunction") then
            for _, payload in ipairs(payloads) do
                local beforeCount = getToolCountValue(tool, nil)
                local ok, invokeResult = pcall(function()
                    return remote:InvokeServer(payload)
                end)
                if ok and (waitForSold(beforeCount) or invokeResult == true) then
                    return true
                end
            end
        end
    end

    return false
end

function isToolStillOwnedByPlayer(tool)
    if not tool or not tool.Parent then
        return false
    end

    local backpack = player:FindFirstChildOfClass("Backpack")
    local character = player.Character
    if backpack and tool:IsDescendantOf(backpack) then
        return true
    end
    if character and tool:IsDescendantOf(character) then
        return true
    end
    return false
end

function waitUntilToolSold(tool, timeoutSeconds)
    local timeout = timeoutSeconds or 1.15
    local startedAt = os.clock()
    while os.clock() - startedAt < timeout do
        if not isToolStillOwnedByPlayer(tool) then
            return true
        end
        task.wait(0.05)
    end
    return not isToolStillOwnedByPlayer(tool)
end

function clickGuiButton(button)
    if not button or not button:IsA("GuiButton") then
        return false
    end
    if not button.Visible or button.AbsoluteSize.X <= 0 or button.AbsoluteSize.Y <= 0 then
        return false
    end

    local clicked = false
    local centerX = math.floor(button.AbsolutePosition.X + (button.AbsoluteSize.X * 0.5))
    local centerY = math.floor(button.AbsolutePosition.Y + (button.AbsoluteSize.Y * 0.5))

    local okActivate = pcall(function()
        button:Activate()
    end)
    if okActivate then
        clicked = true
    end

    if type(firesignal) == "function" then
        local okSignal = pcall(function()
            firesignal(button.MouseButton1Click)
        end)
        if okSignal then
            clicked = true
        end
        pcall(function()
            firesignal(button.Activated)
            clicked = true
        end)
    end

    local okDown = pcall(function()
        VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, true, game, 0)
    end)
    task.wait(0.03)
    local okUp = pcall(function()
        VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, false, game, 0)
    end)
    if okDown and okUp then
        clicked = true
    end

    return clicked
end

function getOwnedToolCount()
    return #collectInventoryTools()
end

function waitOwnedToolCountDrop(beforeCount, timeoutSeconds)
    local timeout = timeoutSeconds or 1.2
    local startedAt = os.clock()
    while os.clock() - startedAt < timeout do
        if getOwnedToolCount() < beforeCount then
            return true
        end
        task.wait(0.05)
    end
    return getOwnedToolCount() < beforeCount
end

function pressSellDialogOptionNumber(optionIndex)
    if optionIndex == 1 then
        tapKeyboardKey(Enum.KeyCode.One)
        return true
    end
    if optionIndex == 2 then
        tapKeyboardKey(Enum.KeyCode.Two)
        return true
    end
    if optionIndex == 3 then
        tapKeyboardKey(Enum.KeyCode.Three)
        return true
    end
    if optionIndex == 4 then
        tapKeyboardKey(Enum.KeyCode.Four)
        return true
    end
    return false
end

function clickSellDialogOption(optionIndex)
    local optionHints = SELL_DIALOG_OPTION_TWO_HINTS
    if optionIndex == 1 then
        optionHints = SELL_DIALOG_OPTION_ONE_HINTS
    end

    ensureSellDialogReady()

    local candidates = {}
    for _, obj in ipairs(playerGui:GetDescendants()) do
        if obj:IsA("GuiButton") and obj.Visible then
            local sourceText = getGuiObjectTextBlob(obj, 16)
            if lowerContainsHint(sourceText, optionHints) then
                candidates[#candidates + 1] = obj
            end
        end
    end

    if #candidates == 0 then
        return pressSellDialogOptionNumber(optionIndex)
    end

    table.sort(candidates, function(a, b)
        return a.ZIndex > b.ZIndex
    end)

    for _, button in ipairs(candidates) do
        if clickGuiButton(button) then
            return true
        end
    end

    return pressSellDialogOptionNumber(optionIndex)
end

function equipToolForSell(tool)
    if not tool or not tool.Parent then
        return false
    end

    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return false
    end

    if tool.Parent ~= character then
        pcall(function()
            humanoid:EquipTool(tool)
        end)
        task.wait(0.05)
    end

    return tool.Parent == character
end

function holdGuiObjectCenter(guiObject, holdDuration)
    if not guiObject or not guiObject:IsA("GuiObject") then
        return false
    end
    if not guiObject.Visible or guiObject.AbsoluteSize.X <= 0 or guiObject.AbsoluteSize.Y <= 0 then
        return false
    end

    local x = math.floor(guiObject.AbsolutePosition.X + (guiObject.AbsoluteSize.X * 0.5))
    local y = math.floor(guiObject.AbsolutePosition.Y + (guiObject.AbsoluteSize.Y * 0.5))
    local duration = holdDuration or Settings.SellGuiHoldSeconds or 0.14
    duration = math.clamp(duration, 0.06, 0.22)

    local okDown = pcall(function()
        VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 0)
    end)
    if not okDown then
        return false
    end

    task.wait(duration)
    pcall(function()
        VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 0)
    end)

    task.wait(0.02)
    pcall(function()
        VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 0)
        VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 0)
    end)
    return true
end

function findBestGuiCardForTool(tool, guiCards)
    if not tool or not guiCards or #guiCards == 0 then
        return nil
    end

    local toolNameLower = string.lower(tool.Name or "")
    local normalizedToolName = normalizeNameForMatch(tool.Name or "")
    local toolCurrency = getToolCountValue(tool, SellState.CountAttr) or getToolCountValue(tool, "CurrencyPerSecond")
    local toolWeight = getToolWeightValue(tool)

    local bestCard = nil
    local bestScore = -math.huge
    for _, card in ipairs(guiCards) do
        if not card.used then
            local score = 0
            local cardName = card.nameLower or string.lower(card.name or "")
            local normalizedCardName = card.normalizedName or normalizeNameForMatch(card.name or "")

            if toolNameLower ~= "" and cardName ~= "" then
                if cardName == toolNameLower then
                    score = score + 8
                elseif string.find(cardName, toolNameLower, 1, true) or string.find(toolNameLower, cardName, 1, true) then
                    score = score + 5
                end
            end
            if normalizedToolName ~= "" and normalizedCardName ~= "" then
                if normalizedCardName == normalizedToolName then
                    score = score + 9
                elseif string.find(normalizedCardName, normalizedToolName, 1, true)
                    or string.find(normalizedToolName, normalizedCardName, 1, true) then
                    score = score + 6
                else
                    score = score + (countSharedTokens(normalizedCardName, normalizedToolName) * 2)
                end
            end

            if toolCurrency and card.currencyPerSecond then
                local currencyDiff = math.abs(card.currencyPerSecond - toolCurrency)
                local currencyTolerance = math.max(15, toolCurrency * 0.18)
                if currencyDiff <= currencyTolerance then
                    score = score + 4
                end
            end

            if toolWeight and card.weight then
                local weightDiff = math.abs(card.weight - toolWeight)
                local weightTolerance = math.max(5, toolWeight * 0.2)
                if weightDiff <= weightTolerance then
                    score = score + 3
                end
            end

            if score > bestScore then
                bestScore = score
                bestCard = card
            end
        end
    end

    if bestCard and bestScore > 0 then
        return bestCard
    end

    return nil
end

function holdInventoryGuiCardForTool(tool, guiCards)
    local card = findBestGuiCardForTool(tool, guiCards)
    if not card then
        local forceRefresh = not FarmState.Active
        guiCards = getInventoryGuiCards(forceRefresh)
        card = findBestGuiCardForTool(tool, guiCards)
    end
    if not card or not card.object then
        return false
    end

    local held = holdGuiObjectCenter(card.object, Settings.SellGuiHoldSeconds)
    if held then
        card.used = true
        task.wait(0.08)
    end
    return held
end

function attemptSellHeldViaKnownByteNet(tool)
    if not tool or not tool.Parent then
        return false
    end

    local replicatedStorage = game:GetService("ReplicatedStorage")
    local remote = replicatedStorage and (replicatedStorage:FindFirstChild("ByteNetReliable") or replicatedStorage:WaitForChild("ByteNetReliable", 2))
    if not remote then
        return false
    end

    local payloads = {}
    pcall(function()
        local bufferPayload = buffer.fromstring(string.char(37, 1, 0))
        if bufferPayload then
            payloads[#payloads + 1] = bufferPayload
        end
    end)
    payloads[#payloads + 1] = string.char(37, 1, 0)

    local unpackArgs = table.unpack or unpack
    for _ = 1, 3 do
        for _, payload in ipairs(payloads) do
            local sent = pcall(function()
                local args = {payload}
                remote:FireServer(unpackArgs(args))
            end)

            if sent and waitUntilToolSold(tool, 0.9) then
                return true
            end
        end
        task.wait(0.08)
    end

    return not isToolStillOwnedByPlayer(tool)
end

function attemptSellToolViaOptionTwo(tool)
    if not tool or not tool.Parent then
        return false
    end

    equipToolForSell(tool)
    if attemptSellHeldViaKnownByteNet(tool) then
        return true
    end

    for _ = 1, 2 do
        ensureSellDialogReady()
        if clickSellDialogOption(2) and waitUntilToolSold(tool, 1.25) then
            return true
        end
        task.wait(0.09)
    end

    return false
end

function attemptSellAllViaKnownByteNet(beforeCount)
    local replicatedStorage = game:GetService("ReplicatedStorage")
    local remote = replicatedStorage and (replicatedStorage:FindFirstChild("ByteNetReliable") or replicatedStorage:WaitForChild("ByteNetReliable", 2))
    if not remote then
        return false, 0
    end

    local payloads = {}
    pcall(function()
        local bufferPayload = buffer.fromstring(string.char(37, 1, 1))
        if bufferPayload then
            payloads[#payloads + 1] = bufferPayload
        end
    end)
    payloads[#payloads + 1] = string.char(37, 1, 1)
    if #payloads == 0 then
        return false, 0
    end

    local unpackArgs = table.unpack or unpack
    for _ = 1, 3 do
        for _, payload in ipairs(payloads) do
            local sent = pcall(function()
                local args = {payload}
                remote:FireServer(unpackArgs(args))
            end)

            if sent and waitOwnedToolCountDrop(beforeCount, 0.55) then
                local soldCount = math.max(0, beforeCount - getOwnedToolCount())
                return soldCount > 0, soldCount
            end
        end
        task.wait(0.08)
    end

    local soldCount = math.max(0, beforeCount - getOwnedToolCount())
    return soldCount > 0, soldCount
end

function attemptSellAllViaRemote(remotes)
    local beforeCount = getOwnedToolCount()
    if beforeCount <= 0 then
        return true, 0
    end

    local soldByteNet, soldByteNetCount = attemptSellAllViaKnownByteNet(beforeCount)
    if soldByteNet then
        return true, soldByteNetCount
    end

    ensureSellDialogReady()

    local payloads = {
        "I want to sell my inventory.",
        "SellAll",
        "SellInventory",
        "SellAllInventory",
        {Action = "SellAll"},
        {Option = 1},
        {"I want to sell my inventory."},
        {"SellAll"},
        1
    }

    for _, remote in ipairs(remotes or {}) do
        local isUnreliable = false
        local okUnrel, unrelResult = pcall(function()
            return remote:IsA("UnreliableRemoteEvent")
        end)
        if okUnrel and unrelResult then
            isUnreliable = true
        end

        if remote:IsA("RemoteEvent") or isUnreliable then
            for _, payload in ipairs(payloads) do
                pcall(function()
                    remote:FireServer(payload)
                end)
                if waitOwnedToolCountDrop(beforeCount, 0.32) then
                    local soldCount = math.max(0, beforeCount - getOwnedToolCount())
                    return true, soldCount
                end
            end
        elseif remote:IsA("RemoteFunction") then
            for _, payload in ipairs(payloads) do
                pcall(function()
                    remote:InvokeServer(payload)
                end)
                if waitOwnedToolCountDrop(beforeCount, 0.32) then
                    local soldCount = math.max(0, beforeCount - getOwnedToolCount())
                    return true, soldCount
                end
            end
        end
    end

    return false, math.max(0, beforeCount - getOwnedToolCount())
end

function attemptSellAllViaDialog()
    local beforeCount = getOwnedToolCount()
    if beforeCount <= 0 then
        return true, 0
    end

    for _ = 1, 2 do
        ensureSellDialogReady()
        if clickSellDialogOption(1) then
            local sold = waitOwnedToolCountDrop(beforeCount, 1.4)
            local soldCount = math.max(0, beforeCount - getOwnedToolCount())
            if sold then
                return true, soldCount
            end
        end
        task.wait(0.1)
    end

    local soldCount = math.max(0, beforeCount - getOwnedToolCount())
    return false, soldCount
end

function getPromptPart(prompt)
    if not prompt then
        return nil
    end

    if prompt.Parent and prompt.Parent:IsA("Attachment") and prompt.Parent.Parent and prompt.Parent.Parent:IsA("BasePart") then
        return prompt.Parent.Parent
    end

    if prompt.Parent and prompt.Parent:IsA("BasePart") then
        return prompt.Parent
    end

    return prompt:FindFirstAncestorWhichIsA("BasePart")
end

function getPromptScore(prompt)
    local sourceText = string.format("%s %s %s", prompt.ActionText or "", prompt.ObjectText or "", prompt.Parent and prompt.Parent.Name or "")
    local score = 1

    if lowerContainsHint(sourceText, INTERACT_HINTS) then
        score = score + 2
    end

    local keyIsE = false
    pcall(function()
        keyIsE = prompt.KeyboardKeyCode == Enum.KeyCode.E
    end)
    if keyIsE then
        score = score + 3
    end

    local actionText = string.lower(cleanGuiText(prompt.ActionText or ""))
    local objectText = string.lower(cleanGuiText(prompt.ObjectText or ""))
    local nameText = string.lower(cleanGuiText(prompt.Name or ""))
    local isCollectPrompt = string.find(actionText, "collect", 1, true)
        or string.find(objectText, "collect", 1, true)
        or string.find(nameText, "collect", 1, true)
    if isCollectPrompt then
        score = score + 8
    end

    return score
end

function isHarvestCollectTreePrompt(prompt, part, root)
    if not prompt then
        return false
    end

    local actionText = string.lower(cleanGuiText(prompt.ActionText or ""))
    if string.find(actionText, "collect", 1, true) == nil then
        return false
    end

    local objectText = string.lower(cleanGuiText(prompt.ObjectText or ""))
    local promptName = string.lower(cleanGuiText(prompt.Name or ""))
    local partName = part and string.lower(cleanGuiText(part.Name or "")) or ""
    local rootName = root and string.lower(cleanGuiText(root.Name or "")) or ""
    local hasTreeHint = string.find(objectText, "tree", 1, true)
        or string.find(promptName, "tree", 1, true)
        or string.find(partName, "tree", 1, true)
        or string.find(rootName, "tree", 1, true)
    if not hasTreeHint then
        return false
    end

    local keyIsE = false
    pcall(function()
        keyIsE = prompt.KeyboardKeyCode == Enum.KeyCode.E
    end)
    return keyIsE
end

function getWorkspacePromptList(forceRefresh, maxAgeSeconds)
    local now = os.clock()
    local maxAge = tonumber(maxAgeSeconds) or 1.2
    if not forceRefresh and (now - (worldPromptCache.LastScanAt or 0)) < maxAge then
        return worldPromptCache.Prompts
    end

    local prompts = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            prompts[#prompts + 1] = obj
        end
    end
    worldPromptCache.LastScanAt = now
    worldPromptCache.Prompts = prompts
    return prompts
end

function getEnabledPromptsCached(root, maxAgeSeconds)
    if not root then
        return {}
    end

    local now = os.clock()
    local maxAge = tonumber(maxAgeSeconds) or 0.6
    local cacheEntry = actionPromptCache[root]
    if cacheEntry and (now - (cacheEntry.at or 0)) < maxAge then
        return cacheEntry.prompts or {}
    end

    local prompts = {}
    for _, prompt in ipairs(root:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") and prompt.Enabled then
            prompts[#prompts + 1] = prompt
        end
    end

    actionPromptCache[root] = {
        at = now,
        prompts = prompts
    }
    return prompts
end

function roundPositionCoordinate(value)
    return math.floor(value + 0.5)
end

function getHarvestRootInstance(part, prompt)
    local treesFolder = workspace:FindFirstChild("Trees")
    if part then
        if treesFolder and part:IsDescendantOf(treesFolder) then
            local node = part
            while node and node.Parent and node.Parent ~= treesFolder do
                node = node.Parent
            end
            if node and node.Parent == treesFolder then
                return node
            end
        end

        local modelAncestor = part:FindFirstAncestorOfClass("Model")
        if modelAncestor and modelAncestor ~= workspace then
            return modelAncestor
        end
    end

    if prompt then
        local promptModel = prompt:FindFirstAncestorOfClass("Model")
        if promptModel and promptModel ~= workspace then
            return promptModel
        end
    end

    return part or prompt
end

function buildHarvestTargetKey(part, prompt)
    local root = getHarvestRootInstance(part, prompt)
    if not root then
        return nil, nil
    end

    local seed = root:GetAttribute("Seed")
    local imposterId = root:GetAttribute("ImposterId")
    if seed or imposterId then
        return string.format("tree|%s|%s|%s", root.Name, tostring(seed or "-"), tostring(imposterId or "-")), root
    end

    local fullPath = nil
    pcall(function()
        fullPath = root:GetFullName()
    end)
    if fullPath and fullPath ~= "" then
        return "path|" .. fullPath, root
    end

    local pivotPart = part
    if not pivotPart and root:IsA("BasePart") then
        pivotPart = root
    elseif not pivotPart and root:IsA("Model") then
        pivotPart = root.PrimaryPart or root:FindFirstChildWhichIsA("BasePart", true)
    end

    if pivotPart then
        return string.format(
            "pos|%s|%d|%d|%d",
            root.Name,
            roundPositionCoordinate(pivotPart.Position.X),
            roundPositionCoordinate(pivotPart.Position.Y),
            roundPositionCoordinate(pivotPart.Position.Z)
        ), root
    end

    return tostring(root), root
end

function isHarvestKeyBlocked(targetKey)
    if not targetKey or targetKey == "" then
        return false
    end

    return HarvestState.HarvestedKeys[targetKey] == true
end

function markHarvestTargetProcessed(target)
    local targetKey = target and target.key
    if not targetKey or targetKey == "" then
        return
    end

    if not HarvestState.HarvestedKeys[targetKey] then
        HarvestState.HarvestedCount = HarvestState.HarvestedCount + 1
    end
    HarvestState.HarvestedKeys[targetKey] = true
end

function clearHarvestCache()
    HarvestState.HarvestedKeys = {}
    HarvestState.HarvestedCount = 0
    HarvestState.LastSkippedCount = 0
    HarvestState.WaitingCacheReset = false
    HarvestState.NextCacheResetAt = 0
end

function getHarvestResetTimeRemaining()
    if not HarvestState.WaitingCacheReset or not HarvestState.NextCacheResetAt or HarvestState.NextCacheResetAt <= 0 then
        return 0
    end

    return math.max(0, math.ceil(HarvestState.NextCacheResetAt - os.clock()))
end

function scanHarvestObjects(radius)
    local character = player.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if not hrp then
        return {}, 0
    end

    local results = {}
    local seenPrompts = {}
    local bestPerKey = {}
    local blockedCount = 0

    local function shouldReplaceEntry(existing, candidate)
        if not existing then
            return true
        end
        if candidate.score == existing.score then
            return candidate.distance < existing.distance
        end
        return candidate.score > existing.score
    end

    local prompts = getWorkspacePromptList(false, Settings.HarvestPromptCacheInterval)
    for _, obj in ipairs(prompts) do
        if obj
            and obj.Parent
            and obj.Enabled
            and not seenPrompts[obj] then
            seenPrompts[obj] = true
            local part = getPromptPart(obj)
            if part and not (character and part:IsDescendantOf(character)) then
                local distance = (part.Position - hrp.Position).Magnitude
                if distance <= radius then
                    local targetKey, rootInstance = buildHarvestTargetKey(part, obj)
                    if not isHarvestCollectTreePrompt(obj, part, rootInstance) then
                        continue
                    end

                    local dedupeKey = targetKey
                    if not dedupeKey then
                        local promptPath = nil
                        pcall(function()
                            promptPath = obj:GetFullName()
                        end)
                        dedupeKey = "prompt|" .. tostring(promptPath or obj)
                    end
                    if isHarvestKeyBlocked(dedupeKey) then
                        blockedCount = blockedCount + 1
                        continue
                    end

                    local entry = {
                        prompt = obj,
                        part = part,
                        root = rootInstance,
                        key = dedupeKey,
                        distance = distance,
                        score = getPromptScore(obj),
                        name = part.Name
                    }

                    if shouldReplaceEntry(bestPerKey[dedupeKey], entry) then
                        bestPerKey[dedupeKey] = entry
                    end
                end
            end
        end
    end

    for _, entry in pairs(bestPerKey) do
        table.insert(results, entry)
    end

    table.sort(results, function(a, b)
        if a.score == b.score then
            return a.distance < b.distance
        end
        return a.score > b.score
    end)

    return results, blockedCount
end

function isMobileClient()
    return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

function sendInteractAction(prompt)
    local holdDuration = prompt and prompt.HoldDuration or 0
    local interactKey = Enum.KeyCode.E
    if prompt then
        pcall(function()
            if prompt.KeyboardKeyCode and prompt.KeyboardKeyCode ~= Enum.KeyCode.Unknown then
                interactKey = prompt.KeyboardKeyCode
            end
        end)
    end

    if prompt and type(fireproximityprompt) == "function" then
        local ok = pcall(function()
            fireproximityprompt(prompt, holdDuration > 0 and holdDuration or 0)
        end)
        if ok then
            return true
        end
    end

    if isMobileClient() then
        sendTap(true)
        task.wait(math.max(holdDuration, 0.08))
        sendTap(false)
        return true
    end

    local keyDownOk = pcall(function()
        VirtualInputManager:SendKeyEvent(true, interactKey, false, game)
    end)
    task.wait(math.max(holdDuration, 0.08))
    local keyUpOk = pcall(function()
        VirtualInputManager:SendKeyEvent(false, interactKey, false, game)
    end)

    if keyDownOk and keyUpOk then
        return true
    end

    sendTap(true)
    task.wait(0.06)
    sendTap(false)
    return false
end

function autoClickLoop()
    while UIState.Active do
        if not equipToolSlotOne() then
            task.wait(0.15)
            continue
        end

        if UIState.PendingCameraLock then
            triggerOneShotCameraLock()
            UIState.PendingCameraLock = false
        end
        performTapCycle()
    end

    pcall(function()
        sendTap(false)
    end)

    UIState.Running = false
end

function readNumberAttribute(container, keyList)
    if not container then
        return nil
    end

    for _, key in ipairs(keyList) do
        local value = container:GetAttribute(key)
        if type(value) == "number" then
            return value
        end
    end

    return nil
end

function readStringAttribute(container, keyList)
    if not container then
        return nil
    end

    for _, key in ipairs(keyList) do
        local value = container:GetAttribute(key)
        if type(value) == "string" then
            return value
        end
        if type(value) == "number" then
            return tostring(value)
        end
    end

    return nil
end

function readNumberValueObject(container, keyList)
    if not container then
        return nil
    end

    for _, key in ipairs(keyList) do
        local candidate = container:FindFirstChild(key, true)
        if candidate and (candidate:IsA("NumberValue") or candidate:IsA("IntValue")) then
            return tonumber(candidate.Value)
        end
    end

    return nil
end

function readStringValueObject(container, keyList)
    if not container then
        return nil
    end

    for _, key in ipairs(keyList) do
        local candidate = container:FindFirstChild(key, true)
        if candidate then
            if candidate:IsA("StringValue") then
                return candidate.Value
            end
            if candidate:IsA("NumberValue") or candidate:IsA("IntValue") then
                return tostring(candidate.Value)
            end
        end
    end

    return nil
end

function readHintedNumberValue(container, hints)
    if not container then
        return nil
    end

    local best = nil
    for _, desc in ipairs(container:GetDescendants()) do
        if desc:IsA("NumberValue") or desc:IsA("IntValue") then
            local lowerName = string.lower(desc.Name)
            for _, hint in ipairs(hints) do
                if string.find(lowerName, hint, 1, true) then
                    local value = tonumber(desc.Value)
                    if value and value > 0 and (not best or value > best) then
                        best = value
                    end
                    break
                end
            end
        end
    end

    return best
end

function findNamedTreeUiContainer(container, nodeName)
    if not container then
        return nil
    end

    local treeNode = container:FindFirstChild(nodeName, true)
    if not treeNode then
        local origin = container:FindFirstChild("Origin", true)
        if origin then
            treeNode = origin:FindFirstChild(nodeName, true)
        end
    end
    if not treeNode then
        return nil
    end

    return treeNode:FindFirstChild("Container", true)
end

function findTreeHealthUiContainer(container)
    return findNamedTreeUiContainer(container, "TreeHealth")
end

function findTreeInfoUiContainer(container)
    return findNamedTreeUiContainer(container, "TreeInfo")
end

function readTreeHealthUiNodeText(node)
    if not node then
        return ""
    end

    if node:IsA("TextLabel") or node:IsA("TextButton") or node:IsA("TextBox") then
        return cleanGuiText(node.Text or "")
    end
    if node:IsA("StringValue") then
        return cleanGuiText(node.Value or "")
    end
    if node:IsA("NumberValue") or node:IsA("IntValue") then
        return cleanGuiText(tostring(node.Value))
    end

    local textObj = node:FindFirstChildWhichIsA("TextLabel", true)
        or node:FindFirstChildWhichIsA("TextButton", true)
        or node:FindFirstChildWhichIsA("TextBox", true)
    if textObj then
        return cleanGuiText(textObj.Text or "")
    end

    local stringObj = node:FindFirstChildWhichIsA("StringValue", true)
    if stringObj then
        return cleanGuiText(stringObj.Value or "")
    end

    local numberObj = node:FindFirstChildWhichIsA("NumberValue", true)
        or node:FindFirstChildWhichIsA("IntValue", true)
    if numberObj then
        return cleanGuiText(tostring(numberObj.Value))
    end

    return ""
end

function parseTreeHealthDisplayText(text)
    local lowerText = string.lower(cleanGuiText(text))
    if lowerText == "" then
        return nil, nil
    end

    local currentToken, maxToken = string.match(lowerText, "([%d%.,]+[kmb]?)%s*/%s*([%d%.,]+[kmb]?)")
    if currentToken then
        local currentValue = parseCompactNumber(currentToken)
        local maxValue = parseCompactNumber(maxToken)
        if currentValue and currentValue > 0 then
            return currentValue, maxValue
        end
    end

    local singleToken = string.match(lowerText, "([%d%.,]+[kmb]?)")
    if singleToken then
        local singleValue = parseCompactNumber(singleToken)
        if singleValue and singleValue > 0 then
            return singleValue, nil
        end
    end

    return nil, nil
end

function readTreeHealthUiValues(container)
    local uiContainer = findTreeHealthUiContainer(container)
    if not uiContainer then
        return nil, nil, nil
    end

    local candidates = {}
    local seen = {}
    local function pushNode(node)
        if node and not seen[node] then
            seen[node] = true
            candidates[#candidates + 1] = node
        end
    end

    local bar = uiContainer:FindFirstChild("Bar", true)
    if bar then
        pushNode(bar:FindFirstChild("Title", true))
        pushNode(bar:FindFirstChild("Tittle", true))
        pushNode(bar:FindFirstChild("CurrentValue", true))
    end
    pushNode(uiContainer:FindFirstChild("Title", true))
    pushNode(uiContainer:FindFirstChild("Tittle", true))
    pushNode(uiContainer:FindFirstChild("CurrentValue", true))

    for _, node in ipairs(candidates) do
        local nodeText = readTreeHealthUiNodeText(node)
        local currentValue, maxValue = parseTreeHealthDisplayText(nodeText)
        if currentValue and currentValue > 0 then
            return currentValue, maxValue, node
        end
    end

    return nil, nil, nil
end

function readTreeRateText(container)
    local uiContainer = findTreeHealthUiContainer(container)
    if not uiContainer then
        return nil
    end

    local rateNode = uiContainer:FindFirstChild("Rate", true)
    local rateText = readTreeHealthUiNodeText(rateNode)
    if rateText ~= "" then
        return rateText
    end

    return nil
end

function normalizeMutationText(text)
    local cleaned = cleanGuiText(text)
    if cleaned == "" then
        return nil
    end

    cleaned = string.gsub(cleaned, "^[Mm][Uu][Tt][Aa][Tt][Ii][Oo][Nn][Ss]?%s*[:%-]?%s*", "")
    cleaned = string.gsub(cleaned, "^[%-%*]+%s*", "")
    cleaned = cleanGuiText(cleaned)
    if cleaned == "" then
        return nil
    end

    local lowerText = string.lower(cleaned)
    if lowerText == "mutation" or lowerText == "mutations" then
        return nil
    end

    return cleaned
end

function readTreeMutationText(container)
    local uiContainers = {}
    local seenContainers = {}
    local function pushContainer(uiContainer)
        if uiContainer and not seenContainers[uiContainer] then
            seenContainers[uiContainer] = true
            uiContainers[#uiContainers + 1] = uiContainer
        end
    end

    pushContainer(findTreeInfoUiContainer(container))
    pushContainer(findTreeHealthUiContainer(container))

    if #uiContainers == 0 then
        return nil
    end

    for _, uiContainer in ipairs(uiContainers) do
        local candidates = {}
        local seen = {}
        local function pushNode(node)
            if node and not seen[node] then
                seen[node] = true
                candidates[#candidates + 1] = node
            end
        end

        pushNode(uiContainer:FindFirstChild("Mutations", true))
        pushNode(uiContainer:FindFirstChild("Mutation", true))
        pushNode(uiContainer:FindFirstChild("Modifiers", true))
        pushNode(uiContainer:FindFirstChild("Modifier", true))

        for _, desc in ipairs(uiContainer:GetDescendants()) do
            local lowerName = string.lower(desc.Name or "")
            for _, hint in ipairs(MUTATION_NAME_HINTS) do
                if string.find(lowerName, hint, 1, true) then
                    pushNode(desc)
                    break
                end
            end
        end

        for _, node in ipairs(candidates) do
            local directText = normalizeMutationText(readTreeHealthUiNodeText(node))
            if directText then
                return directText
            end

            for _, text in ipairs(collectGuiTexts(node, 8)) do
                local parsed = normalizeMutationText(text)
                if parsed then
                    return parsed
                end
            end
        end
    end

    return nil
end

function readHealthValue(container)
    local uiCurrent = readTreeHealthUiValues(container)
    if uiCurrent then
        return uiCurrent
    end

    local direct = readNumberAttribute(container, HP_KEYS) or readNumberValueObject(container, HP_KEYS)
    if direct then
        return direct
    end

    local hinted = readHintedNumberValue(container, HEALTH_NAME_HINTS)
    if hinted then
        return hinted
    end

    local humanoid = container and container:FindFirstChildOfClass("Humanoid")
    if humanoid then
        return humanoid.Health
    end

    return nil
end

function buildHealthProbe(container)
    if not container then
        return nil
    end

    local _, _, uiHealthNode = readTreeHealthUiValues(container)
    if uiHealthNode then
        return {
            kind = "tree_text",
            object = uiHealthNode
        }
    end

    for _, key in ipairs(HP_KEYS) do
        local attrValue = container:GetAttribute(key)
        if type(attrValue) == "number" then
            return {
                kind = "attr",
                container = container,
                key = key
            }
        end
    end

    for _, key in ipairs(HP_KEYS) do
        local candidate = container:FindFirstChild(key, true)
        if candidate and (candidate:IsA("NumberValue") or candidate:IsA("IntValue")) then
            return {
                kind = "value",
                object = candidate
            }
        end
    end

    local bestObject = nil
    local bestValue = nil
    for _, desc in ipairs(container:GetDescendants()) do
        if desc:IsA("NumberValue") or desc:IsA("IntValue") then
            local lowerName = string.lower(desc.Name)
            for _, hint in ipairs(HEALTH_NAME_HINTS) do
                if string.find(lowerName, hint, 1, true) then
                    local value = tonumber(desc.Value)
                    if value and value > 0 and (not bestValue or value > bestValue) then
                        bestValue = value
                        bestObject = desc
                    end
                    break
                end
            end
        end
    end
    if bestObject then
        return {
            kind = "value",
            object = bestObject
        }
    end

    local humanoid = container:FindFirstChildOfClass("Humanoid")
    if humanoid then
        return {
            kind = "humanoid",
            object = humanoid
        }
    end

    return nil
end

function readHealthFromProbe(probe)
    if not probe then
        return nil
    end

    if probe.kind == "attr" then
        local container = probe.container
        if container and container.Parent then
            local value = container:GetAttribute(probe.key)
            if type(value) == "number" then
                return value
            end
        end
        return nil
    end

    if probe.kind == "value" then
        local object = probe.object
        if object and object.Parent and (object:IsA("NumberValue") or object:IsA("IntValue")) then
            return tonumber(object.Value)
        end
        return nil
    end

    if probe.kind == "tree_text" then
        local object = probe.object
        if object and object.Parent then
            local text = readTreeHealthUiNodeText(object)
            local currentValue = parseTreeHealthDisplayText(text)
            if currentValue then
                return currentValue
            end
        end
        return nil
    end

    if probe.kind == "humanoid" then
        local humanoid = probe.object
        if humanoid and humanoid.Parent then
            return tonumber(humanoid.Health)
        end
        return nil
    end

    return nil
end

function readMaxHealthValue(container)
    local direct = readNumberAttribute(container, MAX_HP_KEYS) or readNumberValueObject(container, MAX_HP_KEYS)
    if direct then
        return direct
    end

    local hinted = readHintedNumberValue(container, {"maxhp", "maxhealth", "max", "durabilitymax", "healthmax"})
    if hinted then
        return hinted
    end

    local _, uiMax = readTreeHealthUiValues(container)
    if uiMax and uiMax > 0 then
        return uiMax
    end

    local humanoid = container and container:FindFirstChildOfClass("Humanoid")
    if humanoid then
        return humanoid.MaxHealth
    end

    return nil
end

function readRarityValue(container)
    return readStringAttribute(container, RARITY_KEYS) or readStringValueObject(container, RARITY_KEYS) or readTreeRateText(container)
end

function readMutationValue(container)
    local byAttribute = normalizeMutationText(readStringAttribute(container, MUTATION_KEYS))
    if byAttribute then
        return byAttribute
    end

    local byValue = normalizeMutationText(readStringValueObject(container, MUTATION_KEYS))
    if byValue then
        return byValue
    end

    return readTreeMutationText(container)
end

function getTargetPart(instance)
    if not instance then
        return nil
    end

    if instance:IsA("BasePart") then
        return instance
    end

    if instance:IsA("Model") then
        return instance.PrimaryPart or instance:FindFirstChildWhichIsA("BasePart", true)
    end

    return instance:FindFirstChildWhichIsA("BasePart", true)
end

function hasInteractNode(container, part)
    if container and (container:FindFirstChildWhichIsA("ProximityPrompt", true) or container:FindFirstChildWhichIsA("ClickDetector", true)) then
        return true
    end
    if part and (part:FindFirstChildWhichIsA("ProximityPrompt", true) or part:FindFirstChildWhichIsA("ClickDetector", true)) then
        return true
    end
    return false
end

function shouldSkipFarmTargetByActionPrompt(container, part)
    local prompts = {}
    local seen = {}

    local function collectPrompts(root)
        if not root then
            return
        end
        for _, prompt in ipairs(getEnabledPromptsCached(root, 0.6)) do
            if prompt and prompt.Parent and not seen[prompt] then
                seen[prompt] = true
                prompts[#prompts + 1] = prompt
            end
        end
    end

    collectPrompts(container)
    collectPrompts(part)

    if #prompts == 0 then
        return false, nil
    end

    for _, prompt in ipairs(prompts) do
        local actionText = cleanGuiText(prompt.ActionText or "")
        local objectText = cleanGuiText(prompt.ObjectText or "")
        local sourceText = string.lower(string.format("%s %s %s", actionText, objectText, prompt.Name or ""))

        local keyIsE = false
        pcall(function()
            keyIsE = prompt.KeyboardKeyCode == Enum.KeyCode.E
        end)

        local isTapStyle = string.find(sourceText, "tap", 1, true) ~= nil
        local hasCollectHint = lowerContainsHint(sourceText, FARM_ACTION_SKIP_HINTS)

        if keyIsE or isTapStyle or hasCollectHint then
            local reason = actionText ~= "" and actionText or (objectText ~= "" and objectText or "E/Tap Prompt")
            return true, reason
        end
    end

    return false, nil
end

function isLikelyFarmPart(part, source)
    if not part or not isAimCandidatePart(part) then
        return false
    end

    local sourceName = source and source.Name or ""
    if lowerContainsHint(part.Name, NON_FARM_HINTS) or lowerContainsHint(sourceName, NON_FARM_HINTS) then
        return false
    end

    if part.Size.Y <= 1 and part.Size.X >= 10 and part.Size.Z >= 10 then
        return false
    end

    if lowerContainsHint(part.Name, FARM_OBJECT_HINTS) or lowerContainsHint(sourceName, FARM_OBJECT_HINTS) then
        return true
    end

    if hasInteractNode(source, part) then
        return true
    end

    if part.Size.Y >= 2 and part.Size.Magnitude >= 4 then
        return true
    end

    return false
end

function formatPosition(position)
    return string.format("(%.0f, %.0f, %.0f)", position.X, position.Y, position.Z)
end

function getFarmTreeDisplayName(source, part)
    local displayName = nil
    if source then
        local sourceTreeName = source:GetAttribute("TreeName")
        if type(sourceTreeName) == "string" and sourceTreeName ~= "" then
            displayName = sourceTreeName
        end
    end

    if (not displayName or displayName == "") and part then
        local partTreeName = part:GetAttribute("TreeName")
        if type(partTreeName) == "string" and partTreeName ~= "" then
            displayName = partTreeName
        end
    end

    if not displayName or displayName == "" then
        local fallback = source and source.Name or (part and part.Name or "Unknown")
        fallback = string.gsub(fallback, "_%d+$", "")
        fallback = string.gsub(fallback, "_", " ")
        displayName = fallback
    end

    return tostring(displayName)
end

function doesFarmTreeMatchFilter(source, part, displayName, normalizedFilters)
    if type(normalizedFilters) ~= "table" or #normalizedFilters == 0 then
        return true
    end

    local displayText = normalizeFarmTreeText(displayName)
    local sourceText = source and normalizeFarmTreeText(source.Name) or ""
    local partText = part and normalizeFarmTreeText(part.Name) or ""
    for _, normalizedFilter in ipairs(normalizedFilters) do
        if string.find(displayText, normalizedFilter, 1, true) then
            return true
        end
        if sourceText ~= "" and string.find(sourceText, normalizedFilter, 1, true) then
            return true
        end
        if partText ~= "" and string.find(partText, normalizedFilter, 1, true) then
            return true
        end
    end

    return false
end

function getFarmTreeFilterLabel()
    local filterText = normalizeFarmTreeFilterInput(FarmState.TreeFilter)
    if filterText == "" then
        return "All"
    end
    return filterText
end

function getActiveWeatherMutationTarget()
    local target = FarmState.WeatherMutationTarget
    if not target then
        return nil
    end

    local expiresAt = tonumber(target.expiresAt) or 0
    if expiresAt > 0 and os.clock() > expiresAt then
        FarmState.WeatherMutationTarget = nil
        return nil
    end

    return target
end

function doesMutationMatchWeatherTarget(mutationText, weatherTarget)
    if not weatherTarget then
        return true
    end

    local requiredMutation = normalizeFarmTreeText(weatherTarget.mutationNormalized or weatherTarget.mutation or "")
    if requiredMutation == "" then
        return true
    end

    local candidate = normalizeFarmTreeText(mutationText)
    if candidate == "" or candidate == "-" then
        return false
    end

    if string.find(candidate, requiredMutation, 1, true) then
        return true
    end
    if string.find(requiredMutation, candidate, 1, true) then
        return true
    end

    return false
end

function buildFarmTargetKey(source, part)
    local root = source or part
    if not root then
        return nil
    end

    local seed = root:GetAttribute("Seed")
    local imposterId = root:GetAttribute("ImposterId")
    local treeName = root:GetAttribute("TreeName")
    local treeTypeIndex = root:GetAttribute("TreeTypeIndex")
    if seed or imposterId then
        return string.format(
            "farm|%s|%s|%s|%s",
            tostring(treeName or root.Name),
            tostring(seed or "-"),
            tostring(imposterId or "-"),
            tostring(treeTypeIndex or "-")
        )
    end

    local fullPath = nil
    pcall(function()
        fullPath = root:GetFullName()
    end)
    if fullPath and fullPath ~= "" then
        return "farmpath|" .. fullPath
    end

    local pivotPart = part
    if not pivotPart and root:IsA("BasePart") then
        pivotPart = root
    elseif not pivotPart and root:IsA("Model") then
        pivotPart = root.PrimaryPart or root:FindFirstChildWhichIsA("BasePart", true)
    end

    if pivotPart then
        return string.format(
            "farmpos|%s|%d|%d|%d",
            root.Name,
            roundPositionCoordinate(pivotPart.Position.X),
            roundPositionCoordinate(pivotPart.Position.Y),
            roundPositionCoordinate(pivotPart.Position.Z)
        )
    end

    return tostring(root)
end

function isFarmTargetCoolingDown(targetKey)
    if not targetKey or targetKey == "" then
        return false
    end

    local entry = FarmState.CooldownKeys[targetKey]
    local now = os.clock()
    if not entry then
        return false
    end

    if type(entry) == "number" then
        if now - entry <= Settings.FarmTreeCooldownSeconds then
            return true
        end
        FarmState.CooldownKeys[targetKey] = nil
        return false
    end

    if type(entry) == "table" then
        local expiresAt = tonumber(entry.expiresAt)
        if expiresAt and now <= expiresAt then
            return true
        end
    end

    FarmState.CooldownKeys[targetKey] = nil
    return false
end

function markFarmTargetCooldown(target, durationSeconds)
    local targetKey = target and target.key
    if not targetKey or targetKey == "" then
        return
    end

    local duration = tonumber(durationSeconds)
    if duration and duration > 0 then
        FarmState.CooldownKeys[targetKey] = {
            expiresAt = os.clock() + math.max(2, duration)
        }
        return
    end

    FarmState.CooldownKeys[targetKey] = {
        expiresAt = os.clock() + Settings.FarmTreeCooldownSeconds
    }
end

function countActiveFarmCooldowns()
    local total = 0
    local now = os.clock()
    for key, entry in pairs(FarmState.CooldownKeys or {}) do
        local expiresAt = nil
        if type(entry) == "number" then
            expiresAt = entry + Settings.FarmTreeCooldownSeconds
        elseif type(entry) == "table" then
            expiresAt = tonumber(entry.expiresAt)
        end

        if expiresAt and now <= expiresAt then
            total = total + 1
        else
            FarmState.CooldownKeys[key] = nil
        end
    end
    return total
end

function normalizePlayerNameText(nameText)
    local normalized = cleanGuiText(nameText or "")
    normalized = string.lower(normalized)
    normalized = string.gsub(normalized, "[^%a%d]", "")
    return normalized
end

function isBusyActorLocalPlayer(actorName)
    local actorNormalized = normalizePlayerNameText(actorName)
    if actorNormalized == "" then
        return false
    end
    if actorNormalized == "you" then
        return true
    end

    local localName = normalizePlayerNameText(player.Name or "")
    local localDisplayName = normalizePlayerNameText(player.DisplayName or "")
    return actorNormalized == localName or actorNormalized == localDisplayName
end

function getFarmUiScanRoots()
    local roots = {playerGui}

    pcall(function()
        local coreGui = game:GetService("CoreGui")
        if coreGui then
            roots[#roots + 1] = coreGui
        end
    end)

    if type(gethui) == "function" then
        pcall(function()
            local hui = gethui()
            if hui then
                roots[#roots + 1] = hui
            end
        end)
    end

    return roots
end

function findFarmBusyToastText()
    local now = os.clock()
    if now - (FarmState.LastBusyToastScanAt or 0) < (Settings.FarmUiScanInterval or 0.3) then
        return FarmState.LastBusyToastText
    end

    local foundText = nil
    for _, root in ipairs(getFarmUiScanRoots()) do
        if root then
            local descendants = nil
            pcall(function()
                descendants = root:GetDescendants()
            end)
            if descendants then
                for _, obj in ipairs(descendants) do
                    if obj:IsA("TextLabel") or obj:IsA("TextButton") then
                        local text = cleanGuiText(obj.Text or "")
                        if text ~= "" then
                            local lowerText = string.lower(text)
                            if lowerContainsHint(lowerText, FARM_BUSY_HINTS) and string.find(lowerText, "already chopping this tree", 1, true) then
                                foundText = text
                                break
                            end
                        end
                    end
                end
            end
            if foundText then
                break
            end
        end
    end

    FarmState.LastBusyToastScanAt = now
    FarmState.LastBusyToastText = foundText
    return foundText
end

function detectFarmBusyByOtherPlayer()
    local toastText = findFarmBusyToastText()
    if not toastText then
        return false, nil, nil, nil
    end

    local lowerText = string.lower(toastText)
    if not string.find(lowerText, "already chopping this tree", 1, true) then
        return false, nil, nil, nil
    end

    local actorName = cleanGuiText(string.match(toastText, "^(.-)%s+[iI][sS]%s+already%s+chopping%s+this%s+tree") or "")
    if actorName ~= "" and isBusyActorLocalPlayer(actorName) then
        return false, nil, toastText, actorName
    end

    local waitToken = string.match(lowerText, "try%s+again%s+in%s+([%d%.]+)")
    local waitSeconds = tonumber(waitToken)
    if waitSeconds then
        waitSeconds = math.clamp(waitSeconds + 1.2, 3, Settings.FarmTreeCooldownSeconds)
    end

    return true, waitSeconds, toastText, actorName
end

function detectOtherPlayerNearTargetPart(targetPart, radius)
    if not targetPart or not targetPart.Parent then
        return false, nil, nil
    end

    local checkRadius = tonumber(radius) or Settings.FarmPlayerNearbySkipRadius or 24
    if checkRadius <= 0 then
        return false, nil, nil
    end

    local nearestPlayerName = nil
    local nearestDistance = math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player then
            local character = plr.Character
            local hrp = character and character:FindFirstChild("HumanoidRootPart")
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            if hrp and humanoid and humanoid.Health > 0 then
                local distance = (hrp.Position - targetPart.Position).Magnitude
                if distance < nearestDistance then
                    nearestDistance = distance
                    nearestPlayerName = plr.DisplayName or plr.Name
                end
            end
        end
    end

    if nearestPlayerName and nearestDistance <= checkRadius then
        return true, nearestPlayerName, nearestDistance
    end

    return false, nearestPlayerName, nearestDistance
end

function isLikelyRobuxPopupText(sourceText)
    local lowerText = string.lower(cleanGuiText(sourceText or ""))
    if lowerText == "" then
        return false
    end

    local hasRobuxWord = string.find(lowerText, "robux", 1, true) ~= nil
    local hasActionWord = lowerContainsHint(lowerText, ROBUX_POPUP_HINTS)
    if hasRobuxWord and hasActionWord then
        return true
    end

    if string.find(lowerText, "confirm purchase", 1, true)
        or string.find(lowerText, "buy with", 1, true)
        or string.find(lowerText, "insufficient robux", 1, true) then
        return true
    end

    return false
end

function findRobuxPurchasePopup()
    local now = os.clock()
    local scanInterval = Settings.RobuxPopupScanInterval or 0.35
    if now - (robuxPopupCache.LastScanAt or 0) < scanInterval then
        if robuxPopupCache.HadPopup then
            local cachedPopup = robuxPopupCache.Popup
            if cachedPopup and cachedPopup.Parent and cachedPopup.Visible then
                return cachedPopup, robuxPopupCache.Text
            end
        else
            return nil, nil
        end
    end

    local bestPopup = nil
    local bestScore = -math.huge
    local bestText = nil

    for _, obj in ipairs(playerGui:GetDescendants()) do
        if obj:IsA("GuiObject")
            and obj.Visible
            and obj.AbsoluteSize.X >= 170
            and obj.AbsoluteSize.Y >= 80
            and not (screenGui and obj:IsDescendantOf(screenGui)) then
            local sourceText = getGuiObjectTextBlob(obj, 24)
            if isLikelyRobuxPopupText(sourceText) then
                local score = 0
                if string.find(string.lower(sourceText), "insufficient robux", 1, true) then
                    score = score + 8
                end
                if string.find(string.lower(sourceText), "confirm purchase", 1, true) then
                    score = score + 8
                end
                if string.find(string.lower(sourceText), "buy", 1, true) then
                    score = score + 4
                end
                score = score + math.floor((obj.AbsoluteSize.X * obj.AbsoluteSize.Y) / 60000)

                if score > bestScore then
                    bestScore = score
                    bestPopup = obj
                    bestText = cleanGuiText(sourceText)
                end
            end
        end
    end

    robuxPopupCache.LastScanAt = now
    robuxPopupCache.Popup = bestPopup
    robuxPopupCache.Text = bestText
    robuxPopupCache.HadPopup = bestPopup ~= nil
    return bestPopup, bestText
end

function tryCloseRobuxPopup(popupRoot)
    if not popupRoot then
        return false
    end

    local buttonCandidates = {}
    for _, obj in ipairs(popupRoot:GetDescendants()) do
        if obj:IsA("GuiButton") and obj.Visible and obj.AbsoluteSize.X > 0 and obj.AbsoluteSize.Y > 0 then
            local textBlob = string.lower(getGuiObjectTextBlob(obj, 12))
            local score = 0
            if lowerContainsHint(textBlob, ROBUX_CLOSE_HINTS) then
                score = score + 8
            end
            if cleanGuiText(textBlob) == "x" then
                score = score + 6
            end
            if string.find(textBlob, "buy", 1, true) or string.find(textBlob, "purchase", 1, true) then
                score = score - 7
            end
            if score > 0 then
                buttonCandidates[#buttonCandidates + 1] = {
                    button = obj,
                    score = score
                }
            end
        end
    end

    table.sort(buttonCandidates, function(a, b)
        if a.score == b.score then
            return a.button.ZIndex > b.button.ZIndex
        end
        return a.score > b.score
    end)

    for i = 1, math.min(4, #buttonCandidates) do
        if clickGuiButton(buttonCandidates[i].button) then
            return true
        end
    end

    pcall(function()
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Escape, false, game)
    end)
    task.wait(0.03)
    pcall(function()
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Escape, false, game)
    end)
    return false
end

function detectRobuxPopupAndHandle()
    local popup, popupText = findRobuxPurchasePopup()
    if not popup then
        return false, nil
    end

    tryCloseRobuxPopup(popup)
    return true, popupText
end

function scanFarmObjects(radius)
    local character = player.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if not hrp then
        return {}, 0
    end
    local activeTreeFilters = getNormalizedFarmTreeFilters(FarmState.TreeFilter)
    local weatherMutationTarget = getActiveWeatherMutationTarget()

    local treesFolder = workspace:FindFirstChild("Trees")
    local nearbyParts = nil
    local ok = pcall(function()
        local overlapParams = OverlapParams.new()
        if treesFolder then
            overlapParams.FilterType = Enum.RaycastFilterType.Include
            overlapParams.FilterDescendantsInstances = {treesFolder}
        else
            overlapParams.FilterType = Enum.RaycastFilterType.Exclude
            overlapParams.FilterDescendantsInstances = character and {character} or {}
        end
        nearbyParts = workspace:GetPartBoundsInRadius(hrp.Position, radius, overlapParams)
    end)

    if not ok or not nearbyParts then
        nearbyParts = treesFolder and treesFolder:GetDescendants() or workspace:GetDescendants()
    elseif #nearbyParts == 0 then
        local now = os.clock()
        if now - (FarmState.LastWideScanAt or 0) > 1.8 then
            nearbyParts = treesFolder and treesFolder:GetDescendants() or workspace:GetDescendants()
            FarmState.LastWideScanAt = now
        else
            return {}, 0
        end
    end

    local seen = {}
    local results = {}
    local cooldownSkippedCount = 0

    for _, candidate in ipairs(nearbyParts) do
        if candidate:IsA("BasePart") and (not treesFolder or candidate:IsDescendantOf(treesFolder)) then
            local source = candidate:FindFirstAncestorOfClass("Model")
            if not source then
                local folderAncestor = candidate:FindFirstAncestorOfClass("Folder")
                local useFolderAncestor = false
                if folderAncestor and folderAncestor ~= treesFolder then
                    if treesFolder then
                        useFolderAncestor = folderAncestor:IsDescendantOf(treesFolder)
                    else
                        useFolderAncestor = lowerContainsHint(folderAncestor.Name, FARM_OBJECT_HINTS)
                    end
                end

                if useFolderAncestor then
                    source = folderAncestor
                end
            end
            source = source or candidate
            if not seen[source] and not (character and source:IsDescendantOf(character)) then
                seen[source] = true

                local targetPart = getTargetPart(source)
                if targetPart then
                    local distance = (targetPart.Position - hrp.Position).Magnitude
                    if distance <= radius then
                        local displayName = getFarmTreeDisplayName(source, targetPart)
                        if #activeTreeFilters > 0 and not doesFarmTreeMatchFilter(source, targetPart, displayName, activeTreeFilters) then
                            continue
                        end

                        local targetKey = buildFarmTargetKey(source, targetPart)
                        if targetKey and isFarmTargetCoolingDown(targetKey) then
                            cooldownSkippedCount = cooldownSkippedCount + 1
                            continue
                        end

                        local skipByActionPrompt = false
                        if hasInteractNode(source, targetPart) then
                            local shouldSkipAction = shouldSkipFarmTargetByActionPrompt(source, targetPart)
                            if shouldSkipAction then
                                skipByActionPrompt = true
                            end
                        end
                        if skipByActionPrompt then
                            cooldownSkippedCount = cooldownSkippedCount + 1
                            if targetKey and targetKey ~= "" then
                                FarmState.CooldownKeys[targetKey] = {
                                    expiresAt = os.clock() + (Settings.FarmActionPromptSkipCooldownSeconds or 45)
                                }
                            end
                            continue
                        end

                        local hp = readHealthValue(source) or readHealthValue(targetPart)
                        if (not hp or hp <= 0) and (lowerContainsHint(source.Name, FARM_OBJECT_HINTS) or lowerContainsHint(targetPart.Name, FARM_OBJECT_HINTS)) then
                            hp = readMaxHealthValue(source) or readMaxHealthValue(targetPart) or 1
                        end

                        if (not hp or hp <= 0) and hasInteractNode(source, targetPart) then
                            hp = 1
                        end

                        if (not hp or hp <= 0) and isLikelyFarmPart(targetPart, source) then
                            hp = 1
                        end

                        if hp and hp > 0 then
                            local rarity = readRarityValue(source) or readRarityValue(targetPart) or "Unknown"
                            local mutation = readMutationValue(source) or readMutationValue(targetPart) or "-"
                            if weatherMutationTarget then
                                local matchesWeatherMutation = doesMutationMatchWeatherTarget(mutation, weatherMutationTarget)
                                if not matchesWeatherMutation then
                                    local requiredMutation = normalizeFarmTreeText(weatherMutationTarget.mutation or "")
                                    if requiredMutation ~= "" then
                                        local displayText = normalizeFarmTreeText(displayName)
                                        local sourceText = normalizeFarmTreeText(source.Name)
                                        local partText = normalizeFarmTreeText(targetPart.Name)
                                        if string.find(displayText, requiredMutation, 1, true)
                                            or string.find(sourceText, requiredMutation, 1, true)
                                            or string.find(partText, requiredMutation, 1, true) then
                                            matchesWeatherMutation = true
                                        end
                                    end
                                end
                                if not matchesWeatherMutation then
                                    continue
                                end
                            end
                            table.insert(results, {
                                instance = source,
                                part = targetPart,
                                key = targetKey,
                                name = source.Name,
                                displayName = displayName,
                                hp = hp,
                                maxHp = readMaxHealthValue(source) or readMaxHealthValue(targetPart),
                                rarity = rarity,
                                mutation = mutation,
                                distance = distance,
                                position = targetPart.Position
                            })
                        end
                    end
                end
            end
        end
    end

    table.sort(results, compareFarmTargets)

    return results, cooldownSkippedCount
end

function getCurrentTargetHp(target)
    if not target or not target.instance or not target.instance.Parent then
        return nil
    end

    local now = os.clock()
    local nextScanAt = tonumber(target.nextHpScanAt) or 0
    if nextScanAt > now then
        return target.lastHpValue or target.hp
    end

    target.nextHpScanAt = now + (Settings.FarmHpRescanInterval or 0.35)

    local probeReady = target.healthProbe ~= nil
    local canProbeRetry = now >= (tonumber(target.nextHpProbeRetryAt) or 0)
    if not probeReady and canProbeRetry then
        local discoveredProbe = nil
        if target.instance and target.instance.Parent then
            discoveredProbe = buildHealthProbe(target.instance)
        end
        if not discoveredProbe and target.part and target.part.Parent then
            discoveredProbe = buildHealthProbe(target.part)
        end

        target.healthProbe = discoveredProbe
        target.nextHpProbeRetryAt = now + (Settings.FarmHpProbeRetryInterval or 2.5)
    end

    local detected = readHealthFromProbe(target.healthProbe)
    if detected then
        target.lastHpValue = detected
        return detected
    end

    if target.healthProbe then
        target.healthProbe = nil
        target.nextHpProbeRetryAt = now + (Settings.FarmHpProbeRetryInterval or 2.5)
    end

    if target.hp and target.hp > 0 then
        target.lastHpValue = target.hp
        return target.hp
    end

    if target.part and target.part.Parent then
        target.lastHpValue = 1
        return 1
    end

    return nil
end

function isTargetStillPresent(target)
    if not target then
        return false
    end

    if target.instance and target.instance.Parent then
        return true
    end

    if target.part and target.part.Parent then
        return true
    end

    return false
end

function teleportToPart(part)
    local character = player.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if not hrp or not part then
        return false
    end

    hrp.CFrame = CFrame.new(part.Position + Vector3.new(0, 5, 0))
    return true
end

function faceTargetForChop(part)
    if not part or not part.Parent then
        return false
    end

    local character = player.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if not hrp then
        return false
    end

    local targetPosition = part.Position
    local fromPosition = hrp.Position
    local flatTarget = Vector3.new(targetPosition.X, fromPosition.Y, targetPosition.Z)
    if (flatTarget - fromPosition).Magnitude < 0.1 then
        flatTarget = fromPosition + hrp.CFrame.LookVector
    end

    hrp.CFrame = CFrame.lookAt(fromPosition, flatTarget)

    local camera = workspace.CurrentCamera
    if camera then
        camera.CFrame = CFrame.lookAt(camera.CFrame.Position, targetPosition)
    end

    return true
end

function isOwnedByPlayer(container)
    if not container then
        return false
    end

    local playerNameLower = string.lower(player.Name)
    local displayNameLower = string.lower(player.DisplayName or player.Name)

    local function matchesValue(value)
        if type(value) == "number" then
            return math.floor(value) == player.UserId
        end
        if type(value) == "string" then
            local lowerValue = string.lower(value)
            return lowerValue == playerNameLower or lowerValue == displayNameLower
        end
        return false
    end

    for _, key in ipairs(OWNER_KEYS) do
        local attrValue = container:GetAttribute(key)
        if matchesValue(attrValue) then
            return true
        end

        local childValue = container:FindFirstChild(key, true)
        if childValue then
            if childValue:IsA("StringValue") and matchesValue(childValue.Value) then
                return true
            end
            if (childValue:IsA("IntValue") or childValue:IsA("NumberValue")) and matchesValue(childValue.Value) then
                return true
            end
        end
    end

    if string.find(string.lower(container.Name), playerNameLower, 1, true) then
        return true
    end

    return false
end

function findPlotAnchor(candidate)
    if not candidate then
        return nil
    end

    if candidate:IsA("Model") then
        local preferredNames = {"Spawn", "SpawnPoint", "PlotSpawn", "Base", "Center", "Origin"}
        for _, name in ipairs(preferredNames) do
            local part = candidate:FindFirstChild(name, true)
            if part and part:IsA("BasePart") then
                return part
            end
        end

        return candidate.PrimaryPart or candidate:FindFirstChildWhichIsA("BasePart", true)
    end

    if candidate:IsA("BasePart") then
        return candidate
    end

    return candidate:FindFirstChildWhichIsA("BasePart", true)
end

function getPlayerPlotPart(forceRefresh)
    if not forceRefresh and cachedPlotPart and cachedPlotPart.Parent and os.clock() - lastPlotScanAt < 5 then
        return cachedPlotPart
    end

    local bestCandidate = nil
    local bestScore = -math.huge

    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("Folder") then
            local lowerName = string.lower(obj.Name)
            local isPlotNamed = lowerContainsHint(lowerName, PLOT_HINTS)
            local ownerMatch = isOwnedByPlayer(obj)

            if isPlotNamed or ownerMatch then
                local score = 0
                if isPlotNamed then
                    score = score + 25
                end
                if ownerMatch then
                    score = score + 100
                end

                local anchor = findPlotAnchor(obj)
                if anchor then
                    if score > bestScore then
                        bestScore = score
                        bestCandidate = anchor
                    end
                end
            end
        end
    end

    cachedPlotPart = bestCandidate
    lastPlotScanAt = os.clock()
    return cachedPlotPart
end

function isCharacterNearPart(part, maxDistance)
    if not part or not part.Parent then
        return false
    end

    local character = player.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if not hrp then
        return false
    end

    local distance = (hrp.Position - part.Position).Magnitude
    return distance <= (maxDistance or Settings.HarvestPlotArrivalDistance)
end

function waitCharacterNearPart(part, timeoutSeconds, maxDistance)
    local timeout = timeoutSeconds or Settings.HarvestPlotArrivalTimeout
    local startedAt = os.clock()
    while os.clock() - startedAt < timeout do
        if isCharacterNearPart(part, maxDistance) then
            return true
        end
        task.wait(0.06)
    end
    return isCharacterNearPart(part, maxDistance)
end

function teleportToPlayerPlot()
    local plotPart = getPlayerPlotPart(false)
    if not plotPart then
        plotPart = getPlayerPlotPart(true)
    end

    if not plotPart then
        return false
    end

    if not teleportToPart(plotPart) then
        return false
    end

    if waitCharacterNearPart(plotPart, Settings.HarvestPlotArrivalTimeout, Settings.HarvestPlotArrivalDistance) then
        return true
    end

    if teleportToPart(plotPart) then
        return waitCharacterNearPart(plotPart, Settings.HarvestPlotArrivalTimeout, Settings.HarvestPlotArrivalDistance)
    end

    return false
end

loadConfigFromDisk()

for _, guiName in ipairs({"TimberScriptByVaanGUI", "AutoPerfectChopGUI"}) do
    local existingGui = playerGui:FindFirstChild(guiName)
    if existingGui then
        existingGui:Destroy()
    end
end

 screenGui = Instance.new("ScreenGui")
screenGui.Name = "TimberScriptByVaanGUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

local frameSize = UDim2.new(0, 430, 0, 440)
local collapsedSize = UDim2.new(0, 430, 0, 58)

rootFrame = Instance.new("Frame")
rootFrame.Size = frameSize
rootFrame.Position = UDim2.new(0.5, -215, 0, 44)
rootFrame.BackgroundColor3 = Theme.Background
rootFrame.BorderSizePixel = 0
rootFrame.Active = true
rootFrame.Draggable = true
rootFrame.Parent = screenGui
addCorner(rootFrame, 14)
addStroke(rootFrame, Theme.Border, 1.2, 0)

header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 58)
header.BackgroundColor3 = Theme.Header
header.BorderSizePixel = 0
header.Parent = rootFrame
addCorner(header, 14)

 headerMask = Instance.new("Frame")
headerMask.Size = UDim2.new(1, 0, 0, 16)
headerMask.Position = UDim2.new(0, 0, 1, -16)
headerMask.BorderSizePixel = 0
headerMask.BackgroundColor3 = Theme.Header
headerMask.Parent = header

titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -205, 0, 24)
titleLabel.Position = UDim2.new(0, 14, 0, 7)
titleLabel.Text = "Timber Script by Vaan"
styleTextLabel(titleLabel, 18, Theme.Text, true)
titleLabel.Parent = header

subtitleLabel = Instance.new("TextLabel")
subtitleLabel.Size = UDim2.new(1, -205, 0, 18)
subtitleLabel.Position = UDim2.new(0, 14, 0, 33)
subtitleLabel.Text = "Auto click, farm, harvest, and sell helper"
styleTextLabel(subtitleLabel, 11, Theme.MutedText, false)
subtitleLabel.Parent = header

 headerVersionLabel = Instance.new("TextLabel")
headerVersionLabel.Size = UDim2.new(0, 95, 0, 16)
headerVersionLabel.Position = UDim2.new(1, -115, 0, 37)
headerVersionLabel.Text = "Version v2.1.0"
styleTextLabel(headerVersionLabel, 10, Theme.MutedText, true, Enum.TextXAlignment.Right)
headerVersionLabel.Parent = header

closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 30, 0, 30)
closeButton.Position = UDim2.new(1, -12, 0, 10)
closeButton.AnchorPoint = Vector2.new(1, 0)
closeButton.Text = "X"
setButtonStyle(closeButton, Theme.Danger)
closeButton.Parent = header

minimizeButton = Instance.new("TextButton")
minimizeButton.Size = UDim2.new(0, 30, 0, 30)
minimizeButton.Position = UDim2.new(1, -50, 0, 10)
minimizeButton.AnchorPoint = Vector2.new(1, 0)
minimizeButton.Text = "-"
setButtonStyle(minimizeButton, Theme.Warning)
minimizeButton.TextColor3 = Color3.fromRGB(25, 25, 25)
minimizeButton.Parent = header

tabContainer = Instance.new("Frame")
tabContainer.Size = UDim2.new(1, -24, 0, 76)
tabContainer.Position = UDim2.new(0, 12, 0, 68)
tabContainer.BackgroundTransparency = 1
tabContainer.Parent = rootFrame

 tabGrid = Instance.new("UIGridLayout")
tabGrid.CellSize = UDim2.new(0.3333, -6, 0, 34)
tabGrid.CellPadding = UDim2.new(0, 8, 0, 8)
tabGrid.FillDirection = Enum.FillDirection.Horizontal
tabGrid.FillDirectionMaxCells = 3
tabGrid.HorizontalAlignment = Enum.HorizontalAlignment.Center
tabGrid.SortOrder = Enum.SortOrder.LayoutOrder
tabGrid.VerticalAlignment = Enum.VerticalAlignment.Top
tabGrid.Parent = tabContainer

mainTabButton = Instance.new("TextButton")
mainTabButton.Text = "Main"
setButtonStyle(mainTabButton, Theme.Primary)
mainTabButton.TextSize = 12
mainTabButton.Parent = tabContainer

tpTabButton = Instance.new("TextButton")
tpTabButton.Text = "Teleport"
setButtonStyle(tpTabButton, Theme.Surface)
tpTabButton.TextSize = 12
tpTabButton.Parent = tabContainer

farmTabButton = Instance.new("TextButton")
farmTabButton.Text = "Auto Farm"
setButtonStyle(farmTabButton, Theme.Surface)
farmTabButton.TextSize = 12
farmTabButton.Parent = tabContainer

harvestTabButton = Instance.new("TextButton")
harvestTabButton.Text = "Harvest"
setButtonStyle(harvestTabButton, Theme.Surface)
harvestTabButton.TextSize = 12
harvestTabButton.Parent = tabContainer

sellTabButton = Instance.new("TextButton")
sellTabButton.Text = "Sell"
setButtonStyle(sellTabButton, Theme.Surface)
sellTabButton.TextSize = 12
sellTabButton.Parent = tabContainer

 aboutTabButton = Instance.new("TextButton")
aboutTabButton.Text = "About"
setButtonStyle(aboutTabButton, Theme.Surface)
aboutTabButton.TextSize = 12
aboutTabButton.Parent = tabContainer

content = Instance.new("Frame")
content.Size = UDim2.new(1, -24, 1, -156)
content.Position = UDim2.new(0, 12, 0, 148)
content.BackgroundTransparency = 1
content.ClipsDescendants = true
content.Parent = rootFrame

 mainPage = Instance.new("Frame")
mainPage.Name = "MainPage"
mainPage.Size = UDim2.new(1, 0, 1, 0)
mainPage.BackgroundTransparency = 1
mainPage.Parent = content

 mainPadding = Instance.new("UIPadding")
mainPadding.PaddingTop = UDim.new(0, 2)
mainPadding.PaddingBottom = UDim.new(0, 2)
mainPadding.Parent = mainPage

 mainLayout = Instance.new("UIListLayout")
mainLayout.FillDirection = Enum.FillDirection.Vertical
mainLayout.Padding = UDim.new(0, 10)
mainLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
mainLayout.SortOrder = Enum.SortOrder.LayoutOrder
mainLayout.Parent = mainPage

 statusCard = Instance.new("Frame")
statusCard.Size = UDim2.new(1, 0, 0, 44)
statusCard.BackgroundColor3 = Theme.Surface
statusCard.BorderSizePixel = 0
statusCard.Parent = mainPage
addCorner(statusCard, 10)
addStroke(statusCard, Theme.Border, 1, 0.2)

 statusDot = Instance.new("Frame")
statusDot.Size = UDim2.new(0, 12, 0, 12)
statusDot.Position = UDim2.new(0, 12, 0.5, -6)
statusDot.BackgroundColor3 = Theme.Danger
statusDot.BorderSizePixel = 0
statusDot.Parent = statusCard
addCorner(statusDot, 50)

 statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -36, 1, 0)
statusLabel.Position = UDim2.new(0, 30, 0, 0)
statusLabel.Text = "Auto Click: OFF"
styleTextLabel(statusLabel, 14, Theme.Text, true)
statusLabel.Parent = statusCard

 toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(1, 0, 0, 44)
toggleButton.Text = "START AUTO CLICK"
setButtonStyle(toggleButton, Theme.Success)
toggleButton.TextColor3 = Color3.fromRGB(20, 26, 20)
toggleButton.Parent = mainPage

hotkeyLabel = Instance.new("TextLabel")
hotkeyLabel.Size = UDim2.new(1, 0, 0, 20)
hotkeyLabel.Text = "Hotkey: F = Auto Click, K = Auto Farm"
styleTextLabel(hotkeyLabel, 12, Theme.MutedText, false)
hotkeyLabel.Parent = mainPage

 cameraLabel = Instance.new("TextLabel")
cameraLabel.Size = UDim2.new(1, 0, 0, 20)
cameraLabel.Text = "Camera Lock: OFF"
styleTextLabel(cameraLabel, 12, Theme.MutedText, false)
cameraLabel.Parent = mainPage

 timingLabel = Instance.new("TextLabel")
timingLabel.Size = UDim2.new(1, 0, 0, 20)
timingLabel.Text = string.format("Timing: hold %.2fs, pause %.2fs", Settings.ClickDuration, Settings.WaitDuration)
styleTextLabel(timingLabel, 12, Theme.MutedText, false)
timingLabel.Parent = mainPage

 tipsCard = Instance.new("Frame")
tipsCard.Size = UDim2.new(1, 0, 0, 64)
tipsCard.BackgroundColor3 = Theme.Surface
tipsCard.BorderSizePixel = 0
tipsCard.Parent = mainPage
addCorner(tipsCard, 10)
addStroke(tipsCard, Theme.Border, 1, 0.2)

 tipsLabel = Instance.new("TextLabel")
tipsLabel.Size = UDim2.new(1, -16, 1, -10)
tipsLabel.Position = UDim2.new(0, 8, 0, 5)
tipsLabel.Text = "Tips:\n1. Aktifkan saat mau perfect chop.\n2. Matikan dulu sebelum pakai menu lain."
tipsLabel.TextWrapped = true
tipsLabel.TextYAlignment = Enum.TextYAlignment.Top
styleTextLabel(tipsLabel, 12, Theme.MutedText, false)
tipsLabel.Parent = tipsCard

 teleportPage = Instance.new("ScrollingFrame")
teleportPage.Name = "TeleportPage"
teleportPage.Size = UDim2.new(1, 0, 1, 0)
teleportPage.BackgroundTransparency = 1
teleportPage.BorderSizePixel = 0
teleportPage.ScrollBarThickness = 6
teleportPage.CanvasSize = UDim2.new(0, 0, 0, 0)
teleportPage.Visible = false
teleportPage.Parent = content

 tpPadding = Instance.new("UIPadding")
tpPadding.PaddingBottom = UDim.new(0, 6)
tpPadding.Parent = teleportPage

 tpLayout = Instance.new("UIListLayout")
tpLayout.FillDirection = Enum.FillDirection.Vertical
tpLayout.Padding = UDim.new(0, 8)
tpLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
tpLayout.SortOrder = Enum.SortOrder.LayoutOrder
tpLayout.Parent = teleportPage

trackConnection(tpLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    teleportPage.CanvasSize = UDim2.new(0, 0, 0, tpLayout.AbsoluteContentSize.Y + 12)
end))

 tpInfoCard = Instance.new("Frame")
tpInfoCard.Size = UDim2.new(1, 0, 0, 56)
tpInfoCard.BackgroundColor3 = Theme.Surface
tpInfoCard.BorderSizePixel = 0
tpInfoCard.Parent = teleportPage
addCorner(tpInfoCard, 10)
addStroke(tpInfoCard, Theme.Border, 1, 0.2)

 tpTitle = Instance.new("TextLabel")
tpTitle.Size = UDim2.new(1, -14, 0, 20)
tpTitle.Position = UDim2.new(0, 8, 0, 8)
tpTitle.Text = "Quick Teleport"
styleTextLabel(tpTitle, 13, Theme.Text, true)
tpTitle.Parent = tpInfoCard

 tpDesc = Instance.new("TextLabel")
tpDesc.Size = UDim2.new(1, -14, 0, 20)
tpDesc.Position = UDim2.new(0, 8, 0, 28)
tpDesc.Text = "Pilih area untuk teleport ke PlayerBounds."
styleTextLabel(tpDesc, 11, Theme.MutedText, false)
tpDesc.Parent = tpInfoCard

local zones = {
    {name = "Scarlet Canopy", folder = "Scarlet Canopy"},
    {name = "Birch Glade", folder = "Birch Glade"},
    {name = "Koi Lanterns", folder = "Koi Lanterns"},
    {name = "Thornveil", folder = "Thornveil"},
    {name = "Timber Town", folder = "Timber Town"},
    {name = "Winterneedle", folder = "Winterneedle"}
}
clampConfigZoneIndex(#zones)

function teleportToZone(zone)
    local zonesFolder = workspace:FindFirstChild("Zones")
    if not zonesFolder then
        warn("Zones folder not found.")
        return
    end

    local targetZone = zonesFolder:FindFirstChild(zone.folder)
    if not targetZone then
        warn("Zone not found: " .. zone.folder)
        return
    end

    local playerBounds = targetZone:FindFirstChild("PlayerBounds")
    local bounds = playerBounds and playerBounds:FindFirstChild("Bounds")
    if not bounds or not bounds:IsA("BasePart") then
        warn("Bounds part not found in " .. zone.folder)
        return
    end

    local character = player.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if not hrp then
        warn("HumanoidRootPart not found.")
        return
    end

    local basePosition = bounds.Position
    local isWinterneedle = normalizeFarmTreeText(zone.folder or zone.name or "") == "winterneedle"
    local rayStartHeight = isWinterneedle and 220 or 120
    local raycastLength = isWinterneedle and 900 or 600

    local targetPosition = basePosition + Vector3.new(0, isWinterneedle and 60 or 8, 0)
    local rayOrigin = basePosition + Vector3.new(0, rayStartHeight, 0)

    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    local excludeList = {character, bounds}
    if playerBounds then
        table.insert(excludeList, playerBounds)
    end
    rayParams.FilterDescendantsInstances = excludeList

    local hitResult = workspace:Raycast(rayOrigin, Vector3.new(0, -raycastLength, 0), rayParams)
    if hitResult then
        local groundLift = isWinterneedle and 10 or 7
        targetPosition = Vector3.new(basePosition.X, hitResult.Position.Y + groundLift, basePosition.Z)
    end

    hrp.CFrame = CFrame.new(targetPosition)
    print("Teleported to " .. zone.name)
end

function findZoneIndexByWeatherName(zoneName)
    local normalizedZone = normalizeFarmTreeText(zoneName)
    if normalizedZone == "" then
        return nil
    end

    local bestIndex = nil
    local bestScore = -1
    for i, zone in ipairs(zones) do
        local zoneText = normalizeFarmTreeText(zone.name or zone.folder or "")
        local score = 0
        if zoneText == normalizedZone then
            score = 100
        elseif string.find(zoneText, normalizedZone, 1, true) or string.find(normalizedZone, zoneText, 1, true) then
            score = 80
        else
            score = countSharedTokens(zoneText, normalizedZone) * 12
        end

        if score > bestScore then
            bestScore = score
            bestIndex = i
        end
    end

    if bestScore < 18 then
        return nil
    end
    return bestIndex
end

function parseWeatherMutationEventText(text)
    local cleaned = cleanGuiText(text)
    if cleaned == "" then
        return nil
    end

    local lowerText = string.lower(cleaned)
    if not string.find(lowerText, "weather:", 1, true) or not string.find(lowerText, "mutated", 1, true) then
        return nil
    end

    local zoneName, mutationName = string.match(cleaned, "[Ww]eather:%s*[Aa]%s+tree%s+in%s+(.+)%s+mutated%s+to%s+(.+)")
    if not zoneName then
        zoneName, mutationName = string.match(cleaned, "[Ww]eather:%s*(.+)%s+mutated%s+to%s+(.+)")
    end
    if not zoneName or not mutationName then
        return nil
    end

    zoneName = cleanGuiText(zoneName)
    mutationName = cleanGuiText(mutationName)
    mutationName = string.gsub(mutationName, "[%.,!%?]+$", "")
    mutationName = cleanGuiText(mutationName)
    if zoneName == "" or mutationName == "" then
        return nil
    end

    return {
        zoneName = zoneName,
        mutation = mutationName,
        message = cleaned,
        key = string.lower(cleaned)
    }
end

function scanLatestWeatherMutationEvent()
    local now = os.clock()
    if now - (FarmState.LastWeatherMutationScanAt or 0) < (Settings.WeatherMutationScanInterval or 0.45) then
        return nil
    end
    FarmState.LastWeatherMutationScanAt = now

    local bestEvent = nil
    local bestY = -math.huge
    for _, root in ipairs(getFarmUiScanRoots()) do
        if root then
            local descendants = nil
            pcall(function()
                descendants = root:GetDescendants()
            end)
            if descendants then
                for _, obj in ipairs(descendants) do
                    if (obj:IsA("TextLabel") or obj:IsA("TextButton")) and obj.Visible then
                        local parsed = parseWeatherMutationEventText(obj.Text or "")
                        if parsed then
                            local y = 0
                            pcall(function()
                                y = obj.AbsolutePosition.Y
                            end)
                            if not bestEvent or y >= bestY then
                                bestEvent = parsed
                                bestY = y
                            end
                        end
                    end
                end
            end
        end
    end

    if not bestEvent then
        return nil
    end

    local repeatBlock = Settings.WeatherMutationRepeatBlockSeconds or 180
    if FarmState.LastWeatherMutationMessageKey == bestEvent.key
        and now - (FarmState.LastWeatherMutationMessageAt or 0) < repeatBlock then
        return nil
    end

    FarmState.LastWeatherMutationMessageKey = bestEvent.key
    FarmState.LastWeatherMutationMessageAt = now
    return bestEvent
end

function applyWeatherMutationEvent(event)
    if not event then
        return false
    end

    local zoneIndex = findZoneIndexByWeatherName(event.zoneName)
    if not zoneIndex then
        FarmState.LastConflictText = "Weather event terdeteksi tapi zone tidak dikenali: " .. tostring(event.zoneName)
        FarmState.LastConflictAt = os.clock()
        return false
    end

    local mutationText = cleanGuiText(event.mutation)
    local mutationNormalized = normalizeFarmTreeText(mutationText)
    if mutationNormalized == "" then
        return false
    end

    local now = os.clock()
    FarmState.WeatherMutationTarget = {
        zoneIndex = zoneIndex,
        zoneName = zones[zoneIndex].name or zones[zoneIndex].folder,
        mutation = mutationText,
        mutationNormalized = mutationNormalized,
        message = event.message,
        detectedAt = now,
        expiresAt = now + (Settings.WeatherMutationTargetLifetimeSeconds or 420)
    }
    FarmState.LastWeatherMutationHandledKey = event.key

    FarmState.ZoneIndex = zoneIndex
    if farmZoneButton then
        farmZoneButton.Text = "Farm Zone: " .. zones[zoneIndex].name
    end

    FarmState.LastConflictText = string.format(
        "Weather Hunt: %s | Mutation %s",
        tostring(zones[zoneIndex].name),
        tostring(mutationText)
    )
    FarmState.LastConflictAt = now

    teleportToZone(zones[zoneIndex])
    FarmState.LockedTarget = nil
    FarmState.CurrentTarget = nil
    FarmState.SkipRequested = false
    if refreshFarmUiCallback then
        refreshFarmUiCallback(true)
    end
    return true
end

function processWeatherMutationEvent()
    if not FarmState.WeatherMutationEnabled then
        return false
    end

    local event = scanLatestWeatherMutationEvent()
    if not event then
        return false
    end

    return applyWeatherMutationEvent(event)
end

for _, zone in ipairs(zones) do
    local zoneButton = Instance.new("TextButton")
    zoneButton.Size = UDim2.new(1, 0, 0, 40)
    zoneButton.Text = zone.name
    setButtonStyle(zoneButton, Theme.Surface)
    zoneButton.Parent = teleportPage
    attachHover(zoneButton, Theme.Surface, Theme.SurfaceHover)

    zoneButton.MouseButton1Click:Connect(function()
        teleportToZone(zone)
    end)
end

 farmPage = Instance.new("ScrollingFrame")
farmPage.Name = "FarmPage"
farmPage.Size = UDim2.new(1, 0, 1, 0)
farmPage.BackgroundTransparency = 1
farmPage.BorderSizePixel = 0
farmPage.ScrollBarThickness = 6
farmPage.CanvasSize = UDim2.new(0, 0, 0, 0)
farmPage.Visible = false
farmPage.Parent = content

 farmPadding = Instance.new("UIPadding")
farmPadding.PaddingBottom = UDim.new(0, 6)
farmPadding.Parent = farmPage

 farmLayout = Instance.new("UIListLayout")
farmLayout.FillDirection = Enum.FillDirection.Vertical
farmLayout.Padding = UDim.new(0, 8)
farmLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
farmLayout.SortOrder = Enum.SortOrder.LayoutOrder
farmLayout.Parent = farmPage

trackConnection(farmLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    farmPage.CanvasSize = UDim2.new(0, 0, 0, farmLayout.AbsoluteContentSize.Y + 12)
end))

 harvestPage = Instance.new("ScrollingFrame")
harvestPage.Name = "HarvestPage"
harvestPage.Size = UDim2.new(1, 0, 1, 0)
harvestPage.BackgroundTransparency = 1
harvestPage.BorderSizePixel = 0
harvestPage.ScrollBarThickness = 6
harvestPage.CanvasSize = UDim2.new(0, 0, 0, 0)
harvestPage.Visible = false
harvestPage.Parent = content

 harvestPadding = Instance.new("UIPadding")
harvestPadding.PaddingBottom = UDim.new(0, 6)
harvestPadding.Parent = harvestPage

 harvestLayout = Instance.new("UIListLayout")
harvestLayout.FillDirection = Enum.FillDirection.Vertical
harvestLayout.Padding = UDim.new(0, 8)
harvestLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
harvestLayout.SortOrder = Enum.SortOrder.LayoutOrder
harvestLayout.Parent = harvestPage

trackConnection(harvestLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    harvestPage.CanvasSize = UDim2.new(0, 0, 0, harvestLayout.AbsoluteContentSize.Y + 12)
end))

 sellPage = Instance.new("ScrollingFrame")
sellPage.Name = "SellPage"
sellPage.Size = UDim2.new(1, 0, 1, 0)
sellPage.BackgroundTransparency = 1
sellPage.BorderSizePixel = 0
sellPage.ScrollBarThickness = 6
sellPage.CanvasSize = UDim2.new(0, 0, 0, 0)
sellPage.Visible = false
sellPage.Parent = content

 sellPadding = Instance.new("UIPadding")
sellPadding.PaddingBottom = UDim.new(0, 6)
sellPadding.Parent = sellPage

 sellLayout = Instance.new("UIListLayout")
sellLayout.FillDirection = Enum.FillDirection.Vertical
sellLayout.Padding = UDim.new(0, 8)
sellLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
sellLayout.SortOrder = Enum.SortOrder.LayoutOrder
sellLayout.Parent = sellPage

trackConnection(sellLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    sellPage.CanvasSize = UDim2.new(0, 0, 0, sellLayout.AbsoluteContentSize.Y + 12)
end))

 aboutPage = Instance.new("ScrollingFrame")
aboutPage.Name = "AboutPage"
aboutPage.Size = UDim2.new(1, 0, 1, 0)
aboutPage.BackgroundTransparency = 1
aboutPage.BorderSizePixel = 0
aboutPage.ScrollBarThickness = 6
aboutPage.CanvasSize = UDim2.new(0, 0, 0, 0)
aboutPage.Visible = false
aboutPage.Parent = content

 aboutPadding = Instance.new("UIPadding")
aboutPadding.PaddingBottom = UDim.new(0, 6)
aboutPadding.Parent = aboutPage

 aboutLayout = Instance.new("UIListLayout")
aboutLayout.FillDirection = Enum.FillDirection.Vertical
aboutLayout.Padding = UDim.new(0, 8)
aboutLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
aboutLayout.SortOrder = Enum.SortOrder.LayoutOrder
aboutLayout.Parent = aboutPage

trackConnection(aboutLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    aboutPage.CanvasSize = UDim2.new(0, 0, 0, aboutLayout.AbsoluteContentSize.Y + 12)
end))

 aboutHeroCard = Instance.new("Frame")
aboutHeroCard.Size = UDim2.new(1, 0, 0, 86)
aboutHeroCard.BackgroundColor3 = Theme.Surface
aboutHeroCard.BorderSizePixel = 0
aboutHeroCard.Parent = aboutPage
addCorner(aboutHeroCard, 10)
addStroke(aboutHeroCard, Theme.Border, 1, 0.2)

 aboutHeroTitle = Instance.new("TextLabel")
aboutHeroTitle.Size = UDim2.new(1, -14, 0, 24)
aboutHeroTitle.Position = UDim2.new(0, 8, 0, 8)
aboutHeroTitle.Text = "Timber Script by Vaan"
styleTextLabel(aboutHeroTitle, 15, Theme.Text, true)
aboutHeroTitle.Parent = aboutHeroCard

 aboutHeroSubtitle = Instance.new("TextLabel")
aboutHeroSubtitle.Size = UDim2.new(1, -14, 0, 18)
aboutHeroSubtitle.Position = UDim2.new(0, 8, 0, 34)
aboutHeroSubtitle.Text = "Creator: Vaan | Version: v2.1.0"
styleTextLabel(aboutHeroSubtitle, 12, Theme.Success, true)
aboutHeroSubtitle.Parent = aboutHeroCard

 aboutHeroDesc = Instance.new("TextLabel")
aboutHeroDesc.Size = UDim2.new(1, -14, 0, 26)
aboutHeroDesc.Position = UDim2.new(0, 8, 0, 54)
aboutHeroDesc.Text = "Toolkit untuk auto chop/farm/harvest/sell dengan lock target dan skip safety."
aboutHeroDesc.TextWrapped = true
styleTextLabel(aboutHeroDesc, 11, Theme.MutedText, false)
aboutHeroDesc.Parent = aboutHeroCard

 aboutFeatureCard = Instance.new("Frame")
aboutFeatureCard.Size = UDim2.new(1, 0, 0, 124)
aboutFeatureCard.BackgroundColor3 = Theme.Surface
aboutFeatureCard.BorderSizePixel = 0
aboutFeatureCard.Parent = aboutPage
addCorner(aboutFeatureCard, 10)
addStroke(aboutFeatureCard, Theme.Border, 1, 0.2)

 aboutFeatureTitle = Instance.new("TextLabel")
aboutFeatureTitle.Size = UDim2.new(1, -14, 0, 20)
aboutFeatureTitle.Position = UDim2.new(0, 8, 0, 8)
aboutFeatureTitle.Text = "Core Features"
styleTextLabel(aboutFeatureTitle, 13, Theme.Text, true)
aboutFeatureTitle.Parent = aboutFeatureCard

 aboutFeatureLabel = Instance.new("TextLabel")
aboutFeatureLabel.Size = UDim2.new(1, -14, 1, -34)
aboutFeatureLabel.Position = UDim2.new(0, 8, 0, 26)
aboutFeatureLabel.Text = "1) Auto Chop + Camera lock\n2) Auto Farm hard-lock tree + skip bentrok\n3) Auto Harvest return-to-plot + cache reset\n4) Auto Sell (sell all / filter by item stats)"
aboutFeatureLabel.TextWrapped = true
aboutFeatureLabel.TextYAlignment = Enum.TextYAlignment.Top
styleTextLabel(aboutFeatureLabel, 11, Theme.MutedText, false)
aboutFeatureLabel.Parent = aboutFeatureCard

 aboutHotkeyCard = Instance.new("Frame")
aboutHotkeyCard.Size = UDim2.new(1, 0, 0, 74)
aboutHotkeyCard.BackgroundColor3 = Theme.Surface
aboutHotkeyCard.BorderSizePixel = 0
aboutHotkeyCard.Parent = aboutPage
addCorner(aboutHotkeyCard, 10)
addStroke(aboutHotkeyCard, Theme.Border, 1, 0.2)

 aboutHotkeyTitle = Instance.new("TextLabel")
aboutHotkeyTitle.Size = UDim2.new(1, -14, 0, 20)
aboutHotkeyTitle.Position = UDim2.new(0, 8, 0, 8)
aboutHotkeyTitle.Text = "Hotkeys"
styleTextLabel(aboutHotkeyTitle, 13, Theme.Text, true)
aboutHotkeyTitle.Parent = aboutHotkeyCard

 aboutHotkeyLabel = Instance.new("TextLabel")
aboutHotkeyLabel.Size = UDim2.new(1, -14, 0, 34)
aboutHotkeyLabel.Position = UDim2.new(0, 8, 0, 30)
aboutHotkeyLabel.Text = "F = Toggle Auto Click\nK = Toggle Auto Farm"
aboutHotkeyLabel.TextWrapped = true
styleTextLabel(aboutHotkeyLabel, 12, Theme.MutedText, false)
aboutHotkeyLabel.Parent = aboutHotkeyCard

 farmInfoCard = Instance.new("Frame")
farmInfoCard.Size = UDim2.new(1, 0, 0, 64)
farmInfoCard.BackgroundColor3 = Theme.Surface
farmInfoCard.BorderSizePixel = 0
farmInfoCard.Parent = farmPage
addCorner(farmInfoCard, 10)
addStroke(farmInfoCard, Theme.Border, 1, 0.2)

 farmTitle = Instance.new("TextLabel")
farmTitle.Size = UDim2.new(1, -14, 0, 20)
farmTitle.Position = UDim2.new(0, 8, 0, 8)
farmTitle.Text = "Auto Farm"
styleTextLabel(farmTitle, 13, Theme.Text, true)
farmTitle.Parent = farmInfoCard

 farmDesc = Instance.new("TextLabel")
farmDesc.Size = UDim2.new(1, -14, 0, 28)
farmDesc.Position = UDim2.new(0, 8, 0, 30)
 farmDesc.Text = "Auto Farm: TP zone -> lock tree -> chop. Target Tree bisa lebih dari 1 (pisah koma). No ByteNet packet = auto NEXT, plus skip bentrok 'already chopping', skip player radius dekat tree, skip action E/tap, skip popup Robux, cooldown respawn, dan tombol NEXT manual."
farmDesc.TextWrapped = true
styleTextLabel(farmDesc, 11, Theme.MutedText, false)
farmDesc.Parent = farmInfoCard

 farmStatusCard = Instance.new("Frame")
farmStatusCard.Size = UDim2.new(1, 0, 0, 38)
farmStatusCard.BackgroundColor3 = Theme.Surface
farmStatusCard.BorderSizePixel = 0
farmStatusCard.Parent = farmPage
addCorner(farmStatusCard, 10)
addStroke(farmStatusCard, Theme.Border, 1, 0.2)

 farmStatusLabel = Instance.new("TextLabel")
farmStatusLabel.Size = UDim2.new(1, -14, 1, 0)
farmStatusLabel.Position = UDim2.new(0, 8, 0, 0)
farmStatusLabel.Text = "Farm Status: OFF"
styleTextLabel(farmStatusLabel, 12, Theme.MutedText, true)
farmStatusLabel.Parent = farmStatusCard

 radiusCard = Instance.new("Frame")
radiusCard.Size = UDim2.new(1, 0, 0, 44)
radiusCard.BackgroundColor3 = Theme.Surface
radiusCard.BorderSizePixel = 0
radiusCard.Parent = farmPage
addCorner(radiusCard, 10)
addStroke(radiusCard, Theme.Border, 1, 0.2)

 radiusLabel = Instance.new("TextLabel")
radiusLabel.Size = UDim2.new(0.45, -10, 1, 0)
radiusLabel.Position = UDim2.new(0, 8, 0, 0)
radiusLabel.Text = "Radius Scan"
styleTextLabel(radiusLabel, 12, Theme.Text, true)
radiusLabel.Parent = radiusCard

 farmRadiusInput = Instance.new("TextBox")
farmRadiusInput.Size = UDim2.new(0.55, -12, 0, 30)
farmRadiusInput.Position = UDim2.new(0.45, 4, 0.5, -15)
farmRadiusInput.BackgroundColor3 = Theme.Background
farmRadiusInput.BorderSizePixel = 0
farmRadiusInput.Text = tostring(FarmState.Radius)
farmRadiusInput.ClearTextOnFocus = false
farmRadiusInput.PlaceholderText = "contoh: 120"
farmRadiusInput.TextColor3 = Theme.Text
farmRadiusInput.TextSize = 12
farmRadiusInput.Font = Enum.Font.Gotham
 farmRadiusInput.Parent = radiusCard
addCorner(farmRadiusInput, 8)
addStroke(farmRadiusInput, Theme.Border, 1, 0.3)

 farmTreeFilterCard = Instance.new("Frame")
farmTreeFilterCard.Size = UDim2.new(1, 0, 0, 44)
farmTreeFilterCard.BackgroundColor3 = Theme.Surface
farmTreeFilterCard.BorderSizePixel = 0
farmTreeFilterCard.Parent = farmPage
addCorner(farmTreeFilterCard, 10)
addStroke(farmTreeFilterCard, Theme.Border, 1, 0.2)

 farmTreeFilterLabel = Instance.new("TextLabel")
farmTreeFilterLabel.Size = UDim2.new(0.45, -10, 1, 0)
farmTreeFilterLabel.Position = UDim2.new(0, 8, 0, 0)
farmTreeFilterLabel.Text = "Target Tree"
styleTextLabel(farmTreeFilterLabel, 12, Theme.Text, true)
farmTreeFilterLabel.Parent = farmTreeFilterCard

 farmTreeFilterInput = Instance.new("TextBox")
farmTreeFilterInput.Size = UDim2.new(0.55, -12, 0, 30)
farmTreeFilterInput.Position = UDim2.new(0.45, 4, 0.5, -15)
farmTreeFilterInput.BackgroundColor3 = Theme.Background
farmTreeFilterInput.BorderSizePixel = 0
farmTreeFilterInput.Text = FarmState.TreeFilter ~= "" and FarmState.TreeFilter or ""
farmTreeFilterInput.ClearTextOnFocus = false
farmTreeFilterInput.PlaceholderText = "Pisah koma | contoh: Blackthorn, Oak"
farmTreeFilterInput.TextColor3 = Theme.Text
farmTreeFilterInput.TextSize = 12
farmTreeFilterInput.Font = Enum.Font.Gotham
farmTreeFilterInput.Parent = farmTreeFilterCard
addCorner(farmTreeFilterInput, 8)
addStroke(farmTreeFilterInput, Theme.Border, 1, 0.3)

 farmZoneButton = Instance.new("TextButton")
farmZoneButton.Size = UDim2.new(1, 0, 0, 40)
farmZoneButton.Text = "Farm Zone: " .. zones[FarmState.ZoneIndex].name
setButtonStyle(farmZoneButton, Theme.Surface)
farmZoneButton.Parent = farmPage
attachHover(farmZoneButton, Theme.Surface, Theme.SurfaceHover)

farmPriorityButton = Instance.new("TextButton")
farmPriorityButton.Size = UDim2.new(1, 0, 0, 36)
farmPriorityButton.Text = "Priority: " .. getFarmPriorityModeLabel(FarmState.PriorityMode)
setButtonStyle(farmPriorityButton, Theme.Surface)
farmPriorityButton.Parent = farmPage
attachHover(farmPriorityButton, Theme.Surface, Theme.SurfaceHover)

farmWeatherToggleButton = Instance.new("TextButton")
farmWeatherToggleButton.Size = UDim2.new(1, 0, 0, 36)
farmWeatherToggleButton.Text = "Weather Mutation Hunt: ON"
setButtonStyle(farmWeatherToggleButton, Theme.Success)
farmWeatherToggleButton.TextColor3 = Color3.fromRGB(20, 26, 20)
farmWeatherToggleButton.Parent = farmPage

farmEspToggleButton = Instance.new("TextButton")
farmEspToggleButton.Size = UDim2.new(1, 0, 0, 36)
farmEspToggleButton.Text = "Tree ESP: OFF"
setButtonStyle(farmEspToggleButton, Theme.Surface)
farmEspToggleButton.Parent = farmPage

farmForceTreeInfoToggleButton = Instance.new("TextButton")
farmForceTreeInfoToggleButton.Size = UDim2.new(1, 0, 0, 36)
farmForceTreeInfoToggleButton.Text = "Force TreeInfo: OFF"
setButtonStyle(farmForceTreeInfoToggleButton, Theme.Surface)
farmForceTreeInfoToggleButton.Parent = farmPage

 farmScanButton = Instance.new("TextButton")
farmScanButton.Size = UDim2.new(1, 0, 0, 40)
farmScanButton.Text = "Scan Object Sekitar"
setButtonStyle(farmScanButton, Theme.Primary)
farmScanButton.Parent = farmPage
attachHover(farmScanButton, Theme.Primary, Theme.PrimaryActive)

 farmNextButton = Instance.new("TextButton")
farmNextButton.Size = UDim2.new(1, 0, 0, 36)
farmNextButton.Text = "SKIP TARGET (NEXT)"
setButtonStyle(farmNextButton, Theme.Surface)
farmNextButton.Parent = farmPage
attachHover(farmNextButton, Theme.Surface, Theme.SurfaceHover)

 farmTargetLabel = Instance.new("TextLabel")
farmTargetLabel.Size = UDim2.new(1, 0, 0, 44)
farmTargetLabel.Text = "Target: belum ada hasil scan"
farmTargetLabel.TextWrapped = true
farmTargetLabel.TextYAlignment = Enum.TextYAlignment.Top
styleTextLabel(farmTargetLabel, 12, Theme.MutedText, false)
farmTargetLabel.Parent = farmPage

 farmCooldownLabel = Instance.new("TextLabel")
farmCooldownLabel.Size = UDim2.new(1, 0, 0, 20)
farmCooldownLabel.Text = "Cooldown Skip: 0 | Active Cooldown: 0"
styleTextLabel(farmCooldownLabel, 11, Theme.MutedText, false)
farmCooldownLabel.Parent = farmPage

 treeLockCard = Instance.new("Frame")
treeLockCard.Size = UDim2.new(1, 0, 0, 132)
treeLockCard.BackgroundColor3 = Theme.Surface
treeLockCard.BorderSizePixel = 0
treeLockCard.Parent = farmPage
addCorner(treeLockCard, 10)
addStroke(treeLockCard, Theme.Border, 1, 0.2)

 treeLockTitle = Instance.new("TextLabel")
treeLockTitle.Size = UDim2.new(1, -14, 0, 20)
treeLockTitle.Position = UDim2.new(0, 8, 0, 6)
treeLockTitle.Text = "Tree Lock"
styleTextLabel(treeLockTitle, 12, Theme.Text, true)
treeLockTitle.Parent = treeLockCard

 treeLockLabel = Instance.new("TextLabel")
treeLockLabel.Size = UDim2.new(1, -14, 1, -34)
treeLockLabel.Position = UDim2.new(0, 8, 0, 26)
treeLockLabel.Text = "LOCK: belum ada target."
treeLockLabel.TextWrapped = true
treeLockLabel.TextYAlignment = Enum.TextYAlignment.Top
styleTextLabel(treeLockLabel, 11, Theme.MutedText, false)
treeLockLabel.Parent = treeLockCard

 farmListCard = Instance.new("Frame")
farmListCard.Size = UDim2.new(1, 0, 0, 220)
farmListCard.BackgroundColor3 = Theme.Surface
farmListCard.BorderSizePixel = 0
farmListCard.Parent = farmPage
addCorner(farmListCard, 10)
addStroke(farmListCard, Theme.Border, 1, 0.2)

 farmListLabel = Instance.new("TextLabel")
farmListLabel.Size = UDim2.new(1, -14, 1, -10)
farmListLabel.Position = UDim2.new(0, 8, 0, 5)
farmListLabel.Text = "Hasil deteksi akan tampil di sini."
farmListLabel.TextWrapped = true
farmListLabel.TextYAlignment = Enum.TextYAlignment.Top
styleTextLabel(farmListLabel, 11, Theme.MutedText, false)
farmListLabel.Parent = farmListCard

farmInfoFloatFrame = Instance.new("Frame")
farmInfoFloatFrame.Name = "FarmInfoPanel"
farmInfoFloatFrame.Size = UDim2.new(0, 420, 0, 430)
farmInfoFloatFrame.Position = UDim2.new(0.5, 230, 0, 84)
farmInfoFloatFrame.BackgroundColor3 = Theme.Background
farmInfoFloatFrame.BorderSizePixel = 0
farmInfoFloatFrame.Active = true
farmInfoFloatFrame.Draggable = true
farmInfoFloatFrame.Visible = false
farmInfoFloatFrame.ZIndex = 15
farmInfoFloatFrame.Parent = screenGui
addCorner(farmInfoFloatFrame, 12)
addStroke(farmInfoFloatFrame, Theme.Border, 1, 0.15)

farmInfoFloatHeader = Instance.new("Frame")
farmInfoFloatHeader.Size = UDim2.new(1, 0, 0, 34)
farmInfoFloatHeader.BackgroundColor3 = Theme.Header
farmInfoFloatHeader.BorderSizePixel = 0
farmInfoFloatHeader.Parent = farmInfoFloatFrame
farmInfoFloatHeader.ZIndex = 16
addCorner(farmInfoFloatHeader, 12)

farmInfoFloatHeaderMask = Instance.new("Frame")
farmInfoFloatHeaderMask.Size = UDim2.new(1, 0, 0, 10)
farmInfoFloatHeaderMask.Position = UDim2.new(0, 0, 1, -10)
farmInfoFloatHeaderMask.BackgroundColor3 = Theme.Header
farmInfoFloatHeaderMask.BorderSizePixel = 0
farmInfoFloatHeaderMask.Parent = farmInfoFloatHeader
farmInfoFloatHeaderMask.ZIndex = 16

farmInfoFloatTitle = Instance.new("TextLabel")
farmInfoFloatTitle.Size = UDim2.new(1, -12, 1, 0)
farmInfoFloatTitle.Position = UDim2.new(0, 8, 0, 0)
farmInfoFloatTitle.Text = "Farm Info (Drag)"
styleTextLabel(farmInfoFloatTitle, 12, Theme.Text, true)
farmInfoFloatTitle.TextXAlignment = Enum.TextXAlignment.Left
farmInfoFloatTitle.Parent = farmInfoFloatHeader
farmInfoFloatTitle.ZIndex = 17

farmInfoFloatBody = Instance.new("Frame")
farmInfoFloatBody.Size = UDim2.new(1, -10, 1, -40)
farmInfoFloatBody.Position = UDim2.new(0, 5, 0, 36)
farmInfoFloatBody.BackgroundTransparency = 1
farmInfoFloatBody.Parent = farmInfoFloatFrame
farmInfoFloatBody.ZIndex = 16

farmCooldownLabel.Parent = farmInfoFloatBody
farmCooldownLabel.Size = UDim2.new(1, -10, 0, 20)
farmCooldownLabel.Position = UDim2.new(0, 5, 0, 0)
farmCooldownLabel.ZIndex = 17

treeLockCard.Parent = farmInfoFloatBody
treeLockCard.Size = UDim2.new(1, 0, 0, 132)
treeLockCard.Position = UDim2.new(0, 0, 0, 24)
treeLockCard.ZIndex = 16

treeLockTitle.ZIndex = 17
treeLockLabel.ZIndex = 17

farmListCard.Parent = farmInfoFloatBody
farmListCard.Size = UDim2.new(1, 0, 1, -164)
farmListCard.Position = UDim2.new(0, 0, 0, 164)
farmListCard.ZIndex = 16

farmListLabel.ZIndex = 17

 farmToggleButton = Instance.new("TextButton")
farmToggleButton.Size = UDim2.new(1, 0, 0, 44)
farmToggleButton.Text = "START AUTO FARM"
setButtonStyle(farmToggleButton, Theme.Warning)
farmToggleButton.TextColor3 = Color3.fromRGB(25, 25, 25)
farmToggleButton.Parent = farmPage

 harvestInfoCard = Instance.new("Frame")
harvestInfoCard.Size = UDim2.new(1, 0, 0, 78)
harvestInfoCard.BackgroundColor3 = Theme.Surface
harvestInfoCard.BorderSizePixel = 0
harvestInfoCard.Parent = harvestPage
addCorner(harvestInfoCard, 10)
addStroke(harvestInfoCard, Theme.Border, 1, 0.2)

 harvestTitle = Instance.new("TextLabel")
harvestTitle.Size = UDim2.new(1, -14, 0, 20)
harvestTitle.Position = UDim2.new(0, 8, 0, 8)
harvestTitle.Text = "Auto Harvest"
styleTextLabel(harvestTitle, 13, Theme.Text, true)
harvestTitle.Parent = harvestInfoCard

 harvestDesc = Instance.new("TextLabel")
harvestDesc.Size = UDim2.new(1, -14, 0, 42)
harvestDesc.Position = UDim2.new(0, 8, 0, 30)
harvestDesc.Text = "Balik ke plot lalu collect object terdekat. Jika semua sudah di-harvest, cache reset otomatis tiap 5 menit."
harvestDesc.TextWrapped = true
harvestDesc.TextYAlignment = Enum.TextYAlignment.Top
styleTextLabel(harvestDesc, 11, Theme.MutedText, false)
harvestDesc.Parent = harvestInfoCard

 harvestRadiusLabel = Instance.new("TextLabel")
harvestRadiusLabel.Size = UDim2.new(1, 0, 0, 20)
harvestRadiusLabel.Text = "Radius scan mengikuti input di tab Auto Farm."
styleTextLabel(harvestRadiusLabel, 11, Theme.MutedText, false)
harvestRadiusLabel.Parent = harvestPage

 harvestStatusCard = Instance.new("Frame")
harvestStatusCard.Size = UDim2.new(1, 0, 0, 38)
harvestStatusCard.BackgroundColor3 = Theme.Surface
harvestStatusCard.BorderSizePixel = 0
harvestStatusCard.Parent = harvestPage
addCorner(harvestStatusCard, 10)
addStroke(harvestStatusCard, Theme.Border, 1, 0.2)

 harvestStatusLabel = Instance.new("TextLabel")
harvestStatusLabel.Size = UDim2.new(1, -14, 1, 0)
harvestStatusLabel.Position = UDim2.new(0, 8, 0, 0)
harvestStatusLabel.Text = "Harvest Status: OFF"
styleTextLabel(harvestStatusLabel, 12, Theme.MutedText, true)
harvestStatusLabel.Parent = harvestStatusCard

 harvestTargetLabel = Instance.new("TextLabel")
harvestTargetLabel.Size = UDim2.new(1, 0, 0, 32)
harvestTargetLabel.Text = "Harvest Target: -"
harvestTargetLabel.TextWrapped = true
harvestTargetLabel.TextYAlignment = Enum.TextYAlignment.Top
styleTextLabel(harvestTargetLabel, 12, Theme.MutedText, false)
harvestTargetLabel.Parent = harvestPage

 harvestProcessedLabel = Instance.new("TextLabel")
harvestProcessedLabel.Size = UDim2.new(1, 0, 0, 46)
harvestProcessedLabel.Text = "Processed: 0 | Skipped (done): 0"
harvestProcessedLabel.TextWrapped = true
harvestProcessedLabel.TextYAlignment = Enum.TextYAlignment.Top
styleTextLabel(harvestProcessedLabel, 12, Theme.MutedText, false)
harvestProcessedLabel.Parent = harvestPage

 harvestToggleButton = Instance.new("TextButton")
harvestToggleButton.Size = UDim2.new(1, 0, 0, 44)
harvestToggleButton.Text = "START AUTO HARVEST"
setButtonStyle(harvestToggleButton, Theme.Primary)
harvestToggleButton.Parent = harvestPage

 sellInfoCard = Instance.new("Frame")
sellInfoCard.Size = UDim2.new(1, 0, 0, 74)
sellInfoCard.BackgroundColor3 = Theme.Surface
sellInfoCard.BorderSizePixel = 0
sellInfoCard.Parent = sellPage
addCorner(sellInfoCard, 10)
addStroke(sellInfoCard, Theme.Border, 1, 0.2)

 sellTitle = Instance.new("TextLabel")
sellTitle.Size = UDim2.new(1, -14, 0, 20)
sellTitle.Position = UDim2.new(0, 8, 0, 8)
sellTitle.Text = "Sell Inventory"
styleTextLabel(sellTitle, 13, Theme.Text, true)
sellTitle.Parent = sellInfoCard

 sellDesc = Instance.new("TextLabel")
sellDesc.Size = UDim2.new(1, -14, 0, 38)
sellDesc.Position = UDim2.new(0, 8, 0, 30)
sellDesc.Text = "Mode jual: Opsi 1 = sell all. Opsi 2 = sell by filter, auto hold card item di inventory GUI, lalu equip dan jual."
sellDesc.TextWrapped = true
sellDesc.TextYAlignment = Enum.TextYAlignment.Top
styleTextLabel(sellDesc, 11, Theme.MutedText, false)
sellDesc.Parent = sellInfoCard

 sellStatusCard = Instance.new("Frame")
sellStatusCard.Size = UDim2.new(1, 0, 0, 38)
sellStatusCard.BackgroundColor3 = Theme.Surface
sellStatusCard.BorderSizePixel = 0
sellStatusCard.Parent = sellPage
addCorner(sellStatusCard, 10)
addStroke(sellStatusCard, Theme.Border, 1, 0.2)

 sellStatusLabel = Instance.new("TextLabel")
sellStatusLabel.Size = UDim2.new(1, -14, 1, 0)
sellStatusLabel.Position = UDim2.new(0, 8, 0, 0)
sellStatusLabel.Text = "Sell Status: OFF"
styleTextLabel(sellStatusLabel, 12, Theme.MutedText, true)
sellStatusLabel.Parent = sellStatusCard

 sellNameFilterCard = Instance.new("Frame")
sellNameFilterCard.Size = UDim2.new(1, 0, 0, 44)
sellNameFilterCard.BackgroundColor3 = Theme.Surface
sellNameFilterCard.BorderSizePixel = 0
sellNameFilterCard.Parent = sellPage
addCorner(sellNameFilterCard, 10)
addStroke(sellNameFilterCard, Theme.Border, 1, 0.2)

 sellNameFilterLabel = Instance.new("TextLabel")
sellNameFilterLabel.Size = UDim2.new(0.38, -8, 1, 0)
sellNameFilterLabel.Position = UDim2.new(0, 8, 0, 0)
sellNameFilterLabel.Text = "Name (Opsional)"
styleTextLabel(sellNameFilterLabel, 12, Theme.Text, true)
sellNameFilterLabel.Parent = sellNameFilterCard

 sellNameFilterInput = Instance.new("TextBox")
sellNameFilterInput.Size = UDim2.new(0.62, -12, 0, 30)
sellNameFilterInput.Position = UDim2.new(0.38, 4, 0.5, -15)
sellNameFilterInput.BackgroundColor3 = Theme.Background
sellNameFilterInput.BorderSizePixel = 0
sellNameFilterInput.Text = SellState.NameFilter
sellNameFilterInput.PlaceholderText = "contoh: mushroom"
sellNameFilterInput.ClearTextOnFocus = false
sellNameFilterInput.TextColor3 = Theme.Text
sellNameFilterInput.TextSize = 12
sellNameFilterInput.Font = Enum.Font.Gotham
sellNameFilterInput.Parent = sellNameFilterCard
addCorner(sellNameFilterInput, 8)
addStroke(sellNameFilterInput, Theme.Border, 1, 0.3)

 sellCountFilterCard = Instance.new("Frame")
sellCountFilterCard.Size = UDim2.new(1, 0, 0, 44)
sellCountFilterCard.BackgroundColor3 = Theme.Surface
sellCountFilterCard.BorderSizePixel = 0
sellCountFilterCard.Parent = sellPage
addCorner(sellCountFilterCard, 10)
addStroke(sellCountFilterCard, Theme.Border, 1, 0.2)

 sellCountAttrInput = Instance.new("TextBox")
sellCountAttrInput.Size = UDim2.new(0.42, -10, 0, 30)
sellCountAttrInput.Position = UDim2.new(0, 8, 0.5, -15)
sellCountAttrInput.BackgroundColor3 = Theme.Background
sellCountAttrInput.BorderSizePixel = 0
sellCountAttrInput.Text = SellState.CountAttr
sellCountAttrInput.PlaceholderText = "CurrencyPerSecond Attr"
sellCountAttrInput.ClearTextOnFocus = false
sellCountAttrInput.TextColor3 = Theme.Text
sellCountAttrInput.TextSize = 12
sellCountAttrInput.Font = Enum.Font.Gotham
sellCountAttrInput.Parent = sellCountFilterCard
addCorner(sellCountAttrInput, 8)
addStroke(sellCountAttrInput, Theme.Border, 1, 0.3)

 sellMinCountInput = Instance.new("TextBox")
sellMinCountInput.Size = UDim2.new(0.27, -10, 0, 30)
sellMinCountInput.Position = UDim2.new(0.42, 2, 0.5, -15)
sellMinCountInput.BackgroundColor3 = Theme.Background
sellMinCountInput.BorderSizePixel = 0
sellMinCountInput.Text = tostring(SellState.MinCount)
sellMinCountInput.PlaceholderText = "Min Currency/s"
sellMinCountInput.ClearTextOnFocus = false
sellMinCountInput.TextColor3 = Theme.Text
sellMinCountInput.TextSize = 12
sellMinCountInput.Font = Enum.Font.Gotham
sellMinCountInput.Parent = sellCountFilterCard
addCorner(sellMinCountInput, 8)
addStroke(sellMinCountInput, Theme.Border, 1, 0.3)

 sellKeepInput = Instance.new("TextBox")
sellKeepInput.Size = UDim2.new(0.31, -10, 0, 30)
sellKeepInput.Position = UDim2.new(0.69, 4, 0.5, -15)
sellKeepInput.BackgroundColor3 = Theme.Background
sellKeepInput.BorderSizePixel = 0
sellKeepInput.Text = tostring(SellState.MinWeight or 1)
sellKeepInput.PlaceholderText = "Min Weight"
sellKeepInput.ClearTextOnFocus = false
sellKeepInput.TextColor3 = Theme.Text
sellKeepInput.TextSize = 12
sellKeepInput.Font = Enum.Font.Gotham
sellKeepInput.Parent = sellCountFilterCard
addCorner(sellKeepInput, 8)
addStroke(sellKeepInput, Theme.Border, 1, 0.3)

 sellIntervalCard = Instance.new("Frame")
sellIntervalCard.Size = UDim2.new(1, 0, 0, 44)
sellIntervalCard.BackgroundColor3 = Theme.Surface
sellIntervalCard.BorderSizePixel = 0
sellIntervalCard.Parent = sellPage
addCorner(sellIntervalCard, 10)
addStroke(sellIntervalCard, Theme.Border, 1, 0.2)

 sellIntervalLabel = Instance.new("TextLabel")
sellIntervalLabel.Size = UDim2.new(0.45, -10, 1, 0)
sellIntervalLabel.Position = UDim2.new(0, 8, 0, 0)
sellIntervalLabel.Text = "Auto Interval (s)"
styleTextLabel(sellIntervalLabel, 12, Theme.Text, true)
sellIntervalLabel.Parent = sellIntervalCard

 sellIntervalInput = Instance.new("TextBox")
sellIntervalInput.Size = UDim2.new(0.55, -12, 0, 30)
sellIntervalInput.Position = UDim2.new(0.45, 4, 0.5, -15)
sellIntervalInput.BackgroundColor3 = Theme.Background
sellIntervalInput.BorderSizePixel = 0
sellIntervalInput.Text = tostring(SellState.IntervalSeconds)
sellIntervalInput.PlaceholderText = "contoh: 4"
sellIntervalInput.ClearTextOnFocus = false
sellIntervalInput.TextColor3 = Theme.Text
sellIntervalInput.TextSize = 12
sellIntervalInput.Font = Enum.Font.Gotham
sellIntervalInput.Parent = sellIntervalCard
addCorner(sellIntervalInput, 8)
addStroke(sellIntervalInput, Theme.Border, 1, 0.3)

 sellScanAttrButton = Instance.new("TextButton")
sellScanAttrButton.Size = UDim2.new(1, 0, 0, 38)
sellScanAttrButton.Text = "SCAN ATTR INVENTORY (OPSIONAL)"
setButtonStyle(sellScanAttrButton, Theme.Surface)
sellScanAttrButton.Parent = sellPage
attachHover(sellScanAttrButton, Theme.Surface, Theme.SurfaceHover)

 sellManualAllButton = Instance.new("TextButton")
sellManualAllButton.Size = UDim2.new(1, 0, 0, 40)
sellManualAllButton.Text = "SELL ALL (OPSI 1)"
setButtonStyle(sellManualAllButton, Theme.Warning)
sellManualAllButton.TextColor3 = Color3.fromRGB(25, 25, 25)
sellManualAllButton.Parent = sellPage

 sellManualFilteredButton = Instance.new("TextButton")
sellManualFilteredButton.Size = UDim2.new(1, 0, 0, 40)
sellManualFilteredButton.Text = "SELL BY FILTER (OPSI 2)"
setButtonStyle(sellManualFilteredButton, Theme.Primary)
sellManualFilteredButton.Parent = sellPage
attachHover(sellManualFilteredButton, Theme.Primary, Theme.PrimaryActive)

 sellAutoToggleButton = Instance.new("TextButton")
sellAutoToggleButton.Size = UDim2.new(1, 0, 0, 44)
sellAutoToggleButton.Text = "START AUTO SELL"
setButtonStyle(sellAutoToggleButton, Theme.Success)
sellAutoToggleButton.TextColor3 = Color3.fromRGB(20, 26, 20)
sellAutoToggleButton.Parent = sellPage

 sellSummaryCard = Instance.new("Frame")
sellSummaryCard.Size = UDim2.new(1, 0, 0, 124)
sellSummaryCard.BackgroundColor3 = Theme.Surface
sellSummaryCard.BorderSizePixel = 0
sellSummaryCard.Parent = sellPage
addCorner(sellSummaryCard, 10)
addStroke(sellSummaryCard, Theme.Border, 1, 0.2)

 sellSummaryLabel = Instance.new("TextLabel")
sellSummaryLabel.Size = UDim2.new(1, -14, 1, -10)
sellSummaryLabel.Position = UDim2.new(0, 8, 0, 5)
sellSummaryLabel.Text = "Sell siap."
sellSummaryLabel.TextWrapped = true
sellSummaryLabel.TextYAlignment = Enum.TextYAlignment.Top
styleTextLabel(sellSummaryLabel, 11, Theme.MutedText, false)
sellSummaryLabel.Parent = sellSummaryCard

local updateFarmView

function applyFarmRadiusFromInput(shouldPersist)
    local parsed = tonumber(farmRadiusInput.Text)
    if parsed then
        FarmState.Radius = math.clamp(parsed, 20, 500)
    end
    farmRadiusInput.Text = tostring(math.floor(FarmState.Radius))
    if shouldPersist then
        requestConfigSave()
    end
end

function applyFarmTreeFilterFromInput(shouldPersist)
    local rawFilter = farmTreeFilterInput and farmTreeFilterInput.Text or FarmState.TreeFilter
    rawFilter = normalizeFarmTreeFilterInput(rawFilter)
    FarmState.TreeFilter = rawFilter
    if farmTreeFilterInput and farmTreeFilterInput.Text ~= rawFilter then
        farmTreeFilterInput.Text = rawFilter
    end
    if shouldPersist then
        requestConfigSave()
    end
end

function applySellInputs(shouldPersist)
    SellState.NameFilter = string.gsub(sellNameFilterInput.Text or "", "^%s*(.-)%s*$", "%1")

    local countAttr = string.gsub(sellCountAttrInput.Text or "", "^%s*(.-)%s*$", "%1")
    if countAttr == "" then
        SellState.CountAttr = "CurrencyPerSecond"
    else
        SellState.CountAttr = countAttr
    end
    sellCountAttrInput.Text = SellState.CountAttr

    local parsedMinCount = tonumber(sellMinCountInput.Text)
    if parsedMinCount then
        SellState.MinCount = math.max(0, math.floor(parsedMinCount))
    end
    sellMinCountInput.Text = tostring(SellState.MinCount)

    local parsedMinWeight = tonumber(sellKeepInput.Text)
    if parsedMinWeight then
        SellState.MinWeight = math.max(0, math.floor(parsedMinWeight))
    end
    sellKeepInput.Text = tostring(SellState.MinWeight or 1)

    local parsedInterval = tonumber(sellIntervalInput.Text)
    if parsedInterval then
        SellState.IntervalSeconds = math.clamp(parsedInterval, 1, 60)
    end
    sellIntervalInput.Text = tostring(math.floor(SellState.IntervalSeconds))
    if shouldPersist then
        requestConfigSave()
    end
end

function buildSellCandidates(useFilter)
    local tools = collectInventoryTools()
    if #tools == 0 then
        return {}, 0, 0
    end

    local guiCards = getInventoryGuiCards(false)
    local guiMetricMap = buildInventoryGuiMetricMap(guiCards)

    local currencyCache = {}
    local weightCache = {}
    local function getCurrency(tool)
        if currencyCache[tool] == nil then
            local currency = getToolCurrencyPerSecond(tool)
            if not currency then
                local metricEntry = getGuiMetricForToolName(tool.Name or "", guiMetricMap)
                if metricEntry then
                    currency = metricEntry.CurrencyPerSecond
                end
            end
            currencyCache[tool] = currency
        end
        return currencyCache[tool]
    end
    local function getWeight(tool)
        if weightCache[tool] == nil then
            local weight = getToolWeightValue(tool)
            if not weight then
                local metricEntry = getGuiMetricForToolName(tool.Name or "", guiMetricMap)
                if metricEntry then
                    weight = metricEntry.Weight
                end
            end
            weightCache[tool] = weight
        end
        return weightCache[tool]
    end

    table.sort(tools, function(a, b)
        local aCurrency = getCurrency(a) or 0
        local bCurrency = getCurrency(b) or 0
        if aCurrency ~= bCurrency then
            return aCurrency > bCurrency
        end

        local aWeight = getWeight(a) or 0
        local bWeight = getWeight(b) or 0
        if aWeight ~= bWeight then
            return aWeight > bWeight
        end

        return a.Name < b.Name
    end)

    if not useFilter then
        return tools, #tools, 0
    end

    local filtered = {}
    local skipped = 0
    local nameFilterLower = string.lower(SellState.NameFilter or "")

    for _, tool in ipairs(tools) do
        local include = true
        if nameFilterLower ~= "" and not string.find(string.lower(tool.Name), nameFilterLower, 1, true) then
            include = false
        end

        local currencyValue = getCurrency(tool)
        local weightValue = getWeight(tool)

        if include and (not currencyValue or not weightValue) then
            include = false
        end

        if include and currencyValue < SellState.MinCount then
            include = false
        end

        if include and weightValue < (SellState.MinWeight or 1) then
            include = false
        end

        if include then
            filtered[#filtered + 1] = tool
        else
            skipped = skipped + 1
        end
    end

    return filtered, #tools, skipped
end

function isSellPassRunning()
    return (SellState.PassDepth or 0) > 0
end

function beginSellPass()
    SellState.PassDepth = (SellState.PassDepth or 0) + 1
end

function endSellPass()
    SellState.PassDepth = math.max(0, (SellState.PassDepth or 1) - 1)
end

function runSellPass(useFilter)
    beginSellPass()
    local ok, err = pcall(function()
        applySellInputs(false)
        local candidates, totalTools, skippedTools = buildSellCandidates(useFilter)
        local remotes = getSellRemoteCandidates(false)
        if #remotes == 0 then
            remotes = getSellRemoteCandidates(true)
        end
        local guiCards = getInventoryGuiCards(false)
        local dialogReady = ensureSellDialogReady()

        local soldCalls = 0
        local failedCalls = 0
        local soldViaDialog = 0
        local soldViaRemote = 0

        if not useFilter then
            local soldAllRemote, soldAllRemoteCount = attemptSellAllViaRemote(remotes)
            soldCalls = soldAllRemoteCount or 0
            if soldCalls > 0 then
                soldViaRemote = soldCalls
            end

            if soldAllRemote then
                failedCalls = math.max(0, totalTools - soldCalls)
            else
                local soldAllDialog, soldAllDialogCount = attemptSellAllViaDialog()
                soldCalls = soldCalls + (soldAllDialogCount or 0)
                failedCalls = math.max(0, totalTools - soldCalls)
                if soldAllDialog then
                    soldViaDialog = soldAllDialogCount or 0
                end
            end

            dialogReady = dialogReady or SellState.LastDialogReady
            SellState.LastSellAttemptAt = os.clock()
            SellState.LastSummary = string.format(
                "Sell All (Opsi 1) | Total %d | Sold %d | Fail %d | Remote %d | Dialog %d | DialogReady=%s | Remotes=%d",
                totalTools,
                soldCalls,
                failedCalls,
                soldViaRemote,
                soldViaDialog,
                dialogReady and "YES" or "NO",
                #remotes
            )
            return
        end

        for _, tool in ipairs(candidates) do
            holdInventoryGuiCardForTool(tool, guiCards)
            equipToolForSell(tool)

            local sold = attemptSellToolViaOptionTwo(tool)
            if sold then
                soldViaDialog = soldViaDialog + 1
            else
                sold = attemptSellTool(tool, remotes)
                if sold then
                    soldViaRemote = soldViaRemote + 1
                end
            end

            if sold then
                soldCalls = soldCalls + 1
            else
                failedCalls = failedCalls + 1
            end
            local perItemDelay = FarmState.Active and (Settings.SellPerItemDelayWhenFarmActive or 0.11) or 0.06
            task.wait(perItemDelay)
        end

        dialogReady = dialogReady or SellState.LastDialogReady
        SellState.LastSellAttemptAt = os.clock()
        SellState.LastSummary = string.format(
            "Sell Filter (Opsi 2) | Total %d | Candidate %d | Skip %d | Sold %d | Fail %d | Remote %d | Dialog %d | DialogReady=%s | Remotes=%d | Min CPS %d | Min Weight %d | Attr %s",
            totalTools,
            #candidates,
            skippedTools,
            soldCalls,
            failedCalls,
            soldViaRemote,
            soldViaDialog,
            dialogReady and "YES" or "NO",
            #remotes,
            SellState.MinCount,
            SellState.MinWeight or 1,
            SellState.CountAttr
        )
    end)
    endSellPass()
    if not ok then
        SellState.LastSellAttemptAt = os.clock()
        SellState.LastSummary = "Sell pass error: " .. tostring(err)
        warn("[Timber Script by Vaan] Sell pass error: " .. tostring(err))
    end
end

function runSellAttributeScan()
    applySellInputs(true)
    SellState.LastAttrPreview = scanInventoryAttributePreview()
end

function setSellEnabled(enabled)
    if SellState.Active == enabled then
        return
    end

    SellState.Active = enabled
    if not enabled then
        SellState.PassDepth = 0
        updateFarmView(true)
        return
    end

    if SellState.Running then
        return
    end

    SellState.Running = true
    updateFarmView(true)

    task.spawn(function()
        while SellState.Active do
            runSellPass(true)
            updateFarmView()

            local waitDuration = math.max(1, tonumber(SellState.IntervalSeconds) or 4)
            if FarmState.Active then
                waitDuration = math.max(waitDuration, Settings.SellMinIntervalWhenFarmActive or 6)
            end
            local startedAt = os.clock()
            while SellState.Active and os.clock() - startedAt < waitDuration do
                task.wait(0.2)
            end
        end

        SellState.Running = false
        SellState.PassDepth = 0
        updateFarmView(true)
    end)
end

function buildTreeLockText(target)
    if not target then
        if FarmState.LastConflictText ~= "" and (os.clock() - (FarmState.LastConflictAt or 0) <= 10) then
            return "LOCK: belum ada target.\n" .. FarmState.LastConflictText, Theme.Warning
        end
        return "LOCK: belum ada target.", Theme.MutedText
    end

    local instance = target.instance
    if not instance or not instance.Parent then
        return "LOCK: target hilang, scan target baru...", Theme.Warning
    end

    local attrs = instance:GetAttributes()
    local displayName = target.displayName or attrs.TreeName or target.name or instance.Name
    local seed = attrs.Seed or "-"
    local imposterId = attrs.ImposterId or "-"
    local hpValue = target.hp or readHealthValue(instance) or attrs.BreakPoint or attrs.Breakpoint or "-"
    local typeIndex = attrs.TreeTypeIndex or "-"
    local rarity = target.rarity or attrs.Rarity or "Unknown"
    local mutation = target.mutation or attrs.Mutation or attrs.Mutations or "-"
    local positionText = target.position and formatPosition(target.position) or "-"

    local text = string.format(
        "Mode: Hard Lock\nLOCK: %s\nTreeName: %s | Rarity: %s | Mutation: %s\nSeed: %s | ImposterId: %s\nHP: %s | Type: %s\nPos: %s",
        target.name or instance.Name,
        tostring(displayName),
        tostring(rarity),
        tostring(mutation),
        tostring(seed),
        tostring(imposterId),
        tostring(hpValue),
        tostring(typeIndex),
        tostring(positionText)
    )

    return text, Theme.Success
end

function requestFarmNextTarget()
    local target = FarmState.LockedTarget or FarmState.CurrentTarget
    if target then
        markFarmTargetCooldown(target)
    end

    FarmState.SkipRequested = true
    FarmState.LockedTarget = nil
    FarmState.CurrentTarget = nil
    updateFarmView()
end

updateFarmView = function(force)
    if not screenGui or screenGui.Parent == nil then
        return
    end

    local now = os.clock()
    if not force and (now - (farmViewLastRefreshAt or 0)) < (Settings.FarmUiRefreshInterval or 0.12) then
        return
    end
    farmViewLastRefreshAt = now

    if farmInfoFloatFrame then
        farmInfoFloatFrame.Visible = (not UIState.Minimized) and (UIState.CurrentTab == "Farm" or FarmState.Active)
    end

    if FarmState.Active then
        if isSellPassRunning() then
            farmStatusLabel.Text = "Farm Status: PAUSED (SELL)"
            farmStatusLabel.TextColor3 = Theme.Warning
        else
            farmStatusLabel.Text = "Farm Status: RUNNING"
            farmStatusLabel.TextColor3 = Theme.Success
        end
        farmToggleButton.Text = "STOP AUTO FARM"
        farmToggleButton.BackgroundColor3 = Theme.Danger
        farmToggleButton.TextColor3 = Theme.Text
    else
        farmStatusLabel.Text = "Farm Status: OFF"
        farmStatusLabel.TextColor3 = Theme.MutedText
        farmToggleButton.Text = "START AUTO FARM"
        farmToggleButton.BackgroundColor3 = Theme.Warning
        farmToggleButton.TextColor3 = Color3.fromRGB(25, 25, 25)
    end

    FarmState.PriorityMode = normalizeFarmPriorityMode(FarmState.PriorityMode)
    farmPriorityButton.Text = "Priority: " .. getFarmPriorityModeLabel(FarmState.PriorityMode)
    if FarmState.PriorityMode == "RARITY" then
        farmPriorityButton.BackgroundColor3 = Theme.Primary
        farmPriorityButton.TextColor3 = Theme.Text
    else
        farmPriorityButton.BackgroundColor3 = Theme.Surface
        farmPriorityButton.TextColor3 = Theme.Text
    end

    if FarmState.WeatherMutationEnabled then
        farmWeatherToggleButton.Text = "Weather Mutation Hunt: ON"
        farmWeatherToggleButton.BackgroundColor3 = Theme.Success
        farmWeatherToggleButton.TextColor3 = Color3.fromRGB(20, 26, 20)
    else
        farmWeatherToggleButton.Text = "Weather Mutation Hunt: OFF"
        farmWeatherToggleButton.BackgroundColor3 = Theme.Surface
        farmWeatherToggleButton.TextColor3 = Theme.Text
    end

    if FarmState.EspEnabled then
        farmEspToggleButton.Text = "Tree ESP: ON"
        farmEspToggleButton.BackgroundColor3 = Theme.Primary
        farmEspToggleButton.TextColor3 = Theme.Text
    else
        farmEspToggleButton.Text = "Tree ESP: OFF"
        farmEspToggleButton.BackgroundColor3 = Theme.Surface
        farmEspToggleButton.TextColor3 = Theme.Text
    end

    if FarmState.ForceTreeInfoEnabled then
        farmForceTreeInfoToggleButton.Text = "Force TreeInfo: ON"
        farmForceTreeInfoToggleButton.BackgroundColor3 = Theme.Success
        farmForceTreeInfoToggleButton.TextColor3 = Color3.fromRGB(20, 26, 20)
    else
        farmForceTreeInfoToggleButton.Text = "Force TreeInfo: OFF"
        farmForceTreeInfoToggleButton.BackgroundColor3 = Theme.Surface
        farmForceTreeInfoToggleButton.TextColor3 = Theme.Text
    end

    local target = FarmState.CurrentTarget or FarmState.ScanResults[1]
    if target then
        local hpText = target.maxHp and string.format("%.0f/%.0f", target.hp, target.maxHp) or string.format("%.0f", target.hp)
        local mutationText = target.mutation or "-"
        farmTargetLabel.Text = string.format(
            "Target: %s | HP %s | Rarity %s | Mutation %s | Pos %s",
            target.displayName or target.name,
            hpText,
            target.rarity,
            mutationText,
            formatPosition(target.position)
        )
        farmTargetLabel.TextColor3 = Theme.Text
    else
        farmTargetLabel.Text = string.format("Target: belum ada hasil scan | Filter: %s", getFarmTreeFilterLabel())
        farmTargetLabel.TextColor3 = Theme.MutedText
    end

    local activeCooldownCount = countActiveFarmCooldowns()
    local cooldownText = string.format(
        "Cooldown Skip: %d | Active Cooldown: %d",
        FarmState.LastCooldownSkipped or 0,
        activeCooldownCount
    )
    if FarmState.LastConflictText ~= "" and (os.clock() - (FarmState.LastConflictAt or 0) <= 8) then
        cooldownText = cooldownText .. " | " .. FarmState.LastConflictText
    end
    farmCooldownLabel.Text = cooldownText
    if activeCooldownCount > 0 then
        farmCooldownLabel.TextColor3 = Theme.Warning
    elseif FarmState.LastConflictText ~= "" and (os.clock() - (FarmState.LastConflictAt or 0) <= 8) then
        farmCooldownLabel.TextColor3 = Theme.Warning
    else
        farmCooldownLabel.TextColor3 = Theme.MutedText
    end

    local lockText, lockColor = buildTreeLockText(FarmState.LockedTarget or target)
    treeLockLabel.Text = lockText
    treeLockLabel.TextColor3 = lockColor

    if #FarmState.ScanResults == 0 then
        farmListLabel.Text = "Hasil deteksi akan tampil di sini."
        farmListLabel.TextColor3 = Theme.MutedText
    else
        local lines = {}
        local configuredLines = math.clamp(math.floor(tonumber(Settings.FarmUiListMaxLines) or 12), 3, 40)
        local maxLines = math.min(configuredLines, #FarmState.ScanResults)
        for i = 1, maxLines do
            local item = FarmState.ScanResults[i]
            local hpText = item.maxHp and string.format("%.0f/%.0f", item.hp, item.maxHp) or string.format("%.0f", item.hp)
            local mutationText = item.mutation or "-"
            lines[#lines + 1] = string.format(
                "%d) %s | HP %s | Rarity %s | Mutation %s | %s",
                i,
                item.displayName or item.name,
                hpText,
                item.rarity,
                mutationText,
                formatPosition(item.position)
            )
        end

        if #FarmState.ScanResults > maxLines then
            lines[#lines + 1] = string.format("... +%d target lainnya", #FarmState.ScanResults - maxLines)
        end

        farmListLabel.Text = table.concat(lines, "\n")
        farmListLabel.TextColor3 = Theme.Text
    end

    if HarvestState.Active then
        harvestStatusLabel.Text = "Harvest Status: RUNNING"
        harvestStatusLabel.TextColor3 = Theme.Success
        harvestToggleButton.Text = "STOP AUTO HARVEST"
        harvestToggleButton.BackgroundColor3 = Theme.Danger
        harvestToggleButton.TextColor3 = Theme.Text
    else
        harvestStatusLabel.Text = "Harvest Status: OFF"
        harvestStatusLabel.TextColor3 = Theme.MutedText
        harvestToggleButton.Text = "START AUTO HARVEST"
        harvestToggleButton.BackgroundColor3 = Theme.Primary
        harvestToggleButton.TextColor3 = Theme.Text
    end

    if HarvestState.CurrentTarget and HarvestState.CurrentTarget.part and HarvestState.CurrentTarget.part.Parent then
        harvestTargetLabel.Text = string.format(
            "Harvest Target: %s | Dist %.1f | %s",
            HarvestState.CurrentTarget.name,
            HarvestState.CurrentTarget.distance,
            formatPosition(HarvestState.CurrentTarget.part.Position)
        )
        harvestTargetLabel.TextColor3 = Theme.Text
    else
        harvestTargetLabel.Text = "Harvest Target: -"
        harvestTargetLabel.TextColor3 = Theme.MutedText
    end

    local processedText = string.format(
        "Processed: %d | Skipped (done): %d",
        HarvestState.HarvestedCount or 0,
        HarvestState.LastSkippedCount or 0
    )
    local processedColor = Theme.MutedText

    if HarvestState.WaitingCacheReset then
        local remaining = getHarvestResetTimeRemaining()
        local minutes = math.floor(remaining / 60)
        local seconds = remaining % 60
        processedText = string.format(
            "%s\nCache reset in %02d:%02d",
            processedText,
            minutes,
            seconds
        )
        processedColor = Theme.Warning
    end

    harvestProcessedLabel.Text = processedText
    harvestProcessedLabel.TextColor3 = processedColor

    if SellState.Active then
        sellStatusLabel.Text = "Sell Status: RUNNING"
        sellStatusLabel.TextColor3 = Theme.Success
        sellAutoToggleButton.Text = "STOP AUTO SELL"
        sellAutoToggleButton.BackgroundColor3 = Theme.Danger
        sellAutoToggleButton.TextColor3 = Theme.Text
    else
        sellStatusLabel.Text = "Sell Status: OFF"
        sellStatusLabel.TextColor3 = Theme.MutedText
        sellAutoToggleButton.Text = "START AUTO SELL"
        sellAutoToggleButton.BackgroundColor3 = Theme.Success
        sellAutoToggleButton.TextColor3 = Color3.fromRGB(20, 26, 20)
    end

    sellSummaryLabel.Text = string.format(
        "%s\n\nAttr Preview:\n%s",
        SellState.LastSummary or "Sell siap.",
        SellState.LastAttrPreview or "-"
    )
    if SellState.Active then
        sellSummaryLabel.TextColor3 = Theme.Text
    else
        sellSummaryLabel.TextColor3 = Theme.MutedText
    end
end

refreshFarmUiCallback = updateFarmView

function destroyFarmEspEntry(key)
    local entry = farmEspEntries[key]
    if not entry then
        return
    end

    farmEspEntries[key] = nil
    local gui = entry.gui
    if gui then
        pcall(function()
            gui:Destroy()
        end)
    end
end

function clearFarmEspEntries()
    for key in pairs(farmEspEntries) do
        destroyFarmEspEntry(key)
    end
end

function collectTreeInfoNodes(container)
    local nodes = {}
    local seen = {}
    local function pushNode(node)
        if node and not seen[node] then
            seen[node] = true
            nodes[#nodes + 1] = node
        end
    end

    if not container then
        return nodes
    end

    pushNode(container:FindFirstChild("TreeInfo", true))
    pushNode(container:FindFirstChild("TreeHealth", true))

    local origin = container:FindFirstChild("Origin", true)
    if origin then
        pushNode(origin:FindFirstChild("TreeInfo", true))
        pushNode(origin:FindFirstChild("TreeHealth", true))
    end

    return nodes
end

function setTreeInfoNodeVisible(node)
    if not node then
        return false
    end

    local touched = false
    local function applyVisibility(obj)
        if obj:IsA("BillboardGui") or obj:IsA("SurfaceGui") then
            pcall(function()
                obj.Enabled = true
            end)
            touched = true
        end
        if obj:IsA("GuiObject") then
            pcall(function()
                obj.Visible = true
            end)
            touched = true
        end
    end

    applyVisibility(node)
    local descendants = nil
    pcall(function()
        descendants = node:GetDescendants()
    end)
    if descendants then
        for _, desc in ipairs(descendants) do
            applyVisibility(desc)
        end
    end

    return touched
end

function forceTreeInfoForTarget(target)
    if not target then
        return false
    end

    local source = target.instance or target.part
    if not source then
        return false
    end

    local touchedAny = false
    local nodes = collectTreeInfoNodes(source)
    if #nodes == 0 and target.part and target.part.Parent then
        nodes = collectTreeInfoNodes(target.part)
    end

    for _, node in ipairs(nodes) do
        if setTreeInfoNodeVisible(node) then
            touchedAny = true
        end
    end

    return touchedAny
end

function applyForceTreeInfoToResults(results)
    if not FarmState.ForceTreeInfoEnabled then
        return
    end

    local list = results or {}
    local maxTargets = math.clamp(math.floor(tonumber(Settings.ForceTreeInfoMaxTargets) or 25), 3, 120)
    for i = 1, math.min(maxTargets, #list) do
        local target = list[i]
        if target and target.part and target.part.Parent then
            forceTreeInfoForTarget(target)
        end
    end
end

function getFarmEspEntryKey(target)
    if not target then
        return nil
    end

    local key = target.key
    if type(key) == "string" and key ~= "" then
        return key
    end

    local builtKey = buildFarmTargetKey(target.instance, target.part)
    if builtKey and builtKey ~= "" then
        return builtKey
    end

    local root = target.instance or target.part
    if root then
        local path = nil
        pcall(function()
            path = root:GetFullName()
        end)
        if path and path ~= "" then
            return path
        end
    end

    return nil
end

function buildFarmEspText(target)
    local displayName = cleanGuiText(target.displayName or target.name or "Tree")
    if displayName == "" then
        displayName = "Tree"
    end

    local idText = cleanGuiText(tostring(target.name or (target.instance and target.instance.Name) or ""))
    if idText == "" and target.instance and target.instance.Parent then
        local imposterId = target.instance:GetAttribute("ImposterId")
        if imposterId then
            local baseName = cleanGuiText(tostring(target.displayName or target.instance:GetAttribute("TreeName") or "tree"))
            baseName = normalizeFarmTreeText(baseName)
            if baseName == "" then
                baseName = "tree"
            end
            baseName = string.gsub(baseName, "%s+", "_")
            idText = string.format("%s_%s", baseName, tostring(imposterId))
        end
    end
    if idText == "" then
        idText = "-"
    elseif #idText > 36 then
        idText = string.sub(idText, 1, 33) .. "..."
    end

    local hpValue = tonumber(target.hp)
    local maxHpValue = tonumber(target.maxHp)
    if (not hpValue or hpValue <= 0) and target.instance and target.instance.Parent then
        hpValue = tonumber(readHealthValue(target.instance))
    end
    if (not maxHpValue or maxHpValue <= 0) and target.instance and target.instance.Parent then
        maxHpValue = tonumber(readMaxHealthValue(target.instance))
    end

    local hpText = "-"
    if hpValue and hpValue > 0 then
        if maxHpValue and maxHpValue > 0 then
            hpText = string.format("%.0f/%.0f", hpValue, maxHpValue)
        else
            hpText = string.format("%.0f", hpValue)
        end
    end

    local rarityText = cleanGuiText(tostring(target.rarity or "Unknown"))
    if rarityText == "" then
        rarityText = "Unknown"
    end

    return string.format("%s\nID %s\nHP %s | Rarity %s", displayName, idText, hpText, rarityText)
end

function upsertFarmEspEntry(key, target)
    if not key or key == "" or not target or not target.part or not target.part.Parent then
        return
    end
    if not screenGui or screenGui.Parent == nil then
        return
    end

    local entry = farmEspEntries[key]
    if entry and (not entry.gui or entry.gui.Parent == nil) then
        entry = nil
        farmEspEntries[key] = nil
    end

    if not entry then
        local gui = Instance.new("BillboardGui")
        gui.Name = "TreeEspInfo"
        gui.Size = UDim2.new(0, 240, 0, 74)
        gui.StudsOffset = Vector3.new(0, 4.2, 0)
        gui.AlwaysOnTop = true
        gui.Parent = screenGui

        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, 0, 1, 0)
        frame.BackgroundColor3 = Theme.Header
        frame.BackgroundTransparency = 0.22
        frame.BorderSizePixel = 0
        frame.Parent = gui
        addCorner(frame, 8)
        addStroke(frame, Theme.Border, 1, 0.25)

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -8, 1, -6)
        label.Position = UDim2.new(0, 4, 0, 3)
        label.TextWrapped = true
        label.TextYAlignment = Enum.TextYAlignment.Top
        styleTextLabel(label, 11, Theme.Text, true)
        label.Parent = frame

        entry = {
            gui = gui,
            label = label,
            instance = target.instance
        }
        farmEspEntries[key] = entry
    end

    local maxDistance = tonumber(Settings.FarmEspMaxDistance) or 420
    local radiusDistance = (tonumber(FarmState.Radius) or 120) + 90
    maxDistance = math.max(120, maxDistance, radiusDistance)

    entry.instance = target.instance
    entry.gui.MaxDistance = maxDistance
    entry.gui.Adornee = target.part
    entry.label.Text = buildFarmEspText(target)
    entry.label.TextColor3 = (target.mutation and target.mutation ~= "" and target.mutation ~= "-") and Theme.Success or Theme.Text
end

function updateFarmEspTargets(results)
    if not FarmState.EspEnabled then
        clearFarmEspEntries()
        return
    end

    if not results then
        results = {}
    end

    local visibleKeys = {}
    local maxEntries = math.clamp(math.floor(tonumber(Settings.FarmEspMaxEntries) or 30), 5, 120)
    for i = 1, math.min(maxEntries, #results) do
        local target = results[i]
        if target and target.part and target.part.Parent then
            local key = getFarmEspEntryKey(target)
            if key then
                visibleKeys[key] = true
                upsertFarmEspEntry(key, target)
            end
        end
    end

    for key in pairs(farmEspEntries) do
        if not visibleKeys[key] then
            destroyFarmEspEntry(key)
        end
    end
end

function setFarmEspEnabled(enabled)
    FarmState.EspEnabled = enabled and true or false
    if not FarmState.EspEnabled then
        clearFarmEspEntries()
        if refreshFarmUiCallback then
            refreshFarmUiCallback(true)
        end
        return
    end

    if farmEspRunning then
        if refreshFarmUiCallback then
            refreshFarmUiCallback(true)
        end
        return
    end

    farmEspRunning = true
    task.spawn(function()
        while FarmState.EspEnabled do
            if not screenGui or screenGui.Parent == nil then
                break
            end

            applyFarmRadiusFromInput(false)
            applyFarmTreeFilterFromInput(false)

            local scanResults = nil
            if FarmState.Active and type(FarmState.ScanResults) == "table" and #FarmState.ScanResults > 0 then
                scanResults = FarmState.ScanResults
            else
                scanResults = scanFarmObjects(FarmState.Radius)
                if not FarmState.Active then
                    FarmState.ScanResults = scanResults
                    FarmState.CurrentTarget = scanResults[1]
                end
            end

            updateFarmEspTargets(scanResults)
            if not FarmState.Active and refreshFarmUiCallback then
                refreshFarmUiCallback()
            end

            local waitSeconds = tonumber(Settings.FarmEspRefreshInterval) or 0.65
            waitSeconds = math.clamp(waitSeconds, 0.2, 3)
            local startedAt = os.clock()
            while FarmState.EspEnabled and (os.clock() - startedAt) < waitSeconds do
                task.wait(0.05)
            end
        end

        clearFarmEspEntries()
        farmEspRunning = false
        if not screenGui or screenGui.Parent == nil then
            FarmState.EspEnabled = false
        end
        if refreshFarmUiCallback then
            refreshFarmUiCallback(true)
        end
    end)

    if refreshFarmUiCallback then
        refreshFarmUiCallback(true)
    end
end

function setForceTreeInfoEnabled(enabled)
    FarmState.ForceTreeInfoEnabled = enabled and true or false

    if not FarmState.ForceTreeInfoEnabled then
        if refreshFarmUiCallback then
            refreshFarmUiCallback(true)
        end
        return
    end

    if forceTreeInfoRunning then
        if refreshFarmUiCallback then
            refreshFarmUiCallback(true)
        end
        return
    end

    forceTreeInfoRunning = true
    task.spawn(function()
        while FarmState.ForceTreeInfoEnabled do
            if not screenGui or screenGui.Parent == nil then
                break
            end

            applyFarmRadiusFromInput(false)
            applyFarmTreeFilterFromInput(false)

            local scanResults = nil
            if FarmState.Active and type(FarmState.ScanResults) == "table" and #FarmState.ScanResults > 0 then
                scanResults = FarmState.ScanResults
            else
                scanResults = scanFarmObjects(FarmState.Radius)
                if not FarmState.Active then
                    FarmState.ScanResults = scanResults
                    FarmState.CurrentTarget = scanResults[1]
                end
            end

            applyForceTreeInfoToResults(scanResults)

            local waitSeconds = tonumber(Settings.ForceTreeInfoRefreshInterval) or 0.6
            waitSeconds = math.clamp(waitSeconds, 0.2, 3)
            local startedAt = os.clock()
            while FarmState.ForceTreeInfoEnabled and (os.clock() - startedAt) < waitSeconds do
                task.wait(0.05)
            end
        end

        forceTreeInfoRunning = false
        if not screenGui or screenGui.Parent == nil then
            FarmState.ForceTreeInfoEnabled = false
        end
        if refreshFarmUiCallback then
            refreshFarmUiCallback(true)
        end
    end)

    if refreshFarmUiCallback then
        refreshFarmUiCallback(true)
    end
end

function runFarmScan()
    applyFarmRadiusFromInput(false)
    applyFarmTreeFilterFromInput(false)
    local radius = FarmState.Radius
    local scanResults, skippedCooldown = scanFarmObjects(radius)
    local totalSkippedCooldown = skippedCooldown or 0
    local now = os.clock()
    local shouldWideScan = #scanResults == 0
        and radius < 500
        and (not FarmState.LastWideScanAt or (now - FarmState.LastWideScanAt) > 1.4)
    if shouldWideScan then
        FarmState.LastWideScanAt = now
        local mediumRadius = math.min(500, math.floor(radius * 1.6))
        scanResults, skippedCooldown = scanFarmObjects(mediumRadius)
        totalSkippedCooldown = totalSkippedCooldown + (skippedCooldown or 0)

        if #scanResults == 0 and mediumRadius < 500 then
            scanResults, skippedCooldown = scanFarmObjects(500)
            totalSkippedCooldown = totalSkippedCooldown + (skippedCooldown or 0)
        end
    end

    FarmState.ScanResults = scanResults
    FarmState.LastCooldownSkipped = totalSkippedCooldown
    FarmState.CurrentTarget = FarmState.ScanResults[1]
    applyForceTreeInfoToResults(FarmState.ScanResults)
    if FarmState.EspEnabled then
        updateFarmEspTargets(FarmState.ScanResults)
    end
    updateFarmView()
    return FarmState.CurrentTarget
end

function runHarvestScan()
    applyFarmRadiusFromInput(false)
    local scanResults, skippedCount = scanHarvestObjects(FarmState.Radius)
    HarvestState.ScanResults = scanResults
    HarvestState.LastSkippedCount = skippedCount or 0

    if #HarvestState.ScanResults == 0 and HarvestState.LastSkippedCount > 0 then
        if not HarvestState.WaitingCacheReset then
            HarvestState.WaitingCacheReset = true
            HarvestState.NextCacheResetAt = os.clock() + Settings.HarvestCacheResetSeconds
        elseif os.clock() >= HarvestState.NextCacheResetAt then
            clearHarvestCache()
            local rescannedResults, rescannedSkipped = scanHarvestObjects(FarmState.Radius)
            HarvestState.ScanResults = rescannedResults
            HarvestState.LastSkippedCount = rescannedSkipped or 0
        end
    else
        HarvestState.WaitingCacheReset = false
        HarvestState.NextCacheResetAt = 0
    end

    HarvestState.CurrentTarget = HarvestState.ScanResults[1]
    updateFarmView()
    return HarvestState.CurrentTarget
end

function runHarvestReturnToPlot()
    local plotPart = getPlayerPlotPart(false)
    if not plotPart then
        plotPart = getPlayerPlotPart(true)
    end

    if plotPart and isCharacterNearPart(plotPart, Settings.HarvestPlotArrivalDistance) then
        return true, false
    end

    if teleportToPlayerPlot() then
        return true, true
    end

    local zone = zones[FarmState.ZoneIndex]
    if zone then
        teleportToZone(zone)
        task.wait(0.35)
    end

    return false, false
end

function waitHarvestPostTeleportDelay()
    local delaySeconds = tonumber(Settings.HarvestPostTeleportDelaySeconds) or 0
    delaySeconds = math.clamp(delaySeconds, 0, 20)
    if delaySeconds <= 0 then
        return
    end

    local startedAt = os.clock()
    while HarvestState.Active and (os.clock() - startedAt) < delaySeconds do
        task.wait(0.1)
    end
end

function pauseFarmForSellIfNeeded()
    if not FarmState.Active or not isSellPassRunning() then
        return false
    end

    local now = os.clock()
    local reasonText = "Pause chop: auto sell sedang proses"
    if FarmState.LastConflictText ~= reasonText or (now - (FarmState.LastConflictAt or 0) > 0.4) then
        FarmState.LastConflictText = reasonText
        FarmState.LastConflictAt = now
        updateFarmView()
    end

    resetFarmPacketTimer()
    task.wait(0.1)
    return true
end

function setHarvestEnabled(enabled)
    if HarvestState.Active == enabled then
        return
    end

    HarvestState.Active = enabled
    if not enabled then
        HarvestState.CurrentTarget = nil
        HarvestState.ScanResults = {}
        HarvestState.LastSkippedCount = 0
        updateFarmView(true)
        return
    end

    if HarvestState.Running then
        return
    end

    HarvestState.Running = true
    updateFarmView(true)

    if not HarvestState.WaitingCacheReset then
        local arrivedAtPlot, didTeleport = runHarvestReturnToPlot()
        if arrivedAtPlot and didTeleport then
            waitHarvestPostTeleportDelay()
        end
    end

    task.spawn(function()
        while HarvestState.Active do
            unequipAllTools()
            if not HarvestState.WaitingCacheReset then
                local arrivedAtPlot, didTeleport = runHarvestReturnToPlot()
                if not arrivedAtPlot then
                    task.wait(0.35)
                    continue
                end
                if didTeleport then
                    waitHarvestPostTeleportDelay()
                end
            else
                task.wait(0.15)
            end

            local target = runHarvestScan()
            if not target or not target.part or not target.part.Parent then
                if HarvestState.WaitingCacheReset then
                    task.wait(1)
                else
                    task.wait(0.75)
                end
            else
                HarvestState.CurrentTarget = target
                teleportToPart(target.part)
                task.wait(0.12)

                local interacted = false
                if target.prompt and target.prompt.Parent then
                    interacted = sendInteractAction(target.prompt)
                end

                if interacted then
                    markHarvestTargetProcessed(target)
                end

                task.wait(0.25)
            end
        end

        HarvestState.Running = false
        HarvestState.CurrentTarget = nil
        HarvestState.ScanResults = {}
        HarvestState.LastSkippedCount = 0
        updateFarmView(true)
    end)
end

function setFarmEnabled(enabled)
    if FarmState.Active == enabled then
        return
    end

    FarmState.Active = enabled
    if not enabled then
        FarmState.CurrentTarget = nil
        FarmState.LockedTarget = nil
        FarmState.LastCooldownSkipped = 0
        FarmState.SkipRequested = false
        FarmState.LastConflictText = ""
        FarmState.LastConflictAt = 0
        FarmState.LastBusyToastScanAt = 0
        FarmState.LastBusyToastText = nil
        FarmState.LastWideScanAt = 0
        FarmState.LastWeatherMutationMessageKey = nil
        FarmState.LastWeatherMutationMessageAt = 0
        FarmState.LastWeatherMutationHandledKey = nil
        FarmState.WeatherMutationTarget = nil
        clearFarmPacketWatch()
        unequipAllTools()
        updateFarmView(true)
        return
    end

    if FarmState.Running then
        return
    end

    FarmState.Running = true
    FarmState.LockedTarget = nil
    FarmState.SkipRequested = false
    FarmState.LastConflictText = ""
    FarmState.LastConflictAt = 0
    FarmState.LastBusyToastScanAt = 0
    FarmState.LastBusyToastText = nil
    FarmState.LastWideScanAt = 0
    FarmState.LastWeatherMutationScanAt = 0
    FarmState.LastWeatherMutationMessageKey = nil
    FarmState.LastWeatherMutationMessageAt = 0
    FarmState.LastWeatherMutationHandledKey = nil
    FarmState.WeatherMutationTarget = nil
    startFarmPacketWatch()
    resetFarmPacketTimer()
    equipToolSlotOne()
    updateFarmView(true)

    task.spawn(function()
        local missedScans = 0
        local nextZoneTeleportAt = 0
        local didInitialZoneTeleport = false

        while FarmState.Active do
            if pauseFarmForSellIfNeeded() then
                continue
            end

            if not equipToolSlotOne() then
                task.wait(0.2)
                continue
            end
            if FarmState.SkipRequested and not FarmState.LockedTarget then
                FarmState.SkipRequested = false
            end

            if processWeatherMutationEvent() then
                didInitialZoneTeleport = true
                nextZoneTeleportAt = os.clock() + 4.5
                missedScans = 0
                task.wait(0.25)
                continue
            end

            if not didInitialZoneTeleport then
                local zone = zones[FarmState.ZoneIndex]
                if zone then
                    teleportToZone(zone)
                    task.wait(0.35)
                end
                didInitialZoneTeleport = true
                nextZoneTeleportAt = os.clock() + 4.5
            end

            local target = FarmState.LockedTarget
            if not isTargetStillPresent(target) then
                target = nil
            end

            if not target then
                target = runFarmScan()
                FarmState.LockedTarget = target
            else
                FarmState.CurrentTarget = target
                updateFarmView()
            end

            if not target or not target.part or not target.part.Parent then
                FarmState.LockedTarget = nil
                missedScans = missedScans + 1

                if missedScans >= 3 and os.clock() >= nextZoneTeleportAt then
                    local zone = zones[FarmState.ZoneIndex]
                    if zone then
                        teleportToZone(zone)
                        task.wait(0.35)
                    end
                    nextZoneTeleportAt = os.clock() + 4.5
                    missedScans = 0
                else
                    task.wait(0.45)
                end
            else
                missedScans = 0
                FarmState.CurrentTarget = target
                FarmState.LockedTarget = target
                teleportToPart(target.part)
                task.wait(0.2)
                resetFarmPacketTimer()

                local missingTicks = 0
                local blockedCooldownSeconds = nil
                local nearbyPlayerTicks = 0
                local hasStartedChop = false
                local hasTriggeredCameraLock = false
                local pendingPacketGate = true
                local packetGateStartedAt = 0

                while FarmState.Active do
                    if FarmState.SkipRequested then
                        FarmState.SkipRequested = false
                        break
                    end

                    if processWeatherMutationEvent() then
                        break
                    end

                    if pauseFarmForSellIfNeeded() then
                        missingTicks = 0
                        if not hasStartedChop then
                            nearbyPlayerTicks = 0
                        end
                        continue
                    end

                    if isTargetStillPresent(target) then
                        missingTicks = 0
                    else
                        missingTicks = missingTicks + 1
                        if missingTicks >= 5 then
                            break
                        end
                        task.wait(0.12)
                        continue
                    end

                    if target.instance and target.instance.Parent then
                        local refreshedPart = getTargetPart(target.instance)
                        if refreshedPart then
                            target.part = refreshedPart
                        end
                    end

                    local currentHp = getCurrentTargetHp(target)
                    if currentHp and currentHp > 0 then
                        target.hp = currentHp
                    else
                        target.hp = target.hp or 1
                    end

                    if target.maxHp == nil and not target.maxHpChecked then
                        target.maxHp = readMaxHealthValue(target.instance) or (target.part and readMaxHealthValue(target.part) or nil)
                        target.maxHpChecked = true
                    end
                    target.position = target.part and target.part.Position or target.position
                    FarmState.CurrentTarget = target
                    FarmState.LockedTarget = target
                    updateFarmView()

                    if not hasStartedChop then
                        local shouldSkipActionPrompt, actionPromptReason = shouldSkipFarmTargetByActionPrompt(target.instance, target.part)
                        if shouldSkipActionPrompt then
                            blockedCooldownSeconds = Settings.FarmActionPromptSkipCooldownSeconds or 45
                            FarmState.LastConflictText = string.format(
                                "Skip action E/tap: %s",
                                tostring(actionPromptReason or "Prompt")
                            )
                            FarmState.LastConflictAt = os.clock()
                            break
                        end
                    end

                    if not equipToolSlotOne() then
                        task.wait(0.1)
                        continue
                    end

                    if not hasStartedChop then
                        local nearbyOtherPlayer, nearbyPlayerName, nearbyDistance = detectOtherPlayerNearTargetPart(
                            target.part,
                            Settings.FarmPlayerNearbySkipRadius
                        )
                        if nearbyOtherPlayer then
                            nearbyPlayerTicks = nearbyPlayerTicks + 1
                        else
                            nearbyPlayerTicks = 0
                        end
                        if nearbyPlayerTicks >= 2 then
                            blockedCooldownSeconds = Settings.FarmPlayerNearbyCooldownSeconds or 30
                            FarmState.LastConflictText = string.format(
                                "Skip player dekat: %s (%.1fm)",
                                tostring(nearbyPlayerName or "player lain"),
                                tonumber(nearbyDistance) or 0
                            )
                            FarmState.LastConflictAt = os.clock()
                            break
                        end
                    end

                    if not hasTriggeredCameraLock then
                        faceTargetForChop(target.part)
                        hasTriggeredCameraLock = true
                    end
                    performTapCycle()
                    hasStartedChop = true

                    if pendingPacketGate then
                        if packetGateStartedAt <= 0 then
                            packetGateStartedAt = os.clock()
                        end
                        if hasFarmPacketSinceReset() then
                            pendingPacketGate = false
                        elseif os.clock() - packetGateStartedAt >= Settings.FarmNoPacketSkipSeconds then
                            FarmState.LastConflictText = "Skip no incoming packet (awal chop)"
                            FarmState.LastConflictAt = os.clock()
                            break
                        end
                    end

                    local robuxPopupDetected, robuxPopupText = detectRobuxPopupAndHandle()
                    if robuxPopupDetected then
                        blockedCooldownSeconds = Settings.FarmRobuxPopupCooldownSeconds or 45
                        FarmState.LastConflictText = "Skip popup Robux terdeteksi"
                        FarmState.LastConflictAt = os.clock()
                        if robuxPopupText and robuxPopupText ~= "" then
                            pushDebugLog("Farm popup skip: " .. robuxPopupText)
                        end
                        break
                    end

                    local busyByOther, busyWaitSeconds, busyToastText, busyActor = detectFarmBusyByOtherPlayer()
                    if busyByOther then
                        blockedCooldownSeconds = busyWaitSeconds or 32
                        local actorText = (busyActor and busyActor ~= "") and busyActor or "player lain"
                        local waitText = busyWaitSeconds and string.format("%.1fs", busyWaitSeconds) or "?"
                        FarmState.LastConflictText = string.format("Skip bentrok: %s (%s)", actorText, waitText)
                        FarmState.LastConflictAt = os.clock()
                        if busyToastText and busyToastText ~= "" then
                            pushDebugLog("Farm busy skip: " .. busyToastText)
                        end
                        break
                    end

                    if not isTargetStillPresent(target) then
                        missingTicks = missingTicks + 1
                        if missingTicks >= 5 then
                            break
                        end
                    else
                        missingTicks = 0
                    end

                end

                if blockedCooldownSeconds and blockedCooldownSeconds > 0 then
                    markFarmTargetCooldown(target, blockedCooldownSeconds)
                else
                    markFarmTargetCooldown(target)
                end
                FarmState.LockedTarget = nil
            end

            task.wait(0.1)
        end

        FarmState.Running = false
        FarmState.CurrentTarget = nil
        FarmState.LockedTarget = nil
        FarmState.LastCooldownSkipped = 0
        FarmState.LastConflictText = ""
        FarmState.LastConflictAt = 0
        clearFarmPacketWatch()
        unequipAllTools()
        updateFarmView()
    end)
end

function setTabStyle(button, active)
    if active then
        button.BackgroundColor3 = Theme.Primary
        button.TextColor3 = Theme.Text
    else
        button.BackgroundColor3 = Theme.Surface
        button.TextColor3 = Theme.MutedText
    end
end

function applyLayoutState()
    if UIState.Minimized then
        rootFrame.Size = collapsedSize
        tabContainer.Visible = false
        content.Visible = false
        minimizeButton.Text = "+"
        if farmInfoFloatFrame then
            farmInfoFloatFrame.Visible = false
        end
        return
    end

    rootFrame.Size = frameSize
    tabContainer.Visible = true
    content.Visible = true
    minimizeButton.Text = "-"

    local onMain = UIState.CurrentTab == "Main"
    local onTeleport = UIState.CurrentTab == "Teleport"
    local onFarm = UIState.CurrentTab == "Farm"
    local onHarvest = UIState.CurrentTab == "Harvest"
    local onSell = UIState.CurrentTab == "Sell"
    local onAbout = UIState.CurrentTab == "About"
    mainPage.Visible = onMain
    teleportPage.Visible = onTeleport
    farmPage.Visible = onFarm
    harvestPage.Visible = onHarvest
    sellPage.Visible = onSell
    aboutPage.Visible = onAbout
    teleportPage.ScrollingEnabled = onTeleport
    farmPage.ScrollingEnabled = onFarm
    harvestPage.ScrollingEnabled = onHarvest
    sellPage.ScrollingEnabled = onSell
    aboutPage.ScrollingEnabled = onAbout
    setTabStyle(mainTabButton, onMain)
    setTabStyle(tpTabButton, onTeleport)
    setTabStyle(farmTabButton, onFarm)
    setTabStyle(harvestTabButton, onHarvest)
    setTabStyle(sellTabButton, onSell)
    setTabStyle(aboutTabButton, onAbout)

    if farmInfoFloatFrame then
        farmInfoFloatFrame.Visible = onFarm or FarmState.Active
    end
end

function updateStatusView()
    if UIState.Active then
        statusDot.BackgroundColor3 = Theme.Success
        statusLabel.Text = "Auto Click: ON"
        toggleButton.Text = "STOP AUTO CLICK"
        toggleButton.BackgroundColor3 = Theme.Danger
        toggleButton.TextColor3 = Theme.Text
        if Settings.CameraLockOnFirstChopOnly then
            if Settings.AimNearestObject then
                cameraLabel.Text = "Camera Lock: FIRST CHOP + Nearest Aim"
            else
                cameraLabel.Text = "Camera Lock: FIRST CHOP ONLY"
            end
        elseif Settings.AimNearestObject then
            cameraLabel.Text = "Camera Lock: ON + Nearest Object Aim"
        else
            cameraLabel.Text = "Camera Lock: ON"
        end
        cameraLabel.TextColor3 = Theme.Success
    else
        statusDot.BackgroundColor3 = Theme.Danger
        statusLabel.Text = "Auto Click: OFF"
        toggleButton.Text = "START AUTO CLICK"
        toggleButton.BackgroundColor3 = Theme.Success
        toggleButton.TextColor3 = Color3.fromRGB(20, 26, 20)
        cameraLabel.Text = "Camera Lock: OFF"
        cameraLabel.TextColor3 = Theme.MutedText
    end
end

function setClickerEnabled(enabled)
    if UIState.Active == enabled then
        return
    end

    UIState.Active = enabled
    if enabled then
        if Settings.CameraLockOnFirstChopOnly then
            setCameraLock(false)
            UIState.PendingCameraLock = true
        else
            setCameraLock(true)
            UIState.PendingCameraLock = false
        end
    else
        setCameraLock(false)
        UIState.PendingCameraLock = false
    end
    if enabled then
        equipToolSlotOne()
    else
        unequipAllTools()
    end
    updateStatusView()

    if UIState.Active and not UIState.Running then
        UIState.Running = true
        task.spawn(autoClickLoop)
        print("Auto click enabled.")
    else
        print("Auto click disabled.")
    end
end

function switchTab(tabName)
    if tabName == "Teleport" then
        UIState.CurrentTab = "Teleport"
    elseif tabName == "Farm" then
        UIState.CurrentTab = "Farm"
    elseif tabName == "Harvest" then
        UIState.CurrentTab = "Harvest"
    elseif tabName == "Sell" then
        UIState.CurrentTab = "Sell"
    elseif tabName == "About" then
        UIState.CurrentTab = "About"
    else
        UIState.CurrentTab = "Main"
    end
    applyLayoutState()
    requestConfigSave()
end

function toggleClickerMode()
    if not UIState.Active then
        if FarmState.Active then
            setFarmEnabled(false)
        end
        if HarvestState.Active then
            setHarvestEnabled(false)
        end
    end
    setClickerEnabled(not UIState.Active)
end

toggleButton.MouseButton1Click:Connect(function()
    toggleClickerMode()
end)
toggleButton.MouseEnter:Connect(function()
    if UIState.Active then
        toggleButton.BackgroundColor3 = Color3.fromRGB(236, 105, 105)
    else
        toggleButton.BackgroundColor3 = Color3.fromRGB(92, 216, 145)
    end
end)

toggleButton.MouseLeave:Connect(function()
    if UIState.Active then
        toggleButton.BackgroundColor3 = Theme.Danger
    else
        toggleButton.BackgroundColor3 = Theme.Success
    end
end)

mainTabButton.MouseButton1Click:Connect(function()
    switchTab("Main")
end)

tpTabButton.MouseButton1Click:Connect(function()
    switchTab("Teleport")
end)

farmTabButton.MouseButton1Click:Connect(function()
    switchTab("Farm")
end)

harvestTabButton.MouseButton1Click:Connect(function()
    switchTab("Harvest")
end)

sellTabButton.MouseButton1Click:Connect(function()
    switchTab("Sell")
end)

aboutTabButton.MouseButton1Click:Connect(function()
    switchTab("About")
end)

farmZoneButton.MouseButton1Click:Connect(function()
    FarmState.ZoneIndex = (FarmState.ZoneIndex % #zones) + 1
    farmZoneButton.Text = "Farm Zone: " .. zones[FarmState.ZoneIndex].name
    requestConfigSave()
end)

farmPriorityButton.MouseButton1Click:Connect(function()
    local currentMode = normalizeFarmPriorityMode(FarmState.PriorityMode)
    if currentMode == "HP" then
        FarmState.PriorityMode = "RARITY"
    else
        FarmState.PriorityMode = "HP"
    end

    FarmState.LockedTarget = nil
    FarmState.CurrentTarget = nil
    FarmState.SkipRequested = true
    FarmState.LastConflictText = "Priority: " .. getFarmPriorityModeLabel(FarmState.PriorityMode)
    FarmState.LastConflictAt = os.clock()

    requestConfigSave()
    runFarmScan()
    updateFarmView(true)
end)

farmEspToggleButton.MouseButton1Click:Connect(function()
    setFarmEspEnabled(not FarmState.EspEnabled)
    requestConfigSave()
    updateFarmView(true)
end)

farmForceTreeInfoToggleButton.MouseButton1Click:Connect(function()
    setForceTreeInfoEnabled(not FarmState.ForceTreeInfoEnabled)
    requestConfigSave()
    updateFarmView(true)
end)

farmWeatherToggleButton.MouseButton1Click:Connect(function()
    FarmState.WeatherMutationEnabled = not FarmState.WeatherMutationEnabled
    if FarmState.WeatherMutationEnabled then
        FarmState.LastWeatherMutationScanAt = 0
        FarmState.LastWeatherMutationMessageKey = nil
        FarmState.LastWeatherMutationMessageAt = 0
        FarmState.LastWeatherMutationHandledKey = nil
        FarmState.LastConflictText = "Weather hunt: ON"
    else
        FarmState.WeatherMutationTarget = nil
        FarmState.LastWeatherMutationMessageKey = nil
        FarmState.LastWeatherMutationMessageAt = 0
        FarmState.LastWeatherMutationHandledKey = nil
        FarmState.LastConflictText = "Weather hunt: OFF"
    end
    FarmState.LastConflictAt = os.clock()
    requestConfigSave()
    updateFarmView(true)
end)

farmRadiusInput.FocusLost:Connect(function()
    applyFarmRadiusFromInput(true)
end)

farmTreeFilterInput.FocusLost:Connect(function()
    applyFarmTreeFilterFromInput(true)
    runFarmScan()
end)

sellNameFilterInput.FocusLost:Connect(function()
    applySellInputs(true)
    updateFarmView()
end)

sellCountAttrInput.FocusLost:Connect(function()
    applySellInputs(true)
    updateFarmView()
end)

sellMinCountInput.FocusLost:Connect(function()
    applySellInputs(true)
    updateFarmView()
end)

sellKeepInput.FocusLost:Connect(function()
    applySellInputs(true)
    updateFarmView()
end)

sellIntervalInput.FocusLost:Connect(function()
    applySellInputs(true)
    updateFarmView()
end)

farmScanButton.MouseButton1Click:Connect(function()
    runFarmScan()
end)

farmNextButton.MouseButton1Click:Connect(function()
    requestFarmNextTarget()
end)

farmToggleButton.MouseButton1Click:Connect(function()
    if not FarmState.Active and UIState.Active then
        setClickerEnabled(false)
    end
    if not FarmState.Active and HarvestState.Active then
        setHarvestEnabled(false)
    end
    setFarmEnabled(not FarmState.Active)
end)

harvestToggleButton.MouseButton1Click:Connect(function()
    if not HarvestState.Active and UIState.Active then
        setClickerEnabled(false)
    end
    if not HarvestState.Active and FarmState.Active then
        setFarmEnabled(false)
    end
    setHarvestEnabled(not HarvestState.Active)
end)

sellScanAttrButton.MouseButton1Click:Connect(function()
    runSellAttributeScan()
    updateFarmView()
end)

sellManualAllButton.MouseButton1Click:Connect(function()
    runSellPass(false)
    updateFarmView()
end)

sellManualFilteredButton.MouseButton1Click:Connect(function()
    runSellPass(true)
    updateFarmView()
end)

sellAutoToggleButton.MouseButton1Click:Connect(function()
    setSellEnabled(not SellState.Active)
end)

attachHover(closeButton, Theme.Danger, Color3.fromRGB(236, 105, 105))
attachHover(minimizeButton, Theme.Warning, Color3.fromRGB(250, 206, 108))

minimizeButton.MouseButton1Click:Connect(function()
    UIState.Minimized = not UIState.Minimized
    applyLayoutState()
    requestConfigSave()
end)

closeButton.MouseButton1Click:Connect(function()
    saveConfigNow()
    setClickerEnabled(false)
    setFarmEnabled(false)
    setFarmEspEnabled(false)
    setForceTreeInfoEnabled(false)
    setHarvestEnabled(false)
    setSellEnabled(false)

    for _, connection in ipairs(connections) do
        if connection and connection.Connected then
            connection:Disconnect()
        end
    end
    connections = {}

    if screenGui then
        screenGui:Destroy()
    end

    print("Timber Script by Vaan closed.")
end)

trackConnection(UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.UserInputType == Enum.UserInputType.Keyboard then
        if gameProcessed then
            return
        end

        if input.KeyCode == Settings.ToggleKey then
            toggleClickerMode()
            return
        end

        if input.KeyCode == Settings.FarmToggleKey then
            if not FarmState.Active and UIState.Active then
                setClickerEnabled(false)
            end
            if not FarmState.Active and HarvestState.Active then
                setHarvestEnabled(false)
            end
            setFarmEnabled(not FarmState.Active)
            return
        end
    end
end))

updateStatusView()
updateFarmView()
setFarmEspEnabled(FarmState.EspEnabled)
setForceTreeInfoEnabled(FarmState.ForceTreeInfoEnabled)
applyLayoutState()
requestConfigSave()
