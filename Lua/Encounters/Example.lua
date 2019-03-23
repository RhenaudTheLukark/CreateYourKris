require "Libraries/CYK/Util" -- NEEDED FOR CYK TO RUN

encountertext = "Is this Undertale? I think not..." -- Modify as necessary. It will only be read out in the action select screen.

wavetimer = 4
arenasize = { 155, 130 }
arenapos = { 320, 200 }  -- Position of the middle of the bottom of the arena at the start of the next wave.
arenacolor = { 0, 1, 0 } -- Color of the sides of the at the start of the next wave.
arenarotation = 0        -- Rotation of the arena at the start of the wave.
autolinebreak = true     -- Returns the text to the next line if it goes past a text object's boundary.

-- List of Players. Each Player added here must have a script with the same name in the mod's Lua/Players folder.
players = { "Kris", "Susie", "Ralsei" }
-- Position of each Player on the screen. It is made of tables with two values.
-- Each table contains an x value and a y value. These values move the bottom left corner of each Player's sprite.
playerpositions = {
    { 60, 350 },
    { -2, 256 },
    { 60, 174 }
}

-- List of enemies. Each enemy added here must have a script with the same name in the mod's Lua/Monsters folder.
enemies = { "Poseur", "Poseur", "Poseur" }
-- Position of each enemy on the screen. It is made of tables with two values.
-- Each table contains an x value and a y value. These values move the bottom left corner of each enemy's sprite.
enemypositions = {
    { 540, 320 },
    { 520, 250 },
    { 500, 180 }
}

-- unescape = false -- Uncomment me to remove the pesky QUITTING text when trying to exit the encounter!

-- Preloads all of CYK's animations to reduce loading times in-game, at the price of an increasing loading time at the start of the encounter
preloadAnimations = true

-- CYK's debug level:
-- 0- = No warning
-- 1  = Important warnings
-- 2  = All warnings
-- 3+ = All debug messages
CYKDebugLevel = 0

-- Characters used to display thie players' UI sprite in the font uidialog
-- Here, I used cyrillic characters as they are not used in English
fontCharUsedForPlayer = { Kris = "Ђ", Susie = "Ѓ", Ralsei = "Є", Ieslar = "Љ", KRISP = "Њ", ZOOZIE = "Ћ" }
fontCharUsedForPlayer["2FPEST"] = "Ќ"

background = true     -- Set this variable to false to disable CYK's background
backgroundfade = true -- Set this variable to false to disable the fade effect on the background when entering a wave

-- A custom list with attacks to choose from. Actual selection happens in EnemyDialogueEnding(). Put here in case you want to use it.
possible_attacks = { "bullettest_bouncy", "bullettest_touhou", "bullettest_chaserorb" }
nextwaves = { "bullettest_bouncy" }

function EncounterStarting()
    -- Add the items one by one then set the player's inventory
    Inventory.AddCustomItem("Test", "Test Item", 0, "AllPlayer")
    Inventory.AddCustomItem("Test2", "Another Test Item", 1, "AllPlayer")
    Inventory.AddCustomItem("Bandage", "Used Before\nHeals 20HP", 0, "Player")
    Inventory.AddCustomItem("Nut", "Heals 20HP to Team.", 0, "AllPlayer")
    Inventory.AddCustomItem("Rock", "Throwable Weapon\nDeals 5DMG", 0, "Enemy")
    Inventory.AddCustomItem("Manual", "Very Useful and Cute", 1, "AllEnemy")

    Inventory.SetInventory({ "Test", "Test2", "Manual", "Bandage", "Nut", "Rock", "Bandage" })
end

-- Function called once per frame
function Update() end

-- Function called whenever the enemies are about to speak
function EnemyDialogueStarting()
    -- Good location for setting the targets of the enemies
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

-- Function called whenever a Player spares an enemy
-- Can be called several times per turn
function HandleSpare(player, enemy) end

-- Function called whenever the state of CYK changes
-- Can be called inside itself if State() is called within EnteringState()!
function EnteringState(newstate, oldstate) end

-- This function handles the items' effects!
function HandleItem(user, targets, itemID, itemData)
    if itemID == "Test" then
        BattleDialog({"This is a test of a normal item.[w:10] It should disappear from your bag.[w:10] The test succeeded!"})
    elseif itemID == "Test2" then
        BattleDialog({"This is a test of a persistent item.[w:10] If it succeeded, the item must still be in the inventory!"})
    elseif itemID == "Bandage" then
        targets[1].Heal(20)
        BattleDialog({ targets[1].name .. " reapplied the bandage.[w:10]\nThey regain 20 HP!" })
    elseif itemID == "Nut" then
        for i = 1, #targets do
            targets[i].Heal(20)
        end
        BattleDialog({"The team splits the Nut apart and eat a part each.[w:10]\nEveryone regain 20 HP!"})
    elseif itemID == "Rock" then
        targets[1].Hurt(5, user)
        BattleDialog({ user.name .. " throws the Rock at " .. targets[1].name .. ".[w:10]\nIt collides![w:10] " .. targets[1].name .. " loses 5 HP!"})
    elseif itemID == "Manual" then
        local text = { user.name .. " reads the Manual." }
        for i = 1, #targets do
            -- You can call enemy / Player entity files functions like so:
            --targets[i].UseItem(itemID)
        end
        BattleDialog(text)
    end
end

local gameOverCount = 0
function OnGameOver()
    if gameOverCount == 0 then
        State("NONE")
        Audio.Pause()
        BattleDialog({ "[noskip]Your consciousness fades...",
                       "[noskip][waitall:5].....[waitall:1]But suddenly, [w:20]an unknown energy invades your SOUL!",
                       "[noskip][func:Revive]Kris regains 1 HP!",
                       "[noskip]But you feel like you won't be this lucky next time...",
                       "[noskip][func:State, { ACTIONSELECT, 1 }]"})
        gameOverCount = gameOverCount + 1
        return false
    end
end

function Revive()
    players[1].Heal(players[1].maxhp)
    players[1].hp = 1
    players[1].UpdateUI()
    Audio.Unpause()
end

require "Libraries/CYK/CYKPreProcessing"  -- NEEDED FOR CYK TO RUN