require "Libraries/CYK/Util" -- NEEDED FOR CYK TO RUN

encountertext = "NO OONDARTEL??? WAT???" -- Modify as necessary. It will only be read out in the action select screen.

wavetimer = 4
arenasize = { 155, 130 }
arenapos = { 320, 200 } -- Position of the middle of the bottom of the arena on the next wave.
arenarotation = 0       -- Rotation of the arena at the start of the wave.
autilinebreak = true

-- List of Players. Each Player added here must have a script with the same name in the mod's Lua/Monsters/Players folder.
players = { "KRISP", "ZOOZIE", "2FPEST" }
-- Position of each Player on the screen. It is made of tables with two values.
-- Each table contains an x value and a y value. These values move the bottom left corner of each Player's sprite.
playerpositions = {
    { 60, 350 },
    { -2, 256 },
    { 60, 174 }
}

-- List of enemies. Each enemy added here must have a script with the same name in the mod's Lua/Monsters/Monsters folder.
enemies = { "WITE JOJO", "WITE JOJO", "WITE JOJO", "WITE JOJO" }
-- Position of each enemy on the screen. It is made of tables with two values.
-- Each table contains an x value and a y value. These values move the bottom left corner of each enemy's sprite.
enemypositions = {
    { 530, 320 },
    { 490, 260 },
    { 550, 240 },
    { 510, 180 }
}

-- unescape = false -- Uncomment me to remove the pesky QUITTING text when trying to exit the encounter!

-- CYK's debug level:
-- 0- = No warning
-- 1  = Important warnings
-- 2  = All warnings
-- 3+ = All debug messages
CYKDebugLevel = 0

-- Preloads all of CYK's animations to reduce loading times in-game, at the price of an increasing loading time at the start of the encounter
preloadAnimations = true

CrateYourKris = true --???

-- Characters used to display thie players' UI sprite in the font uidialog
fontCharUsedForPlayer = { Kris = "Ђ", Susie = "Ѓ", Ralsei = "Є", Ieslar = "Љ", KRISP = "Њ", ZOOZIE = "Ћ" }
fontCharUsedForPlayer["2FPEST"] = "Ќ"

-- A custom list with attacks to choose from. Actual selection happens in EnemyDialogueEnding(). Put here in case you want to use it.
possible_attacks = { "bullettest_bouncy", "bullettest_touhou", "bullettest_chaserorb" }
nextwaves = { "bullettest_bouncy" }

function EncounterStarting()
    -- Inventory.AddCustomItem(name, description, type, targetType)
    -- Adds a usable item. If an item is not added, it'll trigger an error when trying to display it on the ITEM command menu.
    -- Arguments:
    --    name        - Name of the item. Must be a string.
    --    description - Description of the item. Must be a short string! Add "\n" to get to the next line.
    --    type        - Type of the item. 0 = Used once then disappears, 1 = Used infinitely.
    --    targetType  - Can be Player, Enemy, AllPlayer or AllEnemy. Chooses if the target of this item is a Player, an enemy, all the Players or all the enemies.
    Inventory.AddCustomItem("TSET", "TSET TEM", 0, "AllPlayer")
    Inventory.AddCustomItem("TSET2", "OTTER TSET TEM", 1, "AllPlayer")
    Inventory.AddCustomItem("KOOL-AID", "YUZD B4! +02PH", 0, "Player")
    Inventory.AddCustomItem("TUN", "+02PH 2 EVRY1!!!", 0, "AllPlayer")
    Inventory.AddCustomItem("ROK", "TRO IT! 5MGD 2 ENMY", 0, "Enemy")
    Inventory.AddCustomItem("MANUL", "OOZFUL N KYOOT!", 1, "AllEnemy")

    Inventory.SetInventory({ "TSET", "TSET2", "MANUL", "KOOL-AID", "TUN", "ROK", "KOOL-AID" })
end

-- Function launched once per frame
function Update() end

-- Function called whenever the enemies are about to speak
function EnemyDialogueStarting()
    -- Good location for setting the targets of the enemies
end

-- Function called after the enemies spoke
function EnemyDialogueEnding()
    -- Good location for setting the wave which is going to be used in the next enemy attack
    nextwaves = { possible_attacks[math.random(1, #possible_attacks)] }
end

-- Function called after the defense round ends
function DefenseEnding()
    encountertext = RandomEncounterText()
end

-- Function called whenever a Player spares an enemy. Can be called several times per turn.
function HandleSpare(player, enemy) end

-- Function called whenever the state of CYK changes
-- Can be launched inside itself if State() is called while in EnteringState!
function EnteringState(newstate, oldstate) end

-- This function handles the items' effects!
function HandleItem(user, targets, itemID, itemData)
    if itemID == "TSET" then
        BattleDialog({"TSETYTSET! NO HERE ANIMOR!"})
    elseif itemID == "TSET2" then
        BattleDialog({"STAY TSETYTSET! SITLL HERE!"})
        return
    elseif itemID == "KOOL-AID" then
        targets[1].Heal(20)
        BattleDialog({ targets[1].name .. " DID KOOL-AID! +02PH!" })
    elseif itemID == "TUN" then
        for i = 1, #targets do
            targets[i].Heal(20)
        end
        BattleDialog({"TUN PARTZ! +02HP 2 EVRY1!!!"})
    elseif itemID == "ROK" then
        targets[1].Hurt(5, user)
        BattleDialog({ user.name .. " TRON ROK AT " .. targets[1].name .. "! OUCHIE OUCH! " .. targets[1].name .. " HAZ -5PH!"})
    elseif itemID == "MANUL" then
        local text = { user.name .. " REEDZ BUUK!" }
        for i = 1, #targets do
            -- You can call enemy (or Players) Entity files functions like so:
            --targets[i].UseItem(itemID)
        end
        BattleDialog(text)
    end
end

require "Libraries/CYK/CYKPreProcessing"  -- NEEDED FOR CYK TO RUN