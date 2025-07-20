-- ЗНАЧЕНИЯ ПО УМОЛЧАНИЮ - ЛЕГКО ИЗМЕНИТЬ
local DEFAULT_CAMERA_DISTANCE = 15      -- Расстояние камеры по умолчанию (максимум и сохраненное)
local DEFAULT_CAMERA_PITCH = 20           -- Угол наклона камеры по умолчанию

-- Игровые значения по умолчанию (когда настройки отключены)
local GAME_DEFAULT_CAMERA_DISTANCE = 15   -- Стандартное расстояние камеры WoW
local GAME_DEFAULT_CAMERA_PITCH = 0       -- Стандартный наклон камеры WoW

-- Расстояния по умолчанию для автоопределения
local DEFAULT_INSTANCE_DISTANCE = 25      -- Инстансы (подземелья/рейды): 20-30
local DEFAULT_INDOOR_DISTANCE = 20        -- Закрытые локации: 15-25
local DEFAULT_OUTDOOR_DISTANCE = 40       -- Открытые области: 35-50
local DEFAULT_PVP_DISTANCE = 50           -- PvP зоны: 50 для максимального обзора
local DEFAULT_CITY_DISTANCE = 28          -- Города: 25-30

-- Простая функция для выполнения с задержкой (аналог C_Timer.After для WoW 3.3.5a)
local function RunAfter(delay, func)
    local f = CreateFrame("Frame")
    local elapsed = 0
    f:SetScript("OnUpdate", function(self, e)
        elapsed = elapsed + e
        if elapsed >= delay then
            self:SetScript("OnUpdate", nil)
            func()
            f = nil
        end
    end)
end

-- Делаем функцию глобальной для использования в других модулях (как в LootLog)
_G["RunAfter"] = RunAfter

-- Создаем аддон используя AceAddon-3.0
local MaxCamEnhanced = LibStub("AceAddon-3.0"):NewAddon("MaxCamEnhanced", "AceEvent-3.0", "AceConsole-3.0")
local L = MaxCamEnhanced_Locale or {}

-- Экспортируем в глобальную область видимости
_G["MaxCamEnhanced"] = MaxCamEnhanced

-- Настройки по умолчанию (используя константы из выше)
local defaults = {
    profile = {
        cameraDistance = DEFAULT_CAMERA_DISTANCE,           -- Максимальное расстояние камеры (cameraDistanceMax)
        cameraSavedDistance = DEFAULT_CAMERA_DISTANCE,      -- То же что и максимальное расстояние для простоты
        linkCameraDistances = true,                         -- Связать позицию по умолчанию и максимальное расстояние
        enabled = true,

        autoDetectDistance = false,
        unifyCameraDistance = true,
        unifiedSavedDistance = DEFAULT_CAMERA_DISTANCE,    -- Устаревшее - будет заменено на cameraSavedDistance

        -- Настройки автоопределения (используя константы из выше)
        autoDetectSettings = {
            -- Расстояния по типу локации
            instanceDistance = DEFAULT_INSTANCE_DISTANCE,  -- 🏰 Инстансы (подземелья/рейды): 20-30
            indoorDistance = DEFAULT_INDOOR_DISTANCE,      -- 🏠 Закрытые локации: 15-25
            outdoorDistance = DEFAULT_OUTDOOR_DISTANCE,    -- 🌍 Открытые области: 35-50
            pvpDistance = DEFAULT_PVP_DISTANCE,            -- ⚔️ PvP зоны: 50 для максимального обзора
            cityDistance = DEFAULT_CITY_DISTANCE,          -- 🏙️ Города: 25-30

            -- Переопределения зон теперь загружаются из MaxCamEnhanced_Zones.lua
            -- Пользователи могут редактировать этот файл для добавления своих зон
            zoneOverrides = {
                -- Зоны по умолчанию будут загружены из внешнего файла во время инициализации
                -- Вы можете добавить пользовательские зоны здесь если нужно, они переопределят внешнюю базу данных
            }
        }
    }
}

