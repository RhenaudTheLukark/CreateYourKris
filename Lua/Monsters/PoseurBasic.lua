return function(newENV)
_ENV = newENV
----- DO NOT MODIFY ABOVE -----

-- A basic Enemy Entity script skeleton you can copy and modify for your own creations.
comments = { "Smells like the work of an enemy stand.", "Poseur is posing like his life depends on it.", "Poseur's limbs shouldn't be moving in this way." }
commands = { "Check", "Act 1", "Act 2", "Act 3" }
randomdialogue = { "It's working." }

AddAct("Check", "", 0)
AddAct("Act 1", "", 0)
AddAct("Act 2", "", 0)
AddAct("Act 3", "", 0)

name = "Poseur"
hp = 150
atk = 10
def = 2
dialogbubble = "DRBubble" -- See documentation for what bubbles you have available.
canspare = false
check = "Check message goes here."

-- CYK variables
mag = 9001            -- MAGIC stat of the enemy
targetType = "single" -- Specifies how many (or which) target(s) this enemy's bullets will target

-- Check the "Special Variables" page of the documentation to learn how to modify this mess
animations = {
    Hurt      = { { 0 },                                           1     , { next = "Idle" } },
    Idle      = { { 0, 1, 2, 3, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }, 1 / 15, { }               },
}

-- Triggered when a Player attacks (or misses) this enemy in the ATTACKING state
function HandleAttack(attacker, attackstatus)
    if attackstatus == -1 then
        -- Player pressed fight but didn't press Z afterwards
    else
        -- Player did actually attack
    end
end

-- Triggered when a Player uses an Act on this enemy.
-- You don't need an all-caps version of the act commands here.
function HandleCustomCommand(user, command)
    local text = { "" }
    if command == "Check" then
        BattleDialog({ name .. " - " .. atk .. " ATK " .. def .. " DEF\n" .. check })
    else
        BattleDialog({"Selected " .. command .. "." })
    end
end

----- DO NOT MODIFY BELOW -----
end