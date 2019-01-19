return function(CYK)
    local self = { }

    self.stuffToShake = { }
    self.shakeInProgress = nil

    -- Adds the entities as sprites to shake
    for i = 1, #CYK.allPlayers + #CYK.allEnemies do
        local pool = i > #CYK.allPlayers and CYK.allEnemies or CYK.allPlayers
        local entity = pool[i > #CYK.allPlayers and i - #CYK.allPlayers or i]
        table.insert(self.stuffToShake, entity)
    end

    -- Creates a shake!
    function self.Shake(intensity, frames, fading, degree)
        local shake = { frames = frames, fading = fading }

        if not intensity then    intensity = 4                end
        if not shake.frames then shake.frames = 10            end
        if not shake.fading then shake.fading = false         end
        if not degree then       degree = math.random(0, 359) end

        shake.xMove = math.cos(math.rad(degree)) * intensity
        shake.yMove = math.sin(math.rad(degree)) * intensity
        shake.start = CYK.frame

        self.shakeInProgress = shake
    end

    -- Update the screen shaking effect
    function self.Update()
        if self.shakeInProgress then
            local shake = self.shakeInProgress
            local frame = CYK.frame - shake.start

            local fadingCoeff = shake.fading and frame / shake.frames or 1
            local dir = frame % 8 < 4 and 2 or 0
            if dir ~= 0 then
                local xMove = shake.xMove * fadingCoeff * dir
                local yMove = shake.yMove * fadingCoeff * dir

                for j = 1, #self.stuffToShake do
                    local sprite = self.stuffToShake[j].sprite
                    sprite.absx = sprite.absx + xMove - (sprite["lastXMove"] or 0)
                    sprite.absy = sprite.absy + yMove - (sprite["lastYMove"] or 0)
                    sprite["lastXMove"] = xMove
                    sprite["lastYMove"] = yMove
                end
            end

            if frame == shake.frames then
                for j = 1, #self.stuffToShake do
                    local sprite = self.stuffToShake[j].sprite
                    sprite.absx = self.stuffToShake[j].posX
                    sprite.absy = self.stuffToShake[j].posY
                    sprite["lastXMove"] = 0
                    sprite["lastYMove"] = 0
                end
                self.shakeInProgress = nil
            end
        end
    end

    return self
end