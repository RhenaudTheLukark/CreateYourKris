return function(CYK)
    -- Oh boy, here comes the police! UIUIUIUIUIUIUIUIUIUIUIUIUI
    local self = { }

    self.flashAttackBarsStart = 0 -- Used to animate the flashing of the attack bars

    self.lowerUIRoot = CreateSprite("empty", "LowerUI")
    self.lowerUIRoot.absx = 0
    self.lowerUIRoot.absy = 0
    self.upperUIRoot = CreateSprite("empty", "UpperUI")
    self.upperUIRoot.absx = 0
    self.upperUIRoot.absy = 0

    -- Hides the bottom part of the screen
    self.hider = CreateSprite("px", "LowerUI")
    self.hider.SetParent(self.lowerUIRoot)
    self.hider.SetPivot(0, 0)
    self.hider.Scale(640, 153)
    self.hider.absx = 0
    self.hider.absy = 0
    self.hider.color = { 0, 0, 0 }

    -- UI bars. AESTHETIC
    self.bar1 = CreateSprite("px", "LowerUI")
    self.bar1.SetParent(self.hider)
    self.bar1.Scale(640, 3)
    self.bar1.SetPivot(0.5, 0)
    self.bar1.absx = 320
    self.bar1.absy = 152
    self.bar1.color32 = { 51, 32, 51 }

    self.bar2 = CreateSprite("px", "LowerUI")
    self.bar2.SetParent(self.hider)
    self.bar2.Scale(640, 3)
    self.bar2.SetPivot(0.5, 0)
    self.bar2.absx = 320
    self.bar2.absy = 116
    self.bar2.color32 = { 51, 32, 51 }

    self.isBeingShown = false
    self.shownTimer = 0

    -- Creates the buttons associated to a Player's UI
    function self.GetButtons(uiObject)
        for i = 1, #uiObject.buttonNames do
            local buttonName = uiObject.buttonNames[i]
            local spriteName = "CreateYourKris/UI/Buttons/" .. buttonName
            local button = CreateSprite(spriteName  .. (CYK.CrateYourKris and "T" or ""), "LowerUI")
            button["active"] = false
            button.SetParent(uiObject.sides)
            button.SetPivot(0, 0)
            button.SetAnchor(0, 0)
            button.x = 15 + 36 * (i - 1)
            button.y = -3
            button["isAct"] = buttonName == "Act"
            -- Case "Magic" or "Spare": don't forget the glowey button
            if buttonName == "Magic" or buttonName == "Spare" then
                local glowButton = CreateSprite(spriteName .. "SG"  .. (CYK.CrateYourKris and "T" or ""), "LowerUI")
                glowButton.SetParent(button)
                glowButton.SetPivot(0, 0)
                glowButton.SetAnchor(0, 0)
                glowButton.x = 0
                glowButton.y = 0
                glowButton.alpha = 0
                button["glow"] = glowButton
            end
            table.insert(uiObject.buttons, button)
        end
    end

    function self.UpdatePlayerHP(player)
        local colorText = ""
        -- Text color & player anim if player
        if player.hp < 1 then
            colorText = "[color:ff0000]"
        elseif player.hp <= player.maxhp / 5 then
            colorText = "[color:ffff00]"
        end

        local hpStart = ""
        for i = 1, 4 - CountDigits(player.hp) do
            hpStart = hpStart .. " "
        end
        local UI = player.UI
        UI.hpText.SetText({ "[instant][font:HPFont][novoice]" .. colorText .. hpStart .. tostring(player.hp) })

        local hpStart = ""
        for i = 1, 4 - CountDigits(player.maxhp) do
            hpStart = hpStart .. " "
        end
        UI.maxHpText.SetText({ "[instant][font:HPFont][novoice]" .. colorText .. hpStart .. tostring(player.maxhp) })

        UI.lifebar.xscale = 76 * (player.hp < 0 and 0 or player.hp) / player.maxhp
    end

    -- Build the Players' UI
    local players = CYK.allPlayers
    for i = 1, #players do
        local player = players[i]
        local playerUI = player.UI
        playerUI.shown = false    -- Are the Player's commands shown?
        playerUI.anim = nil       -- Anim of the UI (show or hide)
        playerUI.animTimer = 0    -- Anim timer

        -- Side bars of the buttons UI
        playerUI.sides = CreateSprite("CreateYourKris/UI/Player/LowerSides", "LowerUI")
        playerUI.sides.SetParent(self.hider)
        playerUI.sides.SetPivot(0, 0)
        playerUI.sides.absx = -500
        playerUI.sides.absy = 119
        playerUI.sides.color = player.playerColor
        playerUI.sides.alpha = 0

        -- Sprite parent of all sprites used in the command UI's effect
        playerUI.sideEffectContainer = CreateSprite("empty", "LowerUI")
        playerUI.sideEffectContainer.SetParent(playerUI.sides)
        playerUI.sideEffectContainer.SetPivot(0, 0)
        playerUI.sideEffectContainer.x = 0
        playerUI.sideEffectContainer.y = 0
        playerUI.sideEffects = { }

        -- Buttons names. Also used in a lot of places
        playerUI.buttonNames = { "Fight", table.containsObj(player.abilities, "Act") and "Act" or "Magic", "Item", "Spare", "Defend" }
        playerUI.buttons = { }
        self.GetButtons(playerUI)

        -- Colorful outer of the stats UI
        playerUI.upperBg = CreateSprite("px", "UpperUI")
        playerUI.upperBg.SetParent(self.upperUIRoot)
        playerUI.upperBg.Scale(212, 37)
        playerUI.upperBg.SetPivot(0, 0)
        playerUI.upperBg.SetAnchor(0, 0)
        playerUI.upperBg.x = -500
        playerUI.upperBg.y = 117.5
        playerUI.upperBg.color = player.playerColor
        playerUI.upperBg.alpha = 0

        -- Boring inner of the stats UI
        playerUI.upperBgStats = CreateSprite("CreateYourKris/UI/Player/UpperBg", "UpperUI")
        playerUI.upperBgStats.SetParent(playerUI.upperBg)
        playerUI.upperBgStats.SetPivot(0, 0)
        playerUI.upperBgStats.SetAnchor(0, 0)
        playerUI.upperBgStats.x = 0
        playerUI.upperBgStats.y = 0

        -- Life bar!
        -- TODO: Find out why the lifebar isn't at the same place when CYF is scaled up
        playerUI.lifebar = CreateSprite("px", "UpperUI")
        playerUI.lifebar.Scale(76 * player.hp / player.maxhp, 9)
        playerUI.lifebar.SetParent(playerUI.upperBg)
        playerUI.lifebar.SetPivot(0, 0)
        playerUI.lifebar.SetAnchor(0, 0)
        playerUI.lifebar.x = 128
        playerUI.lifebar.y = 8
        playerUI.lifebar.color = player.playerColor

        -- FaceSprite, ooo
        playerUI.faceSprite = CreateSprite("CreateYourKris/Players/" .. player.sprite["anim"] .. "/UI/Normal", "UpperUI")
        playerUI.faceSprite.SetParent(playerUI.upperBg)
        playerUI.faceSprite.SetPivot(0, 0)
        playerUI.faceSprite.SetAnchor(0, 0)
        playerUI.faceSprite.x = 2
        playerUI.faceSprite.y = 1.95
        playerUI.faceSprite.loopmode = "ONESHOT"

        -- Player's hp text
        playerUI.hpText = CreateText({ "[instant][font:HPFont][novoice]OONDARTEL" }, {80, 420}, 1000, "UpperUI")
        playerUI.hpText.SetParent(playerUI.upperBg)
        playerUI.hpText.progressmode = "none"
        playerUI.hpText.HideBubble()
        playerUI.hpText.x = 128
        playerUI.hpText.y = 20

        -- Player's maxhp text
        playerUI.maxHpText = CreateText({ "[instant][font:HPFont][novoice]OONDARTEL" }, {80, 420}, 1000, "UpperUI")
        playerUI.maxHpText.SetParent(playerUI.upperBg)
        playerUI.maxHpText.progressmode = "none"
        playerUI.maxHpText.HideBubble()
        playerUI.maxHpText.x = 174
        playerUI.maxHpText.y = 20

        -- Player's name
        playerUI.playerName = CreateText({ "[instant][font:PlayerNameFont][novoice]OONDARTEL" }, {80, 420}, 1000, "UpperUI")
        playerUI.playerName.SetParent(playerUI.upperBg)
        playerUI.playerName.progressmode = "none"
        playerUI.playerName.HideBubble()
        playerUI.playerName.x = 49
        playerUI.playerName.y = 10
        playerUI.playerName.SetText({ "[instant][font:PlayerNameFont][novoice]" .. string.upper(player.name) })

        playerUI.atkZone = { }

        playerUI.atkZone.press = CreateSprite("CreateYourKris/UI/Attack/press", "LowerUI")
        playerUI.atkZone.press.SetPivot(0, 0)
        playerUI.atkZone.press.x = 46
        playerUI.atkZone.press.y = 78 - 38 * (i - 1)
        playerUI.atkZone.press.alpha = 0

        if i > 1 then
            playerUI.atkZone.separator = CreateSprite("px", "LowerUI")
            playerUI.atkZone.separator.SetParent(playerUI.atkZone.press)
            playerUI.atkZone.separator.Scale(226, 3)
            playerUI.atkZone.separator.SetAnchor(0, 0)
            playerUI.atkZone.separator.SetPivot(0, 0)
            playerUI.atkZone.separator.x = 31
            playerUI.atkZone.separator.y = 35
            playerUI.atkZone.separator.color = { 0, 0, .5 }
            playerUI.atkZone.separator.alpha = 0
        end

        playerUI.atkZone.faceSprite = CreateSprite("CreateYourKris/Players/" .. player.sprite["anim"] .. "/UI/Normal", "LowerUI")
        playerUI.atkZone.faceSprite.SetParent(playerUI.atkZone.press)
        playerUI.atkZone.faceSprite.SetAnchor(0, 0)
        playerUI.atkZone.faceSprite.SetPivot(0, 0)
        playerUI.atkZone.faceSprite.x = -50
        playerUI.atkZone.faceSprite.y = 4
        playerUI.atkZone.faceSprite.alpha = 0

        playerUI.atkZone.bar = CreateSprite("CreateYourKris/UI/Attack/bar", "LowerUI")
        playerUI.atkZone.bar.SetParent(playerUI.atkZone.press)
        playerUI.atkZone.bar.SetAnchor(0, 0)
        playerUI.atkZone.bar.SetPivot(0, 0)
        playerUI.atkZone.bar.x = 34
        playerUI.atkZone.bar.y = 1
        playerUI.atkZone.bar.color = player.atkBarColor
        playerUI.atkZone.bar.alpha = 0

        playerUI.atkZone.target = CreateSprite("CreateYourKris/UI/Attack/target", "LowerUI")
        playerUI.atkZone.target.SetParent(playerUI.atkZone.press)
        playerUI.atkZone.target.SetAnchor(0, 0)
        playerUI.atkZone.target.SetPivot(0, 0)
        playerUI.atkZone.target.x = 36
        playerUI.atkZone.target.y = 0
        playerUI.atkZone.target.color = player.damageColor
        playerUI.atkZone.target.alpha = 0

        playerUI.atkZone.visor = CreateSprite("px", "LowerUI")
        playerUI.atkZone.visor.SetParent(playerUI.atkZone.press)
        playerUI.atkZone.visor.Scale(6, 38)
        playerUI.atkZone.visor.SetAnchor(0, 0)
        playerUI.atkZone.visor.SetPivot(0, 0.5)
        playerUI.atkZone.visor.x = 270
        playerUI.atkZone.visor.y = 19
        playerUI.atkZone.visor.alpha = 0

        playerUI.atkZone.visorEffects = { }
        self.UpdatePlayerHP(player)
    end

    function self.ManageUI()
        for i = 1, #CYK.allPlayers do
            local player = CYK.allPlayers[i]
            local index = table.containsObj(CYK.players, player)

            local xShift = index and 214 - 107 * (#CYK.players - 1) + (214 * (index - 1)) or -500
            player.UI.sides.absx = xShift
            player.UI.upperBg.absx = xShift

            local yFightUI = index and 78 - 38 * (index - 1) or -500
            player.UI.atkZone.press.y = yFightUI
        end
    end
    self.ManageUI()

    function self.UpdateUI(player)
        local uiObject = player.UI

        uiObject.upperBg.color = player.playerColor
        uiObject.sides.color = player.playerColor
        uiObject.lifebar.Scale(76 * player.hp / player.maxhp, 9)
        uiObject.lifebar.color = player.playerColor
        uiObject.playerName.SetText({ "[instant][font:PlayerNameFont][novoice]" .. string.upper(player.name) })

        self.UpdatePlayerHP(player)

        uiObject.atkZone.bar.color = player.atkBarColor
        uiObject.atkZone.target.color = player.damageColor
    end

    -- Shows the commands of a Player UI
    function self.ShowUI(uiObject)
        uiObject.anim = "show"
        uiObject.animTimer = 0
        uiObject.sides.alpha = 1
        uiObject.upperBg.alpha = 1
        uiObject.upperBg.y = 117.5
        uiObject.shown = true
    end

    -- Hides the commands of a Player UI
    function self.HideUI(uiObject)
        uiObject.anim = "hide"
        uiObject.animTimer = 0
        for i = #uiObject.sideEffects, 1, -1 do
            uiObject.sideEffects[i].Remove()
            table.remove(uiObject.sideEffects, i)
        end
        for i = 1, #uiObject.buttons do
            local button = uiObject.buttons[i]
            button.Set("CreateYourKris/UI/Buttons/" .. uiObject.buttonNames[i]  .. (CYK.CrateYourKris and "T" or ""))
            if button["glow"] then
                button["glow"].alpha = 0
            end
        end
        uiObject.sides.alpha = 0
        uiObject.upperBg.alpha = 0
        uiObject.upperBg.y = 149.5
        uiObject.shown = false
    end

    function self.Show()
        self.isBeingShown = true
        self.shownTimer = 0
        self.lowerUIRoot.absy = -155
        self.upperUIRoot.absy = -155
    end

    function self.DisplayAtkZone(uiObject, hide)
        local alpha = hide and 0 or 1
        uiObject.atkZone.press.alpha = alpha
        uiObject.atkZone.faceSprite.alpha = alpha
        uiObject.atkZone.bar.alpha = alpha
        uiObject.atkZone.target.alpha = alpha
        uiObject.atkZone.visor.alpha = alpha
        uiObject.atkZone.visor.color = { 1, 1, 1 }
    end

    function self.FlashAttackBars()
        self.flashAttackBarsStart = CYK.frame + 1
    end

    -- Updates all Player UIs
    function self.Update()
        for i = 1, #players do
            local uiObject = players[i].UI
            -- Animation!
            if uiObject.anim ~= nil then
                -- Show: 4 quick frames, 8 slow frames
                if uiObject.anim == "show" then
                    if uiObject.animTimer == 12 then
                        self.EndAnim(uiObject)
                    else
                        uiObject.upperBg.y = uiObject.upperBg.y + (uiObject.animTimer < 4 and 6 or 1)
                    end
                -- Hide: 4...normal frames?
                elseif uiObject.anim == "hide" then
                    if uiObject.animTimer == 4 then
                        self.EndAnim(uiObject)
                    else
                        uiObject.upperBg.y = uiObject.upperBg.y - 8
                    end
                else
                    self.EndAnim(uiObject)
                end
                uiObject.animTimer = uiObject.animTimer + 1
            end
        end
        self.UpdateHPChangeTexts()
        self.UpdateFlashAttackBars()
        self.UpdateButtonGlow()
        self.UpdateSideEffects()

        if self.isBeingShown then
            local increment = self.shownTimer < 12 and 10 or self.shownTimer < 15 and 7 or self.shownTimer < 18 and 4 or 1 -- 20 frames
            --local increment = self.shownTimer < 20 and 6 or self.shownTimer < 25 and 4 or self.shownTimer < 30 and 2 or 1 -- 35 frames
            self.lowerUIRoot.y = self.lowerUIRoot.y + increment
            self.upperUIRoot.y = self.upperUIRoot.y + increment
            self.shownTimer = self.shownTimer + 1
            if self.shownTimer == 20 then
                self.isBeingShown = false
            end
        end
    end

    -- Ends a Player UI's animation
    function self.EndAnim(uiObject)
        uiObject.anim = nil
        uiObject.animTimer = -1
    end

    self.HPChangeTexts = { }
    function self.CreateChangeText(value, entity, color, isMercy)
        local container = { }
        if isMercy==nil then isMercy=false end

        --Change the color of the text if the value immediately spare the enemy (>100%) or decrease the percent for the Mercy system
        if isMercy then
            if value>=100 then
                color={0, 1, 0}
            elseif value<0 then
                color={1, 0, 0}
            else
                color={1, 1, 1}
            end
        end

        local HPChangeTextEntity = 1
        -- Maximum 50 change hp objects at once for each entity
        while HPChangeTextEntity <= 50 do
            if not entity.HPChangeTexts[HPChangeTextEntity] then
                entity.HPChangeTexts[HPChangeTextEntity] = container
                break
            end
            HPChangeTextEntity = HPChangeTextEntity + 1
        end
        if HPChangeTextEntity == 51 then return end
        container.x = entity.posX + entity.sprite.width / 2 - 10 + entity.damageUIOffsetX
        container.y = entity.posY + 30 + 20 * (HPChangeTextEntity - 1) + entity.damageUIOffsetY
        container.entity = entity
        container.yBounce = -12
        container.yAccel = 2

        local parent = CreateSprite("empty", "UpperUI")
        parent.SetPivot(0, 0)
        parent.absx = container.x
        parent.absy = container.y
        container.parent = parent

        local isWord = false
        if not isMercy then
            if value == "Down" or value == "Max" or value == "Miss" or value == "Up" then
                container[1] = value
                isWord = true
            else
                if value < 0 then
                    value = -value
                end
                while value > 0 do
                    local val = value % 10
                    table.insert(container, 1, val)
                    value = math.floor(value / 10)
                end
            end
            container.isWord = isWord
        else
            local valueBeforeModif=value
            if value<0 then value=-value end
            table.insert(container, 1, "%")
            while value>0 do
                local val = value % 10
                table.insert(container, 1, val)
                value = math.floor(value / 10)
            end
            if valueBeforeModif>0 then
                table.insert(container, 1, "+")
            else
                table.insert(container, 1, "-")
            end
        end

        for i = 1, #container do
            local HPNumber = CreateSprite("CreateYourKris/UI/"..(isMercy and "MercyChange" or "HPChange").."/" .. tostring(container[i]))
            HPNumber.SetParent(parent)
            HPNumber.SetPivot(1, 0)
            HPNumber.absx = container.x - (isWord and 0 or 20 * (#container - i))
            HPNumber.absy = container.y
            HPNumber.color = color
            container[i] = HPNumber
        end

        container.frame = CYK.frame
        table.insert(self.HPChangeTexts, container)
    end

    function self.UpdateHPChangeTexts()
        for i = #self.HPChangeTexts, 1, -1 do
            local HPChangeText = self.HPChangeTexts[i]
            local frame = CYK.frame - HPChangeText.frame
            -- Scale at the beginning of the animation
            if frame <= 8 then
                local xScale = 3 - frame * 0.25
                local yScale = 1 / xScale
                for j = 1, #HPChangeText do
                    HPChangeText[j].x = -(isWord and 0 or 20 * (#HPChangeText - j)) * xScale
                    HPChangeText[j].Scale(xScale, yScale)
                end
            end

            -- X movement at the beginning of the animation
            if frame < 28 then
                HPChangeText.parent.x = HPChangeText.parent.x + (frame < 12 and 4 or frame < 16 and 2 or frame < 28 and 1)
            end
            -- Y movement at the beginning of the animation
            if frame < 32 then
                HPChangeText.parent.y = HPChangeText.parent.y + (frame < 12 and 1 or frame < 28 and -1 or frame < 32 and -3)

            -- Bounce time
            elseif frame <= 120 and (HPChangeText.yBounce ~= -16 or HPChangeText.yAccel ~= 0) then
                HPChangeText.yBounce = HPChangeText.yBounce + HPChangeText.yAccel
                HPChangeText.yAccel = HPChangeText.yAccel - 0.25
                -- Can't go under 16 pixels below the animation's original position
                if HPChangeText.yBounce < -16 then
                    HPChangeText.yBounce = -16
                    HPChangeText.yAccel = -HPChangeText.yAccel * 1/2
                    -- If the speed is lower than 1, stop the bounce
                    if HPChangeText.yAccel < 1 then
                        HPChangeText.yAccel = 0
                    end
                end
                HPChangeText.parent.absy = HPChangeText.y + HPChangeText.yBounce
            end

            -- Moves the numbers up and fades them
            if frame > 120 then
                HPChangeText.parent.y = HPChangeText.parent.y + 2
                for j = 1, #HPChangeText do
                    HPChangeText[j].yscale = HPChangeText[j].yscale + 1 / 30
                    HPChangeText[j].alpha = 1 - (frame - 120) / 30
                end
            end

            -- The animation has ended, you can remove all the sprites and destroy it
            if frame == 150 then
                for j = 1, #HPChangeText do
                    HPChangeText[j].Remove()
                end
                HPChangeText.parent.Remove()
                table.remove(self.HPChangeTexts, i)
                -- Can't have more than 50 damage texts at once
                for i = 1, 50 do
                    if HPChangeText.entity.HPChangeTexts[i] == HPChangeText then
                        HPChangeText.entity.HPChangeTexts[i] = nil
                        break
                    end
                end
            end
        end
    end

    function self.UpdateFlashAttackBars()
        if self.flashAttackBarsStart ~= 0 then
            local frame = CYK.frame - self.flashAttackBarsStart
            local multiplier = (8 - frame) / 8
            for i = 1, #CYK.players do
                local player = CYK.players[i]
                local color = player.atkBarColor
                player.UI.atkZone.bar.color = { color[1] + (1 - color[1]) * multiplier, color[2] + (1 - color[2]) * multiplier, color[3] + (1 - color[3]) * multiplier }
            end
            if frame == 8 then
                self.flashAttackBarsStart = 0
                for i = 1, #CYK.players do
                    local player = CYK.players[i]
                    player.UI.atkZone.bar.color = player.atkBarColor
                end
            end
        end
    end

    function self.UpdateButtonGlow()
        local isAnySpareable = false
        local isAnyTired = false
        for i = 1, #CYK.enemies do
            if CYK.enemies[i].tired then
                isAnyTired = true
            end
            if (chapter2 and CYK.enemies[i].mercyPercent>=100) or (not chapter2 and CYK.enemies[i].canspare) then
                isAnySpareable = true
            end
        end
        if isAnySpareable or isAnyTired then
            local alpha = CYK.frame % 90
            alpha = alpha < 45 and alpha / 45 or (90 - alpha) / 45
            for i = 1, #CYK.players do
                local player = CYK.players[i]
                local playerUI = player.UI
                if playerUI.shown then
                    if playerUI.buttons[2]["glow"] then
                        if isAnyTired and table.containsObj(player.abilities, "Pacify") and CYK.TP.trueValue >= CYK.spells.Pacify.tpCost then
                            playerUI.buttons[2]["glow"].alpha = alpha
                        else
                            playerUI.buttons[2]["glow"].alpha = 0
                        end
                    end
                    playerUI.buttons[4]["glow"].alpha = isAnySpareable and alpha or 0
                end
            end
        end
    end

    -- Updates the Player UI's command effects
    function self.UpdateSideEffects()
        for i = 1, #CYK.players do
            local playerUI = CYK.players[i].UI
            if playerUI.shown then
                -- Spawn a new effect every 30 frames
                if CYK.frame % 30 == 0 then
                    for j = 1, 2 do
                        local sideEffect = CreateSprite("px", "LowerUI")
                        sideEffect.SetParent(playerUI.sideEffectContainer)
                        sideEffect.SetAnchor(0, 0)
                        sideEffect.Scale(2, 33)
                        sideEffect.x = j == 1 and -105 or 105
                        sideEffect.y = 0
                        sideEffect.color = playerUI.upperBg.color
                        sideEffect["velX"] = 0
                        table.insert(playerUI.sideEffects, sideEffect)
                    end
                end
                -- Moves the effects
                for j = #playerUI.sideEffects, 1, -1 do
                    local sideEffect = playerUI.sideEffects[j]
                    sideEffect.x = sideEffect.x + sideEffect["velX"] * (j % 2 == 0 and -1 or 1)
                    sideEffect["velX"] = sideEffect["velX"] + 0.01
                    sideEffect.alpha = 1 - sideEffect["velX"] * 1.2
                    -- Delete the effect if it's not visible anymore
                    if sideEffect.alpha <= 0 then
                        sideEffect.Remove()
                        table.remove(playerUI.sideEffects, j)
                    end
                end
            end
        end
    end

    -- Put the UI out of the screen
    self.lowerUIRoot.absy = -155
    self.upperUIRoot.absy = -155

    return self
end