return function(newENV)
_ENV = newENV

-- Sets an entity's sprite. Mostly useless as most of CYK's entities use animations.
function SetSprite(path)
    if type(path) ~= "string" then
        error("entity.SetSprite() needs one argument which is a string.")
    end
    sprite.Set(path)
end

-- Disables/enables an entity.
function SetActive(newActive)
    local pool = UI and CYK.players or CYK.enemies
    -- You can't disable the last remaining player
    if UI and #CYK.players == 1 and self == CYK.players[1] and not newActive then
        error("Tried to deactivate the last remaining player.")
    end
    -- Disabling an entity
    if isactive and not newActive then
        for i = 1, #pool do
            if pool[i] == self then
                -- Remove the current entity from the table of active entities it was in, then disable it
                table.remove(pool, i)
                if CYKDebugLevel > 2 then
                    DEBUG("Disabling " .. (UI and "player" or "enemy") .. " #" .. tostring(ID))
                end
                isactive = false
                if UI then
                    CYK.DisablePlayer(i)
                elseif bubbleTextObject then
                    bubbleTextObject.DestroyText()
                    bubbleTextObject = nil
                    bubble.Remove()
                    bubble = nil
                end
                break
            end
        end
    -- Enabling an entity
    elseif not isactive and newActive then
        if spareOrFleeAnim then
            if CYKDebugLevel > 1 then
                DEBUG("[WARN] You can't use entity.SetActive(true) on an enemy who has been spared or who fled the battle.")
            end
            return
        end
        -- Get the new index of the entity to enable in the active entities table it is supposed to be in
        local index = #pool + 1
        for i = 1, #pool do
            if pool[i].ID > ID then
                index = i
                break
            end
        end
        if CYKDebugLevel > 2 then
            DEBUG("Enabling " .. (UI and "player" or "enemy") .. " #" .. tostring(ID))
        end
        for i = #pool, index, -1 do
            pool[i+1] = pool[i]
        end
        pool[index] = self
        isactive = true
        if UI then
            CYK.EnablePlayer(index)
        end
    elseif CYKDebugLevel > 1 then
        DEBUG("[WARN] Using SetActive(" .. tostring(newActive) .. ") on the " .. (UI and "player" or "enemy") .. " #" .. tostring(ID) .. " who is already " .. (isactive and "" or "in") .. "active.")
    end
    if UI then
        CYK.UI.ManageUI()
    end
end

-- Tries to kill the enemy. If the enemy has a function named OnDeath(), it will fire it instead
function TryKill()
    if UI then
        error("You can only use entity.TryKill() on an enemy entity.")
    else
        if OnDeath then
            ProtectedCYKCall(OnDeath)
        else
            Kill()
        end
    end
end

-- Kills the enemy directly, without checking if a function named OnDeath() exists
function Kill(cancelAnim)
    if UI then
        error("You can only use entity.Kill() on an enemy entity.")
    else
        SetActive(false)
        spareOrFleeAnim = "flee"
        if not cancelAnim then
            spareOrFleeStart = CYK.frame
        end
    end
end

-- Tries to spare the enemy. If the enemy has a function named OnSpare(), it will fire it instead
function TrySpare(cancelAnim)
    if UI then
        error("You can only use entity.TrySpare() on an enemy entity.")
    else
        if OnSpare then
            ProtectedCYKCall(OnSpare)
        else
            Spare()
        end
    end
end

-- Kills the enemy directly, without checking if a function named OnSpare() exists
function Spare()
    if UI then
        error("You can only use entity.Spare() on an enemy entity.")
    else
        SetActive(false)
        spareOrFleeAnim = "spare"
        if not cancelAnim then
            spareOrFleeStart = CYK.frame
        end
    end
end

-- Moves the entity from where it was
function Move(x, y)
    if type(x) ~= "number" or type(y) ~= "number" then
        error("entity.Move() needs two numbers as arguments.")
    end
    sprite.x = sprite.x + x
    posX = posX + x
    sprite.y = sprite.y + y
    posY = posY + y
end

-- Moves the entity from its parent's position (which is the bottom left corner of the screen if it has none)
function MoveTo(x, y)
    if type(x) ~= "number" or type(y) ~= "number" then
        error("entity.MoveTo() needs two numbers as arguments.")
    end
    sprite.x = x
    posX = absx
    sprite.y = y
    posY = absy
end

-- Moves the entity from the bottom left corner of the screen
function MoveToAbs(x, y)
    if type(x) ~= "number" or type(y) ~= "number" then
        error("entity.MoveToAbs() needs two numbers as arguments.")
    end
    sprite.absx = x
    posX = x
    sprite.absy = y
    posY = y
end

-- Disabled
function BindToArena()
    if Encounter.CYKDebugLevel > 0 then
        DEBUG("[WARN] entity.BindToArena() does nothing in Create Your Kris.")
    end
end

-- Sets the next amount of damage to deal to this entity the next time an Attack() function is fired with it as an argument
function SetDamage(dmg)
    if type(dmg) ~= "number" then
        error("entity.SetDamage() needs one number as argument.")
    end
    presetDamage = -dmg
end

