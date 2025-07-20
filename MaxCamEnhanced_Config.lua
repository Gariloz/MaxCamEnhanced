MaxCamEnhanced = MaxCamEnhanced or {}
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
local L = MaxCamEnhanced_Locale or {}

local options = nil

local function get(info)
    if not MaxCamEnhanced.db then
        return nil
    end
    return MaxCamEnhanced.db.profile[info[#info]]
end

local function set(info, value)
    if not MaxCamEnhanced or not MaxCamEnhanced.db then
        return
    end

    local key = info[#info]

    -- Специальная обработка для переключения unifyCameraDistance - обрабатываем ДО сохранения в профиль
    if key == "unifyCameraDistance" then
        -- Обрабатываем переключение профилей для унификации
        MaxCamEnhanced:HandleUnificationToggle(value)
        MaxCamEnhanced:UpdateCurrentValues()
        return -- Выходим рано чтобы избежать обычной обработки
    end

    -- Сначала сохраняем значение в профиль
    MaxCamEnhanced.db.profile[key] = value

    -- Специальная обработка для переключения enabled
    if key == "enabled" then
        if value then
            -- Расстояние камеры включено: применяем текущие настройки
            MaxCamEnhanced:ApplySettings()
        else
            -- Расстояние камеры отключено: восстанавливаем значения по умолчанию
            MaxCamEnhanced:RestoreDefaults()
        end
        MaxCamEnhanced:UpdateCurrentValues()
    -- Специальная обработка для переключения autoDetectDistance
    elseif key == "autoDetectDistance" then
        -- Применяем настройки немедленно при переключении
        if value then
            MaxCamEnhanced:ApplySettings()
        end
        MaxCamEnhanced:UpdateCurrentValues()
    -- Применяем настройки немедленно если включено
    elseif MaxCamEnhanced.db.profile.enabled then
        MaxCamEnhanced:ApplySettings()
        MaxCamEnhanced:UpdateCurrentValues()
    end
end

-- Простая функция set для слайдеров - сохраняем и применяем, но не обновляем интерфейс
local function setSlider(info, value)
    if not MaxCamEnhanced or not MaxCamEnhanced.db then
        return
    end

    -- Сохраняем значение в профиль
    MaxCamEnhanced.db.profile[info[#info]] = value

    -- Держим cameraSavedDistance равным cameraDistance
    if info[#info] == "cameraDistance" then
        MaxCamEnhanced.db.profile.cameraSavedDistance = value

        -- Если пользователь вручную изменяет расстояние камеры когда автоопределение включено,
        -- временно отключаем автоопределение чтобы уважать выбор пользователя
        if MaxCamEnhanced.db.profile.autoDetectDistance then
            MaxCamEnhanced.db.profile.autoDetectDistance = false
            -- Показываем сообщение чтобы информировать пользователя
            print("|cFFFFD700MaxCamEnhanced:|r " .. (L["Auto-detection disabled due to manual camera distance change. You can re-enable it in settings."] or "Auto-detection disabled due to manual camera distance change. You can re-enable it in settings."))
            -- Обновляем интерфейс чтобы отразить изменение
            MaxCamEnhanced:UpdateCurrentValues()
        end
    end

    -- Применяем настройки немедленно если включено
    -- Но НЕ обновляем интерфейс чтобы предотвратить прыжки слайдера
    if MaxCamEnhanced.db.profile.enabled and MaxCamEnhanced.ApplyCameraSettingsOnly then
        MaxCamEnhanced:ApplyCameraSettingsOnly()
    end
end

local function getGeneralOptions()
    return {
            header = {
                type = "header",
                name = L["MaxCamEnhanced Settings"] or "MaxCamEnhanced Settings",
                order = 1,
            },
            -- Основные переключатели вверху для удобства
            enabled = {
                type = "toggle",
                name = L["Enable Camera Distance"] or "Enable Camera Distance",
                desc = L["Enable camera distance control. When disabled, game uses default camera distance (15)"] or "Enable camera distance control. When disabled, game uses default camera distance (15)",
                order = 2,
                get = get,
                set = set,
            },

            unifyCameraDistance = {
                type = "toggle",
                name = L["Unify Camera Distance"] or "Unify Camera Distance",
                desc = L["Apply the same camera distance to ALL characters and accounts. When enabled, all your characters will use identical settings."] or "Apply the same camera distance to ALL characters and accounts. When enabled, all your characters will use identical settings.",
                order = 4,
                get = get,
                set = set,
            },
            autoDetectDistance = {
                type = "toggle",
                name = L["Auto-Detect Optimal Distance"] or "Auto-Detect Optimal Distance",
                desc = L["Automatically adjust camera distance based on current location (indoor/outdoor, dungeons, PvP zones)"] or "Automatically adjust camera distance based on current location (indoor/outdoor, dungeons, PvP zones)",
                order = 5,
                get = get,
                set = set,
            },
            spacer1 = {
                type = "header",
                name = L["Camera Distance Settings"] or "Camera Distance Settings",
                order = 6,
            },




            cameraDistance = {
                type = "range",
                name = L["Camera Distance"] or "Camera Distance",
                desc = function()
                    local baseDesc = ""
                    if MaxCamEnhanced.db.profile.unifyCameraDistance then
                        baseDesc = (L["Camera distance for ALL characters and accounts. Sets cameraDistanceMax and cameraSavedDistance automatically. Works across all your characters!"] or "Camera distance for ALL characters and accounts. Sets cameraDistanceMax and cameraSavedDistance automatically. Works across all your characters!")
                    else
                        baseDesc = (L["Camera distance for this character only. Controls maximum camera distance from player (1-50)"] or "Camera distance for this character only. Controls maximum camera distance from player (1-50)")
                    end

                    if MaxCamEnhanced.db.profile.autoDetectDistance then
                        baseDesc = baseDesc .. "\n\n" .. (L["Note: Auto-detection is enabled. Changing this value will automatically disable auto-detection to respect your manual choice."] or "Note: Auto-detection is enabled. Changing this value will automatically disable auto-detection to respect your manual choice.")
                    end

                    return baseDesc
                end,
                min = 1,
                max = 50,
                step = 1,
                bigStep = 1,
                order = 7,
                get = function() return MaxCamEnhanced.db.profile.cameraDistance end,
                set = setSlider,

            },

            applyCameraSettings = {
                type = "execute",
                name = L["Apply Camera Settings Now"] or "Apply Camera Settings Now",
                desc = L["Apply current camera distance settings immediately (even when addon is disabled)"] or "Apply current camera distance settings immediately (even when addon is disabled)",
                order = 8,
                func = function()
                    -- Принудительно применяем настройки камеры даже когда аддон отключен
                    MaxCamEnhanced:ForceApplyCameraSettings()
                    MaxCamEnhanced:UpdateCurrentValues()
                end,
                hidden = function() return MaxCamEnhanced.db.profile.enabled end,
            },








            spacer4 = {
                type = "header",
                name = L["Actions"] or "Actions",
                order = 15,
            },

            resetDefaults = {
                type = "execute",
                name = L["Reset to Defaults"] or "Reset to Defaults",
                desc = L["Reset all settings to default values (distance: 15, enabled, unified)"] or "Reset all settings to default values (distance: 15, enabled, unified)",
                order = 16,
                func = function()
                    MaxCamEnhanced.db:ResetProfile()
                    MaxCamEnhanced:ApplySettings()
                    MaxCamEnhanced:UpdateCurrentValues()
                end,
            },
            restoreGameDefaults = {
                type = "execute",
                name = L["Restore Game Defaults"] or "Restore Game Defaults",
                desc = L["Restore camera distance to game default (15) - useful when addon is disabled"] or "Restore camera distance to game default (15) - useful when addon is disabled",
                order = 17,
                func = function()
                    MaxCamEnhanced:RestoreDefaults()
                    MaxCamEnhanced:UpdateCurrentValues()
                end,
            },

            spacer3 = {
                type = "header",
                name = L["Current Status"] or "Current Status",
                order = 19,
            },
            currentValues = {
                type = "description",
                name = function()
                    if not MaxCamEnhanced.db or not MaxCamEnhanced.db.profile then
                        return "|cFFFF0000" .. (L["Addon not initialized"] or "Addon not initialized") .. "|r"
                    end

                    local profile = MaxCamEnhanced.db.profile

                    -- Получаем текущие игровые значения
                    local gameCameraSavedDistance = GetCVar("cameraSavedDistance") or (L["Unknown"] or "Unknown")
                    local gameCameraMaxDistance = GetCVar("cameraDistanceMax") or (L["Unknown"] or "Unknown")

                    local text = "|cFF00FFFF" .. (L["Current Status:"] or "Current Status:") .. "|r\n\n"

                    -- Раздел 1: Статус настроек аддона (показывает РЕАЛЬНОЕ рабочее состояние, не только состояние чекбокса)
                    text = text .. "|cFFFFD700" .. (L["Addon Settings:"] or "Addon Settings:") .. "|r\n"

                    -- Включить расстояние камеры
                    local enabledColor = profile.enabled and "|cFF00FF00" or "|cFFFF0000"
                    text = text .. "• " .. enabledColor .. (L["Enable Camera Distance"] or "Enable Camera Distance") .. "|r\n"

                    -- Унифицировать расстояние камеры (работает независимо от основного переключателя аддона)
                    local unifyColor = profile.unifyCameraDistance and "|cFF00FF00" or "|cFFFF0000"
                    local unifyStatus = profile.unifyCameraDistance and " " .. (L["(unified for all characters)"] or "(unified for all characters)") or " " .. (L["(individual per character)"] or "(individual per character)")
                    text = text .. "• " .. unifyColor .. (L["Unify Camera Distance"] or "Unify Camera Distance") .. unifyStatus .. "|r\n"

                    -- Автоопределение оптимального расстояния (работает только если аддон включен)
                    local autoDetectWorking = profile.enabled and profile.autoDetectDistance
                    local autoDetectColor = autoDetectWorking and "|cFF00FF00" or "|cFFFF0000"
                    local autoDetectStatus = ""
                    if autoDetectWorking then
                        local currentZone = GetZoneText() or "Unknown"
                        autoDetectStatus = " " .. (L["(active in %s)"] or "(active in %s)"):format(currentZone)
                    elseif profile.autoDetectDistance and not profile.enabled then
                        autoDetectStatus = " " .. (L["(disabled - addon off)"] or "(disabled - addon off)")
                    end
                    text = text .. "• " .. autoDetectColor .. (L["Auto-Detect Optimal Distance"] or "Auto-Detect Optimal Distance") .. autoDetectStatus .. "|r\n\n"

                    -- Раздел 2: Текущие значения (Игра vs Аддон)
                    text = text .. "|cFFFFD700" .. (L["Current Values:"] or "Current Values:") .. "|r\n"
                    text = text .. "• " .. (L["Camera Max Distance:"] or "Camera Max Distance:") .. " |cFF00FF00" .. gameCameraMaxDistance .. "|r " .. (L["(game)"] or "(game)") .. " / |cFF00FF00" .. profile.cameraDistance .. "|r " .. (L["(addon)"] or "(addon)") .. "\n"
                    text = text .. "• " .. (L["Camera Saved Distance:"] or "Camera Saved Distance:") .. " |cFF00FF00" .. gameCameraSavedDistance .. "|r " .. (L["(game)"] or "(game)") .. " / |cFF00FF00" .. profile.cameraDistance .. "|r " .. (L["(addon)"] or "(addon)") .. "\n\n"

                    -- Раздел 3: Сводка статуса
                    text = text .. "|cFFFFD700" .. (L["Status Summary:"] or "Status Summary:") .. "|r\n"

                    if profile.enabled then
                        -- Строим описание статуса на основе активных функций
                        local statusParts = {}
                        local descriptionParts = {}

                        -- Расстояние камеры всегда активно когда аддон включен
                        table.insert(statusParts, (L["Camera Distance"] or "Camera Distance"))

                        -- Добавляем унификацию если включена
                        if profile.unifyCameraDistance then
                            table.insert(statusParts, (L["Unification"] or "Unification"))
                            table.insert(descriptionParts, (L["unified across all characters"] or "unified across all characters"))
                        end

                        -- Добавляем автоопределение если включено
                        if profile.autoDetectDistance then
                            table.insert(statusParts, (L["Auto-Detection"] or "Auto-Detection"))
                            table.insert(descriptionParts, (L["automatically adjusted by location"] or "automatically adjusted by location"))
                        end

                        -- Наклон камеры автоматически применяется когда настройки камеры активны
                        -- Отдельный переключатель не нужен для совместимости с 3.3.5a

                        -- Строим финальное сообщение статуса
                        local statusText = table.concat(statusParts, " + ")
                        text = text .. "|cFF88FF88" .. (L["Active:"] or "Active:") .. " " .. statusText .. "|r\n"

                        -- Добавляем описание если у нас есть специальные функции
                        if #descriptionParts > 0 then
                            local descriptionText = table.concat(descriptionParts, ", ")
                            text = text .. "|cFF888888" .. (L["Features:"] or "Features:") .. " " .. descriptionText .. "|r"
                        else
                            text = text .. "|cFF888888" .. (L["Manual camera distance control"] or "Manual camera distance control") .. "|r"
                        end
                    else
                        text = text .. "|cFFFF0000" .. (L["Addon disabled"] or "Addon disabled") .. "|r\n"
                        text = text .. "|cFF888888" .. (L["Use 'Apply Settings Now' button to apply manually"] or "Use 'Apply Settings Now' button to apply manually") .. "|r"
                    end

                    return text
                end,
                order = 19,
            },

    }
end

local function getAutoDetectionOptions()
    local options = {
        header = {
            type = "header",
            name = L["Auto-Detection Settings"] or "Auto-Detection Settings",
            order = 1,
        },
        description = {
            type = "description",
            name = L["Configure automatic camera distance detection based on location type and specific zones"] or "Configure automatic camera distance detection based on location type and specific zones",
            order = 2,
        },

        spacer1 = {
            type = "header",
            name = L["Location-Based Distances"] or "Location-Based Distances",
            order = 3,
        },

        instanceDistance = {
            type = "range",
            name = L["Instance Distance"] or "Instance Distance",
            desc = L["Camera distance for dungeons and raids (20-30 recommended)"] or "Camera distance for dungeons and raids (20-30 recommended)",
            min = 1, max = 50, step = 1, bigStep = 1,
            order = 4,
            get = function() return MaxCamEnhanced.db.profile.autoDetectSettings.instanceDistance end,
            set = function(_, value)
                MaxCamEnhanced.db.profile.autoDetectSettings.instanceDistance = value
                if MaxCamEnhanced.SaveSettings then
                    MaxCamEnhanced:SaveSettings()
                end
                if MaxCamEnhanced.db.profile.autoDetectDistance and MaxCamEnhanced.db.profile.enabled then
                    MaxCamEnhanced:ApplySettings()
                end
            end,
        },

        indoorDistance = {
            type = "range",
            name = L["Indoor Distance"] or "Indoor Distance",
            desc = L["Camera distance for indoor locations like buildings and caves (15-25 recommended)"] or "Camera distance for indoor locations like buildings and caves (15-25 recommended)",
            min = 1, max = 50, step = 1, bigStep = 1,
            order = 5,
            get = function() return MaxCamEnhanced.db.profile.autoDetectSettings.indoorDistance end,
            set = function(_, value)
                MaxCamEnhanced.db.profile.autoDetectSettings.indoorDistance = value
                if MaxCamEnhanced.SaveSettings then
                    MaxCamEnhanced:SaveSettings()
                end
                if MaxCamEnhanced.db.profile.autoDetectDistance and MaxCamEnhanced.db.profile.enabled then
                    MaxCamEnhanced:ApplySettings()
                end
            end,
        },

        outdoorDistance = {
            type = "range",
            name = L["Outdoor Distance"] or "Outdoor Distance",
            desc = L["Camera distance for outdoor areas and open world (35-50 recommended)"] or "Camera distance for outdoor areas and open world (35-50 recommended)",
            min = 1, max = 50, step = 1, bigStep = 1,
            order = 6,
            get = function() return MaxCamEnhanced.db.profile.autoDetectSettings.outdoorDistance end,
            set = function(_, value)
                MaxCamEnhanced.db.profile.autoDetectSettings.outdoorDistance = value
                if MaxCamEnhanced.SaveSettings then
                    MaxCamEnhanced:SaveSettings()
                end
                if MaxCamEnhanced.db.profile.autoDetectDistance and MaxCamEnhanced.db.profile.enabled then
                    MaxCamEnhanced:ApplySettings()
                end
            end,
        },

        pvpDistance = {
            type = "range",
            name = L["PvP Distance"] or "PvP Distance",
            desc = L["Camera distance for PvP zones for maximum awareness (50 recommended)"] or "Camera distance for PvP zones for maximum awareness (50 recommended)",
            min = 1, max = 50, step = 1, bigStep = 1,
            order = 7,
            get = function() return MaxCamEnhanced.db.profile.autoDetectSettings.pvpDistance end,
            set = function(_, value)
                MaxCamEnhanced.db.profile.autoDetectSettings.pvpDistance = value
                if MaxCamEnhanced.SaveSettings then
                    MaxCamEnhanced:SaveSettings()
                end
                if MaxCamEnhanced.db.profile.autoDetectDistance and MaxCamEnhanced.db.profile.enabled then
                    MaxCamEnhanced:ApplySettings()
                end
            end,
        },

        cityDistance = {
            type = "range",
            name = L["City Distance"] or "City Distance",
            desc = L["Camera distance for major cities (25-30 recommended)"] or "Camera distance for major cities (25-30 recommended)",
            min = 1, max = 50, step = 1, bigStep = 1,
            order = 8,
            get = function() return MaxCamEnhanced.db.profile.autoDetectSettings.cityDistance end,
            set = function(_, value)
                MaxCamEnhanced.db.profile.autoDetectSettings.cityDistance = value
                if MaxCamEnhanced.SaveSettings then
                    MaxCamEnhanced:SaveSettings()
                end
                if MaxCamEnhanced.db.profile.autoDetectDistance and MaxCamEnhanced.db.profile.enabled then
                    MaxCamEnhanced:ApplySettings()
                end
            end,
        },

        spacer2 = {
            type = "header",
            name = L["Zone Overrides"] or "Zone Overrides",
            order = 9,
        },

        zoneOverridesDesc = {
            type = "description",
            name = L["Specific distance settings for individual zones (overrides location-based settings)"] or "Specific distance settings for individual zones (overrides location-based settings)",
            order = 10,
        },
    }

    -- Добавляем элементы управления переопределениями зон организованные по категориям
    if MaxCamEnhanced and MaxCamEnhanced.db and MaxCamEnhanced.db.profile.autoDetectSettings then
        local zoneOverrides = MaxCamEnhanced.db.profile.autoDetectSettings.zoneOverrides
        local order = 11

        -- Определяем категории зон для лучшей организации
        local zoneCategories = {
            {
                name = L["Classic Raids"] or "Classic Raids",
                zones = {
                    "Molten Core", "Blackwing Lair", "Ahn'Qiraj Temple", "Ruins of Ahn'Qiraj"
                }
            },
            {
                name = L["Burning Crusade Raids"] or "Burning Crusade Raids",
                zones = {
                    "Karazhan", "Gruul's Lair", "Magtheridon's Lair", "Serpentshrine Cavern",
                    "Tempest Keep", "The Eye", "Mount Hyjal", "Black Temple", "Sunwell Plateau"
                }
            },
            {
                name = L["Wrath Raids"] or "Wrath Raids",
                zones = {
                    "Naxxramas", "The Obsidian Sanctum", "The Eye of Eternity", "Ulduar",
                    "Trial of the Crusader", "Onyxia's Lair", "Icecrown Citadel", "The Ruby Sanctum"
                }
            },
            {
                name = L["Classic Dungeons"] or "Classic Dungeons",
                zones = {
                    "Ragefire Chasm", "The Deadmines", "Wailing Caverns", "Shadowfang Keep",
                    "The Stockade", "Gnomeregan", "Scarlet Monastery", "Razorfen Kraul",
                    "Razorfen Downs", "Uldaman", "Zul'Farrak", "Maraudon", "Temple of Atal'Hakkar",
                    "Blackrock Depths", "Lower Blackrock Spire", "Upper Blackrock Spire",
                    "Dire Maul", "Stratholme", "Scholomance"
                }
            },
            {
                name = L["Burning Crusade Dungeons"] or "Burning Crusade Dungeons",
                zones = {
                    "Hellfire Ramparts", "The Blood Furnace", "The Slave Pens", "The Underbog",
                    "Mana-Tombs", "Auchenai Crypts", "Sethekk Halls", "Shadow Labyrinth",
                    "The Steamvault", "The Shattered Halls", "The Mechanar", "The Botanica",
                    "The Arcatraz", "Old Hillsbrad Foothills", "The Black Morass", "Magisters' Terrace"
                }
            },
            {
                name = L["Wrath Dungeons"] or "Wrath Dungeons",
                zones = {
                    "Utgarde Keep", "The Nexus", "Azjol-Nerub", "Ahn'kahet: The Old Kingdom",
                    "Drak'Tharon Keep", "The Violet Hold", "Gundrak", "Halls of Stone",
                    "Halls of Lightning", "The Oculus", "Utgarde Pinnacle", "The Culling of Stratholme",
                    "Trial of the Champion", "Forge of Souls", "Pit of Saron", "Halls of Reflection"
                }
            },
            {
                name = L["PvP Zones"] or "PvP Zones",
                zones = {
                    "Wintergrasp", "Alterac Valley", "Arathi Basin", "Warsong Gulch"
                }
            },
            {
                name = L["Classic Zones"] or "Classic Zones",
                zones = {
                    "Elwynn Forest", "Dun Morogh", "Teldrassil", "Durotar", "Mulgore", "Tirisfal Glades",
                    "Westfall", "Loch Modan", "Darkshore", "The Barrens", "Stonetalon Mountains",
                    "Redridge Mountains", "Wetlands", "Ashenvale", "Thousand Needles", "Desolace",
                    "Stranglethorn Vale", "Dustwallow Marsh", "Badlands", "Swamp of Sorrows",
                    "Tanaris", "The Hinterlands", "Azshara", "Feralas", "Felwood", "Un'Goro Crater",
                    "Silithus", "Blasted Lands", "Burning Steppes", "Western Plaguelands",
                    "Eastern Plaguelands", "Winterspring", "Deadwind Pass"
                }
            },
            {
                name = L["Cities"] or "Cities",
                zones = {
                    "Stormwind City", "Ironforge", "Darnassus", "Orgrimmar", "Thunder Bluff",
                    "Undercity", "Shattrath City", "Dalaran"
                }
            },
            {
                name = L["Burning Crusade Zones"] or "Burning Crusade Zones",
                zones = {
                    "Hellfire Peninsula", "Zangarmarsh", "Nagrand", "Blade's Edge Mountains",
                    "Netherstorm", "Terokkar Forest", "Shadowmoon Valley", "Isle of Quel'Danas"
                }
            },
            {
                name = L["Wrath Zones"] or "Wrath Zones",
                zones = {
                    "Borean Tundra", "Dragonblight", "Grizzly Hills", "Howling Fjord",
                    "Icecrown", "Sholazar Basin", "The Storm Peaks", "Zul'Drak", "Crystalsong Forest"
                }
            }
        }

        -- Добавляем зоны организованные по категориям
        for _, category in ipairs(zoneCategories) do
            -- Добавляем заголовок категории
            options["header_" .. category.name:gsub("[^%w]", "_")] = {
                type = "header",
                name = "|cFFFFD700" .. category.name .. "|r",
                order = order,
            }
            order = order + 1

            -- Добавляем зоны в этой категории
            for _, zoneName in ipairs(category.zones) do
                if zoneOverrides[zoneName] then
                    local safeZoneName = zoneName:gsub("[^%w]", "_") -- Делаем безопасным для ключа таблицы
                    local localizedZoneName = L[zoneName] or zoneName
                    local distance = zoneOverrides[zoneName]
                    local localizedDesc = string.format((L["Camera distance for %s (current: %d)"] or "Camera distance for %s (current: %d)"), localizedZoneName, distance)

                    options[safeZoneName] = {
                        type = "range",
                        name = localizedZoneName,
                        desc = localizedDesc,
                        min = 1, max = 50, step = 1, bigStep = 1,
                        order = order,
                        get = function() return MaxCamEnhanced.db.profile.autoDetectSettings.zoneOverrides[zoneName] end,
                        set = function(_, value)
                            MaxCamEnhanced.db.profile.autoDetectSettings.zoneOverrides[zoneName] = value
                            if MaxCamEnhanced.SaveSettings then
                                MaxCamEnhanced:SaveSettings()
                            end
                            if MaxCamEnhanced.db.profile.autoDetectDistance and MaxCamEnhanced.db.profile.enabled then
                                MaxCamEnhanced:ApplySettings()
                            end
                        end,
                    }
                    order = order + 1
                end
            end
        end
    end

    return options
end

local function createOptions()
    if options then
        return options
    end

    options = {
        type = "group",
        name = "MaxCamEnhanced",
        desc = L["Advanced camera distance control with configurable settings"] or "Advanced camera distance control with configurable settings",
        childGroups = "tab",
        args = {
            general = {
                type = "group",
                name = L["General"] or "General",
                order = 1,
                args = getGeneralOptions()
            },
            autoDetection = {
                type = "group",
                name = L["Auto-Detection"] or "Auto-Detection",
                order = 2,
                args = getAutoDetectionOptions()
            }
        }
    }
    return options
end

-- Функция инициализации конфигурации (вызывается после загрузки аддона)
function MaxCamEnhanced.InitializeConfig()
    if MaxCamEnhanced.configInitialized then
        return -- Предотвращаем дублирующую регистрацию
    end

    -- Убеждаемся что база данных инициализирована
    if not MaxCamEnhanced or not MaxCamEnhanced.db then
        -- Используем глобальную функцию RunAfter (как в LootLog)
        RunAfter(1, function()
            MaxCamEnhanced.InitializeConfig()
        end)
        return
    end

    -- Убеждаемся что AceConfig и AceConfigDialog доступны
    if not AceConfig or not AceConfigDialog then
        RunAfter(1, function()
            MaxCamEnhanced.InitializeConfig()
        end)
        return
    end

    local options = createOptions()

    -- Регистрируем только если еще не зарегистрированы
    local success, existing = pcall(AceConfig.GetOptionsTable, AceConfig, "MaxCamEnhanced")
    if not success or not existing then
        AceConfig:RegisterOptionsTable("MaxCamEnhanced", options)
        AceConfigDialog:AddToBlizOptions("MaxCamEnhanced", "MaxCamEnhanced")
    end

    -- Хукаем закрытие интерфейса чтобы применить настройки
    local originalHide = InterfaceOptionsFrame.Hide
    InterfaceOptionsFrame.Hide = function(self)
        -- Применяем настройки когда интерфейс закрывается
        if MaxCamEnhanced and MaxCamEnhanced.ApplySettings and MaxCamEnhanced.db.profile.enabled then
            MaxCamEnhanced:ApplySettings()
        end
        originalHide(self)
    end

    MaxCamEnhanced.configInitialized = true
end

-- Экспортируем таблицу опций для использования основным аддоном
function MaxCamEnhanced:GetOptionsTable()
    return createOptions()
end
