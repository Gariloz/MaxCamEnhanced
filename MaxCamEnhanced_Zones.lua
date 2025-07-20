-- База данных зон MaxCamEnhanced
-- Этот файл содержит все переопределения зон для автоматического определения расстояния камеры
-- Пользователи могут легко добавить свои зоны здесь следуя формату ниже
--
-- ========================================================================
-- КАК ДОБАВИТЬ СВОИ ЗОНЫ:
-- ========================================================================
-- 1. Найдите подходящую категорию ниже (рейды, подземелья, зоны и т.д.)
-- 2. Добавьте вашу зону используя этот формат: ["Название зоны"] = значение_расстояния,
-- 3. Сохраните файл и перезагрузите аддон (/reload)
-- 4. Ваша зона появится в интерфейсе Переопределения зон
--
-- ========================================================================
-- РЕКОМЕНДАЦИИ ПО РАССТОЯНИЯМ:
-- ========================================================================
-- Маленькие подземелья: 18-22    (тесные пространства, ближний бой)
-- Большие подземелья: 22-25    (большие комнаты, нужно больше места)
-- Маленькие рейды: 25-30       (рейды на 10 человек, умеренное пространство)
-- Большие рейды: 30-35       (рейды на 25 человек, нужен широкий обзор)
-- PvP зоны: 45-50         (нужна максимальная осведомленность)
-- Города: 25-30            (переполненные области, умеренное расстояние)
-- Стартовые зоны: 35       (открытые области, комфортный обзор)
-- Зоны высокого уровня: 40-45  (опасные области, нужен хороший обзор)
--
-- ========================================================================
-- ПРИМЕРЫ:
-- ========================================================================
-- ["Мое пользовательское подземелье"] = 22,
-- ["Специальная PvP область"] = 50,
-- ["Пользовательский рейд"] = 30,
--
-- Примечание: Названия зон должны точно совпадать с тем как они появляются в игре!
-- ========================================================================

