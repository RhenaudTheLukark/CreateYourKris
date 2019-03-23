return function(newENV)
_ENV = newENV
----- DO NOT MODIFY ABOVE -----

-- A basic Enemy Entity script skeleton you can copy and modify for your own creations.
comments = { "Smells like the work of an enemy stand.", "Poseur is posing like his life depends on it.", "Poseur's limbs shouldn't be moving in this way." }
commands = { "Check", "Talk", "Flirt", "Pose", "Working?" }
randomdialogue = {
    { "Check it out.",            "Please"                     },
    { "Check it out again.",      "...",      "For real now"   },
    { "I'll show you something.", "Trust me."                  },
    { "Keep looking!",            "Harder!",  "I SAID HARDER!" },
      "It's working."
}

AddAct("Check", "", 0)
AddAct("Talk", "Little chit-chat", 0)
AddAct("Flirt", "Seduce the enemy", 0, { "Kris" })
AddAct("Pose", "Show him who's cool!", 5, { "Ralsei" })
AddAct("Working?", "Is this working?", 50, { "Ralsei" })

hp = 250
atk = 10
def = 2
dialogbubble = "DRBubble" -- See documentation for what bubbles you have available.
canspare = false
check = "Check message goes here."

-- CYK variables
mag = 9001            -- MAGIC stat of the enemy
targetType = "single" -- Specifies how many (or which) target(s) this enemy's bullets will target
tired = false         -- If true, the Player will be able to spare this enemy using the spell "Pacify"

-- Check the "Special Variables" page of the documentation to learn how to modify this mess
animations = {
    Hurt      = { { 0 },                                           1     , { next = "Idle" }, true },
    Idle      = { { 0, 1, 2, 3, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }, 1 / 15, { }              , true },
    Spareable = { { 0, 1, 2, 3, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }, 1 / 15, { }              , true },
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
    if currentdialogue == nil then
        currentdialogue = { }
    end

    if attackstatus == -1 then
        -- Player pressed fight but didn't press Z afterwards
        table.insert(currentdialogue, "Do no harm, " .. attacker.name .. ".\n")
    else
        -- Player did actually attack
        if attackstatus < 50 then
            table.insert(currentdialogue, "You're strong, " .. attacker.name .. "!\n")
        else
            table.insert(currentdialogue, "Too strong, " .. attacker.name .. "...\n")
        end
    end
end

posecount = 0

-- Triggered when a Player uses an Act on this enemy.
-- You don't need an all-caps version of the act commands here.
function HandleCustomCommand(user, command)
    local text = { "" }
    if command == "Check" then
        text = { name .. " - " .. atk .. " ATK " .. def .. " DEF\n" .. check }
    elseif command == "Talk" then
        if not tired then
            table.insert(comments, "Poseur has trouble staying up.")
        end
        tired = true
        currentdialogue = {"... *yawns*"}
        text = {"You try to talk with Poseur, but all you seem to be able to do is make him yawn."}
    elseif command == "Flirt" then
        currentdialogue = {"Thank you."}
        text = {"You tell Poseur you like his hairstyle.\nHe doesn't seem to mind."}
    elseif command == "Pose" then
        if posecount == 0 then
            currentdialogue = {"Not bad."}
            text = {"You posed dramatically."}
        elseif posecount == 1 then
            currentdialogue = {"Not bad at all...!"}
            text = {"You posed even more dramatically."}
        else
            if not canspare then
                table.insert(comments, "Poseur is impressed by your posing power.")
            end
            currentdialogue = {"That's it...!"}
            text = {"You posed so dramatically your anatomy became incorrect."}
            canspare = true
            SetCYKAnimation("Idle") -- Refresh the animation
        end
        posecount = posecount + 1
    elseif command == "Working?" then
        currentdialogue = {"Good one."}
        text = {"Is this working?", "[func:SetFaceSprite,Players.Ralsei.Mad][voice:v_ralsei]IT'S WORKING!!!", "Poseur smiles and seems to calm down."}
        canspare = true
        SetCYKAnimation("Idle") -- refresh the animation
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