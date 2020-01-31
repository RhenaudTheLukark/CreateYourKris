return function(newENV)
_ENV = newENV
----- DO NOT MODIFY ABOVE -----

hp = 70
atk = 8
def = 2

-- CYK variables
mag = 7                                    -- MAGIC stat of the Player
powers = { "KNID", "FUUF" }                -- Powers of the Player (Unused)
abilities = { "PCIFAY", "LIL PARYE" }      -- Abilities of the Player. If the Player has "Act", he won't be able to use spells!
playerColor = { 0, 1, 0 }                  -- Color used in this Player's main UI
atkBarColor = { 0, .5, 0 }                 -- Color used in this Player's atk bar
damageColor = { 180/255, 230/255, 29/255 } -- Color used in this Player's damage text

AddSpell("PCIFAY", "SAPRE TIERD FEO", 16, "Enemy")
AddSpell("LIL PARYE", "LIL A LY", 32, "Player")

-- Check the "Special Variables" page of the documentation to learn how to modify this mess
animations = {
    Down =          { { 0 },          1,      { loop = "ONESHOT" },     },
    Fight =         { { 0, 1 },       2 / 15, { loop = "ONESHOT" }      },
    Hurt =          { { 0 },          1,      { next = "Idle" },        },
    Idle =          { { 0, 1 },       2 / 15, { },                      },
    Spare =         { { 0, 1, 2, 3 }, 2 / 15, { next = "Idle"  }        },
    SliceAnim =     { { 0, 1, 2, 3 }, 2 / 15, { loop = "ONESHOTEMPTY" } },
}

-- Started when this Player casts a spell through the MAGIC command
-- The first local variables are here to help you know what is what
function HandleCustomSpell(target, spell)
    local spellData = CYK.spells[spell]

    local text = ""
    if spell == "PCIFAY" then
        if target.tired then
            target.TrySpare()
        else
            text = "\n" .. target.name .. " NO [color:00b2ff]ZZZ[color:ffffff]!"
        end
    elseif spell == "LIL PARYE" then
        target.Heal(mag * 5)
    end
    local text = { name .. " DO " .. subAction .. "!" .. text }
    BattleDialog(text)
end

-- Function called whenever this entity's animation is changed.
-- Make it return true if you want the animation to be changed like normal, otherwise do your own stuff here!
function HandleAnimationChange(newAnim) end

----- DO NOT MODIFY BELOW -----
end