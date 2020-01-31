return function(newENV)
_ENV = newENV
----- DO NOT MODIFY ABOVE -----

hp = 90
atk = 10
def = 2

-- CYK variables
mag = 0                               -- MAGIC stat of the Player
powers = { "GOOTS" }                  -- Powers of the Player (Unused)
abilities = { "Act" }                 -- Abilities of the Player. If the Player has "Act", they won't be able to use spells!
playerColor = { 0, 1, 1 }             -- Color used in this Player's main UI
atkBarColor = { 0, 0, .5 }            -- Color used in this Player's atk bar
damageColor = { 0, 162/255, 232/255 } -- Color used in this Player's damage text

-- Check the "Special Variables" page of the documentation to learn how to modify this mess
animations = {
    Down =          { { 0 },                1,      { loop = "ONESHOT" },                       },
    Fight =         { { 0, 1, 2, 3 },       2 / 15, { loop = "ONESHOT", posShift = { 0, -12 } } },
    Hurt =          { { 0 },                1,      { next = "Idle" },                          },
    Idle =          { { 0 },                1,      { heartShift = { -40, 0 } },                },
    PrepareAct =    { { 0, 1 },             3 / 15, { },                                        },
    PrepareSpare =  { { 0, 1 },             3 / 15, { },                                        },
    Spare =         { { 0, 1, 2, 3, 4, 5 }, 2 / 15, { next = "Idle" }                           },
    SliceAnim =     { { 0, 1, 2 },          2 / 15, { loop = "ONESHOTEMPTY" }                   },
}

-- Started when this Player casts a spell through the MAGIC command.
-- Kris has the ability "Act", so this function won't be used.
function HandleCustomSpell(spell) end

-- Function called whenever this entity's animation is changed.
-- Make it return true if you want the animation to be changed like normal, otherwise do your own stuff here!
function HandleAnimationChange(newAnim)
    if newAnim == "Spare" then
        Audio.PlaySound("OOH")
    end
end

----- DO NOT MODIFY BELOW -----
end