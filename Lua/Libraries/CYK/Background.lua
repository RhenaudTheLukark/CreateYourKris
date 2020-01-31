-- This library handles everything related to the background
return function(CYK, isActive, isFadeActive)
    local self = { }

    self.isActive = isActive
    self.isFadeActive = isFadeActive

    if self.isActive then
        -- Hide that old UT
        CYK.hider = CreateSprite("px", "Background")
        CYK.hider.absx = 320
        CYK.hider.absy = 240
        CYK.hider.Scale(640, 480)
        CYK.hider.color = { 0, 0, 0 }

        -- Purple squarey background
        self.dir = { }

        for i = 1, 2 do
            local bg = CreateSprite("CreateYourKris/bg" .. (CYK.CrateYourKris and "Troll" or ""), "Background")
            bg.absx = 320
            bg.absy = 240 + (i == 1 and 0 or -10)
            bg["startX"] = bg.absx
            bg["startY"] = bg.absy
            if i > 1 then
                bg.alpha = 0.6
            end
            table.insert(self, bg)
            table.insert(self.dir, i == 1 and -.5 or .2)
        end
    end

    -- This black sprite is used to "fade" the background
    -- It's actually just this sprite's alpha changing so the background can be darker
    if self.isFadeActive then
        self.fade = CreateSprite("px", "Background")
        self.fade.absx = 320
        self.fade.absy = 240
        self.fade.Scale(640, 480)
        self.fade.color = { 0, 0, 0 }
        self.fade.alpha = 0

        self.shown = true
        self.maxHideTimer = -1
        self.hideTimer = -1
        self.anim = nil
    end

    -- Updates the background
    function self.Update()
        -- Move the purple square grids at different speeds if the background's active
        if self.isActive then
            for i = 1, #self do
                local bg = self[i]
                bg.Move(self.dir[i], -self.dir[i])
                if bg.absx > bg["startX"] + 25 then
                    bg.absx = bg.absx - 51
                elseif bg.absx < bg["startX"] - 25 then
                    bg.absx = bg.absx + 51
                end
                if bg.absy > bg["startY"] + 25 then
                    bg.absy = bg.absy - 51
                elseif bg.absy < bg["startY"] - 25 then
                    bg.absy = bg.absy + 51
                end
            end
        end

        -- Change the fade sprite's alpha when the background is fading in or out
        if self.anim and self.isFadeActive then
            local alpha = self.maxHideTimer == 0 and (self.anim == "show" and 0 or 0.5)
                                                 or  (self.anim == "show" and (self.hideTimer / self.maxHideTimer) * 0.5
                                                                          or  0.5 - self.hideTimer / self.maxHideTimer * 0.5)
            self.fade.alpha = alpha

            self.hideTimer = self.hideTimer - 1
            if self.hideTimer == -1 then
                self.shown = self.anim == "show"
                self.anim = nil
                return
            end
        end
    end

    -- Hides or shows the background
    function self.Display(show, timer)
        if self.isFadeActive then
            self.hideTimer = timer or 0
            self.maxHideTimer = timer or 0
            self.anim = show and "show" or "hide"
            self.shown = true
        end
    end

    return self
end