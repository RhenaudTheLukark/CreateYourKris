return function ()
    -- Check CYF version
    local isOK = true

    if not isCYF then
        isOK = false
    elseif CYFversion < "0.6.2.2" or CYFversion == "1.0" then
        isOK = false
    end

    if not isOK then
        error("Create Your Kris can only be used in Create Your Frisk v0.6.2.2 or a newer version.")
    end

    -- Almost everything in CYK is handled in the state NONE!
    OldState("NONE")

    -- Crate Your Kris: troll song
    if CrateYourKris then
        Audio.LoadFile("mus_battle1_troll")
        Audio.Pause()
        Audio.Volume(1)
    end

    -- Layers!
    CreateLayer("Background", "Top", true)
    CreateLayer("Entity", "Background")
    CreateLayer("LowerUI", "Entity")
    CreateLayer("UpperUI", "LowerUI")
    CreateLayer("Arena", "UpperUI")
    CreateLayer("Bullet", "Arena")

    self = { }                                       -- Self container of everything and such
    unescape = unescape == nil and true or unescape  -- The QUITTING text is enabled by default

    self._ENV_BASE = _ENV_BASE   -- Creates a sandbox used when loading entity libraries

    self.frame = 0               -- Frame counter
    self.state = "BEGIN"         -- Game state
    self.turn = 1                -- ID of the Player whose actions are waited for
    self.choiceIndex = 1         -- Index used for any choice-based system
    self.choiceIndexLimit = 5    -- Limit the choiceIndex variable can't go through
    self.hasEnemyTargetsBeenReset = true -- Self-explanatory

    -- Used to display a text when the Player presses the Escape key for a while, then exits CYK if needed
    self.escapeFrame = 0         -- Amount of frames during which the player pressed the ESCAPE key
    self.quitting = CreateSprite("CreateYourKris/UI/Quitting/0", "LowerUI")
    self.quitting.SetPivot(0, 1)
    self.quitting.absx = 4
    self.quitting.absy = 476
    self.quitting.alpha = 0

    self.CrateYourKris = CrateYourKris -- Crate Your Kris

    require ("Libraries/CYK/SpellData")(self)     -- Handles the spells
    require ("Libraries/CYK/Animation")(self)     -- Handles all the animations
    require ("Libraries/CYK/EntityManager")(self) -- Handles all the entities

    self.turnTPs = { }    -- Stores the value of the TP gauge at each Player's turn
    self.turnMultis = { } -- Stores all the Players ID relted to Act choices that require other Players

    -- Include the subsystems
    self.TP = (require "Libraries/CYK/TPBar")(self)                  -- Handles everything related to TP (except the variable above)
    self.UI = (require "Libraries/CYK/UI")(self)                     -- UI manager
    self.TxtMgr = (require "Libraries/CYK/TextManager")(self)        -- Handles all of CYK's texts
    self.AtkMgr = (require "Libraries/CYK/AttackManager")(self)      -- Handles everything related to the Fight command
    self.Inventory = (require "Libraries/CYK/Inventory")(self)       -- Inventory management
    self.ScreenShake = (require "Libraries/CYK/ScreenShake")(self)   -- Screen shaking handler
    self.BubbleData = require "Libraries/CYK/BubbleData"             -- Lists all the bubbles usable in CYK

    -- Background! You can disable it by setting the variable background to false
    self.Background = (require "Libraries/CYK/Background")(self, background, backgroundfade)

    -- Sets the Player's sprite
    Player.sprite.Set("CreateYourKris/ut-heart")
    Player.sprite.SetParent(self.UI.hider)
    Player.sprite.alpha = 0

    -- Sprite used in waves to tell the player he grazed a bullet
    self.grazeSprite = CreateSprite("CreateYourKris/playerGraze")
    self.grazeSprite.SetParent(Player.sprite)
    self.grazeSprite.alpha = 0
    self.grazeSprite.x = 0
    self.grazeSprite.y = 0

    -- Hitbox sprite used to detect if the player grazed a bullet
    self.grazeHitbox = CreateSprite("px")
    self.grazeHitbox.SetParent(Player.sprite)
    self.grazeHitbox.Scale(40, 40)
    self.grazeHitbox.alpha = 0
    self.grazeHitbox.x = 0
    self.grazeHitbox.y = 0
    self.grazeHitbox = { sprite = self.grazeHitbox }

    self.playerTargets = { } -- Players targeted by the enemies

    -- Triggered when the player presses the Confirm key
    function self.Confirm(force)
        -- State when the player chooses his Players' actions
        local player = self.players[self.turn]
        local realChoice = self.GetRealChoiceIndex()
        if self.state == "ACTIONSELECT" then
            -- Choice between Fight, Act/Magic, Item, Spare, Defend
            PlaySoundOnceThisFrame("menuconfirm")
            self.turnTPs[self.turn] = self.TP.trueValue

            player.action = player.UI.buttonNames[self.choiceIndex]

            -- FIGHT
            if self.choiceIndex == 1 then
                player.targetType = "Enemy"
                self.State("ENEMYSELECT")
            -- ACT/MAGIC
            elseif self.choiceIndex == 2 then
                -- Case ACT
                if table.containsObj(player.abilities, "Act") then
                    player.targetType = "Enemy"
                    self.State("ENEMYSELECT")
                -- Case MAGIC
                else
                    self.State("ACTMENU")
                end
            -- ITEM
            elseif self.choiceIndex == 3 then
                if #self.Inventory.GetCurrentInventory().inventory > 0 then
                    self.State("ITEMMENU")
                end
            -- SPARE
            elseif self.choiceIndex == 4 then
                player.targetType = "Enemy"
                self.State("ENEMYSELECT")
            -- DEFEND
            elseif self.choiceIndex == 5 then
                -- Add 16 TP to the team
                self.TP.Set(16, true)
                self.SetAnim(player, "Defend")
                self.ChangePlayerTurn("Defend")
            end
        -- State used when the player is choosing actions (Check, Flirt, Talk...), spells (Pacify, Heal Prayer...) or items (Lancer Cookie, TopCake...)
        elseif self.state == "ACTMENU" or self.state == "ITEMMENU" then
            -- ACT
            if player.action == "Act" then
                -- Check if this Act command requires any other Player's action
                local availableActions = self.GetAvailableActions(player.target, true)
                -- If it does, check if any required Player is down. If there's any, don't do anything
                if availableActions.isDown[realChoice] then
                    PlaySoundOnceThisFrame("menumove")
                    return
                end
                player.subAction = availableActions.commands[realChoice]
                -- Prepare the other Players needed for the current action too
                for i = 1, #availableActions.IDs[realChoice] do
                    local player = self.allPlayers[availableActions.IDs[realChoice][i]]
                    self.SetAnim(player, "PrepareAct")
                    player.action = "MultiAct"
                    player.UI.faceSprite.Set("CreateYourKris/Players/" .. player.sprite["anim"] .. "/UI/Act")
                end
                self.turnMultis[self.turn] = availableActions.IDs[realChoice]
                PlaySoundOnceThisFrame("menuconfirm")
                self.ChangePlayerTurn("PrepareAct")
            -- MAGIC
            elseif player.action == "Magic" then
                player.subAction = player.abilities[realChoice]
                local spell = self.spells[player.subAction]
                -- Check if the player has enough TP to use this spell
                if spell.tpCost > self.TP.trueValue then
                    PlaySoundOnceThisFrame("menumove")
                    return
                end
                PlaySoundOnceThisFrame("menuconfirm")
                player.targetType = spell.targetType
                self.State("ENEMYSELECT")
            -- ITEM
            else
                PlaySoundOnceThisFrame("menuconfirm")
                local inventory = self.Inventory.GetCurrentInventory()
                local itemData = self.Inventory.items[inventory.inventory[realChoice]]

                player.subAction = realChoice

                self.Inventory.turnItemsUsed[self.turn] = realChoice

                -- If this item targets all entities of a given type, you don't need to choose a target
                if string.match(itemData.targetType, "All") then
                    self.ChangePlayerTurn("PrepareItem")
                else
                    player.targetType = itemData.targetType
                    self.State("ENEMYSELECT")
                end
            end
        -- State used when the player is choosing a target
        elseif self.state == "ENEMYSELECT" then
            PlaySoundOnceThisFrame("menuconfirm")
            player.target = (player.targetType == "Enemy" and self.enemies or self.players)[realChoice]
            -- ACT
            if player.action == "Act" then
                self.State("ACTMENU")
            -- FIGHT
            elseif player.action == "Fight" then
                self.ChangePlayerTurn("PrepareFight")
            -- MAGIC
            elseif player.action == "Magic" then
                self.ChangePlayerTurn("PrepareMagic")
            -- SPARE
            elseif player.action == "Spare" then
                self.ChangePlayerTurn("PrepareSpare")
            -- ITEM
            else
                self.ChangePlayerTurn("PrepareItem")
            end
        -- State when the Players are actually doing something
        elseif self.state == "PLAYERTURN" then
            -- Only when the encounter text is finished or the next turn is forced
            if ((self.TxtMgr.text.allLinesComplete or self.turn == 0) and not self.stopPlayerTurnProgress) or force then
                self.stopPlayerTurnProgress = false
                -- Time for the enemies to talk if all the players did something
                if self.SetTurn(1, true) == "after" then
                    self.State("ENEMYDIALOGUE")
                else
                    -- If there are no enemy left, end the battle
                    if #self.enemies == 0 then
                        self.State("BEFOREDONE")
                        return
                    end

                    local player = self.players[self.turn]
                    local enemy = player.target
                    local hasAnimNow = true

                    -- Do something for this Player!
                    local availableActions = nil
                    -- ACT
                    if player.action == "Act" and enemy and player.subAction ~= "" then
                        availableActions = self.GetAvailableActions(enemy, true)
                        ProtectedCYKCall(enemy.HandleCustomCommand, player, player.subAction)
                    -- MAGIC
                    elseif player.action == "Magic" and player.subAction ~= "" then
                        ProtectedCYKCall(player.HandleCustomSpell, enemy, player.subAction)
                    -- ITEM
                    elseif player.action == "Item" and player.subAction ~= ""  then
                        local itemData = self.Inventory.items[self.Inventory.inventory[player.subAction]]
                        local targets = { }
                        -- Get the targets of the item
                        if string.match(itemData.targetType, "All") then
                            targets = string.match(itemData.targetType, "Player") and self.players or self.enemies
                        else
                            table.insert(targets, enemy)
                        end
                        local item = self.Inventory.inventory[player.subAction]
                        -- Use the item
                        self.Inventory.UseItem(player.subAction)
                        ProtectedCYKCall(HandleItem, player, targets, item, itemData)
                    -- SPARE
                    elseif player.action == "Spare" and enemy then
                        -- Get another entity if this one has already been deactivated
                        if not enemy.isactive then
                            enemy = self.enemies[self.GetEntityUp(enemy, true)]
                            player.target = enemy
                        end
                        -- Build the SPARE text
                        local text = player.name .. (self.CrateYourKris and " SPERD " or " spared ") .. enemy.name .. (self.CrateYourKris and "!!" or "!")
                        if not enemy.canspare then
                            text = text .. (self.CrateYourKris and "\nBTU NO [color:ffff00]YEELO[color:ffffff]!?!" or "\nBut his name was not [color:ffff00]YELLOW[color:ffffff]...")
                        end
                        self.TxtMgr.SetText({ text })
                        ProtectedCYKCall(HandleSpare, player, enemy)
                        if enemy.canspare then
                            -- Actually spare the enemy
                            enemy.TrySpare()
                        end
                    else
                        hasAnimNow = false
                    end
                    -- If the Player's last action is valid, then use an animation for it
                    if hasAnimNow then
                        self.SetAnim(player, player.action == "Act" and "Spare" or player.action)
                        -- If the Player's last action is to use an Act, also set the animation of the other players needed to perform this action
                        if player.action == "Act" then
                            if enemy.multicommands[string.gsub(player.subAction, " ", "_")] then
                                for i = 1, #availableActions.commands do
                                    if availableActions.commands[i] == player.subAction then
                                        for j = 1, #availableActions.IDs[i] do
                                            local player = self.allPlayers[availableActions.IDs[i][j]]
                                            player.action = ""
                                            self.SetAnim(player, "Spare")
                                        end
                                    end
                                end
                            end
                        end
                    -- Otherwise go to the next turn directly
                    else
                        self.Confirm(true)
                    end
                end
            -- If the text is not completely done, go to the next line
            elseif self.TxtMgr.text.lineComplete then
                self.TxtMgr.ScanTextLine(true)
            end
        -- State where the players are attacking the enemies
        elseif self.state == "ATTACKING" then
            self.AtkMgr.Confirm()
        -- State where the enemies are talking
        elseif self.state == "ENEMYDIALOGUE" then
            local allLinesComplete = true
            local lineComplete = true
            for i = 1, #self.enemies do
                local enemy = self.enemies[i]
                -- Check if this enemy's text is finished
                if enemy.bubbleTextObject then
                    if not enemy.bubbleTextObject.allLinesComplete then
                        allLinesComplete = false
                    end
                    if not enemy.bubbleTextObject.lineComplete then
                        lineComplete = false
                        break
                    end
                end
            end
            -- If all the texts are finished, jump to the wave
            if allLinesComplete then
                self.State("DEFENDING")
            -- If not all the texts are finished, go to their next line
            elseif lineComplete then
                for i = 1, #self.enemies do
                    local enemy = self.enemies[i]
                    if enemy.bubbleTextObject then
                        -- If this text object is finished, destroy it early
                        if enemy.bubbleTextObject.allLinesComplete then
                            enemy.bubbleTextObject.DestroyText()
                            enemy.bubbleTextObject = nil
                            enemy.bubble.Remove()
                            enemy.bubble = nil
                        else
                            enemy.bubbleTextObject.NextLine()
                            enemy.bubble.alpha = (enemy.lastBubbleText[enemy.bubbleTextObject.currentLine + 1] == "" and 0 or 1)
                        end
                    end
                end
            end
        -- State just before the encounter is done
        elseif self.state == "BEFOREDONE" then
            -- Remove an annoying sound at the end of the encounter
            Audio["menuconfirm"] = "silence"
            -- If the main text object is finished and all of the Players' animation ended, end the encounter for real
            if self.TxtMgr.text.allLinesComplete then
                for i = 1, #self.players do
                    if not (self.players[i].sprite["currAnim"] ~= "EndBattle" or self.players[i].sprite.animcomplete) then return end
                end
                self.State("DONE")
            end
        end
    end

    -- Function executed when switching the engine's current state
    function self.EnteringState(state)
        -- State where we're choosing a target
        if state == "ENEMYSELECT" then
            local player = self.players[self.turn]
            local targets = { }
            local gradientText = { "[font:uidialog][novoice][instant]" }
            local targetPool = player.targetType == "Enemy" and self.enemies or self.players

            -- Add each target (Player or enemy) in the target choice
            for i = 1, #targetPool do
                local entity = targetPool[i]
                local name = entity.name
                local pre = ""
                local post = ""
                local gradientName = ""
                -- Adds colors to the enemy names if they're spareable or pacifiable
                if player.targetType == "Enemy" then
                    pre = entity.canspare and "[color:ffff00]" or entity.tired and "[color:00b2ff]" or ""
                    post = "[color:ffffff]      " .. (entity.canspare and "è" or "ê") .. (entity.tired and "é[color:808080](Tired)[color:ffffff]" or "ê")
                    if entity.canspare and entity.tired then
                        gradientName = "[color:00b2ff]"
                        local chars = #name - 1
                        -- Gradient effect
                        for i = 0, chars do
                            local val = math.floor(i / chars * 255)
                            local alpha = NumberToHex(val)
                            gradientName = gradientName .. "[alpha:" .. (val < 16 and ("0" .. alpha) or alpha) .. "]" .. string.sub(name, i + 1, i + 1)
                        end
                    end
                end
                table.insert(targets, pre .. name .. post)
                gradientText[i] = (gradientText[i] and gradientText[i] or "") .. gradientName .. "[alpha:00]"
            end
            self.TxtMgr.SetChoice(targets, true, false, nil, gradientText)
            self.MovePlayer()
        -- State when choosing an action, a spell or an item
        elseif state == "ACTMENU" or state == "ITEMMENU" then
            local player = self.players[self.turn]
            local actions = { }
            local pool = player.action
            local actionPool = pool == "Magic" and player.abilities or pool == "Item" and self.Inventory.GetCurrentInventory() or player.target.commands

            -- If we're choosing an item, fetch the remaining items
            local availableActions = nil
            if pool == "Item" then
                actionPool = actionPool.inventory
            -- If we're choosing an action, don't include the actions requiring other Players if they're not available
            elseif pool == "Act" then
                availableActions = self.GetAvailableActions(player.target)
                actionPool = availableActions.commands
            end

            -- Add each action/item/spell to the next choice
            for i = 1, #actionPool do
                local name = actionPool[i]
                local cost = 0
                local isEnemyTired = false
                local isMultiActPlayerDown = false
                if pool == "Magic" then
                    if self.spells[actionPool[i]] == nil then
                         error("The spell " .. tostring(actionPool[i]) .. " doesn't exist.")
                    end
                    cost = self.spells[actionPool[i]].tpCost
                    -- Set the SPELL "Pacify" in blue if an enemy can be put asleep
                    if name == "Pacify" then
                        for j = 1, #self.enemies do
                            if self.enemies[j].tired then
                                isEnemyTired = true
                                break
                            end
                        end
                        name = isEnemyTired and "[color:00b2ff]Pacify" or name
                    end
                end
                local pre = (((pool == "Magic" and cost > self.TP.trueValue) or (pool == "Act" and availableActions.isDown[i])) and "[color:808080]" or "[color:ffffff]")
                table.insert(actions, pre .. (pre ~= "" and actionPool[i] or name))
            end

            -- Displays the choice and stuff
            self.TxtMgr.SetChoice(actions, false, true, pool == "Magic" or pool == "Item")
            self.MovePlayer()

            -- Updates the description text if we need it
            if pool == "Magic" or pool == "Item" then
                local data = (pool == "Magic" and self.spells or self.Inventory.items)[actionPool[1]]
                self.TxtMgr.textDescription.SetText({ data.description })
                if pool == "Magic" then
                    self.TP.PreviewTPLoss(data.tpCost)
                end
            end
        -- State when the enemies are talking
        elseif state == "ENEMYDIALOGUE" then
            for i = 1, #self.enemies do
                local enemy = self.enemies[i]
                local bubbleData = nil
                enemy.bubble, bubbleData = self.GetBubbleSprite(enemy)

                -- Choose a text for the enemy
                enemy.lastBubbleText = self.GetEnemyText(enemy)
                enemy.currentdialogue = nil
                local text = table.copy(enemy.lastBubbleText)
                for j = 1, #text do
                    text[j] = "[effect:none]" .. text[j]
                end

                enemy.bubble.alpha = (enemy.lastBubbleText[1] == "" and 0 or 1)

                -- Creates the enemy's bubble text
                enemy.bubbleTextObject = CreateText(text, {600, 200}, bubbleData.wideness, "Top")
                enemy.bubbleTextObject.SetParent(enemy.bubble)
                enemy.bubbleTextObject.progressmode = "none"
                enemy.bubbleTextObject.HideBubble()
                enemy.bubbleTextObject.x = bubbleData.x
                enemy.bubbleTextObject.y = -bubbleData.y
            end
            self.ResetEnemyTargets()
        end
    end

    -- Resets the targets of all enemies
    function self.ResetEnemyTargets()
        self.hasEnemyTargetsBeenReset = true
        self.playerTargets = { }
        for i = 1, #self.enemies do
            local enemy = self.enemies[i]
            -- If the enemy's targetType value is a number, then it'll always target the same player
            if type(enemy.targetType) == "number" and enemy.targetType > 0 and enemy.targetType < #self.allPlayers then
                enemy.target = self.GetEntityUp(self.allPlayers[enemy.targetType], true)
            else
                local availablePlayers = self.GetAvailableEntities(true, true)

                -- If the enemy's targetType is all, it'll target all non-down Players
                -- Otherwise it'll target a random Player
                enemy.target = enemy.targetType == "all" and 0 or availablePlayers[math.random(1, #availablePlayers)]
                if enemy.targetType == "all" then
                    self.playerTargets = { 0 }
                end
            end
            if not table.containsObj(self.playerTargets, enemy.target, true) and self.playerTargets[1] ~= 0 then
                table.insert(self.playerTargets, enemy.target)
            end
        end
    end

    -- Function executed when the modder calls the State() function
    function self.PlayerState(newState, arg1, arg2, arg3)
        if CYKDebugLevel > 2 then
            DEBUG("State " .. tostring(newState) .. (arg1 and ": " .. tostring(arg1) .. (arg2 and ", " .. tostring(arg2) .. (arg3 and ", " .. tostring(arg3) or "") or "") or ""))
        end

        -- Tests
        -- Some states need a player index
        if (newState == "ACTIONSELECT" or newState == "ENEMYSELECT" or newState == "ACTMENU" or newState == "ITEMMENU") and (type(arg1) ~= "number" or arg1 < 1 or arg1 > #self.players) then
            error("The state " .. newState .. " needs its first argument to be the index of the player we're choosing the action of, between 1 and the number of players.")
        -- ENEMYSELECT wrong type
        elseif newState == "ENEMYSELECT" and arg2 ~= "ITEM" and arg2 ~= "FIGHT" and arg2 ~= "ACT" and arg2 ~= "SPELL" and arg2 ~= "SPARE" then
            error("The state ENEMYSELECT needs its second argument to be either \"ITEM\", \"FIGHT\", \"ACT\", \"SPELL\" or \"SPARE\".")
        -- ITEM doesn't exist
        elseif newState == "ENEMYSELECT" and arg2 == "ITEM" and (type(arg3) ~= "number" or arg3 < 1 or arg3 > #self.Inventory.GetCurrentInventory().inventory) then
            error("The state ENEMYSELECT needs its third argument to be the index of the item the player is using, between 1 and the number of items in the player's inventory.")
        -- ITEM choice when used on all entities
        elseif newState == "ENEMYSELECT" and arg2 == "ITEM" and string.find(self.Inventory.items[self.Inventory.GetCurrentInventory().inventory[arg3]].targetType, "All") then
            error("You can't choose an entity for the item #" .. tostring(arg3) .. " (" .. self.Inventory.GetCurrentInventory().inventory[arg3] .. ") as it targets all the players or enemies.")
        -- SPELL on Player with Act
        elseif newState == "ENEMYSELECT" and arg2 == "SPELL" and table.containsObj(self.players[arg1].abilities, "Act") then
            error("The Player " .. tostring(self.players[arg1].sprite["anim"]) .. " has the ability \"Act\", so you can't access its spells.")
        -- SPELL with wrong index
        elseif newState == "ENEMYSELECT" and arg2 == "SPELL" and (type(arg3) ~= "number" or arg3 < 1 or arg3 > #self.players[arg1].abilities) then
            error("The state ENEMYSELECT needs its third argument to be the index of an ability (spell) the player has, between 1 and the number of abilities the player has.")
        -- ACT on Player with no Act
        elseif newState == "ENEMYSELECT" and arg2 == "ACT" and not table.containsObj(self.players[arg1].abilities, "Act") then
            error("The Player " .. tostring(self.players[arg1].sprite["anim"]) .. " doesn't have the ability \"Act\", so you can't access the ACT menu with them.")
        -- ACT with wrong enemy index
        elseif newState == "ACTMENU" and (type(arg1) ~= "number" or arg1 < 1 or arg1 > #self.enemies) then
            error("The state ACTMENU needs its first argument to be the index of the enemy we're targeting, between 1 and the number of enemies.")
        -- FIGHT with no attacking player table
        elseif newState == "ATTACKING" and (arg1 ~= nil and type(arg1) ~= "table") then
            error("The state ATTACKING needs its first argument to be a table of tables or nil.")
        -- FIGHT, check player indexes
        elseif newState == "ATTACKING" and type(arg1) == "table" then
            local attackingPlayers = { }
            local targetedEnemies = { }
            for i = 1, #arg1 do
                local arg1tab = arg1[i]
                if type(arg1tab) ~= "table" then
                    error("The state ATTACKING needs its first argument to be a table of tables or nil.")
                else
                    if arg1tab[2] < 1 or arg1tab[2] > #self.enemies then
                        error("Each of the state ATTACKING's tables of tables must contain two values: first the index of the attacking player then the index of the enemy targeted. The targeted enemy's index is invalid.")
                    end
                    if arg1tab[1] < 1 or arg1tab[1] > #self.players then
                        error("Each of the state ATTACKING's tables of tables must contain two values: first the index of the attacking player then the index of the enemy targeted. The attacking player's index is invalid.")
                    end
                    if table.containsObj(attackingPlayers, arg1tab[1], true) then
                        if CYKDebugLevel > 1 then
                            DEBUG("[WARN] The player #" .. arg1tab[1] .. " has been added several times while entering the state ATTACKING.")
                        end
                    else
                        table.insert(attackingPlayers, arg1tab[1])
                        table.insert(targetedEnemies, arg1tab[2])
                    end
                end
            end
            arg1 = { attackingPlayers, targetedEnemies }
        end

        local secondaryData = nil

        -- Apply the arguments
        local player = self.players[self.turn]
        if player ~= nil then
            player.action = ""
            player.subAction = ""
        end
        -- If the old state is ENEMYSELECT, set the player's targetType
        if self.state == "ENEMYSELECT" then
            secondaryData = player.targetType
            if player.action == "Magic" then
                self.TP.Set(self.turnTPs[self.turn])
            end
            player.action = ""
        end
        -- Change the turn value if we're in a state in which the turn value matters
        if newState == "ACTIONSELECT" or newState == "ENEMYSELECT" or newState == "ACTMENU" or newState == "ITEMMENU" then
            self.turn = arg1
            player = self.players[arg1]
        end
        -- If we're entering the state ENEMYSELECT, then we have to check what context we are in
        if newState == "ENEMYSELECT" then
            player = self.players[self.turn]
            -- If we're choosing an item's target, set the current Player's targetType as the targetType of the item we're using
            if arg2 == "ITEM" then
                self.EnableButton(self.turn, 3)
                player.action = "Item"
                player.targetType = self.Inventory.items[self.Inventory.GetCurrentInventory().inventory[arg3]].targetType
            -- If we're choosing a spell's target, set the current Player's targetType as the targetType of the spell we're casting
            elseif arg2 == "SPELL" then
                self.EnableButton(self.turn, 2)
                player.action = "Spell"
                player.subAction = player.abilities[arg3]
                player.targetType = self.spells[player.abilities[arg3]].targetType
            -- If we're choosing an act's target, choose an enemy
            elseif arg2 == "ACT" then
                self.EnableButton(self.turn, 2)
                player.action = "Act"
                player.target = self.enemies[arg3]
                player.targetType = "Enemy"
            -- If we're choosing an attack's target, choose an enemy
            elseif arg2 == "FIGHT" then
                self.EnableButton(self.turn, 1)
                player.action = "Fight"
                player.targetType = "Enemy"
            -- If we're choosing an enemy to spare, choose an enemy
            elseif arg2 == "SPARE" then
                self.EnableButton(self.turn, 4)
                player.action = "Spare"
                player.targetType = "Enemy"
            end
        -- If we're entering the state ACTMENU, we set the enemy we're targeting
        elseif newState == "ACTMENU" then
            player.action = "Act"
            self.EnableButton(self.turn, 2)
            player.targetType = "Enemy"
            player.target = self.enemies[arg1]
        -- If we're entering the state ITEMMENU, we set up the UI to show we're choosing an item
        elseif newState == "ITEMMENU" then
            player.action = "Item"
            self.EnableButton(self.turn, 3)
        elseif newState == "ATTACKING" then
            -- Add the players if we need to add them
            if arg1 ~= nil then
                for i = 1, #self.players do
                    local player = self.players[i]
                    local isInArg1 = table.containsObj(arg1[1], i, true)
                    if isInArg1 then
                        player.action = "Fight"
                        player.target = self.enemies[arg1[2][i]]
                        self.SetAnim(player, "PrepareFight")
                    elseif not isInArg1 and player.action == "Fight" then
                        player.action = ""
                    end
                end
            end
        end
        self.State(newState, secondaryData)
    end

    -- Function executed when CYK's state is changed
    function self.State(newState, secondaryData)
        local oldState = self.state

        -- Calls EnteringState at the start of the function
        EnteringState(newState, self.state, true)
        -- If the state has been changed, don't go any further
        if self.state ~= oldState then return end

        local hackDoubleDefending = false

        -- If there are no enemies left, go to the state BEFOREDONE
        if #self.enemies == 0 and (newState ~= "BEFOREDONE" and newState ~= "DONE") then
            if oldState ~= "BEFOREDONE" then
                self.State("BEFOREDONE")
            end
            return
        end

        if oldState == "DEFENDING" then
            -- Display the background again
            self.Background.Display(true, 0)
            for i = 1, #self.players do
                self.HideFlash(self.players[i])
            end
            -- If we're trying to etner the state DEFENDING again, we need to go through the state ACTIONSELECT to reset the wave and choose a new one
            if newState == "DEFENDING" then
                hackDoubleDefending = true
                oldState = "ACTIONSELECT"
            end
            self.hasEnemyTargetsBeenReset = false
            OldState("NONE")
            -- Hide the arena if it is shown
            if self.arenaAnimInfo.shown then
                self.StartArenaAnim(false, true, true)
            end
            self.choiceIndex = 1
        end
        if oldState == "ATTACKING" then
            -- Hide everything related to the attack UI
            for i = #self.AtkMgr.attackingPlayers, 1, -1 do
                local attackingPlayer = self.AtkMgr.attackingPlayers[i]
                attackingPlayer.visor.Scale(6, 38)
                attackingPlayer.visor.alpha = 0
                self.AtkMgr.DisplayAtkZone(self.players[attackingPlayer.playerID].UI, true)
                self.SetAnim(self.players[attackingPlayer.playerID], "Idle")
            end
            -- Hide the attack gauge separators
            for i = 2, #self.players do
                self.players[i].UI.atkZone.separator.alpha = 0
            end
        end
        if oldState == "INTRO" then
            -- Display the encounter text, reset the Players' animation and start the music
            self.TxtMgr.SetText({ encountertext })
            for i = 1, #self.players do
                self.SetAnim(self.players[i], "Idle")
            end
            -- Hide the TP bar and the UI, and start the Players' Intro anim
            if not self.TP.isBeingShown then self.TP.Show() end
            if not self.UI.isBeingShown then self.UI.Show() end
            Audio.Unpause()
            self.NewPlayerTurns()
        elseif oldState == "ACTIONSELECT" then
            -- Hide the encounter text if we get out of this state
            if newState ~= "ACTIONSELECT" then
                self.TxtMgr.HideText()
            end
            self.choiceIndex = 1
        elseif oldState == "ENEMYSELECT" then
            -- Reset the current TP value to the TP value at the beginning of the turn
            if self.players[self.turn].action == "Magic" and newState == "ACTIONSELECT" then
                self.TP.Set(self.turnTPs[self.turn])
            end
            -- Hide the flash sprite of all entities (somehow I can't get the right entity so I do that instead)
            for i = 1, #self.players + #self.enemies do
                self.HideFlash(i <= #self.players and self.players[i] or self.enemies[i - #self.players])
            end
            self.TxtMgr.HideText()
            Player.sprite.alpha = 0
            self.choiceIndex = 1
        elseif oldState == "ACTMENU" then
            self.TxtMgr.HideText()
            -- Remove the preview of the TP bar
            if self.players[self.turn].action == "Magic" then
                self.TP.PreviewTPLoss(101)
                -- If we choose an enemy, that means we player agreed to go further, so we can remove the amount of TP the spell uses!
                if newState == "ENEMYSELECT" then
                    local spell = self.spells[self.players[self.turn].subAction]
                    self.TP.Set(-spell.tpCost, true)
                end
            end
            Player.sprite.alpha = 0
            self.choiceIndex = 1
        elseif oldState == "ITEMMENU" then
            self.TxtMgr.HideText()
            Player.sprite.alpha = 0
            self.choiceIndex = 1
        elseif oldState == "ENEMYDIALOGUE" then
            -- Hide the background
            self.Background.Display(true, 0)
            -- Destroy all of the enemies' bubble text objects if they haven't been destroyed before
            for i = 1, #self.enemies do
                if self.enemies[i].bubbleTextObject then
                    self.enemies[i].bubbleTextObject.DestroyText()
                    self.enemies[i].bubbleTextObject = nil
                    self.enemies[i].bubble.Remove()
                    self.enemies[i].bubble = nil
                end
            end

            -- Hide the "TARGET" cursor for each Player
            for i = 1, #self.players do
                if self.players[i].targetCursor.alpha > 0 then
                    self.players[i].targetCursor.alpha = 0
                end
            end

            -- Call EnemyDialogueEnding if it exists
            ProtectedCYKCall(EnemyDialogueEnding)
        elseif oldState == "BEFOREDONE" and newState ~= "DONE" then
            -- Enable the soundd menuconfirm
            Audio["menuconfirm"] = nil
        end
        -- Hides the Players' UI's button choice if we don't need to display them anymore
        if not hackDoubleDefending and (oldState == "ACTIONSELECT" or oldState == "ITEMMENU" or oldState == "ACTMENU" or oldState == "ENEMYSELECT")
           and (newState ~= "ACTIONSELECT" and newState ~= "ITEMMENU" and newState ~= "ACTMENU" and newState ~= "ENEMYSELECT") then
            for i = 1, #self.players do
                if self.players[i].UI.shown then
                    self.UI.HideUI(self.players[i].UI)
                end
            end
        end
        -- If the new state is ATTACKING then the old state is PLAYERTURN
        if newState == "ATTACKING" then
            oldState = "PLAYERTURN"
        end

        if oldState == "PLAYERTURN" then
            self.TxtMgr.HideText()
            -- Case a Player attacks: enter the state ATTACKING
            local inAttacking = false
            for i = 1, #self.players do
                if self.players[i].action == "Fight" then
                    -- Empty the current attackingPlayers table and finish any existing animation
                    if not inAttacking then
                        while #self.AtkMgr.attackingPlayers > 0 do
                            local attackingPlayer = self.AtkMgr.attackingPlayers[1]
                            while #attackingPlayer.perfectStars > 0 do
                                local star = attackingPlayer.perfectStars[0]
                                if star.isactive then star.Remove() end
                                table.remove(attackingPlayer.perfectStars, 1)
                            end
                        end
                    end
                    self.players[i].UI.faceSprite.Set("CreateYourKris/Players/" .. self.players[i].sprite["anim"] .. "/UI/Fight")
                    self.players[i].action = ""
                    table.insert(self.AtkMgr.attackingPlayers, i)
                    inAttacking = true
                end
            end
            -- If any Player is attacking, enter the state ATTACKING
            if #self.AtkMgr.attackingPlayers > 0 and inAttacking then
                self.state = "PLAYERTURN"
                self.State("ATTACKING")
                return
            end

            -- Reset the players' animation and action unless they're defending
            if newState == "ENEMYDIALOGUE" then
                for i = 1, #self.players do
                    local player = self.players[i]
                    if player.action ~= "Defend" then
                        if player.hp > 0 then
                            self.SetAnim(player, "Idle")
                        end
                        player.action = ""
                        player.UI.faceSprite.Set("CreateYourKris/Players/" .. player.sprite["anim"] .. "/UI/Normal")
                    end
                end
            end
        end

        self.state = newState

        -- New turn if we reached one of the states where the player can take action from a state where the player can't take action
        if not hackDoubleDefending and (oldState == "PLAYERTURN" or oldState == "ENEMYDIALOGUE" or oldState == "DEFENDING")
           and (newState == "ACTIONSELECT" or newState == "ITEMMENU" or newState == "ACTMENU" or newState == "ENEMYSELECT") then
            self.NewPlayerTurns()
        end
        if newState == "INTRO" then
            -- Play the Intro animation of each Player
            for i = 1, #self.players do
                self.SetAnim(self.players[i], "Intro")
            end
            Audio.PlaySound("battlestart")
        elseif newState == "ACTIONSELECT" then
            -- Start the turn if it's not started yet
            if self.turn == 0 then
                self.SetTurn(1)
            -- If we come back from another state where the player can choose an action, display the encounter text again
            elseif oldState == "ACTMENU" or oldState == "ITEMMENU" or oldState == "ENEMYSELECT" then
                self.TxtMgr.SetText({ self.TxtMgr.lastText[#self.TxtMgr.lastText] }, { self.TxtMgr.lastText2[#self.TxtMgr.lastText2] })
            end
            self.Inventory.turnItemsUsed[self.turn] = nil

            local set = false
            -- Resets the current Player's buttons
            for i = 1, #self.players[self.turn].UI.buttons do
                local button = self.players[self.turn].UI.buttons[i]
                if button["active"] then
                    button.Set("CreateYourKris/UI/Buttons/" .. self.players[self.turn].UI.buttonNames[i] .. "S"  .. (CYK.CrateYourKris and "T" or ""))
                    if self.state == "ACTIONSELECT" then
                        self.choiceIndex = i
                        set = true
                    end
                end
            end
            if not set then self.choiceIndex = 1 end
            self.choiceIndexLimit = 5
        -- Shows the player and does some more stuff when entering this state
        elseif newState == "ENEMYSELECT" then
            Player.sprite.alpha = 1
            self.EnteringState(newState)
        elseif newState == "ACTMENU" then
            Player.sprite.alpha = 1
            self.EnteringState(newState)
        elseif newState == "ITEMMENU" then
            Player.sprite.alpha = 1
            self.EnteringState(newState)
        -- Reset the current turn and start the first player's turn
        elseif newState == "PLAYERTURN" then
            self.turn = 0
            self.Confirm()
        -- Prepare the player attack
        elseif newState == "ATTACKING" then
            self.AtkMgr.SetupAttack()
        elseif newState == "ENEMYDIALOGUE" then
            -- Call the function EnemyDialogueStarting() if it exists
            ProtectedCYKCall(EnemyDialogueStarting)
            self.EnteringState(newState)
            -- Hide the background
            self.Background.Display(false, 30)
            -- Show the "TARGET" cursor on each Player who can be hit during this wave
            for i = 1, #self.players do
                if table.containsObj(self.playerTargets, i, true) or self.playerTargets[1] == 0 then
                    local targetShift = self.players[i].animations[self.players[i].sprite["currAnim"]][3].targetShift
                    self.players[i].targetCursor.x = targetShift and targetShift[1] or 0
                    self.players[i].targetCursor.y = targetShift and targetShift[2] or 0
                    self.players[i].targetCursor.alpha = 1
                    self.players[i].targetCursor.currenttime = 0
                end
            end
        elseif newState == "DEFENDING" then
            if not self.hasEnemyTargetsBeenReset then
                self.ResetEnemyTargets()
            end
            -- Hide the background directly
            self.Background.Display(false, 0)
            -- Set the Arena and the Player's position
            self.nextwaves = nextwaves
            nextwaves = { "empty" }
            OldState("DEFENDING")
            Wave[1].Call("PrepareArenaForAnim", { arenapos[1], arenapos[2], arenasize[1], arenasize[2], false, true })
            self.StartArenaAnim(true)
            OldState("PAUSE")
        elseif newState == "NONE" then
        elseif newState == "BEFOREDONE" then
            -- Play the EndBattle animation of each Players and display the end text
            for i = 1, #self.players do
                self.SetAnim(self.players[i], "EndBattle")
            end
            self.TxtMgr.SetText({ (self.CrateYourKris and "YOO WONN! WONN 0 PEX N " .. tostring(50 + math.floor((0.75 + math.random() / 4) * self.TP.trueValue)) .. " DEES."
                                                      or "YOU WON! You earned 0 EXP\rand " .. tostring(50 + math.floor((0.75 + math.random() / 4) * self.TP.trueValue)) .. " D$.") })
        elseif newState == "DONE" then
            OldState("DONE")
        else
            error("The state \"" .. tostring(newState) .. "\" doesn't exist.")
        end

        -- Display one of the Player's UI's choice buttons if needed
        if not hackDoubleDefending and (newState == "ACTIONSELECT" or newState == "ITEMMENU" or newState == "ACTMENU" or newState == "ENEMYSELECT") then
            for i = 1, #self.players do
                if self.players[i].UI.shown and self.turn ~= i then
                    self.UI.HideUI(self.players[i].UI)
                elseif not self.players[i].UI.shown and self.turn == i then
                    self.UI.ShowUI(self.players[i].UI)
                end
            end
        end
    end

    -- Triggered when the Player presses the Cancel key
    function self.Cancel()
        -- Goes back to the previous Player's action selection menu
        if self.state == "ACTIONSELECT" then
            PlaySoundOnceThisFrame("menumove")
            self.ChangePlayerTurn(nil, true)
        -- Goes back to this Player's action selection menu
        elseif self.state == "ITEMMENU" or self.state == "ENEMYSELECT" or self.state == "ACTMENU" then
            PlaySoundOnceThisFrame("menumove")
            self.State("ACTIONSELECT")
        end
    end

    -- Triggered when the Player presses the Left key
    function self.Left()
        -- Moves the cursor left and changes the cursor's position for both cases
        if self.state == "ACTIONSELECT" then
            PlaySoundOnceThisFrame("menumove")
            self.MoveCursor(-1)
        elseif (self.state == "ACTMENU" or self.state == "ITEMMENU" or self.state == "ENEMYSELECT") and self.TxtMgr.twoColumns then
            PlaySoundOnceThisFrame("menumove")
            self.MoveCursor(self.choiceIndex % 2 == 0 and -1 or 1)
            self.MovePlayer()
        end
    end

    -- Triggered when the Player presses the Right key
    function self.Right()
        -- Moves the cursor right and changes the cursor's position for both cases
        if self.state == "ACTIONSELECT" then
            PlaySoundOnceThisFrame("menumove")
            self.MoveCursor(1)
        elseif (self.state == "ACTMENU" or self.state == "ITEMMENU" or self.state == "ENEMYSELECT") and self.TxtMgr.twoColumns then
            PlaySoundOnceThisFrame("menumove")
            self.MoveCursor(self.choiceIndex % 2 == 0 and -1 or 1)
            self.MovePlayer()
        end
    end

    -- Triggered when the Player presses the Up key
    function self.Up()
        -- Moves the cursor up and changes the cursor's position if we're in some states
        if self.state == "ACTMENU" or self.state == "ITEMMENU" or self.state == "ENEMYSELECT" then
            PlaySoundOnceThisFrame("menumove")
            self.MoveCursor(self.TxtMgr.twoColumns and -2 or -1)
            self.MovePlayer()
        end
    end

    -- Triggered when the Player presses the Down key
    function self.Down()
        -- Moves the cursor down and changes the cursor's position if we're in some states
        if self.state == "ACTMENU" or self.state == "ITEMMENU" or self.state == "ENEMYSELECT" then
            PlaySoundOnceThisFrame("menumove")
            self.MoveCursor(self.TxtMgr.twoColumns and 2 or 1)
            self.MovePlayer()
        end
    end

    -- Moves the player's SOUL in a choice menu
    function self.MovePlayer()
        -- Only moves the player horizontally if there are two choice columns
        if self.TxtMgr.twoColumns or Player.sprite.absx ~= 62 then
            Player.sprite.x = self.choiceIndex % 2 == 0 and 222 or (self.TxtMgr.lastTwoColumns and 22 or 62)
        end
        Player.sprite.y = 87 - 30 * ((self.TxtMgr.twoColumns and math.ceil(self.choiceIndex / 2) or self.choiceIndex) - 1)
    end

    -- Returns the real choice position of the player when making a choice
    function self.GetRealChoiceIndex()
        return self.choiceIndex + (self.TxtMgr.lastTwoColumns and 6 or 3) * (self.TxtMgr.currentPage - 1)
    end

    -- Starts a new Player turn
    function self.NewPlayerTurns()
        for i = 1, #self.players do
            -- Displays the first Player's first button
            self.EnableButton(i, 1, self.turn == 0 and i > 1 or i ~= self.turn)
            local player = self.players[i]

            -- Resets the Player's action and animation
            player.action = ""
            player.subAction = ""
            if player.hp > 0 then
                self.SetAnim(player, "Idle")
                player.UI.faceSprite.Set("CreateYourKris/Players/" .. player.sprite["anim"] .. "/UI/Normal")
            else
                -- Increment the Player's HP by 1/8th of his max HP if he's down
                self.AtkMgr.ChangeHP(player, player, math.ceil(player.maxhp / 8))
            end
        end
        -- Reset some turn-based variables
        self.turnTPs = { }
        self.turnMultis = { }

        -- Display up the encounter text
        self.TxtMgr.SetText({ encountertext })

        local text1 = self.TxtMgr.lastText[#self.TxtMgr.lastText]
        local commandEnd1 = self.TxtMgr.GetCommandEnd(text1)
        local textCommands1 = commandEnd1 > 1 and string.sub(text1, 1, commandEnd1 - 1) or ""
        local textRealText1 = commandEnd1 > 1 and string.sub(text1, commandEnd1, #text1) or text1
        self.TxtMgr.lastText[#self.TxtMgr.lastText] = textCommands1 .. "[instant]" .. textRealText1

        local text2 = self.TxtMgr.lastText2[#self.TxtMgr.lastText2]
        local commandEnd2 = self.TxtMgr.GetCommandEnd(text2)
        local textCommands2 = commandEnd2 > 1 and string.sub(text2, 1, commandEnd2 - 1) or ""
        local textRealText2 = commandEnd2 > 1 and string.sub(text2, commandEnd2, #text2) or text2
        self.TxtMgr.lastText2[#self.TxtMgr.lastText2] = textCommands2 .. "[instant]" .. textRealText2
    end

    -- Goes to another Player's turn
    function self.ChangePlayerTurn(anim, prev)
        local oldPlayer = self.players[self.turn]
        local oldAction = oldPlayer.action

        local setTurnResult = self.SetTurn(prev and -1 or 1, prev)
        -- If it was the last Player's choice, execute the Players' actions
        if setTurnResult == "after" then
            self.State("PLAYERTURN")
        elseif setTurnResult == "before" then
            return
        else
            -- Reset the previous Player if the player pressed a Cancel key
            if prev then
                oldPlayer.action = ""
                local newPlayer = self.players[self.turn]
                newPlayer.action = ""
                newPlayer.UI.faceSprite.Set("CreateYourKris/Players/" .. newPlayer.sprite["anim"] .. "/UI/Normal")
                if self.turnTPs[self.turn] then
                    self.TP.Set(self.turnTPs[self.turn])
                end
                if self.turnMultis[self.turn] then
                    for i = 1, #self.turnMultis[self.turn] do
                        local player = self.allPlayers[self.turnMultis[self.turn][i]]
                        self.SetAnim(player, "Idle")
                        player.action = ""
                        player.UI.faceSprite.Set("CreateYourKris/Players/" .. player.sprite["anim"] .. "/UI/Normal")
                    end
                end
                self.turnMultis[self.turn] = nil
                self.SetAnim(newPlayer, "Idle")
            end
            self.State("ACTIONSELECT")
        end

        -- Only if we're going to the next Player, change the old Player's face UI and change his animation
        if not prev then
            if oldAction ~= "" then
                oldPlayer.UI.faceSprite.Set("CreateYourKris/Players/" .. oldPlayer.sprite["anim"] .. "/UI/" .. oldAction)
            end
            if oldAction ~= "Defend" and self.state ~= "PLAYERTURN" then
                self.SetAnim(oldPlayer, "Prepare" .. oldAction)
            end
        end
    end

    -- Sets the current player turn. Returns nil if everything's okay,
    -- "before" if we're trying to get a Player before the first Player, "after" if we're trying to get a Player after the last Player
    function self.SetTurn(dir, allowNonVoidAction)
        local isReturning = nil
        -- Increment/Decrement the current turn value
        self.turn = self.turn + dir
        -- If the current value of turn can be associated to a Player
        if self.turn <= #self.players and self.turn > 0 then
            local player = self.players[self.turn]
            -- If said Player is down or already has an action
            if player.hp <= 0 or player.action == "MultiAct" or (not allowNonVoidAction and player.action ~= "") then
                -- Check for the next Player
                isReturning = self.SetTurn(dir, allowNonVoidAction)
                if isReturning then
                    self.turn = self.turn - dir
                end
            end
        else
            -- Return "before" or "after" depending on the value we got
            local oldTurn = self.turn
            self.turn = self.turn - dir
            return oldTurn <= 0 and "before" or "after"
        end
        return isReturning
    end

    -- Handles everything after disabling a Player. The modder will still need to set the disabled Player's sprite's alpha to 0 to hide its sprite
    function self.DisablePlayer(currPlayerID)
        local player = self.allPlayers[currPlayerID]
        -- If we're trying to remove a Player before the one we're currently choosing an action for
        if currPlayerID < self.turn then
            -- Remove everything related to the Player we removed by shifting all the data we stored related to this current Player turn
            for i = currPlayerID, self.turn do
                self.Inventory.turnItemsUsed[i] = self.Inventory.turnItemsUsed[i+1]
                self.turnTPs[i] = self.turnTPs[i+1]
            end
            self.turn = self.turn - 1
        -- If we're trying to remove the Player we're trying to choose an action for
        elseif currPlayerID == self.turn then
            -- Keep self.turn below or equal to the new amount of players
            if self.turn > #self.players then
                self.turn = #self.players
                self.players[self.turn].action = ""
            end
            -- Hide the disabled Player's UI and reenter the state ACTIONSELECT
            self.UI.HideUI(player.UI)
            self.State("ACTIONSELECT", true)
        end
    end

    -- Handles everything after enabling a Player. The modder will still need to set the enabled Player's sprite's alpha to 1 to show its sprite
    function self.EnablePlayer(currPlayerID)
        local player = self.players[currPlayerID]
        -- If we're trying to add a Player before the one we're currently choosing an action for
        if currPlayerID < self.turn then
            -- Shifting all the data we stored related to this current Player turn to insert a Player with no action in it
            for i = currPlayerID, self.turn do
                self.Inventory.turnItemsUsed[i-1] = self.Inventory.turnItemsUsed[i]
                self.turnTPs[i-1] = self.turnTPs[i]
            end
            self.Inventory.turnItemsUsed[currPlayerID] = nil
            self.turnTPs[currPlayerID] = nil
            self.turn = self.turn + 1
        -- If we're trying to addd a Player at the index of the Player we're trying to choose an action for
        elseif currPlayerID == self.turn then
            player.UI.faceSprite.Set("CreateYourKris/Players/" .. player.sprite["anim"] .. "/UI/Normal")
            player.action = ""
            -- Choose an action for this new Player instead
            self.State("ACTIONSELECT", true)
        end
    end

    -- Moves the cursor in a choice by a given amount
    function self.MoveCursor(val)
        local oldChoiceIndex = self.choiceIndex
        local oldRealChoiceIndex = self.GetRealChoiceIndex()
        self.choiceIndex = self.choiceIndex + val

        -- ACTUALLY move the cursor
        local pageChanged = false
        local pageSize = self.TxtMgr.lastTwoColumns and 6 or 3
        -- Override: if there's only one choice, well...no need to compute anything, self.choiceIndex is set to 1
        if self.choiceIndexLimit == 1 and self.TxtMgr.currentPage == 1 then
            self.choiceIndex = 1
        elseif self.choiceIndex < 1 or self.choiceIndex > self.choiceIndexLimit then
            local prev = self.choiceIndex < 1
            -- Check page up and down
            if (prev and self.TxtMgr.textArrow.alpha > 0) or (not prev and self.TxtMgr.textArrowDown.alpha > 0) then
                pageChanged = true
                self.TxtMgr.NextChoicePage(prev)
                -- Update the choice index limit value and put the choice index back in bounds
                local oldChoiceIndexLimit = self.choiceIndexLimit
                self.choiceIndexLimit = math.min(#self.TxtMgr.lastChoice - pageSize * (self.TxtMgr.currentPage - 1), pageSize)
                self.choiceIndex = self.choiceIndex > 0 and self.choiceIndex + (self.choiceIndexLimit - oldChoiceIndexLimit) or self.choiceIndex
            end
            -- Keep choiceIndex below choiceIndexLimit
            self.choiceIndex = self.choiceIndex + self.choiceIndexLimit * (prev and 1 or -1) + (self.choiceIndexLimit % math.abs(val)) * (prev and -1 or 1)
            if self.choiceIndex > self.choiceIndexLimit then
                self.choiceIndex = self.choiceIndexLimit
            end
        end

        -- Same value for choiceIndex: do nothing
        if self.choiceIndex == oldChoiceIndex and not pageChanged then
            return
        end

        local player = self.players[self.turn]

        -- Change the selected button and target
        if self.state == "ACTIONSELECT" then
            self.EnableButton(self.turn, self.choiceIndex)
        elseif self.state == "ACTMENU" then
            -- Update the current display of the previewed TP loss
            if self.players[self.turn].action == "Magic" then
                self.TP.PreviewTPLoss(self.spells[self.players[self.turn].abilities[self.choiceIndex]].tpCost)
            end
        elseif self.state == "ENEMYSELECT" then
            -- Hide the flashing animation of the last target
            self.HideFlash((player.targetType == "Enemy" and self.enemies or self.players)[oldRealChoiceIndex])
            local pool = player.targetType == "Enemy" and self.enemies or self.players
            pool[self.choiceIndex].sprite["f"].color = { 1, 1, 1 }
        end

        -- Update the spell description if we're in the MAGIC menu
        if self.TxtMgr.textDActive then
            local currentObject = self.choiceIndex + 6 * (self.TxtMgr.currentPage - 1)
            self.TxtMgr.textDescription.SetText({ (player.action == "Magic" and self.spells[player.abilities[currentObject]] or self.Inventory.items[self.Inventory.GetCurrentInventory().inventory[currentObject]]).description })
        end
    end

    -- Handles the buttons in a Player's UI and display one button as "active"
    function self.EnableButton(playerID, buttonIndex, doNotShow)
        local playerUI = self.players[playerID].UI
        for i = 1, 5 do
            if buttonIndex == i then
                if not doNotShow then
                    playerUI.buttons[i].Set("CreateYourKris/UI/Buttons/" .. playerUI.buttonNames[i] .. "S"  .. (CYK.CrateYourKris and "T" or ""))
                end
                playerUI.buttons[i]["active"] = true
            elseif buttonIndex ~= i then
                if not doNotShow then
                    playerUI.buttons[i].Set("CreateYourKris/UI/Buttons/" .. playerUI.buttonNames[i]  .. (CYK.CrateYourKris and "T" or ""))
                end
                playerUI.buttons[i]["active"] = false
            end
        end
    end

    -- Hides the flash sprite of an entity
    function self.HideFlash(forced)
        forced.sprite["f"].alpha = 0
    end

    -- Prevents the current Player's turn from ending when the player presses the Confirm button in the state PLAYERTURN
    function self.WaitBeforeNextPlayerTurn()
        if self.state == "PLAYERTURN" then
            self.beginPlayerTurn = self.frame
            self.stopPlayerTurnProgress = true
        else
            DEBUG("[WARN] Using CYK.WaitBeforeNextPlayerTurn() when not in the PLAYERTURN state does nothing.")
        end
    end

    -- Forces the current Player's turn to end only if it has been stopped previously
    function self.EndPlayerTurn()
        if not self.stopPlayerTurnProgress then
            error("You can't use CYK.EndPlayerTurn() if you haven't used CYK.WaitBeforeNextPlayerTurn() in this Player's turn before.")
        elseif self.frame - self.beginPlayerTurn == 0 then
            error("You can't use CYK.EndPlayerTurn() on the same frame as the one when this Player's turn starts!")
        elseif self.state == "PLAYERTURN" then
            self.Confirm(true)
        elseif CYKDebugLevel > 0 then
            DEBUG("[WARN] Using CYK.EndPlayerTurn() when not in the PLAYERTURN state does nothing.")
        end
    end

    self.beginWait = false
    -- Updates the whole thing
    function self.Update()
        -- Waits for one frame at the beginning of the Encounter then starts the Intro of the fight
        if self.state == "BEGIN" then
            if self.beginWait then
                self.State("INTRO")
            else
                self.beginWait = true
            end
        end

        -- Lesser Update function calls
        self.UpdateQuitting()
        self.UpdateFollowUps()
        self.UpdateFlash()
        self.UpdateEntityHurting()
        self.UpdateArenaAnim()
        self.UpdateIntro()
        self.UpdateAttackingPerfectStars()

        -- Subsystems Update function calls
        self.UI.Update()
        self.TxtMgr.Update()
        self.AtkMgr.Update()
        self.TP.Update()
        self.Background.Update()
        self.ScreenShake.Update()

        -- Player inputs
        if awaitingCYKInput then
            if Input.Confirm == 1 then    self.Confirm()
            elseif Input.Cancel == 1 then self.Cancel()
            elseif Input.Left == 1 then   self.Left()
            elseif Input.Right == 1 then  self.Right()
            elseif Input.Up == 1 then     self.Up()
            elseif Input.Down == 1 then   self.Down()
            end
        end

        -- Execute the current Player's UpdateTurn() function if his turn has been stopped
        if self.state == "PLAYERTURN" then
            if self.stopPlayerTurnProgress then
                if not self.players[self.turn].UpdateTurn then
                    error("You need a function named UpdateTurn in the Player " .. self.players[self.turn].sprite["anim"] .. "'s script if you want to use CYK.WaitBeforeNextPlayerTurn() during its turn.")
                else
                    self.players[self.turn].UpdateTurn(self.frame - self.beginPlayerTurn, self.frame)
                end
            end
        end

        -- Frame count update
        self.frame = self.frame + 1
    end

    -- Updates everything related to the QUITTING text
    function self.UpdateQuitting()
        local hasEscapeChanged = false
        -- Increment a count for each frame if the key Escape is pressed or held. If it reaches 120, the encounter ends abruptly
        if Input.GetKey("Escape") > 0 then
            self.escapeFrame = self.escapeFrame + 1
            hasEscapeChanged = true
            if self.escapeFrame >= 120 then
                OldState("DONE")
            end
        -- If the Escape key is not pressed but the count used above is above 0, decrement it
        elseif self.escapeFrame > 0 then
            hasEscapeChanged = true
            self.escapeFrame = self.escapeFrame == 1 and 0 or self.escapeFrame - 2
        end
        -- Updates the QUITTING text
        if hasEscapeChanged and self.escapeFrame < 120 then
            self.quitting.alpha = self.escapeFrame / 30
            self.quitting.Set("CreateYourKris/UI/Quitting/" .. tostring(math.floor(self.escapeFrame / 24)))
        end
    end

    -- Updates everything related to the INTRO state
    function self.UpdateIntro()
        if self.state == "INTRO" then
            for i = 1, #self.players do
                -- If all of the Players' Intro animation has ended, go to the ACTIONSELECT state
                if not (self.players[i].sprite["currAnim"] ~= "Intro" or self.players[i].sprite.animcomplete) then return end
            end
            self.State("ACTIONSELECT")
        end
    end

    -- Pause the current music if the current state is still BEGIN
    if self.state == "BEGIN" then
        Audio.Pause()
    end

    -- CYF-like shortcuts
    enemies = self.allEnemies
    players = self.allPlayers

    return self
end