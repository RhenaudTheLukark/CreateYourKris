require "Libraries/CYK/Sandboxing/All"

-- Alright, here comes the complex part
-- We save the current environment so we can create a new environment for entities to be created
-- We isolate _G, as running table.copy on _ENV with it creates an infinite loop, as _G has a pointer toward _ENV and _ENV has a pointer toward _G
-- Then we add it back, and so we successfully copied the current environment
local _ENV_G = _ENV._G
_ENV._G = { }
_ENV_BASE = _ENV.table.copy(_ENV)
_ENV._G = _ENV_G
_ENV_G = nil
_ENV_BASE.Update = nil

-- Gets a random encounter text from entities
function RandomEncounterText()
    local availableEnemies = { }
    local textToDisplay = ""
    -- If an enemy has available random encounter texts, register this enemy
    for i = 1, #CYK.enemies do
        if #CYK.enemies[i].comments > 0 then
            table.insert(availableEnemies, CYK.enemies[i])
        end
    end
    -- If no enemies have any available random encounter texts, trigger a warning message
    if #availableEnemies == 0 then
        if CYKDebugLevel > 0 then
            DEBUG("[WARN] No enemy has any string to display on the encounter text.")
        end
    -- Else, return a random encounter text
    else
        local enemy = availableEnemies[math.random(1, #availableEnemies)]
        textToDisplay = enemy.comments[math.random(1, #enemy.comments)]
    end
    return textToDisplay
end

function CallEntityFunc(isPlayer, entityID, func, ...)
    local pool = isPlayer and players or enemies
    local entity = pool[entityID]
    if entity == nil then
        error("CallEntityFunc: The " .. (isPlayer and "Player" or "Enemy") .. " entity #" .. entityID .. " doesn't exist.")
    end
    if entity[func] == nil then
        if CYKDebugLevel > 0 then
            DEBUG("[WARN] The " .. (isPlayer and "Player" or "Enemy") .. " " .. entity.scriptName .. " doesn't have a function named " .. func .. "!")
        end
    elseif type(entity[func]) ~= "function" then
        error("The " .. (isPlayer and "Player" or "Enemy") .. " " .. entity.scriptName .. "'s " .. func .. " variable is not a function!")
    else
        return entity[func](...)
    end
end

-- Function executed when the current CYF state has changed
function EnteringRealState(newstate, oldstate)
    -- End of a wave
    if oldstate == "DEFENDING" and newstate ~= "PAUSE" and newstate ~= "DEFENDING" then
        CYK.grazeSprite.alpha = 0
        _Player.Hurt(0, 0)
        CYK.StartArenaAnim()
        for i = 1, #Wave do
            local wave = Wave[i]
            for j = #wave["veryBigBulletPool"], 1, -1 do
                local bullet = wave["veryBigBulletPool"][j]
                if bullet.isactive then
                    bullet.Remove()
                end
            end
        end
        SuperCall(Wave[1], "FakeArena.Destroy")
        OldState("NONE", false)
    -- Start of the encounter
    elseif oldstate == "NONE" and newstate == "ACTIONSELECT" then
        OldState("NONE")
    end
end

-- Basic arena information. Its values will be replaced when needed
arenainfo = { x = 0, y = 0, width = 0, height = 0, rotation = 0 }