-- База данных переопределений зон - будет загружена основным аддоном
local ZoneDatabase = {
    -- Классические рейды (40 человек)
    ["Molten Core"] = 30,
    ["Blackwing Lair"] = 35,
    ["Ahn'Qiraj Temple"] = 35,
    ["Ruins of Ahn'Qiraj"] = 30,

    -- Рейды Burning Crusade
    ["Karazhan"] = 30,
    ["Gruul's Lair"] = 30,
    ["Magtheridon's Lair"] = 25,
    ["Serpentshrine Cavern"] = 35,
    ["Tempest Keep"] = 30,
    ["The Eye"] = 30,
    ["Mount Hyjal"] = 35,
    ["Black Temple"] = 35,
    ["Sunwell Plateau"] = 30,

    -- Рейды Wrath of the Lich King
    ["Naxxramas"] = 30,
    ["The Obsidian Sanctum"] = 25,
    ["The Eye of Eternity"] = 25,
    ["Ulduar"] = 35,
    ["Trial of the Crusader"] = 25,
    ["Onyxia's Lair"] = 25,
    ["Icecrown Citadel"] = 30,
    ["The Ruby Sanctum"] = 25,

    -- Классические подземелья (5 человек)
    ["Ragefire Chasm"] = 20,
    ["The Deadmines"] = 20,
    ["Wailing Caverns"] = 20,
    ["Shadowfang Keep"] = 20,
    ["The Stockade"] = 18,
    ["Gnomeregan"] = 22,
    ["Scarlet Monastery"] = 20,
    ["Razorfen Kraul"] = 22,
    ["Razorfen Downs"] = 22,
    ["Uldaman"] = 25,
    ["Zul'Farrak"] = 25,
    ["Maraudon"] = 25,
    ["Temple of Atal'Hakkar"] = 22,
    ["Blackrock Depths"] = 25,
    ["Lower Blackrock Spire"] = 25,
    ["Upper Blackrock Spire"] = 25,
    ["Dire Maul"] = 25,
    ["Stratholme"] = 25,
    ["Scholomance"] = 22,

    -- Подземелья Burning Crusade (5 человек)
    ["Hellfire Ramparts"] = 20,
    ["The Blood Furnace"] = 20,
    ["The Slave Pens"] = 22,
    ["The Underbog"] = 22,
    ["Mana-Tombs"] = 20,
    ["Auchenai Crypts"] = 20,
    ["Sethekk Halls"] = 22,
    ["Shadow Labyrinth"] = 22,
    ["The Steamvault"] = 25,
    ["The Shattered Halls"] = 22,
    ["The Mechanar"] = 22,
    ["The Botanica"] = 22,
    ["The Arcatraz"] = 22,
    ["Old Hillsbrad Foothills"] = 25,
    ["The Black Morass"] = 25,
    ["Magisters' Terrace"] = 20,

    -- Подземелья Wrath of the Lich King (5 человек)
    ["Utgarde Keep"] = 22,
    ["The Nexus"] = 22,
    ["Azjol-Nerub"] = 20,
    ["Ahn'kahet: The Old Kingdom"] = 22,
    ["Drak'Tharon Keep"] = 22,
    ["The Violet Hold"] = 20,
    ["Gundrak"] = 22,
    ["Halls of Stone"] = 22,
    ["Halls of Lightning"] = 22,
    ["The Oculus"] = 25,
    ["Utgarde Pinnacle"] = 25,
    ["The Culling of Stratholme"] = 25,
    ["Trial of the Champion"] = 22,
    ["Forge of Souls"] = 20,
    ["Pit of Saron"] = 22,
    ["Halls of Reflection"] = 20,

    -- PvP зоны
    ["Wintergrasp"] = 50,
    ["Alterac Valley"] = 50,
    ["Arathi Basin"] = 45,
    ["Warsong Gulch"] = 45,

    -- Классические зоны - Стартовые области
    ["Elwynn Forest"] = 35,
    ["Dun Morogh"] = 35,
    ["Teldrassil"] = 35,
    ["Durotar"] = 35,
    ["Mulgore"] = 35,
    ["Tirisfal Glades"] = 35,

    -- Классические зоны - Низкий уровень
    ["Westfall"] = 35,
    ["Loch Modan"] = 35,
    ["Darkshore"] = 35,
    ["The Barrens"] = 40,
    ["Stonetalon Mountains"] = 35,
    ["Redridge Mountains"] = 35,
    ["Wetlands"] = 35,
    ["Ashenvale"] = 35,
    ["Thousand Needles"] = 40,
    ["Desolace"] = 40,
    ["Stranglethorn Vale"] = 40,
    ["Dustwallow Marsh"] = 35,
    ["Badlands"] = 35,
    ["Swamp of Sorrows"] = 35,
    ["Tanaris"] = 40,
    ["The Hinterlands"] = 35,
    ["Azshara"] = 40,
    ["Feralas"] = 40,
    ["Felwood"] = 35,
    ["Un'Goro Crater"] = 40,
    ["Silithus"] = 40,

    -- Классические зоны - Высокий уровень
    ["Blasted Lands"] = 35,
    ["Burning Steppes"] = 35,
    ["Western Plaguelands"] = 35,
    ["Eastern Plaguelands"] = 35,
    ["Winterspring"] = 40,
    ["Deadwind Pass"] = 35,

    -- Классические города
    ["Stormwind City"] = 25,
    ["Ironforge"] = 25,
    ["Darnassus"] = 25,
    ["Orgrimmar"] = 25,
    ["Thunder Bluff"] = 30,
    ["Undercity"] = 25,

    -- Зоны Burning Crusade
    ["Hellfire Peninsula"] = 40,
    ["Zangarmarsh"] = 35,
    ["Nagrand"] = 45,
    ["Blade's Edge Mountains"] = 40,
    ["Netherstorm"] = 40,
    ["Terokkar Forest"] = 35,
    ["Shadowmoon Valley"] = 40,
    ["Shattrath City"] = 25,

    -- Зоны Wrath of the Lich King
    ["Borean Tundra"] = 45,
    ["Dragonblight"] = 45,
    ["Grizzly Hills"] = 40,
    ["Howling Fjord"] = 40,
    ["Icecrown"] = 45,
    ["Sholazar Basin"] = 40,
    ["The Storm Peaks"] = 45,
    ["Zul'Drak"] = 40,
    ["Crystalsong Forest"] = 35,
    ["Dalaran"] = 25,

    -- Специальные зоны
    ["Isle of Quel'Danas"] = 35,
}

-- Экспортируем базу данных зон в глобальную область видимости для доступа основного аддона
_G["MaxCamEnhanced_ZoneDatabase"] = ZoneDatabase
