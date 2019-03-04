return function(CreateYourKris)
    -- TP bar and info
    local self = { }
    self.CreateYourKris = CreateYourKris       -- CYK core

    self.ySize = 187                           -- Y size of the TP bar
    self.trueValue = 0                         -- TP the team has
    self.barValue = 0                          -- TP value used to display the bar
    self.previewValue = 0                      -- TP value used to display the bar's preview (white bar)
    self.barSpeed = 1                          -- Speed at which the bar can change per frame
    self.previewSpeed = 4                      -- Speed at which the preview bar can change per frame
    self.bgColor32 = { 128, 0, 0 }             -- Color of the TP bar's background
    self.noFullColor32 = { 255, 160, 64 }      -- Color of the TP bar when not full
    self.fullColor32 = { 255, 208, 32 }        -- Color of the TP bar when full
    self.previewUpColor32 = { 255, 255, 255 }  -- Color of one of the preview bars of the TP bar
    self.previewDownColor32 = { 255, 0, 0 }    -- Color of one of the preview bars of the TP bar
    self.isLossPreviewed = false               -- Are we in the MAGIC choice, showing the TP loss if we choose this option?

    self.bar = { }

    -- TP bar background
    self.bar.bg = CreateSprite("px", "UpperUI")
    self.bar.bg.Scale(19, 187)
    self.bar.bg.SetPivot(0, 1)
    self.bar.bg.absx = 41
    self.bar.bg.absy = 435
    self.bar.bg.color32 = self.bgColor32

    -- TP bar (white gauge)
    self.bar.preview = CreateSprite("px")
    self.bar.preview.SetParent(self.bar.bg)
    self.bar.preview.Scale(19, 0)
    self.bar.preview.SetAnchor(0, 0)
    self.bar.preview.SetPivot(0, 0)
    self.bar.preview.x = 0
    self.bar.preview.y = 0
    self.bar.preview.color32 = self.previewUpColor32

    -- TP bar (red gauge)
    self.bar.previewDown = CreateSprite("px")
    self.bar.previewDown.SetParent(self.bar.bg)
    self.bar.previewDown.Scale(19, 0)
    self.bar.previewDown.SetAnchor(0, 0)
    self.bar.previewDown.SetPivot(0, 0)
    self.bar.previewDown.x = 0
    self.bar.previewDown.y = 0
    self.bar.previewDown.color32 = self.previewDownColor32

    -- TP bar (normal gauge)
    self.bar.bar = CreateSprite("px")
    self.bar.bar.SetParent(self.bar.bg)
    self.bar.bar.Scale(19, 0)
    self.bar.bar.SetAnchor(0, 0)
    self.bar.bar.SetPivot(0, 0)
    self.bar.bar.x = 0
    self.bar.bar.y = 0
    self.bar.bar.color32 = self.noFullColor32

    -- TP bar preview loss TP with MAGIC command choice
    self.bar.previewTPLoss = CreateSprite("px")
    self.bar.previewTPLoss.SetParent(self.bar.bg)
    self.bar.previewTPLoss.Scale(19, 0)
    self.bar.previewTPLoss.SetAnchor(0, 0)
    self.bar.previewTPLoss.SetPivot(0, 1)
    self.bar.previewTPLoss.x = 0
    self.bar.previewTPLoss.y = 0
    self.bar.previewTPLoss.color32 = self.previewUpColor32

    -- TP bar mask
    self.bar.mask = CreateSprite("CreateYourKris/TP Bar/mask")
    self.bar.mask.SetParent(self.bar.bg)
    self.bar.mask.SetPivot(0, 0)
    self.bar.mask.SetAnchor(0, 0)
    self.bar.mask.x = -3
    self.bar.mask.y = -4

    -- TP bar text
    self.staticText = CreateSprite("CreateYourKris/TP Bar/text")
    self.staticText.SetParent(self.bar.bg)
    self.staticText.SetPivot(0, 1)
    self.staticText.absx = 0
    self.staticText.absy = 435

    -- TP bar numbers
    self.num1 = CreateSprite("CreateYourKris/TP Bar/Numbers/0")
    self.num1.SetParent(self.bar.bg)
    self.num1.SetPivot(0.5, 0)
    self.num1.absx = 20
    self.num1.absy = 345

    self.num2 = CreateSprite("empty")
    self.num2.SetParent(self.bar.bg)
    self.num2.SetPivot(0.5, 0)
    self.num2.absx = 28
    self.num2.absy = 345

    self.isBeingShown = false
    self.shownTimer = 0

    -- Updates the TP bar
    function self.Update()
        if self.isBeingShown then
            self.bar.bg.x = self.bar.bg.x + (self.shownTimer < 10 and 5 or self.shownTimer < 15 and 4 or 2)
            self.shownTimer = self.shownTimer + 1
            if self.shownTimer == 20 then
                self.isBeingShown = false
            end
        end

        -- Move the preview of the TP bar if it's not equal to the TP bar's true value
        if self.trueValue ~= self.previewValue then
            -- Case TP was 100
            if self.previewValue == 100 then
                self.bar.bar.color32 = self.noFullColor32
                self.staticText.Set("CreateYourKris/TP Bar/text")
            end

            local gt = self.trueValue > self.previewValue
            self.previewValue = self.previewValue + math.min(self.previewSpeed, math.abs(self.previewValue - self.trueValue)) * (gt and 1 or -1)

            -- Case TP is now 100: hide the numbers and set the bar's color
            if self.previewValue == 100 then
                self.barValue = 99
                self.bar.bar.color32 = self.fullColor32
                self.num1.Set("empty")
                self.num2.Set("empty")
                self.staticText.Set("CreateYourKris/TP Bar/textMAX")
            else
                -- Computes the scale of the bar and applies it
                local associatedYScale = self.previewValue / 100 * self.ySize
                if gt then
                    self.bar.preview.yscale = associatedYScale + 1  -- +1 because the preview has to be visible
                else
                    self.bar.bar.yscale = associatedYScale
                    if self.barValue >= self.trueValue then
                        self.bar.previewDown.yscale = associatedYScale
                    end
                end

                -- Updates the numbers
                local twoNumbers = self.previewValue >= 10
                self.num1.Set("CreateYourKris/TP Bar/Numbers/" .. (twoNumbers and tostring(math.floor(self.previewValue / 10)) or tostring(math.floor(self.previewValue))))
                if twoNumbers then
                    self.num1.absx = 12
                    self.num2.Set("CreateYourKris/TP Bar/Numbers/" .. tostring(math.floor(self.previewValue) % 10))
                else
                    self.num1.absx = 20
                    self.num2.Set("empty")
                end
            end
        end

        -- Move the TP bar if it's not equal to the TP bar's true value
        if self.trueValue ~= self.barValue then
            local gt = self.trueValue > self.barValue
            self.barValue = self.barValue + math.min(self.barSpeed, math.abs(self.barValue - self.trueValue)) * (gt and 1 or -1)

            -- Computes the scale of the bar and applies it
            local associatedYScale = self.barValue / 100 * self.ySize
            if gt then
                self.bar.bar.yscale = associatedYScale
            else
                self.bar.previewDown.yscale = associatedYScale
                self.bar.preview.yscale = associatedYScale + (self.barValue == 0 and 0 or 1)
            end

            -- Check if preview was above the other value
            local previewDiff = self.trueValue - self.previewValue
            local barDiff = self.trueValue - self.barValue
            associatedYScale = self.trueValue / 100 * self.ySize
            if (previewDiff < 0 and barDiff > 0) or (previewDiff > 0 and barDiff < 0) then
                if previewDiff < 0 then
                    self.bar.preview.yscale = associatedYScale + (self.barValue == 0 and 0 or 1)
                else
                    self.bar.bar.yscale = associatedYScale
                end
            end
        end

        if self.isLossPreviewed then
            self.bar.previewTPLoss.alpha = self.CreateYourKris.frame % 60 < 30 and self.CreateYourKris.frame % 60 / 40 or (60 - (self.CreateYourKris.frame % 60)) / 40
        end
    end

    function self.PreviewTPLoss(loss)
        if loss > self.trueValue then
            self.isLossPreviewed = false
            self.bar.previewTPLoss.alpha = 0
            return
        end
        self.isLossPreviewed = true

        self.bar.previewTPLoss.yscale = loss / 100 * self.ySize
        self.bar.previewTPLoss.y = self.barValue / 100 * self.ySize
    end

    -- Sets the TP bar's true value
    function self.Set(value, isRelative)
        self.trueValue = isRelative and self.trueValue + value or value
        if self.trueValue < 0 then   self.trueValue = 0   end
        if self.trueValue > 100 then self.trueValue = 100 end
    end

    function self.Show()
        self.bar.bg.absx = -39
        self.shownTimer = 0
        self.isBeingShown = true
    end

    self.bar.bg.absx = -39

    return self
end