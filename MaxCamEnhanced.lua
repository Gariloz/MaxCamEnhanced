-- MaxCam Enhanced - Advanced camera distance control using Ace3
-- Version 2.0

-- ============================================================================
-- DEFAULT VALUES - EASY TO MODIFY
-- ============================================================================
local DEFAULT_CAMERA_DISTANCE = 15      -- Default camera distance (both max and saved)
local DEFAULT_CAMERA_PITCH = 20           -- Default camera pitch angle

-- Game default values (when settings are disabled)
local GAME_DEFAULT_CAMERA_DISTANCE = 15   -- WoW default camera distance
local GAME_DEFAULT_CAMERA_PITCH = 0       -- WoW default camera pitch

-- Auto-detection default distances
local DEFAULT_INSTANCE_DISTANCE = 25      -- Instances (dungeons/raids): 20-30
local DEFAULT_INDOOR_DISTANCE = 20        -- Indoor locations: 15-25
local DEFAULT_OUTDOOR_DISTANCE = 40       -- Outdoor areas: 35-50
local DEFAULT_PVP_DISTANCE = 50           -- PvP zones: 50 for maximum view
local DEFAULT_CITY_DISTANCE = 28          -- Cities: 25-30
-- ============================================================================

-- Create addon using AceAddon-3.0
local MaxCamEnhanced = LibStub("AceAddon-3.0"):NewAddon("MaxCamEnhanced", "AceEvent-3.0", "AceConsole-3.0")
local L = MaxCamEnhanced_Locale or {}

-- Export to global scope
_G["MaxCamEnhanced"] = MaxCamEnhanced

-- Default settings (using constants from above)
local defaults = {
    profile = {
        cameraDistance = DEFAULT_CAMERA_DISTANCE,           -- Maximum camera distance (cameraDistanceMax)
        cameraSavedDistance = DEFAULT_CAMERA_DISTANCE,      -- Same as max distance for simplicity
        linkCameraDistances = true,                         -- Link default position and maximum distance
        enabled = true,

        autoDetectDistance = false,
        unifyCameraDistance = true,
        unifiedSavedDistance = DEFAULT_CAMERA_DISTANCE,    -- Legacy - will be replaced by cameraSavedDistance

        -- Auto-detection settings (using constants from above)
        autoDetectSettings = {
            -- Location-based distances
            instanceDistance = DEFAULT_INSTANCE_DISTANCE,  -- 🏰 Instances (dungeons/raids): 20-30
            indoorDistance = DEFAULT_INDOOR_DISTANCE,      -- 🏠 Indoor locations: 15-25
            outdoorDistance = DEFAULT_OUTDOOR_DISTANCE,    -- 🌍 Outdoor areas: 35-50
            pvpDistance = DEFAULT_PVP_DISTANCE,            -- ⚔️ PvP zones: 50 for maximum view
            cityDistance = DEFAULT_CITY_DISTANCE,          -- 🏙️ Cities: 25-30

            -- Zone overrides are now loaded from MaxCamEnhanced_Zones.lua
            -- Users can edit that file to add their own zones
            zoneOverrides = {
                -- Default zones will be loaded from external file during initialization
                -- You can add custom zones here if needed, they will override external database
            }
        }
    }
}

function MaxCamEnhanced:OnInitialize()
    -- Initialize database with per-character support
    self.db = LibStub("AceDB-3.0"):New("MaxCamEnhancedDB", defaults, true)

    -- Determine which profile to use based on unifyCameraDistance
    local characterName = UnitName("player") .. " - " .. GetRealmName()

    -- First, set character-specific profile to check current settings
    self.db:SetProfile(characterName)

    -- If unification is enabled in character profile, switch to unified profile
    if self.db.profile.unifyCameraDistance then
        self.db:SetProfile("Unified")
        -- Ensure the unified profile also has the flag set
        self.db.profile.unifyCameraDistance = true
        -- Note: Unification will be applied in PLAYER_ENTERING_WORLD
    end

    -- Migrate legacy settings
    self:MigrateLegacySettings()

    -- Load zone database from external file
    self:LoadZoneDatabase()

    -- Register slash commands
    self:RegisterChatCommand("maxcam", "SlashCmdHandler")
    self:RegisterChatCommand("mc", "SlashCmdHandler")

    print("|cFF00FF00MaxCamEnhanced v2.0 " .. (L["loaded! Type /maxcam config for settings."] or "loaded! Type /maxcam config for settings.") .. "|r")
