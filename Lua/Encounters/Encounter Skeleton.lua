require "Libraries/CYK/Util" -- NEEDED FOR CYK TO RUN

encountertext = "Welcome to Create Your Kris!\rFeel free to look around!" -- Modify as necessary. It will only be read out in the action select screen.

wavetimer = 4
arenasize = { 155, 130 }
arenapos = { 320, 200 }  -- Position of the middle of the bottom of the arena at the start of the next wave.

-- List of Players. Each Player added here must have a script with the same name in the mod's Lua/Players folder.
players = { "KrisBasic", "RalseiBasic" }
-- Position of each Player on the screen. It is made of tables with two values.
-- Each table contains an x value and a y value. These values move the bottom left corner of each Player's sprite.
playerpositions = {
    { 60, 350 },
    { 60, 230 }
}

-- List of enemies. Each enemy added here must have a script with the same name in the mod's Lua/Monsters folder.
enemies = { "PoseurBasic" }
-- Position of each enemy on the screen. It is made of tables with two values.
-- Each table contains an x value and a y value. These values move the bottom left corner of each enemy's sprite.
enemypositions = {
    { 500, 260 },
}

-- unescape = false -- Uncomment me to remove the pesky QUITTING text when trying to exit the encounter!

-- CYK's debug level:
-- 0- = No warning
-- 1  = Important warnings
-- 2  = All warnings
-- 3+ = All debug messages
CYKDebugLevel = 0

-- A custom list with attacks to choose from. Actual selection happens in EnemyDialogueEnding(). Put here in case you want to use it.
possible_attacks = { "bullettest_bouncy", "bullettest_touhou", "bullettest_chaserorb" }
nextwaves = { "bullettest_bouncy" }

-- Function called at the very beginning of the encounter.
function EncounterStarting()
    -- Set the player's inventory up here!
end

-- Function called after the enemies have spoken, before entering a wave
function EnemyDialogueEnding()
    -- Good location for setting the wave which is going to be used in the next enemy attack
    nextwaves = { possible_attacks[math.random(1, #possible_attacks)] }
end

-- Function called after the defense round ends
function DefenseEnding()
    encountertext = RandomEncounterText()
end

require "Libraries/CYK/CYKPreProcessing"  -- NEEDED FOR CYK TO RUN