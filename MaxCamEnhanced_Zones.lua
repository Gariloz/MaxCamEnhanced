-- MaxCamEnhanced Zone Database
-- This file contains all zone overrides for automatic camera distance detection
-- Users can easily add their own zones here by following the format below
--
-- ========================================================================
-- HOW TO ADD YOUR OWN ZONES:
-- ========================================================================
-- 1. Find the appropriate category below (raids, dungeons, zones, etc.)
-- 2. Add your zone using this format: ["Zone Name"] = distance_value,
-- 3. Save the file and reload the addon (/reload)
-- 4. Your zone will appear in the Zone Overrides interface
--
-- ========================================================================
-- DISTANCE RECOMMENDATIONS:
-- ========================================================================
-- Small dungeons: 18-22    (tight spaces, close combat)
-- Large dungeons: 22-25    (bigger rooms, more space needed)
-- Small raids: 25-30       (10-man raids, moderate space)
-- Large raids: 30-35       (25-man raids, need wide view)
-- PvP zones: 45-50         (maximum awareness needed)
-- Cities: 25-30            (crowded areas, moderate distance)
-- Starting zones: 35       (open areas, comfortable view)
-- High-level zones: 40-45  (dangerous areas, need good view)
--
-- ========================================================================
-- EXAMPLES:
-- ========================================================================
-- ["My Custom Dungeon"] = 22,
-- ["Special PvP Area"] = 50,
-- ["Custom Raid"] = 30,
--
-- Note: Zone names must match exactly as they appear in-game!
-- ========================================================================

-- Zone override database - will be loaded by the main addon
local ZoneDatabase = {
    -- Classic Raids (40-man)
    ["Molten Core"] = 30,
    ["Blackwing Lair"] = 35,
    ["Ahn'Qiraj Temple"] = 35,
    ["Ruins of Ahn'Qiraj"] = 30,

    -- Burning Crusade Raids
    ["Karazhan"] = 30,
    ["Gruul's Lair"] = 30,
    ["Magtheridon's Lair"] = 25,
    ["Serpentshrine Cavern"] = 35,
    ["Tempest Keep"] = 30,
    ["The Eye"] = 30,
    ["Mount Hyjal"] = 35,
    ["Black Temple"] = 35,
    ["Sunwell Plateau"] = 30,

    -- Wrath of the Lich King Raids
    ["Naxxramas"] = 30,
    ["The Obsidian Sanctum"] = 25,
    ["The Eye of Eternity"] = 25,
    ["Ulduar"] = 35,
    ["Trial of the Crusader"] = 25,
    ["Onyxia's Lair"] = 25,
    ["Icecrown Citadel"] = 30,
    ["The Ruby Sanctum"] = 25,

    -- Classic Dungeons (5-man)
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

    -- Burning Crusade Dungeons (5-man)
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

    -- Wrath of the Lich King Dungeons (5-man)
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

    -- PvP Zones
    ["Wintergrasp"] = 50,
    ["Alterac Valley"] = 50,
    ["Arathi Basin"] = 45,
    ["Warsong Gulch"] = 45,

    -- Classic Zones - Starting Areas
    ["Elwynn Forest"] = 35,
    ["Dun Morogh"] = 35,
    ["Teldrassil"] = 35,
    ["Durotar"] = 35,
    ["Mulgore"] = 35,
    ["Tirisfal Glades"] = 35,

    -- Classic Zones - Low Level
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

    -- Classic Zones - High Level
    ["Blasted Lands"] = 35,
    ["Burning Steppes"] = 35,
    ["Western Plaguelands"] = 35,
    ["Eastern Plaguelands"] = 35,
    ["Winterspring"] = 40,
    ["Deadwind Pass"] = 35,

    -- Classic Cities
    ["Stormwind City"] = 25,
    ["Ironforge"] = 25,
    ["Darnassus"] = 25,
    ["Orgrimmar"] = 25,
    ["Thunder Bluff"] = 30,
    ["Undercity"] = 25,

    -- Burning Crusade Zones
    ["Hellfire Peninsula"] = 40,
    ["Zangarmarsh"] = 35,
    ["Nagrand"] = 45,
    ["Blade's Edge Mountains"] = 40,
    ["Netherstorm"] = 40,
    ["Terokkar Forest"] = 35,
    ["Shadowmoon Valley"] = 40,
    ["Shattrath City"] = 25,

    -- Wrath of the Lich King Zones
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

    -- Special Zones
    ["Isle of Quel'Danas"] = 35,
}

-- Export the zone database to global scope for the main addon to access
_G["MaxCamEnhanced_ZoneDatabase"] = ZoneDatabase