end



-- Load zone database from external file
function MaxCamEnhanced:LoadZoneDatabase()
    local zoneDatabase = _G["MaxCamEnhanced_ZoneDatabase"]
    if zoneDatabase then
        -- Copy zones from external database to profile settings
        for zoneName, distance in pairs(zoneDatabase) do
            self.db.profile.autoDetectSettings.zoneOverrides[zoneName] = distance
        end
        self:Print("Loaded " .. self:CountTable(zoneDatabase) .. " zones from zone database")
    else
        self:Print("Warning: Zone database not found. Using default zones only.")
    end
end

-- Helper function to count table entries
function MaxCamEnhanced:CountTable(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

-- Migrate legacy settings to new separate camera distance controls
function MaxCamEnhanced:MigrateLegacySettings()
    if not self.db.profile.cameraSavedDistance and self.db.profile.unifiedSavedDistance then
        -- Migrate from old unified system to new separate controls
        self.db.profile.cameraSavedDistance = self.db.profile.unifiedSavedDistance
        self.db.profile.linkCameraDistances = true  -- Keep old behavior by default
    end
end

function MaxCamEnhanced:OnEnable()
    -- Register events
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    self:RegisterEvent("ZONE_CHANGED")
    self:RegisterEvent("ZONE_CHANGED_INDOORS")

    -- Initialize configuration with small delay
    C_Timer.After(0.1, function()
        if MaxCamEnhanced.InitializeConfig then
            MaxCamEnhanced.InitializeConfig()
        end
    end)
end

function MaxCamEnhanced:OnDisable()
    -- Unregister all events for cleanup
    self:UnregisterAllEvents()

    -- Clean up configuration registration
    self.configInitialized = false
end

-- Event handler - Apply settings on login
function MaxCamEnhanced:PLAYER_ENTERING_WORLD()
    -- Apply camera settings for this character
    if self.db.profile.enabled then
        self:ApplyCameraSettings()
    end

    -- Unregister event after first application
    self:UnregisterEvent("PLAYER_ENTERING_WORLD")
end

-- Force unification across ALL accounts by writing to shared WTF location
function MaxCamEnhanced:ForceUnifyAllAccounts()
    if not self.db.profile.unifyCameraDistance then
        return
    end

    -- Get camera distances - use new separate settings or legacy unified setting
    local savedDistance = self.db.profile.cameraSavedDistance or self.db.profile.unifiedSavedDistance
    local maxDistance = self.db.profile.cameraDistance

    -- Apply unified camera settings to CVars (works across ALL accounts)
    SetCVar("cameraDistanceMax", maxDistance)
    SetCVar("cameraSavedDistance", savedDistance)
    SetCVar("cameraSavedPitch", "10")  -- Standard camera angle

    -- Try factor method for servers that support it
    if maxDistance > 15 then
        local factor = maxDistance / 15
        pcall(SetCVar, "cameraDistanceMaxFactor", factor)
    end

    -- Force save CVars to WTF files for persistence across ALL accounts
    ConsoleExec("cvar_save")

    -- Settings saved via CVars above
end



-- Force unification for all characters by overriding WTF values (silent check)
function MaxCamEnhanced:ForceUnifyAllCharacters()
    if not self.db.profile.unifyCameraDistance then
        return
    end

    -- Get camera distances - use new separate settings or legacy unified setting
    local savedDistance = self.db.profile.cameraSavedDistance or self.db.profile.unifiedSavedDistance
    local maxDistance = self.db.profile.cameraDistance

    -- Get current values to check if change is needed
    local currentSaved = GetCVar("cameraSavedDistance")
    local currentMax = GetCVar("cameraDistanceMax")
    local currentPitch = GetCVar("cameraSavedPitch")

    local needsUpdate = false

    -- Check if values need updating
    if not currentSaved or math.abs(tonumber(currentSaved) - savedDistance) > 0.1 then
        needsUpdate = true
    end
    if not currentMax or math.abs(tonumber(currentMax) - maxDistance) > 0.1 then
        needsUpdate = true
    end
    -- Don't modify pitch in 3.3.5a - it may not work properly

    if needsUpdate then
        -- Apply all values silently
        SetCVar("cameraSavedDistance", savedDistance)
        SetCVar("cameraDistanceMax", maxDistance)

        -- Apply camera pitch (simplified for 3.3.5a compatibility)
        pcall(SetCVar, "cameraSavedPitch", "10")

        -- Force to WTF files
        ConsoleExec("CameraDistanceMax " .. maxDistance)
        ConsoleExec("CameraSavedDistance " .. savedDistance)
        ConsoleExec("cvar_save")

        -- Settings apply silently like MouseSpeedEnhanced
    end
end

function MaxCamEnhanced:ZONE_CHANGED_NEW_AREA()
    -- Auto-detect for new location if enabled
    if self.db.profile.autoDetectDistance then
        self:ApplyCameraSettings()
    end
end

function MaxCamEnhanced:ZONE_CHANGED()
    -- Auto-detect for location change if enabled
    if self.db.profile.autoDetectDistance then
        self:ApplyCameraSettings()
    end
end

function MaxCamEnhanced:ZONE_CHANGED_INDOORS()
    -- Auto-detect for indoor/outdoor change if enabled
    if self.db.profile.autoDetectDistance then
        self:ApplyCameraSettings()
    end
end

-- Auto-detect optimal camera distance based on current location/environment
function MaxCamEnhanced:AutoDetectOptimalDistance()
    -- Get current location information
    local zone = GetZoneText() or ""
    local subzone = GetSubZoneText() or ""
    local isIndoors = IsIndoors()
    local isInInstance = IsInInstance()

    -- Get auto-detection settings
    local settings = self.db.profile.autoDetectSettings
    local optimalDistance = 30 -- Default fallback

    -- Check for specific zone override first
    if settings.zoneOverrides[zone] then
        optimalDistance = settings.zoneOverrides[zone]
    elseif isInInstance then
        -- Instance (dungeon/raid) - closer camera for better control
        optimalDistance = settings.instanceDistance
    elseif self:IsPvPZone(zone) then
        -- PvP zone - maximum distance for awareness
        optimalDistance = settings.pvpDistance
    elseif self:IsCityZone(zone) then
        -- City - moderate distance for navigation
        optimalDistance = settings.cityDistance
    elseif isIndoors then
        -- Indoor location - close camera for tight spaces
        optimalDistance = settings.indoorDistance
    else
        -- Outdoor location - far camera for better view
        optimalDistance = settings.outdoorDistance
    end

    -- Ensure reasonable bounds
    optimalDistance = math.max(optimalDistance, 1)
    optimalDistance = math.min(optimalDistance, 50)

    return math.floor(optimalDistance)
end

-- Check if zone is a PvP zone
function MaxCamEnhanced:IsPvPZone(zoneName)
    local pvpZones = {
        ["Wintergrasp"] = true,
        ["Alterac Valley"] = true,
        ["Arathi Basin"] = true,
        ["Warsong Gulch"] = true,
        ["Eye of the Storm"] = true,
        ["Strand of the Ancients"] = true,
        ["Isle of Conquest"] = true,
    }
    return pvpZones[zoneName] or false
end

-- Check if zone is a city
function MaxCamEnhanced:IsCityZone(zoneName)
    local cityZones = {
        ["Stormwind City"] = true,
        ["Ironforge"] = true,
        ["Darnassus"] = true,
        ["Orgrimmar"] = true,
        ["Thunder Bluff"] = true,
        ["Undercity"] = true,
        ["Shattrath City"] = true,
        ["Dalaran"] = true,
    }
    return cityZones[zoneName] or false
end



-- Apply camera settings with forced WTF modification
function MaxCamEnhanced:ApplyCameraSettings()
    if not self.db.profile.enabled then
        return
    end

    local distance = self.db.profile.cameraDistance

    -- Auto-detect optimal distance if enabled
    if self.db.profile.autoDetectDistance then
        local autoDistance = self:AutoDetectOptimalDistance()
        if autoDistance ~= distance then
            distance = autoDistance
            -- Update profile values only if auto-detection changed the distance
            self.db.profile.cameraDistance = distance
            self.db.profile.cameraSavedDistance = distance
        end
    end

    -- Apply camera settings (basic application for current character)
    SetCVar("cameraDistanceMax", distance)
    SetCVar("cameraSavedDistance", distance)
    SetCVar("cameraSavedPitch", "10")

    -- Try factor method for servers that support it
    if distance > 15 then
        local factor = distance / 15
        pcall(SetCVar, "cameraDistanceMaxFactor", factor)
    end

    -- Force unification ONLY if enabled
    if self.db.profile.unifyCameraDistance then
        self:ForceUnifyAllCharacters()
        self:ForceUnifyAllAccounts()
    else
        -- Save to WTF files for current character only
        ConsoleExec("cvar_save")
    end

    -- Settings apply silently like MouseSpeedEnhanced
end

-- Apply only camera settings (for manual application) - like MouseSpeedEnhanced
function MaxCamEnhanced:ApplyCameraSettingsOnly()
    local distance = self.db.profile.cameraDistance

    -- Note: Auto-detection is NOT applied here - this is for manual slider changes only
    -- If auto-detection is needed, use ApplyCameraSettings() instead

    -- Apply camera settings directly
    SetCVar("cameraDistanceMax", distance)
    SetCVar("cameraSavedDistance", distance)
    SetCVar("cameraSavedPitch", "10")

    -- Try factor method
    if distance > 15 then
        local factor = distance / 15
        pcall(SetCVar, "cameraDistanceMaxFactor", factor)
    end

    -- Force unification if enabled
    if self.db.profile.unifyCameraDistance then
        self:ForceUnifyAllAccounts()
    else
        -- Save to WTF files for current character only
        ConsoleExec("cvar_save")
    end

    -- Settings apply silently like MouseSpeedEnhanced
end

-- Force apply camera settings even when addon is disabled (for manual Apply button)
function MaxCamEnhanced:ForceApplyCameraSettings()
    if not self.db or not self.db.profile then
        return
    end

    local distance = self.db.profile.cameraDistance

    -- Apply camera settings directly
    SetCVar("cameraDistanceMax", distance)
    SetCVar("cameraSavedDistance", distance)
    SetCVar("cameraSavedPitch", "10")

    -- Try factor method
    if distance > 15 then
        local factor = distance / 15
        pcall(SetCVar, "cameraDistanceMaxFactor", factor)
    end

    -- Save to WTF files
    ConsoleExec("cvar_save")

    self:Print(L["Camera settings applied manually"] or "Camera settings applied manually")
end





-- Handle unification toggle - switch profiles while preserving current UI state (like MouseSpeedEnhanced)
function MaxCamEnhanced:HandleUnificationToggle(value)
    -- Save current UI state before switching profiles
    local currentEnabled = self.db.profile.enabled
    local currentCameraDistance = self.db.profile.cameraDistance
    local currentCameraSavedDistance = self.db.profile.cameraSavedDistance
    local currentAutoDetectDistance = self.db.profile.autoDetectDistance
    local characterName = UnitName("player") .. " - " .. GetRealmName()

    if value then
        -- Save unification state to character profile first
        self.db.profile.unifyCameraDistance = true

        -- Switch to unified profile when enabling
        self.db:SetProfile("Unified")
        print("MaxCamEnhanced: Switched to unified profile")
        -- Force unification across all accounts
        self:ForceUnifyAllAccounts()
    else
        -- Save unification state to current profile first
        self.db.profile.unifyCameraDistance = false

        -- Switch to character-specific profile when disabling
        self.db:SetProfile(characterName)
        print("MaxCamEnhanced: Switched to character profile: " .. characterName)
    end

    -- Restore UI state in the new profile to prevent unwanted changes
    self.db.profile.enabled = currentEnabled
    self.db.profile.cameraDistance = currentCameraDistance
    self.db.profile.cameraSavedDistance = currentCameraSavedDistance
    self.db.profile.autoDetectDistance = currentAutoDetectDistance
    self.db.profile.unifyCameraDistance = value

    -- Force save the setting
    self:SaveSettings()
end

-- Save settings to database (like MouseSpeedEnhanced)
function MaxCamEnhanced:SaveSettings()
    -- Settings are automatically saved by AceDB when changed
    -- This function exists for compatibility with other parts of the code
end

-- Apply settings to game (simplified like MouseSpeedEnhanced)
function MaxCamEnhanced:ApplySettings()
    if self.db.profile.enabled then
        self:ApplyCameraSettings()
    else
        -- Reset to default WoW camera distance
        SetCVar("cameraDistanceMax", GAME_DEFAULT_CAMERA_DISTANCE)
        SetCVar("cameraSavedDistance", GAME_DEFAULT_CAMERA_DISTANCE)
        -- Reset factor to 1 (default)
        ConsoleExec("CameraDistanceMaxFactor 1")
        ConsoleExec("cvar_save")
    end

    -- Force save settings to database
    self:SaveSettings()

    -- Settings apply silently like MouseSpeedEnhanced
end

-- Restore default game values (when settings are disabled)
function MaxCamEnhanced:RestoreDefaults()
    -- Restore default camera distance
    SetCVar("cameraDistanceMax", GAME_DEFAULT_CAMERA_DISTANCE)
    SetCVar("cameraSavedDistance", GAME_DEFAULT_CAMERA_DISTANCE)

    -- Reset factor to 1 (default)
    ConsoleExec("CameraDistanceMaxFactor 1")



    -- Force save
    ConsoleExec("cvar_save")

    -- Settings apply silently
end

-- Reset to defaults
function MaxCamEnhanced:ResetToDefaults()
    self.db:ResetProfile()
    self:ApplySettings()
    self:Print(L["Settings reset to defaults"] or "Settings reset to defaults")
end





-- Update current values display in config
function MaxCamEnhanced:UpdateCurrentValues()
    -- Update configuration interface if it's open
    if LibStub and LibStub("AceConfigRegistry-3.0", true) then
        LibStub("AceConfigRegistry-3.0"):NotifyChange("MaxCamEnhanced")
    end
end





-- Slash command handler (like MouseSpeedEnhanced)
function MaxCamEnhanced:SlashCmdHandler(input)
    local command = string.lower(input or "")

    if command == "config" or command == "settings" or command == "" then
        -- Open Blizzard interface options to our addon
        InterfaceOptionsFrame_OpenToCategory("MaxCamEnhanced")
    elseif command == "apply" then
        self:ApplySettings()
    elseif command == "reset" then
        self:ResetToDefaults()
    elseif command == "help" then
        print("|cFF00FF00MaxCamEnhanced " .. (L["Commands:"] or "Commands:") .. "|r")
        print("|cFFFFFF00/maxcam|r - " .. (L["Open settings"] or "Open settings"))
        print("|cFFFFFF00/maxcam apply|r - " .. (L["Apply current settings"] or "Apply current settings"))
        print("|cFFFFFF00/maxcam reset|r - " .. (L["Reset to defaults"] or "Reset to defaults"))
        print("|cFFFFFF00/maxcam help|r - " .. (L["Show this help"] or "Show this help"))
    else
        print("|cFFFF0000" .. (L["Unknown command. Type '/maxcam help' for available commands."] or "Unknown command. Type '/maxcam help' for available commands.") .. "|r")
    end
end

-- Configuration is handled in MaxCamEnhanced_Config.lua
