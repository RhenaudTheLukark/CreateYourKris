_OnHit = OnHit

-- Overrides OnHit()
function OnHit(bullet)
    if bullet == nil then return end
    local damage = nil
    local invulTimer = nil
    local onHitOverridden = _OnHit ~= nil
    -- Triggers the function OnHit() if it exists and retrieve its return values if there are any
    if _OnHit then
        damage, invulTimer = _OnHit(bullet)
    end
    -- Only triggered when the Player is not hurting and if the Player's OnHit() has returned anything, if it exists
    if not Player.ishurting and (damage ~= nil or not onHitOverridden) then
        local enemyID = bullet["from"]
        -- No attacking enemy set for this bullet -> Pick a random attacking enemy
        if not enemyID then
            enemyID = Encounter["CYK"].enemies[math.random(1, #Encounter["CYK"].enemies)].ID
        end

        local damageMult = nil
        local damageForced = nil
        -- Check damage
        -- Damage not set: use 100% of the enemy's attack power instead
        if damage == nil then
            damageMult = 1
            damage = "100%"
            if OnHit and Encounter["CYKDebugLevel"] > 2 then
                DEBUG("[WARN] OnHit() doesn't return a value for damage. Using \"100%\" instead.")
            end
        -- Damage as string: uses a percentage of the enemy's power to deal damage
        elseif type(damage) == "string" then
            if damage[#damage] == "%" then
                local tempDamage = string.sub(damage, 1, #damage-1)
                -- Checks if the value is negative by checking if the string starts with a - character
                local negative = false
                if tempDamage[1] == "-" then
                    tempDamage = string.sub(tempDamage, 2, #tempDamage)
                    negative = true
                end
                -- Valid number
                if tonumber(tempDamage) then
                    damageMult = tonumber(tempDamage) / 100 * (negative and -1 or 1)
                -- Invalid number: use 100% of the enemy's attack power instead
                else
                    damageMult = 1
                    if Encounter["CYKDebugLevel"] > 0 then
                        DEBUG("[WARN] Bad damage value returned in OnHit(): \"" .. tostring(damage) .. "\" (string)\nThe function OnHit() must return two parameters: the first one is a string (percentage), a number or nil and the second one must be a number or nil.")
                    end
                end
            -- Invalid number: use 100% of the enemy's attack power instead
            else
                damageMult = 1
                if Encounter["CYKDebugLevel"] > 0 then
                    DEBUG("[WARN] Bad damage value returned in OnHit(): \"" .. tostring(damage) .. "\" (string)\nThe function OnHit() must return two parameters: the first one is a string (percentage), a number or nil and the second one must be a number or nil.")
                end
            end
        -- Damage as number: force this amount of damage for this attack
        elseif type(damage) == "number" then
            damageForced = -damage
        -- Invalid damage value: use 100% of the enemy's attack power instead
        else
            damageMult = 1
            if Encounter["CYKDebugLevel"] > 0 then
                DEBUG("[WARN] Bad damage value returned in OnHit(): it is a " .. type(damage) .. ".\nThe function OnHit() must return two parameters: the first one is a string (percentage), a number or nil and the second one must be a number or nil.")
            end
        end

        -- Check invulTimer
        -- Not set: use default value 1.7
        if invulTimer == nil then
            invulTimer = 1.7
            if Encounter["CYKDebugLevel"] > 2 then
                DEBUG("[WARN] OnHit() doesn't return a value for invulTimer. Using 1.7 instead.")
            end
        -- Not a number: use 1.7 instead
        elseif type(invulTimer) ~= "number" then
            invulTimer = 1.7
            if Encounter["CYKDebugLevel"] > 0 then
                DEBUG("[WARN] Bad invulTimer value returned in OnHit(): it is a " .. type(invulTimer) .. ".\nThe function OnHit() must return two parameters: the first one is a string (percentage), a number or nil and the second one must be a number or nil.")
            end
        end

        -- Targets all players: the amount of damage dealt to each player is divided by the amount of Players who haven't been KO'd
        local playerIDs = Encounter["CYK"].enemies[enemyID].target
        if Encounter["CYK"].enemies[enemyID].target == 0 then
            playerIDs = SuperCall(Encounter, "CYK.GetAvailableEntities", true)
        end

        playerIDs = type(playerIDs) == "table" and playerIDs or { playerIDs }
        -- Override: bullet["target"] overrides bullet["from"]
        if bullet["target"] then
            if type(bullet["target"]) ~= "number" then                                       error("bullet[\"target\"] must be an integer if it's set!", 2)
            elseif bullet["target"] < 0 or bullet["target"] > #Encounter["CYK"].players then error("bullet[\"target\"] must be an integer between 1 and the number of active players!", 2)
            elseif bullet["target"] == 0 then                                                playerIDs = SuperCall(Encounter, "CYK.GetAvailableEntities", true)
            else                                                                             playerIDs = { bullet["target"] }
            end
        end

        -- For each player to attack, check if this entity can be attacked, and attack it
        for i = 1, #playerIDs do
            local playerID = playerIDs[i]
            playerID = SuperCall(Encounter, "CYK.GetEntityUp", playerID, true)
            Encounter["players"][playerID].presetDamage = damageForced or
                math.ceil(-SuperCall(Encounter, "CYK.AtkMgr.ComputeDamage", playerID, enemyID, damageMult, true, false) / #playerIDs)
            -- If the attack was unsuccessful, pick another available player
            if not SuperCall(Encounter, "CYK.AtkMgr.Attack", playerID, true, enemyID, false, damageMult or 1) then
                local availablePlayers = SuperCall(Encounter, "CYK.GetAvailableEntities", true)
                SuperCall(Encounter, "CYK.AtkMgr.Attack", availablePlayers[math.random(#availablePlayers)], true, enemyID, false, damageMult or 1)
            end
        end

        -- Plays the hurt sound and makes the player invulnerable for a while
        if not Encounter["doneFor"] then
            if (type(damage) == "string" and damage[1] ~= "-") or (type(damage) == "number" and damage >= 0) then
                _Player.Hurt(0, invulTimer)
            end
        end
    end
end

_Update = Update
-- Override the Arena
function Update()
    if _Update then _Update() end
    Arena.Update()
    GrazeUpdate()
    -- Updates some of CYK's Arena values (which is not technically the Arena so it's not in Arena.Update())
    Encounter["arenainfo"].x = Arena.currentx
    Encounter["arenainfo"].y = Arena.currenty
    Encounter["arenainfo"].width = Arena.currentwidth
    Encounter["arenainfo"].height = Arena.currentheight
    Encounter["arenainfo"].rotation = Arena.inner.rotation
end

-- Prepares the arena to be moved and/or resized
function PrepareArenaForAnim(x, y, width, height, movePlayer, immediate)
    Arena.MoveToAndResize(x, y, width, height, movePlayer, immediate)
    Arena.inner.alpha = 0
    Arena.outer.alpha = 0
    Arena.inner.rotation = Encounter["arenarotation"]
    Arena.outer.rotation = Encounter["arenarotation"]
end

-- Shows the arena after the end of the Arena's "show" animation
function ShowArenaAfterEndAnim()
    Arena.inner.alpha = 1
    Arena.outer.alpha = 1
    Player.sprite.alpha = 1
end

-- Returns the Player entity/entities which will be damaged by the Player
function GetTargetEntityFromBullet(bullet)
    local targetID = Encounter["enemies"][bullet["from"]].target
    if targetID == 0 then
        return SuperCall(Encounter, "CYK.GetAvailableEntities", true)
    end
    return { SuperCall(Encounter, "CYK.GetEntityUp", targetID, true) }
end

-- Checks for the grazing collision, using WD's Rotational Collision Library TM
RotationalCollision = require "Libraries/CYK/RotationalCollision"
local lastGrazeFrame = 0
local halfPlayerSize = Encounter["CYK"].grazeHitbox.sprite.xscale / 2
function GrazeUpdate()
    local bulletsGrazing = 0
    local frame = Encounter["CYK"].frame - lastGrazeFrame
    -- Only works if the Player is not hurting
    if not Player.ishurting then
        for i = #veryBigBulletPool, 1, -1 do
            local bullet = veryBigBulletPool[i]
            if not bullet.isactive then
                table.remove(veryBigBulletPool, i)
            elseif not bullet["noGraze"] then
                -- Checks if the current bullet is detected by the normal collision check
                local grazed = false
                local radRot = math.rad(bullet.sprite.rotation)
                local bulletWidth = bullet.ppcollision and math.ceil(bullet.sprite.width * math.abs(math.cos(radRot)) + bullet.sprite.height * math.abs(math.sin(radRot))) or bullet.sprite.width
                local bulletHeight = bullet.ppcollision and math.ceil(bullet.sprite.height * math.abs(math.cos(radRot)) + bullet.sprite.width * math.abs(math.sin(radRot))) or bullet.sprite.height
                if math.abs(bullet.sprite.absx - Player.sprite.absx) < bulletWidth * bullet.sprite.xscale / 2 + halfPlayerSize and
                   math.abs(bullet.sprite.absy - Player.sprite.absy) < bulletHeight * bullet.sprite.yscale / 2 + halfPlayerSize then
                   -- Check new RotationalCollision
                    if not bullet.ppcollision or RotationalCollision.CheckCollision(bullet, Encounter["CYK"].grazeHitbox) then
                        grazed = true
                    end
                end

                -- Grazing!
                if grazed then
                    bulletsGrazing = bulletsGrazing + 1
                    bullet["grazeTime"] = Time.time
                    if bullet["grazed"] then
                        SuperCall(Encounter, "CYK.TP.Set", bullet["TPGain"] and bullet["TPGain"] * 0.025 or 0.05, true)
                    else
                        Encounter["CYK"].grazeSprite.color = { 1, 1, 1 }
                        Encounter["CYK"].grazeSprite.alpha = 1
                        lastGrazeFrame = Encounter["CYK"].frame
                        PlaySoundOnceThisFrame("graze")
                        bullet["grazed"] = true
                        SuperCall(Encounter, "CYK.TP.Set", bullet["TPGain"] and bullet["TPGain"] or 2, true)
                    end
                -- Grazed last a second ago: reset the graze
                elseif bullet["grazed"] and Time.time - bullet["grazeTime"] >= 1 then
                    bullet["grazed"] = false
                end
            end
        end
    end

    -- Update the grazing sprite
    local frame = Encounter["CYK"].frame - lastGrazeFrame
    if frame >= 6 and frame < 12 then
        local coeff = (frame - 5) / 6
        Encounter["CYK"].grazeSprite.color32 = { 255 - math.floor(91 * coeff), 255 - math.floor(137 * coeff), 255 - math.floor(137 * coeff) }
    elseif frame >= 12 and frame < 18 and bulletsGrazing == 0 then
        Encounter["CYK"].grazeSprite.alpha = 1 - ((frame - 11) / 12)
    elseif frame >= 12 and bulletsGrazing > 0 then
        Encounter["CYK"].grazeSprite.alpha = 1
        lastGrazeFrame = Encounter["CYK"].frame - 11
    elseif frame == 18 then
        Encounter["CYK"].grazeSprite.alpha = 0
    end
end