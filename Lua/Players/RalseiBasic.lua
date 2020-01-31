return function(newENV)
_ENV = newENV
----- DO NOT MODIFY ABOVE -----

name = "Ralsei"
hp = 70
atk = 8
def = 2

-- CYK variables
mag = 7                                    -- MAGIC stat of the Player
powers = { }                               -- Powers of the Player (Unused)
abilities = { "Pacify", "Heal Prayer" }    -- Abilities of the Player. If the Player has "Act", he won't be able to use spells!
playerColor = { 0, 1, 0 }                  -- Color used in this Player's main UI
atkBarColor = { 0, .5, 0 }                 -- Color used in this Player's atk bar
damageColor = { 180/255, 230/255, 29/255 } -- Color used in this Player's damage text

-- Check the "Special Variables" page of the documentation to learn how to modify this mess
AddSpell("Pacify", "Spare TIRED foe", 16, "Enemy")
AddSpell("Heal Prayer", "Heal Ally", 32, "Player")

animations = {
    Defend =        { { 0, 1, 2, 3, 4 },                                    1 / 15, { loop = "ONESHOT", targetShift = { -14, 11 } } },
    Down =          { { 0 },                                                1,      { loop = "ONESHOT" },                           },
    EndBattle =     { { 0, 1, 3, 2, 3, 2, 3, 2, 4, 5, 6, 7, 8, 9, 10, 11 }, 2 / 15, { loop = "ONESHOT" }                            },
    Fight =         { { 0, 1, 2, 3, 4, 5 },                                 1 / 15, { loop = "ONESHOT" }                            },
    Hurt =          { { 0 },                                                1,      { next = "Idle" },                              },
    Idle =          { { 0, 1, 2, 3, 4 },                                    2 / 15, { targetShift = { -14, 11 } },                  },
    Intro =         { { 0, 1, 2, 3, 4, 5, 6, 7, 8 },                        1 / 15, { next = "Idle" }                               },
    Item =          { { 0, 1, 2, 3, 4, 5, 0, 6 },                           1 / 15, { next = "Idle" }                               },
    Magic =         { { 0, 1, 2, 3, 4, 5, 6, 7, 8 },                        1 / 15, { next = "Idle" }                               },
    PrepareAct =    { { 0 },                                                1,      { loop = "ONESHOT" },                           },
    PrepareFight =  { { 0 },                                                1,      { loop = "ONESHOT" },                           },
    PrepareItem =   { { 0 },                                                1,      { loop = "ONESHOT" },                           },
    PrepareMagic =  { { 0, 1, 2, 3 },                                       2 / 15, { },                                            },
    PrepareSpare =  { { 0 },                                                1,      { loop = "ONESHOT" },                           },
    Spare =         { { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 },                     1 / 15, { next = "Idle"  }                              },
    SliceAnim =     { { 0, 1, 2, 3 },                                       2 / 15, { loop = "ONESHOTEMPTY" }                       },
}

-- Started when this Player casts a spell through the MAGIC command
-- The first local variables are here to help you know what is what
function HandleCustomSpell(target, spell)
    local spellData = CYK.spells[spell]

    local text = ""
    if spell == "Pacify" then
        if target.tired then target.TrySpare()
        else                 text = "\nBut " .. target.name .. " was not [color:00b2ff]TIRED[color:ffffff]..."
        end
    elseif spell == "Heal Prayer" then
        target.Heal(mag * 5)
    end
    local text = { name .. " casts " .. subAction .. "!" .. text }
    BattleDialog(text)
end

----- DO NOT MODIFY BELOW -----
end