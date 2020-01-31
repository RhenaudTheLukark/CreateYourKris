return function(newENV)
_ENV = newENV
----- DO NOT MODIFY ABOVE -----

hp = 110
atk = 14
def = 2

-- CYK variables
mag = 1                                      -- MAGIC stat of the Player
powers = { "ROOD", "CROOD", "GOOTS" }        -- Powers of the Player (Unused)
abilities = { "ROOD BOSTOR" }                -- Abilities of the Player. If the Player has "Act", he won't be able to use spells!
playerColor = { 1, 0, 1 }                    -- Color used in this Player's main UI
atkBarColor = { .5, 0, .5 }                  -- Color used in this Player's atk bar
damageColor = { 234/255,  121/255, 200/255 } -- Color used in this Player's damage text

-- Check the "Special Variables" page of the documentation to learn how to modify this mess
AddSpell("ROOD BOSTOR", "ROOD ADMAG", 50, "Enemy")

animations = {
    RudeBuster =    { { 0, 1, 2, 3 }, 2 / 15, { next = "Idle" },        },
    Down =          { { 0 },          1,      { loop = "ONESHOT" },     },
    Fight =         { { 0, 1, 2, 3 }, 2 / 15, { loop = "ONESHOT" }      },
    Hurt =          { { 0 },          1,      { next = "Idle" },        },
    Idle =          { { 0, 1 },       1 / 15, { },                      },
    Spare =         { { 0 },          1,      { next = "Idle" }         },
    SliceAnim =     { { 0, 1, 2, 3 }, 2 / 15, { loop = "ONESHOTEMPTY" } },
}

rudeBusterStartFrame = -1
rudeBusters = { }
rudeBusterActive = false
rudeBusterAttacked = false
function UpdateTurn(frame, absoluteFrame)
    if action == "Magic" and subAction == "ROOD BOSTOR" or rudeBusterActive then
        if frame == 0 then
            rudeBusterStartFrame = -1
            rudeBusterAttacked = false
            rudeBusterActive = true
            SetCYKAnimation("RudeBuster")
        end
        if sprite.currentframe >= 2 and rudeBusterStartFrame == -1 then
            rudeBusterStartFrame = absoluteFrame
            Audio.PlaySound("rudebusterswing")
        end

        if rudeBusterStartFrame > -1 then
            if absoluteFrame - rudeBusterStartFrame < 20 then
                if (absoluteFrame - rudeBusterStartFrame) % 2 == 0 then
                    local num = (absoluteFrame - rudeBusterStartFrame) / 2
                    local startX = sprite.absx + 3 * sprite.width / 4
                    local startY = sprite.absy + sprite.height / 4
                    local shiftX = num / 10 * ((target.sprite.absx + target.sprite.width / 2) - startX)
                    local shiftY = (num / 10 * ((target.sprite.absy + target.sprite.height / 2) - startY)) - 20 * math.cos(math.rad(84 - num * 18))
                    local currPos = { x = startX + shiftX, y = startY + shiftY }
                    local rudeBuster = CreateSprite("RudeBuster/6", "Entity")
                    rudeBuster.SetPivot(1, 0.5)
                    rudeBuster.absx = currPos.x
                    rudeBuster.absy = currPos.y
                    rudeBuster.Scale(2, 2)
                    rudeBuster["startFrame"] = absoluteFrame
                    table.insert(rudeBusters, rudeBuster)
                    num = num + 1
                    shiftX = num / 10 * ((target.sprite.absx + target.sprite.width / 2) - startX)
                    shiftY = (num / 10 * ((target.sprite.absy + target.sprite.height / 2) - startY)) - 20 * math.cos(math.rad(84 - num * 18))
                    rudeBuster.rotation = math.deg(math.atan2(startY + shiftY - currPos.y, startX + shiftX - currPos.x))
                end
            elseif absoluteFrame - rudeBusterStartFrame == 20 then
                for i = 1, 8 do
                    local rudeBuster = CreateSprite("RudeBuster/6", "Entity")
                    rudeBuster.absx = target.sprite.absx + target.sprite.width/2 + ((i > 2 and i < 7) and -30 or 30)
                    rudeBuster.absy = target.sprite.absy + target.sprite.height/2 + (i <= 5 and -30 or 30)
                    rudeBuster.rotation = 45 + 90 * math.floor((i - 1) / 2)
                    rudeBuster.Scale(2, 2)
                    rudeBuster["startFrame"] = absoluteFrame
                    rudeBuster["hit"] = true
                    rudeBuster["hitPlus"] = i % 2 == 0
                    table.insert(rudeBusters, rudeBuster)
                end
                Attack(target, 1.5)
                rudeBusterAttacked = true
            end
        end

        if rudeBusterAttacked and Input.Confirm == 1 then
            if #rudeBusters == 0 then
                rudeBusterActive = false
            end
            EndPlayerTurn()
        end

        for i = #rudeBusters, 1, -1 do
            local rB = rudeBusters[i]
            local frame = absoluteFrame - rB["startFrame"]
            if rB["hit"] then
                local rot = math.rad(rB.rotation)
                local coeff = 5 * (1 - frame / 30) * (rB["hitPlus"] and 1.1 or 1)
                rB.Move(math.cos(rot) * coeff, math.sin(rot) * coeff)
                rB.xscale = rB.xscale * .9
            else
                rB.yscale = rB.yscale - 0.05
            end
            if frame == 30 then
                rB.Remove()
                table.remove(rudeBusters, i)
                if #rudeBusters == 0 and not rudeBusterAttacked then
                    rudeBusterActive = false
                end
                rB = nil
            elseif frame > 24 then
                rB.alpha = 1 - (24 - frame) / 6
            elseif frame % 4 == 0 then
                rB.Set("RudeBuster/" .. tostring(6 - frame / 4))
            end
        end
    end
end

-- Started when this Player casts a spell through the MAGIC command
-- The first local variables are here to help you know what is what
function HandleCustomSpell(target, spell)
    local spellData = CYK.spells[spell]

    local text = ""
    if spell == "ROOD BOSTOR" then
        WaitBeforeNextPlayerTurn()
    end
    local text = { name .. " DO " .. subAction .. "!" }
    BattleDialog(text)
end

-- Function called whenever this entity's animation is changed.
-- Make it return true if you want the animation to be changed like normal, otherwise do your own stuff here!
function HandleAnimationChange(newAnim) end

function Update()
    if rudeBusterActive and (GetCurrentState() ~= "PLAYERTURN" or CYK.turn ~= ID) then
        UpdateTurn(-21, CYK.frame)
    end
end

----- DO NOT MODIFY BELOW -----
end