function MaxCamEnhanced:OnInitialize()
    -- Инициализируем базу данных с поддержкой для каждого персонажа
    self.db = LibStub("AceDB-3.0"):New("MaxCamEnhancedDB", defaults, true)

    -- Определяем какой профиль использовать на основе unifyCameraDistance
    local characterName = UnitName("player") .. " - " .. GetRealmName()

    -- Сначала устанавливаем профиль для конкретного персонажа чтобы проверить текущие настройки
    self.db:SetProfile(characterName)

    -- Если унификация включена в профиле персонажа, переключаемся на унифицированный профиль
    if self.db.profile.unifyCameraDistance then
        self.db:SetProfile("Unified")
        -- Убеждаемся что унифицированный профиль тоже имеет флаг установленный
        self.db.profile.unifyCameraDistance = true
        -- Примечание: Унификация будет применена в PLAYER_ENTERING_WORLD
    end

    -- Мигрируем устаревшие настройки
    self:MigrateLegacySettings()

    -- Загружаем базу данных зон из внешнего файла
    self:LoadZoneDatabase()

    -- Регистрируем команды чата
    self:RegisterChatCommand("maxcam", "SlashCmdHandler")
    self:RegisterChatCommand("mc", "SlashCmdHandler")

    print("|cFF00FF00MaxCamEnhanced v2.0 " .. (L["loaded! Type /maxcam config for settings."] or "loaded! Type /maxcam config for settings.") .. "|r")
end



-- Загружаем базу данных зон из внешнего файла
function MaxCamEnhanced:LoadZoneDatabase()
    local zoneDatabase = _G["MaxCamEnhanced_ZoneDatabase"]
    if zoneDatabase then
        -- Копируем зоны из внешней базы данных в настройки профиля
        for zoneName, distance in pairs(zoneDatabase) do
            self.db.profile.autoDetectSettings.zoneOverrides[zoneName] = distance
        end
        self:Print("Loaded " .. self:CountTable(zoneDatabase) .. " zones from zone database")
    else
        self:Print("Warning: Zone database not found. Using default zones only.")
    end
end

