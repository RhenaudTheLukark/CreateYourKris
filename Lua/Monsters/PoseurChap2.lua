return function(newENV)
_ENV = newENV
----- DO NOT MODIFY ABOVE -----

-- A basic Enemy Entity script skeleton you can copy and modify for your own creations.
comments = { "Smells like the work of an enemy stand.", "Poseur is posing like his life depends on it.", "Poseur's limbs shouldn't be moving in this way." }
--commands = { "Check", "Talk", "Warning", "Flirt", "Pose" }
commands = { "Check", "Talk", "Pose", "MegaPose"}
randomdialogue = {
    { "Check it out.",            "Please"                     },
    { "Check it out again.",      "...",      "For real now"   },
    { "I'll show you something.", "Trust me."                  },
    { "Keep looking!",            "Harder!",  "I SAID HARDER!" },
      "It's working."
}

AddAct("Check", "", 0)
AddAct("Talk", "Little chit-chat", 0)
AddAct("Pose", "Show him who's cool!", 5, { "Ralsei" })
AddAct("MegaPose", "Menacing coolness", 10, { "Ralsei", "Susie" })

name = "Poseur"
hp = 250
atk = 10
def = 2
dialogbubble = "DRBubble" -- See documentation for what bubbles you have available.
useMercyCounter=true
check = "Check message goes here."
isTiredWhenHPLow=true

-- CYK variables
mag = 9001            -- MAGIC stat of the enemy
targetType = "all" -- Specifies how many (or which) target(s) this enemy's bullets will target
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
SetGlobal("megaposecount", 0)

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
        ChangeMercyPercent(10)
    elseif command == "Flirt" then
        currentdialogue = {"Thank you."}
        text = {"You tell Poseur you like his hairstyle.\nHe doesn't seem to mind."}
        ChangeMercyPercent(10, true, "All")
    elseif command == "Pose" then
        if posecount == 0 then
            currentdialogue = {"Not bad."}
            text = {"You posed dramatically."}
            ChangeMercyPercent(10)
        elseif posecount == 1 then
            currentdialogue = {"Not bad at all...!"}
            text = {"You posed even more dramatically."}
            ChangeMercyPercent(20)
        else
            if GetMercyPercent()~=100 then
                table.insert(comments, "Poseur is impressed by your posing power.")
            end
            ChangeMercyPercent(100)
            currentdialogue = {"That's it...!"}
            text = {"You posed so dramatically your anatomy became incorrect."}
            SetCYKAnimation("Idle") -- Refresh the animation
        end
        posecount = posecount + 1
    elseif command == "MegaPose" then
        local megaposecount = GetGlobal("megaposecount")
        if megaposecount==0 then
            ChangeMercyPercent(30, "All", true, true)
            text = {"Kris almost broke his arm trying to pose!","All Poseurs are impressed!"}
            CYK.enemies[1]["currentdialogue"]={"Good job Kris"}
            CYK.enemies[2]["currentdialogue"]={"Nice Kris"}
            CYK.enemies[3]["currentdialogue"]={"Wow Kris"}
            SetCYKAnimation("Idle") -- refresh the animation
        elseif megaposecount==1 then
            ChangeMercyPercent(40, "All", true, true)
            CYK.enemies[1]["currentdialogue"]={"Your head is cool, Susie"}
            CYK.enemies[2]["currentdialogue"]={"Soon Susie, soon..."}
            CYK.enemies[3]["currentdialogue"]={"If reminds me of when I first posed.","[noskip]I mean...[w:10][next]","Cool Susie"}
            text = {"Susie fell head first while trying to pose!", "The Poseurs thought it was voluntary and applaud (while continuing to pose)."}
        elseif megaposecount==2 then
            ChangeMercyPercent(-30, "All", true, true)
            CYK.enemies[1]["currentdialogue"]={"Ouch Ralsei"}
            CYK.enemies[2]["currentdialogue"]={"It comes with time Ralsei"}
            CYK.enemies[3]["currentdialogue"]={"...Ralsei"}
            text = {"Ralsei slipped on his scarf trying to pose!", "The Poseurs respect the fact that he tried but weren't impressed at all."}
        elseif megaposecount==3 then
            ChangeMercyPercent(100, "All", true, true)
            CYK.enemies[1]["currentdialogue"]={"OH"}
            CYK.enemies[2]["currentdialogue"]={"", "NOOOOOOOOOO"}
            CYK.enemies[3]["currentdialogue"]={"", "", "OOOOOOOOOOOOOOOO"}
            text = {"You three together do the ultimate pose and assert your dominance!", "The Poseurs can't resist your coolness!"}
        else
            text = {"[func:SetFaceSprite, Players.Susie.Mad2][voice:v_susie]Kris, if you make me do that AGAIN...","Oddly, you decide not to do it again."}
        end
        SetGlobal("megaposecount",megaposecount+1)
    end
    BattleDialog(text)
end

-- Function called whenever this entity's animation is changed.
-- Make it return true if you want the animation to be changed like normal, otherwise do your own stuff here!
function HandleAnimationChange(newAnim)
    local oldAnim = self.sprite["currAnim"]
    if (chapter2 and GetMercyPercent()>=100) or (not chapter2 and canspare) then
        if newAnim == "Idle" then
            SetCYKAnimation("Spareable")
            return false
        end
    end
end

----- DO NOT MODIFY BELOW -----
end