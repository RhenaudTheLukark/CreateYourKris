return function(newENV)
_ENV = newENV
----- DO NOT MODIFY ABOVE -----

-- A basic Enemy Entity script skeleton you can copy and modify for your own creations.
comments = { "ENMEY SATND!", "LEIF POZEZ.", "AMRS FUNNEH." }
commands = { "CEHCK", "AKT1", "AKT2", "AKT3", "AKT4", "AKT5", "AKT6" }
randomdialogue = {
    { "NOCIE SUTF.", "PLS"                  },
    { "SEE.",        "...",    "PLSSSS"     },
    { "HREE.",       "AM GUD."              },
    { "LOKO!",       "MOAR!",  "MOAAAAAAR!" },
      "WROKS!"
}

AddAct("CEHCK", "", 0)
AddAct("AKT1", "", 0)
AddAct("AKT2", "", 0, { "ZOOZIE" })
AddAct("AKT3", "", 0, { "2FPEST" })
AddAct("AKT4", "", 0, { "Ieslar" })
AddAct("AKT5", "", 0, { "ZOOZIE", "2FPEST" })
AddAct("AKT6", "MANI AKTS!!!", 0)

hp = 250
atk = 10
def = 2
check = "CKECH HREE!"
dialogbubble = "DRBubble" -- See documentation for what bubbles you have available.
canspare = false
cancheck = true

-- CYK variables
mag = 9001            -- MAGIC stat of the enemy
targetType = "all"    -- Specifies how many (or which) target(s) this enemy's bullets will target
tired = false         -- If true, the Player will be able to spare this enemy using the spell "Pacify"

animations = {
    Hurt      = { { 0 }, 1, { next = "Idle" } },
    Idle      = { { 0 }, 1, { }               },
    Spareable = { { 0 }, 1, { }               },
}

-- Triggered just before computing an attack on this target
function BeforeDamageCalculation(attacker, damageCoeff)
    -- Good location to set the damage dealt to this enemy using self.SetDamage()
    if damageCoeff > 0 then
        --SetDamage(666)
    end
end

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
    if command == "CEHCK" then
        text = { name .. " - " .. atk .. " AKT " .. def .. " FED\n" .. check }
    elseif command == "AKT1" then
        currentdialogue = {"AKT1 IN!"}
        text = {"AKT1 IN!", "WOW!!!"}
    elseif command == "AKT2" then
        currentdialogue = {"AKT2 IN!"}
        text = {"AKT2 IN!"}
    elseif command == "AKT3" then
        currentdialogue = {"AKT3 IN!"}
        text = {"AKT3 IN!"}
    elseif command == "AKT4" then
        currentdialogue = {"AKT4 IN!"}
        text = {"AKT4 IN!"}
    elseif command == "AKT5" then
        currentdialogue = {"AKT5 IN!"}
        text = {"AKT5 IN!"}
    elseif command == "AKT6" then
        currentdialogue = {"AKT6 IN!"}
        text = {"AKT6 IN!"}
    end
    BattleDialog(text)
end

-- Function called whenever this entity's animation is changed.
-- Make it return true if you want the animation to be changed like normal, otherwise do your own stuff here!
function HandleAnimationChange(newAnim)
    local oldAnim = self.sprite["currAnim"]
    if newAnim == "Idle" and canspare then
        SetCYKAnimation("Spareable")
        return false
    end
end

----- DO NOT MODIFY BELOW -----
end