-- Вспомогательная функция для подсчета записей в таблице
function MaxCamEnhanced:CountTable(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

-- Мигрируем устаревшие настройки к новым отдельным элементам управления расстоянием камеры
function MaxCamEnhanced:MigrateLegacySettings()
    if not self.db.profile.cameraSavedDistance and self.db.profile.unifiedSavedDistance then
        -- Мигрируем из старой унифицированной системы к новым отдельным элементам управления
        self.db.profile.cameraSavedDistance = self.db.profile.unifiedSavedDistance
        self.db.profile.linkCameraDistances = true  -- Сохраняем старое поведение по умолчанию
    end
end

function MaxCamEnhanced:OnEnable()
    -- Регистрируем события
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    self:RegisterEvent("ZONE_CHANGED")
    self:RegisterEvent("ZONE_CHANGED_INDOORS")

    -- Инициализируем конфигурацию с задержкой (убеждаемся что файл конфигурации загружен)
    RunAfter(0.5, function()
        if MaxCamEnhanced.InitializeConfig then
            MaxCamEnhanced.InitializeConfig()
        else
            -- Резервный вариант: попробуем позже
            RunAfter(1, function()
                if MaxCamEnhanced.InitializeConfig then
                    MaxCamEnhanced.InitializeConfig()
                end
            end)
        end
    end)
end

function MaxCamEnhanced:OnDisable()
    -- Отменяем регистрацию всех событий для очистки
    self:UnregisterAllEvents()

    -- Очищаем регистрацию конфигурации
    self.configInitialized = false
end

-- Обработчик событий - Применяем настройки при входе в игру
function MaxCamEnhanced:PLAYER_ENTERING_WORLD()
    -- Применяем настройки камеры для этого персонажа
    if self.db.profile.enabled then
        self:ApplyCameraSettings()
        
        -- Дополнительная проверка через 2 секунды
        RunAfter(2, function()
            if self.db.profile.enabled then
                local currentDistance = GetCVar("cameraDistanceMax")
                local targetDistance = self.db.profile.cameraDistance
                
                if currentDistance and targetDistance and math.abs(tonumber(currentDistance) - targetDistance) > 0.1 then
                    -- Если настройки не применились, принудительно применяем
                    self:ForceApplyCameraSettings()
                end
            end
        end)
    end

    -- Отменяем регистрацию события после первого применения
    self:UnregisterEvent("PLAYER_ENTERING_WORLD")
end

-- Принудительная унификация через ВСЕ аккаунты записывая в общее расположение WTF
function MaxCamEnhanced:ForceUnifyAllAccounts()
    if not self.db.profile.unifyCameraDistance then
        return
    end

    -- Получаем расстояния камеры - используем новые отдельные настройки или устаревшую унифицированную настройку
    local savedDistance = self.db.profile.cameraSavedDistance or self.db.profile.unifiedSavedDistance
    local maxDistance = self.db.profile.cameraDistance

    -- Применяем унифицированные настройки камеры к CVars (работает через ВСЕ аккаунты)
    SetCVar("cameraDistanceMax", maxDistance)
    SetCVar("cameraSavedDistance", savedDistance)
    SetCVar("cameraSavedPitch", "10")  -- Стандартный угол камеры

    -- Пробуем метод фактора для серверов которые его поддерживают
    if maxDistance > 15 then
        local factor = maxDistance / 15
        pcall(SetCVar, "cameraDistanceMaxFactor", factor)
    end

    -- Принудительно сохраняем CVars в WTF файлы для постоянства через ВСЕ аккаунты
    ConsoleExec("cvar_save")

    -- Настройки сохранены через CVars выше
end



-- Принудительная унификация для всех персонажей переопределяя WTF значения (тихая проверка)
function MaxCamEnhanced:ForceUnifyAllCharacters()
    if not self.db.profile.unifyCameraDistance then
        return
    end

    -- Получаем расстояния камеры - используем новые отдельные настройки или устаревшую унифицированную настройку
    local savedDistance = self.db.profile.cameraSavedDistance or self.db.profile.unifiedSavedDistance
    local maxDistance = self.db.profile.cameraDistance

    -- Получаем текущие значения чтобы проверить нужны ли изменения
    local currentSaved = GetCVar("cameraSavedDistance")
    local currentMax = GetCVar("cameraDistanceMax")
    local currentPitch = GetCVar("cameraSavedPitch")

    local needsUpdate = false

    -- Проверяем нужно ли обновление значений
    if not currentSaved or math.abs(tonumber(currentSaved) - savedDistance) > 0.1 then
        needsUpdate = true
    end
    if not currentMax or math.abs(tonumber(currentMax) - maxDistance) > 0.1 then
        needsUpdate = true
    end
    -- Не изменяем наклон в 3.3.5a - он может работать неправильно

    if needsUpdate then
        -- Применяем все значения тихо
        SetCVar("cameraSavedDistance", savedDistance)
        SetCVar("cameraDistanceMax", maxDistance)

        -- Применяем наклон камеры (упрощено для совместимости с 3.3.5a)
        pcall(SetCVar, "cameraSavedPitch", "10")

        -- Принудительно в WTF файлы
        ConsoleExec("CameraDistanceMax " .. maxDistance)
        ConsoleExec("CameraSavedDistance " .. savedDistance)
        ConsoleExec("cvar_save")

        -- Настройки применяются тихо как MouseSpeedEnhanced
    end
end

function MaxCamEnhanced:ZONE_CHANGED_NEW_AREA()
    -- Автоопределение для новой локации если включено
    if self.db.profile.autoDetectDistance then
        self:ApplyCameraSettings()
    end
end

function MaxCamEnhanced:ZONE_CHANGED()
    -- Автоопределение для изменения локации если включено
    if self.db.profile.autoDetectDistance then
        self:ApplyCameraSettings()
    end
end

function MaxCamEnhanced:ZONE_CHANGED_INDOORS()
    -- Автоопределение для изменения закрытая/открытая локация если включено
    if self.db.profile.autoDetectDistance then
        self:ApplyCameraSettings()
    end
end

-- Автоопределение оптимального расстояния камеры на основе текущей локации/окружения
function MaxCamEnhanced:AutoDetectOptimalDistance()
    -- Получаем информацию о текущей локации
    local zone = GetZoneText() or ""
    local subzone = GetSubZoneText() or ""
    local isIndoors = IsIndoors()
    local isInInstance = IsInInstance()

    -- Получаем настройки автоопределения
    local settings = self.db.profile.autoDetectSettings
    local optimalDistance = 30 -- Резервное значение по умолчанию

    -- Сначала проверяем специфическое переопределение зоны
    if settings.zoneOverrides[zone] then
        optimalDistance = settings.zoneOverrides[zone]
    elseif isInInstance then
        -- Инстанс (подземелье/рейд) - ближе камера для лучшего контроля
        optimalDistance = settings.instanceDistance
    elseif self:IsPvPZone(zone) then
        -- PvP зона - максимальное расстояние для осведомленности
        optimalDistance = settings.pvpDistance
    elseif self:IsCityZone(zone) then
        -- Город - умеренное расстояние для навигации
        optimalDistance = settings.cityDistance
    elseif isIndoors then
        -- Закрытая локация - близкая камера для тесных пространств
        optimalDistance = settings.indoorDistance
    else
        -- Открытая локация - дальняя камера для лучшего обзора
        optimalDistance = settings.outdoorDistance
    end

    -- Убеждаемся в разумных пределах
    optimalDistance = math.max(optimalDistance, 1)
    optimalDistance = math.min(optimalDistance, 50)

    return math.floor(optimalDistance)
end

-- Проверяем является ли зона PvP зоной
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

-- Проверяем является ли зона городом
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



-- Применяем настройки камеры с принудительной модификацией WTF
function MaxCamEnhanced:ApplyCameraSettings()
    if not self.db.profile.enabled then
        return
    end

    local distance = self.db.profile.cameraDistance

    -- Автоопределение оптимального расстояния если включено
    if self.db.profile.autoDetectDistance then
        local autoDistance = self:AutoDetectOptimalDistance()
        if autoDistance ~= distance then
            distance = autoDistance
            -- Обновляем значения профиля только если автоопределение изменило расстояние
            self.db.profile.cameraDistance = distance
            self.db.profile.cameraSavedDistance = distance
        end
    end

    -- Применяем настройки камеры (базовое применение для текущего персонажа)
    SetCVar("cameraDistanceMax", distance)
    SetCVar("cameraSavedDistance", distance)
    SetCVar("cameraSavedPitch", "10")

    -- Пробуем метод фактора для серверов которые его поддерживают
    if distance > 15 then
        local factor = distance / 15
        pcall(SetCVar, "cameraDistanceMaxFactor", factor)
    end

    -- Принудительная унификация ТОЛЬКО если включена
    if self.db.profile.unifyCameraDistance then
        self:ForceUnifyAllCharacters()
        self:ForceUnifyAllAccounts()
    else
        -- Сохраняем в WTF файлы только для текущего персонажа
        ConsoleExec("cvar_save")
    end

    -- Принудительно применяем через консольные команды
    ConsoleExec("CameraDistanceMax " .. distance)
    ConsoleExec("CameraSavedDistance " .. distance)
    ConsoleExec("cvar_save")

    -- Принудительно обновляем камеру
    CameraZoomIn(0.1)
    CameraZoomOut(0.1)
end

-- Применяем только настройки камеры (для ручного применения) - как MouseSpeedEnhanced
function MaxCamEnhanced:ApplyCameraSettingsOnly()
    local distance = self.db.profile.cameraDistance

    -- Примечание: Автоопределение НЕ применяется здесь - это только для ручных изменений слайдера
    -- Если нужно автоопределение, используйте ApplyCameraSettings() вместо этого

    -- Применяем настройки камеры напрямую
    SetCVar("cameraDistanceMax", distance)
    SetCVar("cameraSavedDistance", distance)
    SetCVar("cameraSavedPitch", "10")

    -- Пробуем метод фактора
    if distance > 15 then
        local factor = distance / 15
        pcall(SetCVar, "cameraDistanceMaxFactor", factor)
    end

    -- Принудительная унификация если включена
    if self.db.profile.unifyCameraDistance then
        self:ForceUnifyAllAccounts()
    else
        -- Сохраняем в WTF файлы только для текущего персонажа
        ConsoleExec("cvar_save")
    end

    -- Принудительно применяем через консольные команды
    ConsoleExec("CameraDistanceMax " .. distance)
    ConsoleExec("CameraSavedDistance " .. distance)
    ConsoleExec("cvar_save")

    -- Принудительно обновляем камеру
    CameraZoomIn(0.1)
    CameraZoomOut(0.1)
end

-- Принудительно применяем настройки камеры даже когда аддон отключен (для ручной кнопки Применить)
function MaxCamEnhanced:ForceApplyCameraSettings()
    if not self.db or not self.db.profile then
        return
    end

    local distance = self.db.profile.cameraDistance

    -- Применяем настройки камеры напрямую
    SetCVar("cameraDistanceMax", distance)
    SetCVar("cameraSavedDistance", distance)
    SetCVar("cameraSavedPitch", "10")

    -- Пробуем метод фактора
    if distance > 15 then
        local factor = distance / 15
        pcall(SetCVar, "cameraDistanceMaxFactor", factor)
    end

    -- Принудительно применяем через консольные команды
    ConsoleExec("CameraDistanceMax " .. distance)
    ConsoleExec("CameraSavedDistance " .. distance)
    ConsoleExec("cvar_save")

    -- Принудительно обновляем камеру
    CameraZoomIn(0.1)
    CameraZoomOut(0.1)

    self:Print(L["Camera settings applied manually"] or "Camera settings applied manually")
end





-- Обрабатываем переключение унификации - переключаем профили сохраняя текущее состояние UI (как MouseSpeedEnhanced)
function MaxCamEnhanced:HandleUnificationToggle(value)
    -- Сохраняем текущее состояние UI перед переключением профилей
    local currentEnabled = self.db.profile.enabled
    local currentCameraDistance = self.db.profile.cameraDistance
    local currentCameraSavedDistance = self.db.profile.cameraSavedDistance
    local currentAutoDetectDistance = self.db.profile.autoDetectDistance
    local characterName = UnitName("player") .. " - " .. GetRealmName()

    if value then
        -- Сначала сохраняем состояние унификации в профиль персонажа
        self.db.profile.unifyCameraDistance = true

        -- Переключаемся на унифицированный профиль при включении
        self.db:SetProfile("Unified")
        print("MaxCamEnhanced: Switched to unified profile")
        -- Принудительная унификация через все аккаунты
        self:ForceUnifyAllAccounts()
    else
        -- Сначала сохраняем состояние унификации в текущий профиль
        self.db.profile.unifyCameraDistance = false

        -- Переключаемся на профиль для конкретного персонажа при отключении
        self.db:SetProfile(characterName)
        print("MaxCamEnhanced: Switched to character profile: " .. characterName)
    end

    -- Восстанавливаем состояние UI в новом профиле чтобы предотвратить нежелательные изменения
    self.db.profile.enabled = currentEnabled
    self.db.profile.cameraDistance = currentCameraDistance
    self.db.profile.cameraSavedDistance = currentCameraSavedDistance
    self.db.profile.autoDetectDistance = currentAutoDetectDistance
    self.db.profile.unifyCameraDistance = value

    -- Принудительно сохраняем настройку
    self:SaveSettings()
end

-- Сохраняем настройки в базу данных (как MouseSpeedEnhanced)
function MaxCamEnhanced:SaveSettings()
    -- Настройки автоматически сохраняются AceDB при изменении
    -- Эта функция существует для совместимости с другими частями кода
end

-- Применяем настройки к игре (упрощено как MouseSpeedEnhanced)
function MaxCamEnhanced:ApplySettings()
    if self.db.profile.enabled then
        self:ApplyCameraSettings()
    else
        -- Когда аддон отключен, НЕ сбрасываем настройки автоматически
        -- Пользователь может применить настройки вручную через кнопку "Применить"
        -- Только если настройки не были применены вручную, сбрасываем к стандартным
        local currentDistance = GetCVar("cameraDistanceMax")
        local targetDistance = self.db.profile.cameraDistance
        
        -- Если текущее расстояние отличается от целевого, применяем настройки
        if currentDistance and targetDistance and math.abs(tonumber(currentDistance) - targetDistance) > 0.1 then
            self:ForceApplyCameraSettings()
        end
    end

    -- Принудительно сохраняем настройки в базу данных
    self:SaveSettings()
end

-- Восстанавливаем стандартные игровые значения (когда настройки отключены)
function MaxCamEnhanced:RestoreDefaults()
    -- Восстанавливаем стандартное расстояние камеры
    SetCVar("cameraDistanceMax", GAME_DEFAULT_CAMERA_DISTANCE)
    SetCVar("cameraSavedDistance", GAME_DEFAULT_CAMERA_DISTANCE)

    -- Сбрасываем фактор к 1 (по умолчанию)
    ConsoleExec("CameraDistanceMaxFactor 1")

    -- Принудительно применяем через консольные команды
    ConsoleExec("CameraDistanceMax " .. GAME_DEFAULT_CAMERA_DISTANCE)
    ConsoleExec("CameraSavedDistance " .. GAME_DEFAULT_CAMERA_DISTANCE)
    ConsoleExec("cvar_save")

    -- Принудительно обновляем камеру
    CameraZoomIn(0.1)
    CameraZoomOut(0.1)

    -- Настройки применяются тихо
end

-- Сбрасываем к значениям по умолчанию
function MaxCamEnhanced:ResetToDefaults()
    self.db:ResetProfile()
    self:ApplySettings()
    self:Print(L["Settings reset to defaults"] or "Settings reset to defaults")
end





-- Обновляем отображение текущих значений в конфигурации
function MaxCamEnhanced:UpdateCurrentValues()
    -- Обновляем интерфейс конфигурации если он открыт
    if LibStub and LibStub("AceConfigRegistry-3.0", true) then
        LibStub("AceConfigRegistry-3.0"):NotifyChange("MaxCamEnhanced")
    end
end





-- Обработчик команд чата (как MouseSpeedEnhanced)
function MaxCamEnhanced:SlashCmdHandler(input)
    local command = string.lower(input or "")

    if command == "config" or command == "settings" or command == "" then
        -- Открываем интерфейс настроек Blizzard к нашему аддону
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

-- Конфигурация обрабатывается в MaxCamEnhanced_Config.lua
