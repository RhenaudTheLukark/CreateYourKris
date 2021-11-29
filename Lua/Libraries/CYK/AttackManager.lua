return function(CYK)
    local self = { }

    self.attackingPlayers = { }  -- Used when players are attacking. It keeps track of who is attacking and who is attacking first!

    -- Sets a Player attack up
    function self.SetupAttack()
        -- If a player's target entity is not active, take an active entity instead
        for i = 1, #self.attackingPlayers do
            local player = CYK.players[self.attackingPlayers[i]]
            if not player.target.isactive then
                player.target = CYK.enemies[CYK.GetEntityUp(player.target, true)]
            end
        end

        -- Nobody attacking
        if #self.attackingPlayers == 0 then
            CYK.State("ENEMYDIALOGUE")
            return
        end

        -- Computes the order at which the Players will attack and the position of their attack visor
        local differentInputs = math.random()
        differentInputs = math.min(#self.attackingPlayers, differentInputs < 0.1 and 1 or differentInputs < 0.9 and 2 or 3)
        local differentInputsOriginal = differentInputs
        local usedInputs = { }
        for i = 1, #self.attackingPlayers do
            local attackingPlayer = { playerID = self.attackingPlayers[i], stopped = false, perfectStars = { } }
            local player = CYK.players[self.attackingPlayers[i]]
            local chancesDifferent = differentInputs == 0 and 0 or (#self.attackingPlayers - i + 1) / differentInputs
            local chosen = 0
            -- BRAND NEW INPUT! LIMITED STOCK!
            if math.random() <= chancesDifferent then
                differentInputs = differentInputs - 1
                repeat
                    chosen = math.random(1, differentInputsOriginal)
                until not table.containsObj(usedInputs, chosen, true) or limitCount == 0
                table.insert(usedInputs, chosen)
            -- Same input as someone else
            else
                chosen = usedInputs[math.random(1, #usedInputs)]
            end
            attackingPlayer.inputNumber = chosen
            attackingPlayer.visor = player.UI.atkZone.visor
            attackingPlayer.visor.x = 272 + 96 * (attackingPlayer.inputNumber - 1)
            self.attackingPlayers[i] = attackingPlayer
            self.DisplayAtkZone(player.UI)
        end
        for i = 2, #CYK.players do
            CYK.players[i].UI.atkZone.separator.alpha = 1
        end
    end

    -- Handles the press of the "Confirm" key while we're in the state ATTACKING
    function self.Confirm()
        local nextPlayers = { }
        local lowerPlayerX = 126
        -- For each Player
        for i = 1, #self.attackingPlayers do
            local attackingPlayer = self.attackingPlayers[i]
            -- If it hasn't attacked yet
            if not attackingPlayer.stopped then
                -- If this Player is the closest Player to the left, add it to a table
                local visor = attackingPlayer.visor
                local added = true
                -- If this Player is closer to the left than the Player(s) currently in the table where the Players are stored, remove those Players
                if visor.x < lowerPlayerX then
                    nextPlayers = { { attackingPlayer, i } }
                    lowerPlayerX = visor.x
                -- If this Player is at the same X position as the Player(s) currently in the table where the Players are stored, add this Player to the table
                elseif visor.x == lowerPlayerX then
                    table.insert(nextPlayers, { attackingPlayer, i })
                else
                    added = false
                end
                if added then
                    -- Get the attack coefficient of this Player that'll be used if this Player's attack cursor is closer to the left than any other cursors
                    local diff = math.abs(38 - visor.x)
                    local attackingPlayer = nextPlayers[#nextPlayers][1]
                    -- Missed
                    if visor.x == -500 then
                        attackingPlayer.coeff = 0
                    -- 3 frames input for a perfect hit
                    elseif diff < 5 then
                        visor.x = 38
                        diff = 0
                        attackingPlayer.coeff = 1
                        CYK.TP.Set(6, true)
                        local player = CYK.players[attackingPlayer.playerID]
                        -- Create the stars displayed during perfect attacks
                        for j = 1, 3 do
                            local star = CreateSprite("CreateYourKris/UI/Attack/Stars/1", "Entity")
                            star.absx = player.sprite.absx + math.random(player.sprite.width / 2, player.sprite.width)
                            star.absy = player.sprite.absy + math.random(0, player.sprite.height / 2)
                            star["anim"] = "damageStar"
                            CYK.SetAnim({ sprite = star }, "Idle", { noAnimOverride = true, destroyOnEnd = true })
                            star["startX"] = star.absx
                            attackingPlayer.perfectStars[j] = star
                        end
                    -- Formula when close to the target
                    elseif diff <= 28 then
                        attackingPlayer.coeff = 1 - diff / 70
                        CYK.TP.Set(2, true)
                    -- Formula when far from the target
                    else
                        attackingPlayer.coeff = 0.6 - (diff - 28) / 600
                        CYK.TP.Set(2, true)
                    end
                end
            end
        end
        -- If a Player has attacked
        if #nextPlayers > 0 then
            -- For each of those Players
            while #nextPlayers > 0 do
                local playerID = nextPlayers[1][1].playerID
                local visor = nextPlayers[1][1].visor
                if visor.x == 38 then
                    visor.color = { 1, 1, 0 }
                end
                nextPlayers[1][1].stopped = true
                -- Start this Player's "Fight" animation
                CYK.SetAnim(CYK.players[playerID], "Fight")
                table.remove(nextPlayers, 1)
            end
            PlaySoundOnceThisFrame("slice")
            CYK.UI.FlashAttackBars()
        end
    end

    -- Updates this library, if the current state is ATTACKING
    function self.Update()
        if CYK.state == "ATTACKING" then
            local done = true
            -- For each attacking Player
            for i = 1, #self.attackingPlayers do
                local attackingPlayer = self.attackingPlayers[i]
                if attackingPlayer == nil then return end
                local player = CYK.players[attackingPlayer.playerID]
                local enemy = player.target

                if attackingPlayer.done then
                    -- Nothing happens when it's done
                -- Reset the enemy's animation to Idle when it's Hurt animation is done
                elseif (attackingPlayer.coeff == 0 or enemy.sprite["currAnim"] ~= "Hurt") and attackingPlayer.done == false then
                    attackingPlayer.done = true
                    if attackingPlayer.coeff > 0 then
                        CYK.SetAnim(enemy, "Idle")
                    end
                -- Once this Player's "Hurt" animation is complete
                elseif attackingPlayer.stopped and player.sprite.animcomplete and attackingPlayer.done == nil then
                    attackingPlayer.done = false
                    player.UI.faceSprite.Set("CreateYourKris/Players/" .. player.sprite["anim"] .. "/UI/Normal")
                    -- Attack the enemy, and if the attack is not missed, start a slashing animation on the target enemy!
                    if self.Attack(enemy.ID, false, player.ID, true, attackingPlayer.coeff) and attackingPlayer.coeff > 0 then
                        local atkSprite = CreateSprite("empty", "Entity")
                        atkSprite.absx = enemy.posX + enemy.sprite.width / 2
                        atkSprite.absy = enemy.posY + enemy.sprite.height / 2
                        atkSprite.loopmode = "ONESHOTEMPTY"
                        atkSprite["anim"] = player.sprite["anim"]
                        atkSprite["xShift"] = enemy.sliceAnimOffsetX
                        atkSprite["yShift"] = enemy.sliceAnimOffsetY
                        CYK.SetAnim({ sprite = atkSprite }, "SliceAnim", nil, nil, { noAnimOverride = true, destroyOnEnd = true })
                        attackingPlayer.attackAnim = atkSprite
                    end
                end
                -- Shows the Player's visor scale up and disappear as the attack is confirmed
                if attackingPlayer.stopped and attackingPlayer.visor.alpha > 0 then
                    attackingPlayer.visor.Scale(attackingPlayer.visor.xscale + 6 * 0.05, attackingPlayer.visor.yscale + 38 * 0.05)
                    attackingPlayer.visor.alpha = attackingPlayer.visor.alpha - 0.05
                -- Moves the visor to the left
                elseif not attackingPlayer.stopped then
                    attackingPlayer.visor.x = attackingPlayer.visor.x - 4
                    -- If the visor goes too far to the left, it disappears and the attack ends
                    if attackingPlayer.visor.x < 20 then
                        attackingPlayer.visor.alpha = attackingPlayer.visor.x / 20
                    end
                    -- If the visor is too far to the left, the attack is missed
                    if attackingPlayer.visor.x == -20 then
                        attackingPlayer.visor.x = -500
                        self.Confirm()
                    end
                end
                -- If any of the Players isn't done attacking, do not exit this state
                if not attackingPlayer.done then
                    done = false
                end
            end
            -- If any enemy is still displaying their Hurt animation, do not exit this state
            for i = 1, #CYK.enemies do
                local enemy = CYK.enemies[i]
                if enemy.sprite["currAnim"] == "Hurt" then
                    done = false
                end
            end
            -- If everything is done, exit this state
            if done then
                CYK.State("ENEMYDIALOGUE")
            end
        end
    end

    self.DisplayAtkZone = CYK.UI.DisplayAtkZone

    -- Attacks a target
    function self.Attack(targetID, isTargetPlayer, attackerID, isAttackerPlayer, coeff)
        local target = (isTargetPlayer and CYK.allPlayers or CYK.allEnemies)[targetID]
        local attacker = (isAttackerPlayer and CYK.allPlayers or CYK.allEnemies)[attackerID]
        -- Do not attack a dead / disabled entity
        if target.hp < 0 or not target.isactive then
            return false
        end
        -- If a Player is targeted, shake the screen
        if (coeff == 1 and not isTargetPlayer) or isTargetPlayer then
            CYK.ScreenShake.Shake(4, nil, true)
        end
        -- Tries to call this entity's BeforeDamageCalculation function
        ProtectedCYKCall(target.BeforeDamageCalculation, attacker, coeff)
        local damage
        -- If the amount of damage dealt to the entity is fixed, use it
        if target.presetDamage ~= nil then
            damage = target.presetDamage
            target.presetDamage = nil
        -- Otherwise, computes the damage dealt to the entity
        else
            damage = -self.ComputeDamage(targetID, attackerID, coeff and coeff or 1, isTargetPlayer, isAttackerPlayer)
        end
        self.ChangeHP(target, attacker, damage)
        return true
    end

    -- Computes the damage an attacker is supposed to deal to a target
    function self.ComputeDamage(targetID, attackerID, coeff, isTargetPlayer, isAttackerPlayer)
        local target = (isTargetPlayer and CYK.allPlayers or CYK.allEnemies)[targetID]
        local attacker = (isAttackerPlayer and CYK.allPlayers or CYK.allEnemies)[attackerID]

        local dmg = math.ceil((target.UI and 5 or 7.5) * attacker.atk)
        dmg = math.ceil((dmg - (3 * target.def)) * coeff)
        if target.action == "Defend" then
            dmg = math.ceil(dmg * 2 / 3)
        end

        return dmg
    end

    -- Changes an entity's HP, spawns a damage text and changes the entity's animation
    function self.ChangeHP(target, attacker, value, isAbsolute)
        local textValue = value
        local color = nil
        local isPlayer = table.containsObj(CYK.players, target)

        target.hp = target.hp + value

        -- Displays the "Miss" text if the entity's HP is changed by 0
        if value == 0 then
            textValue = "Miss"
        -- If the entity's HP is changed by a positive number, heal it
        elseif value > 0 then
            PlaySoundOnceThisFrame("healsound")
            -- Cap this entity's HP to its map HP value
            if target.hp >= target.maxhp then
                textValue = "Max"
                target.hp = target.maxhp
            -- If this (Player) entity is healed, display the text "Up" instead
            elseif target.hp > 0 and value >= target.hp then
                textValue = "Up"
                target.hp = math.min(math.max(math.ceil(target.maxhp / 5), target.hp), target.maxhp)
                CYK.SetAnim(target, "Idle")
                if isPlayer then
                    target.UI.faceSprite.Set("CreateYourKris/Players/" .. target.sprite["anim"] .. "/UI/Normal")
                end
            end
        -- If the entity's HP is changed by a negative number, hurt it
        else
            PlaySoundOnceThisFrame(isPlayer and "hurtsound" or "hitsound")
            -- If the entity's HP is 0 or below
            if target.hp <= 0 then
                if isPlayer then
                    -- Check for game over if we're damaging a Player
                    local gameOver = true
                    for i = 1, #CYK.players do
                        if CYK.players[i].hp > 0 then
                            gameOver = false
                            break
                        end
                    end
                    -- If all the Players are down, GAME OVER
                    if gameOver and ProtectedCYKCall(OnGameOver) ~= false then
                        if CYK.Background then
                            for i = 1, #CYK.Background do
                                CYK.Background[i].Remove()
                            end
                        end
                        Player.sprite.set("ut-heart")
                        Player.sprite.alpha = 1
                        doneFor = true
                        unescape = false
                        CYK.GameOver.StartGameOver()
                    end
                    color = { 1, 0, 0 }
                    textValue = "Down"
                    target.hp = -target.maxhp / 2
                    target.UI.faceSprite.Set("CreateYourKris/Players/" .. target.sprite["anim"] .. "/UI/Down")
                    CYK.SetAnim(target, "Down")
                -- Try to kill the enemy, unless it has a function named OnDeath()
                else
                    target.TryKill()
                    -- If all the enemies are gone, enter the state BEFOREDONE
                    if #CYK.enemies == 0 then
                        CYK.State("BEFOREDONE")
                    end
                end
            -- Set the entity's animation to Hurt if it's not defending
            elseif target.action ~= "Defend" then
                CYK.SetAnim(target, "Hurt")
            end
            -- Hidden feature?!
            if not isPlayer and target.isTiredWhenHPLow and target.hp <= target.maxhp / 2 then
                target.tired = true
            end
        end

        -- Updates the Player's UI if the entity is a Player
        if isPlayer then
            CYK.UI.UpdatePlayerHP(target)
        end
        -- Call the entity's HandleAttack() function if it exists
        if value <= 0 then
            ProtectedCYKCall(target.HandleAttack, attacker, value == 0 and -1 or -value)
        end

        -- Computes the damage text's color, then spawns it
        if not color and value > 0 then
            color = { 0, 1, 0 }
        elseif attacker and attacker.UI and not color then
            color = attacker.damageColor
            for i = 1, #color do
                color[i] = color[i] == 0 and 0.5 or color[i]
            end
        elseif not color then
            color = { 1, 1, 1 }
        end

        CYK.UI.CreateHPChangeText(textValue, target, color)
    end

    -- Updates the stars that appear when a Player executes a perfect attack
    function CYK.UpdateAttackingPerfectStars()
        for i = #CYK.AtkMgr.attackingPlayers, 1, -1 do
            local attackingPlayer = CYK.AtkMgr.attackingPlayers[i]
            -- If there's any star left
            if #attackingPlayer.perfectStars > 0 then
                -- If the star's anim is complete, remove it
                while #attackingPlayer.perfectStars > 0 and attackingPlayer.perfectStars[1].animcomplete do
                    table.remove(attackingPlayer.perfectStars, 1)
                end
                -- Move the star to the right and fade it out over time
                if #attackingPlayer.perfectStars > 0 then
                    local starAlpha = (200 - (attackingPlayer.perfectStars[1].absx - attackingPlayer.perfectStars[1]["startX"] + 5)) / 200
                    for j = 1, #attackingPlayer.perfectStars do
                        local star = attackingPlayer.perfectStars[j]
                        star.absx = star.absx + 5
                        star.alpha = starAlpha
                    end
                end
            -- Remove the current attacking player from the attackingPlayers table if we're not in the state ATTACKING
            elseif CYK.state ~= "ATTACKING" then
                table.remove(CYK.AtkMgr.attackingPlayers, i)
            end
        end
    end

    return self
end
