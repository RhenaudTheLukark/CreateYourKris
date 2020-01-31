-- This library handles everything related to entities
-- No wonder why it got its current name!
return function(self)
    -- Checks if a loaded Entity file is valid
    -- If anything is wrong, it can throw errors or warnings.
    function self.CheckEntityFile(entity, entityName, isPlayer)
        local debug = CYKDebugLevel > 0

        if type(entity) ~= "table" then
            error("The Entity file Lua/" .. (isPlayer and "Players/" or "Monsters/") .. entityName .. ".lua can't be found.")
        elseif type(entity.hp) ~= "number" then
            error("The Entity file " .. entityName .. " must contain a number variable named \"hp\".\nThis value is the amount of HP the entity has.")
        elseif type(entity.maxhp) ~= "number" and entity.maxhp ~= nil then
            error("The Entity file " .. entityName .. " can contain a number variable named \"maxhp\".\nThis value is the amount of HP the entity can have when fully healed.\nIt is used with entity.hp if you want the entity to not\nbe fully healed at the start of the battle.")
        elseif type(entity.atk) ~= "number" then
            error("The Entity file " .. entityName .. " must contain a number variable named \"atk\".\nThis value is the ATK value of the entity.")
        elseif type(entity.def) ~= "number" then
            error("The Entity file " .. entityName .. " must contain a number variable named \"def\".\nThis value is the DEF value of the entity.")
        elseif type(entity.mag) ~= "number" then
            error("The Entity file " .. entityName .. " must contain a number variable named \"mag\".\nThis value is the MAG value of the entity.")
        elseif type(entity.animations) ~= "table" then
            error("The Entity file " .. entityName .. " must contain a variable named \"animations\".\nYou should check an example Entity file in order to know how to set this variable.")
        else
            -- Checks if the entity files have some required animations
            -- Stores all the anims an entity should have and check if they exist
            local minAnims = { Idle, Hurt, SliceAnim = isPlayer }
            for k, v in pairs(minAnims) do
                if not minAnims[k] then
                    minAnims[k] = nil
                end
            end

            for k, v in pairs(entity.animations) do
                if type(v) ~= "table" then
                    error("Each variable inside an Entity file's animations variable must be a table, however the Entity file " .. entityName .. "'s animations." .. k .. " is a " .. type(v) .. ".")
                elseif type(v[1]) ~= "table" then
                    error("The Entity file " .. entityName .. "'s animations." .. k .. "'s first variable must be a table, but it is a " .. type(v[1]) .. ".")
                elseif type(v[2]) ~= "number" then
                    error("The Entity file " .. entityName .. "'s animations." .. k .. "'s second variable must be a number, but it is a " .. type(v[2]) .. ".")
                elseif type(v[3]) ~= "table" then
                    error("The Entity file " .. entityName .. "'s animations." .. k .. "'s third variable must be a table, but it is a " .. type(v[3]) .. ".")
                end
                minAnims[k] = nil
            end

            local missingAnims = ""
            for k, v in pairs(minAnims) do
                if missingAnims == "" then
                    missingAnims = k
                else
                    missingAnims = missingAnims .. ", " .. k
                end
            end
            if missingAnims ~= "" then
                error("The " .. (isPlayer and "Player" or "Enemy") .. " Entity file " .. entityName .. " requires the animations " .. missingAnims)
            end
        end

        if entity.HandleAnimationChange == nil then if debug then    DEBUG("[WARN] " .. (isPlayer and "Player" or "Enemy") .. " " .. entityName .. ": HandleAnimationChange() missing.") end
        elseif type(entity.HandleAnimationChange) ~= "function" then error("The " .. (isPlayer and "Player" or "Enemy") .. " " .. entityName .. " can have a variable named HandleAnimationChange as a function, but it is a " .. type(entity.HandleAnimationChange) .. ".")
        end

        if entity.HandleAttack == nil then if debug then    DEBUG("[WARN] " .. (isPlayer and "Player" or "Enemy") .. " " .. entityName .. ": HandleAttack() missing.") end
        elseif type(entity.HandleAttack) ~= "function" then error("The " .. (isPlayer and "Player" or "Enemy") .. " " .. entityName .. " can have a variable named HandleAttack as a function, but it is a " .. type(entity.HandleAttack) .. ".")
        end

        if entity.BeforeDamageCalculation == nil then if debug then    DEBUG("[WARN] " .. (isPlayer and "Player" or "Enemy") .. " " .. entityName .. ": BeforeDamageCalculation() missing.") end
        elseif type(entity.BeforeDamageCalculation) ~= "function" then error("The " .. (isPlayer and "Player" or "Enemy") .. " " .. entityName .. " can have a variable named BeforeDamageCalculation as a function, but it is a " .. type(entity.BeforeDamageCalculation) .. ".")
        end

        if entity.Update == nil then if debug then    DEBUG("[WARN] " .. (isPlayer and "Player" or "Enemy") .. " " .. entityName .. ": Update() missing.") end
        elseif type(entity.Update) ~= "function" then error("The " .. (isPlayer and "Player" or "Enemy") .. " " .. entityName .. " can have a variable named Update as a function, but it is a " .. type(entity.Update) .. ".")
        end

        if isPlayer then
            if type(entity.abilities) ~= "table" then
                error("The Player Entity file " .. entityName .. " must contain a table variable named \"abilities\".\nThis table contains the list of all spells the character can use. If it contains the value \"Act\", this Player will be able to access the ACT menu but won't be able to use magic!")
            else
                for i = 1, #entity.abilities do
                    if type(entity.abilities[i]) ~= "string" then
                        error("The Player Entity file " .. entityName .. "'s abilities table's value #" .. tostring(i) .. " must be a string, but it is a " .. type(entity.abilities[i]) .. ".")
                    end
                end
            end
            local colors = { "playerColor", "atkBarColor", "damageColor" }
            for h = 1, #colors do
                local colorName = colors[h]
                local color = entity[colorName]
                if type(color) ~= "table" then
                    error("The Player Entity file " .. entityName .. " must contain a table variable named \"" .. colorName .. "\".\nThis table contains the R, G, B (and A) color values of " .. (h == 1 and "most of the Player's UI." or "the Player's attack bar.") .. "\nThose values must be between 0 and 1.")
                else
                    if #color < 3 or #color > 4 then
                        error("The Player Entity file " .. entityName .. "'s " .. colorName .. " table must contain 3 or 4 variables.")
                    end
                    for i = 1, #color do
                        if (i ~= 4 and color[i] ~= nil) and type(color[i]) ~= "number" then
                            error("The Player Entity file " .. entityName .. "'s " .. colorName .. " table's value #" .. tostring(i) .. " must be a string, but it is a " .. type(color[i]) .. ".")
                        elseif color[i] < 0 or color[i] > 1 then
                            error("The Player Entity file " .. entityName .. "'s " .. colorName .. " table's value #" .. tostring(i) .. " must be between 0 and 1, but its current value is " .. tostring(color[i]) .. ".")
                        end
                    end
                end
            end

            if entity.HandleCustomSpell == nil then if debug then    DEBUG("[WARN] " .. (isPlayer and "Player" or "Enemy") .. " " .. entityName .. ": HandleCustomSpell() missing.") end
            elseif type(entity.HandleCustomSpell) ~= "function" then error("The " .. (isPlayer and "Player" or "Enemy") .. " " .. entityName .. " can have a variable named HandleCustomSpell as a function, but it is a " .. type(entity.HandleCustomSpell) .. ".")
            end
        else
            local tableNames = { "comments", "commands" }
            for h = 1, #tableNames do
                local tableName = tableNames[h]
                local tab = entity[tableName]
                if type(tab) ~= "table" then
                    error("The Enemy Entity file " .. entityName .. " must contain a table variable named \"" .. tableName .. "\".\nMuch like Unitale or CYF, " ..
                        (h == 1 and "at the beginning of a new turn, a random enemy is selected, then a random string in this enemy's comments table is shown in the encounter text when the player must choose their Players' action." or
                         h == 2 and "the commands table contains the list of ACTs a Player able to use ACTs can use."))
                else
                    for i = 1, #tab do
                        local value = tab[i]
                        if type(value) ~= "string" then
                            error("The Enemy Entity file " .. entityName .. "'s " .. tableName .. " table's value #" .. tostring(i) .. " must be a string, but it is a " .. type(value[i]) .. ".")
                        end
                    end
                end
            end

            if entity.OnSpare == nil then if debug then    DEBUG("[WARN] " .. (isPlayer and "Player" or "Enemy") .. " " .. entityName .. ": OnSpare() missing.") end
            elseif type(entity.OnSpare) ~= "function" then error("The " .. (isPlayer and "Player" or "Enemy") .. " " .. entityName .. " can have a variable named OnSpare as a function, but it is a " .. type(entity.OnSpare) .. ".")
            end

            if entity.OnDeath == nil then if debug then    DEBUG("[WARN] " .. (isPlayer and "Player" or "Enemy") .. " " .. entityName .. ": OnDeath() missing.") end
            elseif type(entity.OnDeath) ~= "function" then error("The " .. (isPlayer and "Player" or "Enemy") .. " " .. entityName .. " can have a variable named OnDeath as a function, but it is a " .. type(entity.OnDeath) .. ".")
            end
        end
    end

    -- Players table
    self.allPlayers = players
    self.players = { }
    self.playersPos = playerpositions

    -- Enemies table
    self.allEnemies = _enemies
    self.enemies = { }
    self.enemiesPos = enemypositions
    enemies = _enemies
    _enemies = nil

    -- Creates the entity objects and stores them in the appropriate entity table
    for i = 1, #self.allPlayers + #self.allEnemies do
        local isPlayer = i <= #self.allPlayers
        local realI = isPlayer and i or i - #self.allPlayers
        local entity = isPlayer and self.allPlayers[realI] or self.allEnemies[realI]

        -- Loads the entity file itself
        local queriedEntityFile = entity
        if isPlayer then self.allPlayers[realI] = LoadEntityFile(self._ENV_BASE, "Players/" .. queriedEntityFile, self)
        else             self.allEnemies[realI] = LoadEntityFile(self._ENV_BASE, "Monsters/" .. queriedEntityFile, self)
        end
        -- Checks if the entity file is correct
        entity = isPlayer and self.allPlayers[realI] or self.allEnemies[realI]
        self.CheckEntityFile(entity, queriedEntityFile, isPlayer)

        -- Add some extra useful values to the entity and the animation table
        entity.scriptName = queriedEntityFile
        if entity.name == nil then
            entity.name = queriedEntityFile
        end
        -- Add this entity's animations to the table containing all animations
        self.anims[entity.scriptName] = entity.animations
        self.anims[entity.scriptName].isPlayer = isPlayer
        -- Moves the entity based on its value in the table self.playersPos or self.enemiesPos
        local entityPos = (isPlayer and self.playersPos or self.enemiesPos)[realI]
        if not entityPos then
            error("The " .. (isPlayer and "player" or "enemy") .. " #" .. tostring(realI) .. " can't be placed. Did you forget to set its position in the self." .. (isPlayer and "players" or "enemies") .. "Pos table?")
        end
        entity.posX = entityPos[1]
        entity.posY = entityPos[2]

        -- If the entity is active, add it to the active players or active enemies table
        if entity.isactive == nil or entity.isactive then
            entity.isactive = true
            if isPlayer then table.insert(self.players, self.allPlayers[realI])
            else             table.insert(self.enemies, self.allEnemies[realI])
            end
        end
    end

    -- Builds the content in the self.anims table to make it look like proper animations usable with sprite.SetAnimation()
    self.BuildAnimations()

    -- Creates an entity
    function self.GetEntity(data, i, isPlayer)
        local entity = data

        -- Entity sprite
        entity.sprite = CreateSprite("empty", "Entity")
        entity.sprite.SetPivot(0, 0)
        entity.sprite.absx = entity.posX
        entity.sprite.absy = entity.posY
        entity.sprite["anim"] = entity.scriptName
        entity.sprite["xShift"] = 0
        entity.sprite["yShift"] = 0

        -- CYF shortcut
        entity.monstersprite = entity.sprite

        -- Entity mask sprite
        entity.sprite["mask"] = CreateSprite("empty", "Entity")
        entity.sprite["mask"].SetParent(entity.sprite)
        entity.sprite["mask"].MoveTo(0, 0)
        entity.sprite["mask"].Mask("stencil")

        -- Entity flash sprite
        entity.sprite["f"] = CreateSprite("px", "Entity")
        entity.sprite["f"].SetParent(entity.sprite["mask"])
        entity.sprite["f"].Scale(640, 480)
        entity.sprite["f"].MoveTo(0, 0)
        entity.sprite["f"].alpha = 0

        entity.scriptName = nil

        entity.ID = i

        if isPlayer then
            -- Table used to hold all of this entity's UI
            entity.UI = { }

            entity.action = ""            -- Name of the action this Player chose
            entity.subAction = ""         -- Name of the subaction this Player chose

            -- This sprite is used to display the "TARGET" cursor on a Player in the state ENEMYDIALOGUE, if this Player can be damaged in the next wave
            entity.targetCursor = CreateSprite("empty", "Entity")
            entity.targetCursor.SetParent(entity.sprite)
            local idleTargetShift = entity.animations.Idle[3].targetShift
            entity.targetCursor.x = idleTargetShift and idleTargetShift[1] or 0
            entity.targetCursor.y = idleTargetShift and idleTargetShift[2] or 0
            entity.targetCursor.SetAnimation({ "CreateYourKris/UI/TargetCursor/0", "CreateYourKris/UI/TargetCursor/1" }, 1 / 2)
            entity.targetCursor.alpha = 0

            entity.targetType = "Player"  -- Type of the target of this entity
        else
            -- Bubble and animation related variables
            entity.bubbleOffsetX = 0
            entity.bubbleOffsetY = 0
            entity.sliceAnimOffsetX = 0
            entity.sliceAnimOffsetY = 0

            -- Variables related to the flee and spare animations
            entity.spareOrFleeAnim = nil
            entity.spareOrFleeStart = 0
            entity.spareStars = { }
            entity.fleeSprites = { }
            entity.fleeSpritesNeeded = 0
            entity.fleeSpritesEnabled = 0
            entity.fleeDrops = nil
        end

        -- Target of this entity
        entity.target = nil

        if entity.maxhp == nil then
            entity.maxhp = entity.hp
        end

        -- Variables related to the damage texts of this entity
        entity.HPChangeTexts = { }
        entity.damageUIOffsetX = 0
        entity.damageUIOffsetY = 0

        entity.presetDamage = nil

        self.SetAnim(entity, "Idle")
    end

    -- If this entity is in the active players or active enemies table, get its ID in this table
    -- Otherwise, get the ID it'd have if it was added to the active table
    function self.GetEntityCurrentOrHypotheticalID(entity)
        local pool = entity.UI and self.players or self.enemies
        local hypothesis = #pool + 1
        for i = 1, #pool do
            if pool[i] == entity then
                return i
            elseif pool[i].ID > entity.ID then
                hypothesis = i
                break
            end
        end
        return hypothesis
    end

    -- Returns the table containing the indexes of the active players or active enemies
    function self.GetAvailableEntities(isPlayer)
        local tab = { }
        local pool = isPlayer and self.players or self.enemies
        for i = 1, #pool do
            if pool[i].hp > 0 then
                table.insert(tab, i)
            end
        end
        return tab
    end

    -- Gets an entity in the active players or active enemies table related to the entity given as parameter
    -- (Can be this entity itself or an entity which is after it in the active entity table)
    function self.GetEntityUp(target, arg2)
        local oldTarget = target
        if type(target) == "number" then
            target = arg2 and self.players[target] or self.enemies[target]
        end
        local pool = target.UI and self.players or self.enemies
        if not target.isactive or target.hp < 0 then
            if arg2 then
                local targetID = self.GetEntityCurrentOrHypotheticalID(target)
                if targetID > #pool then
                    targetID = 1
                end
                local i = targetID
                repeat
                    i = i + 1
                    if i > #pool then
                        i = 1
                    end
                    if pool[i].hp > 0 and pool[i].isactive then
                        return i
                    end
                until i == targetID
                return i
            else
                local availableTargets = { }
                for i = 1, #pool do
                    if pool[i].hp > 0 then
                        table.insert(availableTargets, i)
                    end
                end
                target = availableTargets[math.random(1, #availableTargets)]
                return target
            end
        end
        return oldTarget
    end

    -- Returns a table with some values related to the commands of an enemy and their availability
    function self.GetAvailableActions(enemy, withoutPlayerChars)
        local tab = { commands = table.copy(enemy.commands), isDown = { }, IDs = { } }
        for i = 1, #tab.commands do
            tab.isDown[i] = 1
            tab.IDs[i] = 1
        end
        for i = #tab.commands, 1, -1 do
            local command = tab.commands[i]
            local isOK = true
            local isOKButDown = false
            local lockedDown = false
            local IDs = { }
            if not enemy.acts or not enemy.acts[command] then
                break
            end
            if enemy.acts[command].requiredPlayers then
                local playersRequired = enemy.acts[command].requiredPlayers
                -- Check if this action requires other players
                if playersRequired then
                    for j = 1, #playersRequired do
                        local playerID = 0
                        local playerRequired = playersRequired[j]
                        isOK = false
                        -- Check if this required player is currently in the players table
                        local charAdded = false
                        for k = 1, #self.players do
                            local availablePlayer = self.players[k]
                            -- If this player is available, check for the other required players
                            if availablePlayer.name == playerRequired and availablePlayer ~= self.players[self.turn] then
                                playerID = availablePlayer.ID
                                if availablePlayer.hp <= 0 then
                                    isOKButDown = true
                                else
                                    isOKButDown = false
                                    isOK = true
                                    break
                                end
                            end
                        end

                        if not withoutPlayerChars and playerID > 0 then
                            local charToAdd = fontCharUsedForPlayer[self.allPlayers[playerID].name]
                            if charToAdd ~= nil then
                                tab.commands[i] = charToAdd .. tab.commands[i]
                            elseif CYKDebugLevel > 0 then
                                DEBUG("[WARN] There is no character for the Player with the name " .. tostring(self.allPlayers[playerID].name) .. " in the table fontCharUsedForPlayer.")
                            end
                        end

                        if isOKButDown then
                            lockedDown = true
                        end
                        if isOK or isOKButDown then
                            table.insert(IDs, playerID)
                        end
                    end
                end
            end
            if not lockedDown and not isOK then table.remove(tab.commands, i) table.remove(tab.isDown, i) table.remove(tab.IDs, i)
            else
                tab.isDown[i] = lockedDown
                tab.IDs[i] = IDs
            end
        end
        return tab
    end

    -- Gets the text of an enemy
    function self.GetEnemyText(enemy)
        --- Test if currentdialogue is a valid text
        local isText, text = CheckText(enemy.currentdialogue, true)
        if not isText then
            if CYKDebugLevel > 0 then
                if text == "empty"     then DEBUG("[WARN] The enemy #" .. tostring(i) .. " (\"" .. enemy.script["anim"] .. "\")'s currentdialogue variable is an empty table. Checking for randomdialogue instead.")
                elseif text == "nostr" then DEBUG("[WARN] The enemy #" .. tostring(i) .. " (\"" .. enemy.script["anim"] .. "\")'s currentdialogue variable is not a string or table. Checking for randomdialogue instead.")
                else                        DEBUG("[WARN] The enemy #" .. tostring(i) .. " (\"" .. enemy.script["anim"] .. "\")'s currentdialogue variable's #" .. text[1] .. " value is not a string. Checking for randomdialogue instead.")
                end
            end
            text = nil
        end

        -- No currentdialogue
        if not text then
            -- Test if randomdialogue is a valid text container
            local isText, res = CheckText(enemy.randomdialogue, false, true)
            if not isText then
                if CYKDebugLevel > 0 then
                    if text2 == "nil"       then DEBUG("[WARN] The enemy #" .. tostring(i) .. " (\"" .. enemy.script["anim"] .. "\")'s currentdialogue and randomdialogue variables are nil. Using an empty text instead.")
                    elseif text2 == "empty" then DEBUG("[WARN] The enemy #" .. tostring(i) .. " (\"" .. enemy.script["anim"] .. "\")'s randomdialogue variable is an empty table. Using an empty text instead.")
                    elseif text2 == "nostr" then DEBUG("[WARN] The enemy #" .. tostring(i) .. " (\"" .. enemy.script["anim"] .. "\")'s randomdialogue variable is not a table. Using an empty text instead.")
                    else                         DEBUG("[WARN] The enemy #" .. tostring(i) .. " (\"" .. enemy.script["anim"] .. "\")'s randomdialogue variable's #" .. res[1] .. " value is not a string or table. Using an empty text instead.")
                    end
                end
                text = { "" }
            else
                -- Test if the selected value of randomdialogue is a valid text
                local randomIndex = math.random(1, #enemy.randomdialogue)
                local randomText = enemy.randomdialogue[randomIndex]
                local isText, text2 = CheckText(randomText)
                if not isText then
                    if CYKDebugLevel > 0 then
                        if text2 == "empty"     then DEBUG("[WARN] The enemy #" .. tostring(i) .. " (\"" .. enemy.script["anim"] .. "\")'s randomdialogue variable's #" .. randomIndex .. " value is an empty table. Using an empty text instead.")
                        elseif text2 == "nostr" then DEBUG("[WARN] The enemy #" .. tostring(i) .. " (\"" .. enemy.script["anim"] .. "\")'s randomdialogue variable's #" .. randomIndex .. " value is not a string or table. Using an empty text instead.")
                        else                         DEBUG("[WARN] The enemy #" .. tostring(i) .. " (\"" .. enemy.script["anim"] .. "\")'s randomdialogue variable's #" .. randomIndex .. " value's #" .. text2[1] .. " value is not a string. Using an empty text instead.")
                        end
                    end
                    text = { "" }
                else
                    text = text2
                end
            end
        end

        -- Replace all func calls
        local superText = text
        for j = 1, type(superText) == "table" and #superText or 1 do
            text = type(superText) == "table" and superText[j] or superText

            local funcs = string.split(text, "%[ *func *: *", true)
            if #funcs > 1 then
                text = funcs[1]
                for i = 2, #funcs do
                    local textPart = funcs[i]
                    local func = string.split(textPart, "]")[1]
                    local startFuncLength = #func
                    func = string.gsub(string.gsub(func, "{", ""), "}", "")
                    textPart = "[func:CallEntityFunc,{false," .. tostring(enemy.ID) .. "," .. func .. "}" .. string.sub(textPart, startFuncLength + 1, #textPart)
                    text = text .. textPart
                end
                if type(superText) == "table" then
                    superText[j] = text
                end
            end
        end
        return superText
    end

    -- Get the enemy's bubble sprite
    function self.GetBubbleSprite(enemy)
        local bubble = enemy.dialogbubble
        if not bubble then
            if CYKDebugLevel > 0 then
                DEBUG("[WARN] The bubble of the enemy \"" .. enemy.sprite["anim"] .. "\" is nil. Using the bubble DRBubble instead.")
            end
            bubble = "DRBubble"
        elseif not table.containsObj(self.BubbleData, bubble) then
            if CYKDebugLevel > 0 then
                DEBUG("[WARN] The bubble \"" .. enemy.dialogbubble .. "\" of the enemy \"" .. enemy.sprite["anim"] .. "\" isn't in the file BubbleData. Using the bubble DRBubble instead.")
            end
            bubble = "DRBubble"
        end

        local bubbleData = self.BubbleData[bubble]
        if not bubbleData then
            error("The bubble DRBubble is missing from the BubbleData file!")
        end

        local bubbleSprite = CreateSprite("UI/SpeechBubbles/" .. bubble)
        bubbleSprite.SetParent(enemy.sprite)
        bubbleSprite.SetAnchor(0, 1)
        bubbleSprite.SetPivot(0, 1)
        bubbleSprite.x = (bubbleData.side == "right" and enemy.sprite.width or
                          bubbleData.side == "left"  and -bubbleSprite.width or
                                                         (bubbleSprite.width - enemy.sprite.width) / 2) + enemy.bubbleOffsetX + 0.01
        bubbleSprite.y = (bubbleData.side == "up"    and bubbleSprite.height or
                          bubbleData.side == "down"  and -enemy.sprite.height or
                                                         (bubbleSprite.height - enemy.sprite.height) / 2) + enemy.bubbleOffsetY + 0.01

        return bubbleSprite, bubbleData
    end

    -- Updates the entity's position if he's hurt
    function self.UpdateEntityHurting()
        local pools = { self.players, self.enemies }
        for i = 1, #pools do
            local pool = pools[i]
            for j = 1, #pool do
                local entity = pool[j]
                if entity.sprite["currAnim"] == "Hurt" then
                    local totalHurtAnimTime = entity.animations["Hurt"][2]
                    local currentTime = Time.time - entity.sprite["lastAnimTime"]
                    local speed = (1 - currentTime / totalHurtAnimTime) * 2
                    local hurtMovePlus = entity.sprite["hurtMovePlus"]

                    if not hurtMovePlus then
                        entity.sprite.absx = entity.posX - 6 * (speed > 1 and 1 or speed)
                    else
                        entity.sprite.absx = entity.posX
                    end

                    local betweenLastMove = entity.lastEntityHurtingMove and self.frame - entity.lastEntityHurtingMove or self.frame
                    if betweenLastMove >= 6 then
                        entity.lastEntityHurtingMove = self.frame
                        entity.sprite["hurtMovePlus"] = not hurtMovePlus
                    end
                end
            end
        end
    end

    -- Updates a target's flash sprite's alpha
    self.lastBgAnim = nil
    function self.UpdateFlash()
        if self.state == "ENEMYSELECT" then
            local player = self.players[self.turn]
            local pool = player.targetType == "Enemy" and self.enemies or self.players
            pool[self.GetRealChoiceIndex()].sprite["f"].color = { 1, 1, 1 }
            pool[self.GetRealChoiceIndex()].sprite["f"].alpha = self.frame % 60 < 30 and self.frame % 60 / 40 + .25 or (60 - (self.frame % 60)) / 40 + .25
        elseif self.Background and self.Background.anim then
            -- Grey out all normally unharmed players
            self.lastBgAnim = self.Background.anim
            if self.Background.maxHideTimer > 0 then
                for i = 1, #self.players do
                    if self.players[i].hp <= 0 or (self.playerTargets[1] ~= 0 and not table.containsObj(self.playerTargets, i, true)) then
                        local coeff = self.Background.hideTimer / self.Background.maxHideTimer * 0.5
                        self.players[i].sprite["f"].alpha = self.Background.anim == "show" and coeff or 0.5 - coeff
                        self.players[i].sprite["f"].color = { 0, 0, 0 }
                    else
                        self.players[i].sprite["f"].alpha = 0
                    end
                end
            end
        elseif self.lastBgAnim then
            for i = 1, #self.players do
                if self.players[i].hp <= 0 or (self.playerTargets[1] ~= 0 and not table.containsObj(self.playerTargets, i, true)) then
                    self.players[i].sprite["f"].alpha = self.lastBgAnim == "show" and 0 or 0.5
                else
                    self.players[i].sprite["f"].alpha = 0
                end
            end
            self.lastBgAnim = nil
        end
    end

    function self.UpdateFlee(entity)
        local frame = self.frame - entity.spareOrFleeStart - 1
        if frame == 0 then
            entity.sprite.StopAnimation()
            entity.sprite.Set(self.anims[entity.sprite["anim"]].Hurt[1][1])
            PlaySoundOnceThisFrame("enemyflee")
            entity.fleeDrops = CreateSprite("CreateYourKris/fleeEnemy", "Entity")
            entity.fleeDrops.SetParent(entity.sprite)
            entity.fleeDrops.SetPivot(1, 1)
            entity.fleeDrops.SetAnchor(0, 1)
            entity.fleeDrops.x = 0
            entity.fleeDrops.y = 0
            entity.fleeSpritesNeeded = math.ceil((640 - entity.sprite.absx) / 4)
            entity.fleeSpritesEnabled = 0
        end
        if frame < 30 then
            while #entity.fleeSprites < math.ceil((frame + 1) / 30 * entity.fleeSpritesNeeded) do
                local fleeSprite = CreateSprite(self.anims[entity.sprite["anim"]].Hurt[1][1], "Entity")
                fleeSprite.SetParent(entity.sprite)
                fleeSprite.SetPivot(0, 0)
                fleeSprite.SetAnchor(0, 0)
                fleeSprite.x = #entity.fleeSprites * 4
                fleeSprite.y = 0
                fleeSprite.alpha = 0
                table.insert(entity.fleeSprites, fleeSprite)
            end
        elseif frame >= 30 then
            if frame == 30 then
                entity.sprite.alpha = 0
            end
            entity.fleeSpritesEnabled = entity.fleeSpritesEnabled + 10
            for i = 1, math.min(entity.fleeSpritesEnabled, #entity.fleeSprites) do
                entity.fleeSprites[i].alpha = i == entity.fleeSpritesEnabled and 1 or 0.5 - ((entity.fleeSpritesEnabled - i) / 200)
            end
            if entity.fleeSpritesEnabled >= #entity.fleeSprites + 100 then
                while #entity.fleeSprites > 0 do
                    entity.fleeSprites[1].Remove()
                    table.remove(entity.fleeSprites, 1)
                end
                entity.fleeDrops.Remove()
                entity.fleeDrops = nil
                entity.spareOrFleeStart = 0
                return
            end
        end
        if frame == 12 or frame == 30 then
            entity.fleeDrops.alpha = 0
        elseif frame == 18 then
            entity.fleeDrops.alpha = 1
        end
    end

    function self.UpdateSpare(entity)
        local frame = self.frame - entity.spareOrFleeStart - 1
        if frame == 0 then
            self.SetAnim(entity, "Spareable")
            PlaySoundOnceThisFrame("spare")
        elseif frame < 20 then
            entity.sprite["f"].alpha = frame / 15
        elseif frame == 20 then
            entity.sprite["f"].alpha = 1
        elseif frame < 60 then
            entity.sprite.x = entity.sprite.x + 2
            entity.sprite.alpha = 1 - ((frame - 20) / 40)
            entity.sprite["f"].x = entity.sprite["f"].x + 2
            entity.sprite["f"].alpha = 1 - ((frame - 20) / 20)
        elseif frame == 60 then
            entity.spareOrFleeStart = 0
        end

        -- Create a new star!
        if frame % 2 == 0 and frame >= 10 and frame < 30 then
            local star = CreateSprite("CreateYourKris/SpareStars/0", "Entity")
            star.MoveBelow(entity.sprite)
            star.x = math.random(0, entity.sprite.width)
            star.y = math.random(0, entity.sprite.height)
            star["startFrame"] = frame
            star.MoveAbove(entity.sprite)
            table.insert(entity.spareStars, star)
        end

        for i = #entity.spareStars, 1, -1 do
            local star = entity.spareStars[i]
            local starFrame = frame - star["startFrame"]
            if starFrame % 5 == 0 then
                if starFrame == 30 then
                    star.Remove()
                    table.remove(entity.spareStars, i)
                else
                    star.Set("CreateYourKris/SpareStars/" .. tostring(starFrame / 5))
                end
            end
            if star.isactive then
                if starFrame >= 10 then
                    star.rotation = star.rotation + (8 * (1 - ((starFrame - 10) / 20)))
                    star.x = star.x + 1 * (starFrame <= 20 and 0.5 or 0.5 - ((starFrame - 20) / 10))
                end
                if starFrame > 20 then
                    star.alpha = 1 - ((starFrame - 20) / 10)
                end
            end
        end
    end

    -- Build the Player entities
    for i = 1, #self.allPlayers do
        self.GetEntity(self.allPlayers[i], i, true)
    end

    -- Build the enemy entities
    for i = 1, #self.allEnemies do
        self.GetEntity(self.allEnemies[i], i)
    end

    OldBattleDialog = BattleDialog
    function BattleDialog(text)
        if type(text) ~= "table" or type(text[1]) ~= "string" then
            error("BattleDialog() needs a table of strings as argument.")
        end
        self.TxtMgr.SetText(text)
    end
end