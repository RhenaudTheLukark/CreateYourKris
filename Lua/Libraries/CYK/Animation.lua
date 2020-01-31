return function(self)
    -- Animation collection
    self.anims = { }
    self.anims.followUps = { }  -- List of sprites in an animation that starts another animation when it's finished

    -- Build the content in the self.anims table to make it look like proper animations usable with sprite.SetAnimation()
    function self.BuildAnimations()
        local testSprite = CreateSprite("empty", "Top")
        -- Check each registered entity
        for k, v in pairs(self.anims) do
            local isPlayer = v.isPlayer
            v.isPlayer = nil
            -- For each animation in the current entity
            for k2, v2 in pairs(v) do
                -- Create the animation with file paths
                for i = 1, #v2[1] do
                    local file = "CreateYourKris/" .. (isPlayer and "Players/" or "Monsters/") .. k .. "/" .. k2 .. "/" .. tostring(v2[1][i])
                    v2[1][i] = file
                end
                -- Starts the anim if preloadAnimations is true to register it in CYK
                if preloadAnimations then
                    testSprite.SetAnimation(v2[1], v2[2])
                end
            end
        end
        -- Animation of the stars that appear when a Player's attack is performed perfectly
        self.anims.damageStar = {
            Idle = { { "CreateYourKris/UI/Attack/Stars/1", "CreateYourKris/UI/Attack/Stars/2", "CreateYourKris/UI/Attack/Stars/3" }, 1 / 4, { loop = "ONESHOTEMPTY" } }
        }
        testSprite.Remove()
    end

    -- Sets a sprite object's animation
    function self.SetAnim(entity, animName, followUpData)
        local sprite = entity.sprite

        if entity.hp and entity.hp <= 0 then
            animName = self.anims[sprite["anim"]]["Down"] and "Down" or "Idle"
        end

        local animObject = self.anims[sprite["anim"]][animName]
        followUpData = followUpData or { }

        -- Removes any occurence of this sprite in the followUp table
        for i = #self.anims.followUps, 1, -1 do
            if self.anims.followUps[i].entity == entity then
                table.remove(self.anims.followUps, i)
            end
        end

        -- Check if this entity allows this animation to play
        if animName ~= "Hurt" and not followUpData.noAnimOverride then
            if ProtectedCYKCall(entity.HandleAnimationChange, animName) == false then
                return
            end
        elseif animName == "Hurt" and sprite["currAnim"] ~= "Defend" and entity.UI ~= nil then
            entity.UI.faceSprite.SetAnimation({ "CreateYourKris/Players/" .. sprite["anim"] .. "/UI/Hurt", "CreateYourKris/Players/" .. sprite["anim"] .. "/UI/Normal" }, 1/2)
        end

        -- If the current animation doesn't exist, abort
        if not animObject then
            if CYKDebugLevel > 0 then
                error("[WARN] The animation " .. animName .. " of the " .. (entity.UI and "player" or "enemy") .. " " .. tostring(entity.sprite["anim"]) .. " doesn't exist.")
            end
            return
        end
        local loopmode = animObject[3].loop and animObject[3].loop or animObject[3].next and "ONESHOT" or "LOOP"

        -- Doesn't change the sprite's animation if it is the same looped anim
        if sprite["currAnim"] == animName and loopmode == "LOOP" then
            return
        end

        -- Adds the sprite to the followUp table if this anim must be followed by another anim when it ends
        sprite.loopmode = loopmode
        if animObject[3].next or followUpData.noAnimOverride or followUpData.destroyOnEnd then
            followUpData.entity = followUpData.entity or entity
            followUpData.next = followUpData.next or animObject[3].next
            table.insert(self.anims.followUps, followUpData)
        end

        sprite["currAnim"] = animName
        sprite["lastAnimTime"] = Time.time

        -- Moves the sprite if needed
        local posShift = animObject[3].posShift
        local xShift = animObject[3].posShift and animObject[3].posShift[1] or 0
        local yShift = animObject[3].posShift and animObject[3].posShift[2] or 0
        sprite.Move(xShift - (sprite["xShift"] or 0), yShift - (sprite["yShift"] or 0))
        sprite["xShift"] = xShift
        sprite["yShift"] = yShift

        -- FINALLY set the animation
        sprite.SetAnimation(animObject[1], animObject[2])
        -- Don't forget the sprite's mask
        if sprite["mask"] then
            sprite["mask"].SetAnimation(animObject[1], animObject[2])
        end
    end

    -- Check if any sprite animation in the followUp list has ended
    -- if an animation has ended, it launches the animation that is supposed to follow it
    function self.UpdateFollowUps()
        for i = #self.anims.followUps, 1, -1 do
            local followUp = self.anims.followUps[i]
            if followUp.entity.sprite.animcomplete then
                -- Move the sprite back where it was if the current animation was Hurt
                if followUp.entity.sprite["currAnim"] == "Hurt" then
                    followUp.entity.sprite.absx = followUp.entity.posX
                end

                -- Update the Player UI's face sprite if the followUp is one of the player and it is supposed to go back to Idle
                if followUp.entity.UI ~= nil and followUp.next == "Idle" then
                    followUp.entity.UI.faceSprite.Set("CreateYourKris/Players/" .. followUp.entity.sprite["anim"] .. "/UI/Normal")
                end

                -- Remove the sprite if it has to be removed at the end of the anim, otherwise set its followUp animation
                if followUp.destroyOnEnd then
                    followUp.entity.sprite.Remove()
                    table.remove(self.anims.followUps, i)
                else
                    self.SetAnim(followUp.entity, followUp.next)
                end

                break
            end
        end
    end

    self.arenaAnim = nil
    self.arenaAnimEffects = { }
    self.arenaAnimHeartEffects = { }
    self.arenaAnimFrame = 0
    self.arenaAnimInfo = { x = 0, y = 0, width = 0, height = 0, rotation = 0, nostate = false, shown = false }
    self.arenaAnimTime = 20
    self.arenaAnimNotMoved = true
    -- Starts one of the Arena's animations
    function self.StartArenaAnim(show, nowave, nostate)
        -- If an animation is currently running, end it
        if self.arenaAnim then
            self.EndArenaAnim(true)
        end
        self.arenaAnim = show and "show" or "hide"
        self.arenaAnimFrame = self.frame - 1

        -- The player's sprite is added to the layer Bullet so it can be visible above the arena effects at all times
        Player.sprite.layer = "Bullet"

        -- Fill in the anim's info
        self.arenaAnimInfo.x = (show or nowave) and arenapos[1] or arenainfo.x
        self.arenaAnimInfo.y = (show or nowave) and arenapos[2] + arenasize[2] / 2 + 5 or arenainfo.y + arenainfo.height / 2 + 5
        self.arenaAnimInfo.width = (show or nowave) and arenasize[1] or arenainfo.width
        self.arenaAnimInfo.height = (show or nowave) and arenasize[2] or arenainfo.height
        self.arenaAnimInfo.rotation = (show or nowave) and arenarotation or arenainfo.rotation
        self.arenaAnimInfo.px = Player.sprite.absx
        self.arenaAnimInfo.py = Player.sprite.absy
        self.arenaAnimInfo.nostate = nostate
        self.arenaAnimInfo.shown = true

        self.arenaAnimNotMoved = true

        -- Displays the Arena if the "hide" animation is started and if the Arena will last for less than 31 frames
        if not show and self.arenaAnimTime <= 30 and self.Background then
            self.Background.Display(true, self.arenaAnimTime)
        end

        -- Heart effect
        for i = 1, 3 do
            local heart = CreateSprite("CreateYourKris/playerWaveEffect", "Arena")
            local heartShift = self.players[1].animations[self.players[1].sprite["currAnim"]][3].heartShift
            heart.absx = self.players[1].sprite.absx + self.players[1].sprite.width / 2 + (heartShift and heartShift[1] or 0)
            heart.absy = self.players[1].sprite.absy + self.players[1].sprite.height / 2 + (heartShift and heartShift[2] or 0)
            heart.alpha = 0
            table.insert(self.arenaAnimHeartEffects, heart)
        end

        self.UpdateArenaAnim()
    end

    -- Spawns an Arena sprite during its "show" or "hide" animation
    function self.SpawnArenaSpriteForAnim(frame)
        local effect = { }
        local scale = frame / self.arenaAnimTime

        local rotation = self.arenaAnimInfo.rotation - (self.arenaAnimTime - frame) * 4
        -- Creates 4 sides + the center sprite
        for i = 1, 5 do
            local side = CreateSprite("px", "Arena")
            side.color = i < 5 and arenacolor or { 0, 0, 0 }
            side.rotation = rotation
            if i < 5 then
                -- Moves and scales the side sprite
                side.Scale((i % 2 == 0 and self.arenaAnimInfo.width + 10 or 5) * scale, (i % 2 == 1 and self.arenaAnimInfo.height or 5) * scale)
                local distance = ((i % 2 == 0 and self.arenaAnimInfo.height or self.arenaAnimInfo.width) + 5) / 2 * scale
                local angle = math.rad((side.rotation + 90 * (i - 1)) % 360)
                side.x = self.arenaAnimInfo.x + math.cos(angle) * distance
                side.y = self.arenaAnimInfo.y + math.sin(angle) * distance
            else
                -- Moves and scales the center sprite
                side.Scale(self.arenaAnimInfo.width * scale, self.arenaAnimInfo.height * scale)
                side.x = self.arenaAnimInfo.x
                side.y = self.arenaAnimInfo.y
            end
            table.insert(effect, side)
            if self.arenaAnim == "show" then
                side.SendToBottom()
            end
        end

        effect.frame = self.frame
        effect.angle = rotation

        table.insert(self.arenaAnimEffects, effect)
    end

    -- Updates the Arena's animation
    function self.UpdateArenaAnim()
        if self.arenaAnim then
            local frame = self.arenaAnim == "show" and self.frame - self.arenaAnimFrame or self.arenaAnimTime - (self.frame - self.arenaAnimFrame)
            local scale = frame / self.arenaAnimTime

            -- Update the arena
            local effectCount = #self.arenaAnimEffects
            for i = effectCount, 1, -1 do
                local effect = self.arenaAnimEffects[i]
                local effectFrame = self.frame - effect.frame
                local isEnd = false
                -- For each part of each arena
                for j = 1, #effect do
                    local effectPart = effect[j]
                    -- Hide it over time
                    effectPart.alpha = 0.8 - effectFrame / 20
                    -- Hide it quicker if we're close to the end of the animation
                    if frame < 10 then
                        effectPart.alpha = effectPart.alpha * frame / 10
                    end
                    -- Only one trailing sprite out of two is kept to match Deltarune's animation
                    if frame % 2 == 0 and i == effectCount then
                        effectPart.alpha = 0
                    end
                    -- If the effect is not visible, delete it
                    if effectPart.alpha == 0 then
                        effectPart.Remove()
                        isEnd = true
                    -- We don't need the middle part when we're hiding the arena
                    elseif self.arenaAnim ~= "show" and i ~= effectCount and j == 5 then
                        effectPart.Remove()
                        table.remove(effect, 5)
                    end
                end
                if isEnd then
                    table.remove(self.arenaAnimEffects, i)
                end
            end
            self.SpawnArenaSpriteForAnim(frame)

            -- Updates the heart
            if frame <= 30 then
                if frame == self.arenaAnimTime - 30 and self.arenaAnim ~= "show" and self.Background then
                    self.Background.Display(true, 30)
                end
                -- Updates the heart's little spawn effects
                for i = 1, #self.arenaAnimHeartEffects do
                    local heart = self.arenaAnimHeartEffects[i]
                    local coeff = frame * (1.25 - (i * 0.25))
                    heart.Scale(coeff / 4, coeff / 6)
                    heart.alpha = 1 - ((2 * (i - 1) + frame) / 20)
                end
                -- Move the player's soul from the first Player's position to the Arena or from the Arena to the first Player's position
                if frame <= 20 and (Player.sprite.layer == "Arena" or Player.sprite.layer == "Bullet") then
                    Player.sprite.alpha = frame / 10
                    local coeff = frame * 0.05
                    local startingPos = self.arenaAnim == "show" and { x = self.arenaAnimInfo.x, y = self.arenaAnimInfo.y } or { x = self.arenaAnimInfo.px, y = self.arenaAnimInfo.py }
                    Player.MoveToAbs(self.arenaAnimHeartEffects[1].absx + (startingPos.x - self.arenaAnimHeartEffects[1].absx) * coeff,
                                     self.arenaAnimHeartEffects[1].absy + (startingPos.y - self.arenaAnimHeartEffects[1].absy) * coeff, true)
                end
            end

            -- End of the animation
            if frame == self.arenaAnimTime or frame == 0 then
                self.EndArenaAnim()
            end
        end
    end

    -- Ends the current arena animation
    function self.EndArenaAnim(nostate)
        -- Destroys the heart effects
        for i = #self.arenaAnimHeartEffects, 1, -1 do
            self.arenaAnimHeartEffects[i].Remove()
            table.remove(self.arenaAnimHeartEffects, i)
        end
        -- Destroys the arena effects
        for i = #self.arenaAnimEffects, 1, -1 do
            while #self.arenaAnimEffects[i] > 0 do
                self.arenaAnimEffects[i][1].Remove()
                table.remove(self.arenaAnimEffects[i], 1)
            end
            table.remove(self.arenaAnimEffects, i)
        end
        self.arenaAnimInfo.shown = oldArenaAnim == "show"
        local oldArenaAnim = self.arenaAnim
        self.arenaAnim = nil
        -- If this is the end of the "show" animation, start the wave
        if oldArenaAnim == "show" then
            if #Wave == 0 then
                self.StartArenaAnim(false, true)
                return
            end
            Wave[1].Call("ShowArenaAfterEndAnim")
            nextwaves = self.nextwaves
            -- Don't ask me why there's two calls to "DEFENDING", I don't remember why and I'm afraid to touch it!
            OldState("DEFENDING")
            OldState("DEFENDING")
            Player.sprite.MoveToAbs(self.arenaAnimInfo.x, self.arenaAnimInfo.y)
        -- If this is the end of the "hide" animation, start another Player turn
        elseif not self.arenaAnimInfo.nostate and not nostate then
            Player.sprite.SetParent(self.UI.hider)
            -- Time for a new turn!
            self.turn = 0
            self.State("ACTIONSELECT")
        end
    end
end