-- Moves this enemy's bubble from where it originally was
function SetBubbleOffset(x, y)
    if UI then
        if CYKDebugLevel > 1 then
            DEBUG("[WARN] entity.SetBubbleOffset() only has an effect on an enemy entity, however you used it on a Player entity.")
        end
        return
    end
    if type(x) ~= "number" or type(y) ~= "number" then
        error("entity.SetBubbleOffset() needs two numbers as arguments.")
    end
    bubbleOffsetX = x
    bubbleOffsetY = y
end

-- Moves this entity's damage text spawn position from where it originally was
function SetDamageUIOffset(x, y)
    if type(x) ~= "number" or type(y) ~= "number" then
        error("entity.SetDamageUIOffset() needs two numbers as arguments.")
    end
    damageUIOffsetX = x
    damageUIOffsetY = y
end

-- Moves this enemy's slashing animation from where it originally was
function SetSliceAnimOffset(x, y)
    if UI then
        if CYKDebugLevel > 1 then
            DEBUG("[WARN] entity.SetSliceAnimOffset() only has an effect on an enemy entity, however you used it on a Player entity.")
        end
        return
    end
    if type(x) ~= "number" or type(y) ~= "number" then
        error("entity.SetSliceAnimOffset() needs two numbers as arguments.")
    end
    sliceAnimOffsetX = x
    sliceAnimOffsetY = y
end

-- Same as CYF: displays an encounter text
function BattleDialog(text)
    if type(text) ~= "table" or type(text[1]) ~= "string" then
        error("BattleDialog() needs a table of strings as an argument.")
    end
    CYK.TxtMgr.SetText(text)
end

canmove = true

-- Heals this entity by a given amount
function Heal(val)
    if type(val) ~= "number" then
        error("entity.Heal() needs at least one number as argument.")
    end
    CYK.AtkMgr.ChangeHP(self, self, val)
end

-- Hurts this entity by a given amount, from another entity
function Hurt(val, from)
    if type(val) ~= "number" and type(from) ~= "table" and type(from.name) ~= "string" then
        error("entity.Hurt() needs one number and one entity as arguments.")
    end
    CYK.AtkMgr.ChangeHP(self, from, -val)
end

-- Attacks another entity, taking this entity's presetDamage value in account for the damage calculation
function Attack(target, coeff)
    if type(val) ~= "number" and type(target) ~= "table" and type(target.name) ~= "string" then
        error("entity.Attack() needs one entity and one number as arguments.")
    end
    return CYK.AtkMgr.Attack(target.ID, target.UI ~= nil, ID, UI ~= nil, coeff)
end

-- Starts one of this entities' animations. These animations can be found in the table "animations"
function SetCYKAnimation(anim)
    if type(anim) ~= "string" and type(from) ~= "table" and type(from.name) ~= "string" then
        error("entity.SetCYKAnimation() needs one string as argument.")
    end
    return CYK.SetAnim(self, anim)
end

-- Adds a spell to CYK's spell table
function AddSpell(name, description, tpCost, targetType)
    return CYK.AddSpell(name, description, tpCost, targetType)
end

-- Prevents the next Player's turn to start if executed
function WaitBeforeNextPlayerTurn()
    return CYK.WaitBeforeNextPlayerTurn()
end

-- Starts the next Player's turn if WaitBeforeNextPlayerTurn() has been started before
function EndPlayerTurn()
    return CYK.EndPlayerTurn()
end

-- Returns true if the entity is a Player, false otherwise
function IsPlayer()
    return UI ~= nil
end

-- Updates the Player's UI manually
function UpdateUI()
    if IsPlayer() then
        CYK.UI.UpdateUI(self)
    else
        if CYKDebugLevel > 1 then
            DEBUG("[WARN] entity.UpdateUI() only has an effect on a Player entity, however you used it on an enemy entity.")
        end
        return
    end
end

-- Adds an act to an enemy
function AddAct(name, description, tpCost, requiredPlayers)
    -- Add the acts table if it doesn't exist
    if acts == nil then
        acts = { }
    end

    -- Function usage checking
    if type(name) ~= "string" then
        error("The first argument of CYK.AddAct() must be a string. (name)")
    elseif type(description) ~= "string" then
        error("The second argument of CYK.AddAct() must be a string. (description)")
    elseif type(tpCost) ~= "number" or tpCost < 0 or tpCost > 100 then
        error("The third argument of CYK.AddAct() must be a number between 0 and 100. (tpCost)")
    elseif requiredPlayers ~= nil and type(requiredPlayers) ~= "table" then
        error("The fourth argument of CYK.AddAct() must be a table of string values or nil. (requiredPlayers)")
    elseif acts[name] then
        if CYKDebugLevel > 1 then
            DEBUG("[WARN] The act command " .. name .. " already exists in " .. scriptName .. "'s act command database.")
        end
    end

    local act = { }
    act.description = "[font:uidialog][novoice][instant][color:808080]" .. description .. (tpCost > 0 and ("\n[color:ff8040]" .. tostring(tpCost) .. "% TP") or "")
    act.tpCost = tpCost
    act.requiredPlayers = requiredPlayers
    acts[name] = act
end

end