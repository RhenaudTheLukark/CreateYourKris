return function(CYK)
    local self = { }

    -- Main encounter text
    self.text = CreateText({ "" }, {600, 200}, 500, "LowerUI")
    self.text.SetParent(CYK.UI.hider)
    self.text.progressmode = "none"
    self.text.HideBubble()
    self.text.x = 30
    self.text.y = 78

    -- Choice text
    self.text2 = CreateText({ "" }, {600, 200}, 540, "LowerUI")
    self.text2.SetParent(CYK.UI.hider)
    self.text2.progressmode = "none"
    self.text2.HideBubble()
    self.text2.x = 260
    self.text2.y = 78

    -- Magic description text
    self.textDescription = CreateText({ "" }, {600, 200}, 140, "LowerUI")
    self.textDescription.SetParent(CYK.UI.hider)
    self.textDescription.progressmode = "none"
    self.textDescription.HideBubble()
    self.textDescription.x = 480
    self.textDescription.y = 78

    self.twoColumns = false    -- Does the last choice displayed use two columns?
    self.textDActive = false   -- Is the text used for displaying a spell's or item's description active?
    self.lifebars = { }        -- Used when we need lifebars to be displayed in a choice
    self.lastText = ""         -- Keeps the last encounter text displayed
    self.lastText2 = ""        -- Keeps the last encounter text displayed (stars)

    -- Text arrows used when displaying a choice of items but there are some more items left
    self.textArrowAnimStart = 0
    self.textArrow = CreateSprite("CreateYourKris/UI/Arrow", "LowerUI")
    self.textArrow.SetPivot(0, 0)
    self.textArrow.SetAnchor(0, 0)
    self.textArrow.SetParent(CYK.UI.hider)
    self.textArrow.x = 450
    self.textArrow.y = 83
    self.textArrow.alpha = 0

    self.textArrowDown = CreateSprite("CreateYourKris/UI/Arrow", "LowerUI")
    self.textArrowDown.SetPivot(0, 1)
    self.textArrowDown.SetAnchor(0, 0)
    self.textArrowDown.SetParent(CYK.UI.hider)
    self.textArrowDown.yscale = -1
    self.textArrowDown.x = 450
    self.textArrowDown.y = 17
    self.textArrowDown.alpha = 0
    self.textArrows = { self.textArrow, self.textArrowDown }

    self.textLine = 1

    self.faceSprite = CreateSprite("empty", "LowerUI")
    self.faceSprite.SetPivot(0, 0)
    self.faceSprite.SetAnchor(0, 0)
    self.faceSprite.SetParent(CYK.UI.hider)
    self.faceSprite.x = 17
    self.faceSprite.y = 2
    self.faceSprite.alpha = 0

    -- Displays an encounter text
    function self.SetText(text, text2, noReplaceTexts)
        if CYK.state == "NONE" then
            self.text.progressmode = "manual"
            self.text2.progressmode = "manual"
        else
            self.text.progressmode = "none"
            self.text2.progressmode = "none"
        end
        self.faceSprite.alpha = 0
        self.textLine = 1
        self.DestroyLifebars()
        self.DisplayTextArrow(false, false)
        self.DisplayTextArrow(false, true)

        self.text.x = 80
        self.text2.x = 40

        if not text2 then
            text2 = table.copy(text)
            for i = 1, #text do
                local commandsEnd = self.GetCommandEnd(text[i])
                local textCommands = commandsEnd > 1 and string.sub(text[i], 1, commandsEnd - 1) or ""
                local textRealText = commandsEnd > 1 and string.sub(text[i], commandsEnd, #text[i]) or text[i]
                text[i] = "[font:uidialog2]" .. textCommands .. "¤¤" .. string.gsub(string.gsub(textRealText, "\n", "\n¤¤"), "\r", "\n")
                -- TODO: Detect size star and space for each \n and begin of text
                text2[i] = "[font:uidialog2]" .. self.SilenceText(textCommands) .. "[novoice]*[charspacing:-37] [charspacing:1][alpha:00]" ..
                           string.gsub(string.gsub(self.SilenceText(textRealText), "\n", "\n[alpha:ff]*[charspacing:-37] [charspacing:1][alpha:00]"), "\r", "\n")
            end
        end

        if not noReplaceTexts then
            self.lastText = text
            self.lastText2 = text2
        end
        self.ScanTextLine()
        self.text.SetText(text)
        self.text2.SetText(text2)

        self.twoColumns = false
        self.textDescription.SetText({ "" })
        self.textDActive = false
    end

    -- Handles a string and "silences" any dangerous command in it
    function self.SilenceText(text)
        local index = 1
        local bracketCount = 0
        local bracketBegin = -1
        while index <= #text do
            local char = text[index]
            -- Char is opening bracket
            if char == "[" then
                if bracketCount == 0 then
                    bracketBegin = index
                end
                bracketCount = bracketCount + 1
            -- Char is closing bracket
            elseif char == "]" then
                bracketCount = bracketCount - 1
                -- If this is the end of a command, isolate it and see what we should do depending on what it is
                if bracketCount == 0 then
                    local command = string.sub(text, bracketBegin + 1, index - 1)
                    local commandName = string.split(command, ":")[1]
                    -- Remove any func, color or alpha call
                    if commandName == "func" or commandName == "color" or commandName == "alpha" then
                        text = string.sub(text, 1, bracketBegin - 1) .. (#text < index and "" or string.sub(text, index + 1, #text))
                        index = bracketBegin - 1
                    -- Add [novoice] to any font or voice call
                    elseif commandName == "font" or commandName == "voice" then
                        text = string.sub(text, 1, index) .. "[novoice]" .. (#text < index and "" or string.sub(text, index + 1, #text))
                        index = index + 9
                    end
                    bracketBegin = -1
                -- Too many brackets: omit it
                elseif bracketCount < 0 then
                    bracketCount = 0
                end
            end

            index = index + 1
        end
        return text
    end

    function self.GetCommandEnd(text)
        local braCount = 0
        local charIndex = 1
        while braCount > 0 or text[charIndex] == "[" do
            if text[charIndex] == "[" then
                braCount = braCount + 1
            elseif text[charIndex] == "]" then
                braCount = braCount - 1
            end
            charIndex = charIndex + 1
            if #text < charIndex then
                charIndex = #text + 1
                break
            end
        end
        return charIndex
    end

    function self.HideText()
        self.SetText({ "" }, { "" }, true)
    end

    function self.ScanTextLine(nextLine)
        local doNextLine = false
        self.faceSprite.alpha = 0
        if nextLine then
            if self.text.allLinesComplete then
                self.HideText()
            else
                self.textLine = self.textLine + 1
                doNextLine = true
            end
        end
        if self.textLine <= #self.lastText or not nextLine then
            local text = self.lastText[self.textLine < #self.lastText and self.textLine or #self.lastText]
            if string.find(text, "SetFaceSprite") then
                self.text.x = 180
                self.text.textMaxWidth = 440
                self.text2.x = 140
                self.text2.textMaxWidth = 440
            else
                self.text.x = 80
                self.text.textMaxWidth = 540
                self.text2.x = 40
                self.text2.textMaxWidth = 540
            end
        end
        if doNextLine then
            self.text.NextLine()
            self.text2.NextLine()
        end
    end

    -- Displays a choice
    self.lastChoice = { "" }
    self.lastBars = false
    self.lastTwoColumns = false
    self.lastGradientChoices = false
    function self.SetChoice(choices, bars, twoColumns, description, gradientChoices)
        self.faceSprite.alpha = 0
        self.DestroyLifebars()
        Player.sprite.alpha = 1
        Player.sprite.SetParent(CYK.UI.hider)

        if #choices == 0 then
            error("Can't have a choice with 0 options!")
        end

        local choiceLimit = 3 * (twoColumns and 2 or 1)

        self.DisplayChoices(choices, bars, twoColumns, 1, gradientChoices)

        if #choices > choiceLimit then
            self.DisplayTextArrow(true, false)
        end

        self.twoColumns = twoColumns
        self.textDescription.SetText({ "" })
        self.textDActive = description and true or false

        self.lastChoice = choices
        self.lastTwoColumns = twoColumns
        self.lastBars = bars
        self.lastGradientChoices = gradientChoices
        self.currentPage = 1

        CYK.choiceIndexLimit = math.min(#choices, 3 * (twoColumns and 2 or 1))
    end

    self.currentPage = 1
    -- Displays a new choice page if there are more choices than the UI can display
    function self.NextChoicePage(prev)
        self.DestroyLifebars()

        local values = self.lastTwoColumns and 6 or 3
        self.currentPage = self.currentPage + (prev and -1 or 1)
        local maxPage = math.ceil(#self.lastChoice / values)
        if self.currentPage == 0 then
            self.currentPage = maxPage
        elseif self.currentPage > maxPage then
            self.currentPage = 1
        end

        self.DisplayChoices(self.lastChoice, self.lastBars, self.lastTwoColumns, 1 + values * (self.currentPage - 1), self.lastGradientChoices)

        self.DisplayTextArrow(self.currentPage > 1, true)
        self.DisplayTextArrow(self.currentPage < maxPage, false)
    end

    -- Displays choices. Used in several functions so condensed in an util function
    function self.DisplayChoices(choices, bars, twoColumns, start, gradientChoices)
        self.DisplayTextArrow(false, true)
        self.DisplayTextArrow(false, false)

        local choiceText = "[font:uidialog][instant][novoice]"
        local choiceText2 = "[font:uidialog][instant][novoice]"
        local testText = ""
        for i = start, math.min(#choices, start + (twoColumns and 5 or 2)) do
            testText = testText .. tostring(choices[i]) .. ","
            if twoColumns then
                if i % 2 == 1 then
                    choiceText = choiceText .. choices[i] .. "\n"
                else
                    choiceText2 = choiceText2 .. choices[i] .. "\n"
                end
            else
                choiceText = choiceText .. choices[i] .. "\n"
                if gradientChoices ~= nil then
                    choiceText2 = choiceText2 .. gradientChoices[i] .. "\n"
                end
            end

            -- Lifebars needed!
            if bars then
                local lifebar1 = CreateSprite("px", "LowerUI")
                lifebar1.SetParent(CYK.UI.hider)
                lifebar1.Scale(81, 16)
                lifebar1.SetPivot(0, 0)
                lifebar1.SetAnchor(0, 0)
                lifebar1.x = 510
                lifebar1.y = 84 - (30 * (i - start))
                lifebar1.color = { 0.5, 0, 0 }

                local lifebar2 = CreateSprite("px", "LowerUI")
                lifebar2.SetParent(lifebar1)
                lifebar2.Scale(81, 16)
                lifebar2.SetAnchor(0, 0)
                lifebar2.SetPivot(0, 0)
                lifebar2.x = 0
                lifebar2.y = 0
                lifebar2.color = { 0, 1, 0 }

                local targetPool = CYK.players[CYK.turn].targetType == "Enemy" and CYK.enemies or CYK.players
                lifebar2.xscale = 81 * targetPool[i].hp / targetPool[i].maxhp

                table.insert(self.lifebars, { lifebar1, lifebar2 })
            end
        end

        self.text.x = twoColumns and 40 or 80
        self.text.SetText({ choiceText })
        self.text2.x = twoColumns and 240 or 80
        self.text2.SetText({ choiceText2 })
    end

    -- Display a text arrow on the screen. They are used when there are too many choices to fit everything in the box at once
    function self.DisplayTextArrow(show, isUp)
        local textArrow = isUp and self.textArrow or self.textArrowDown
        textArrow.alpha = show and 1 or 0
        textArrow.y = isUp and 83 or 21
        textArrowAnimStart = CYK.frame
    end

    -- Destroys the lifebars on the choice screen if there's any
    function self.DestroyLifebars()
        for i = #self.lifebars, 1, -1 do
            local lifebar = self.lifebars[i]
            lifebar[1].Remove()
            lifebar[2].Remove()
            table.remove(self.lifebars, i)
        end
    end

    function self.Update()
        self.UpdateTextArrows()
    end

    function self.UpdateTextArrows()
        local arrowFrame = (CYK.frame - self.textArrowAnimStart) % 60
        for i = 1, #self.textArrows do
            local textArrow = self.textArrows[i]
            if textArrow.alpha > 0 then
                if arrowFrame % 4 == 0 and arrowFrame ~= 0 then
                    if arrowFrame < 20 then
                        textArrow.y = textArrow.y + (i == 1 and 1 or -1)
                    elseif arrowFrame > 40 then
                        textArrow.y = textArrow.y + (i == 1 and -1 or 1)
                    end
                end
            end
        end
    end

    function SetFaceSprite(faceSprite)
        local faceSpriteData = string.split(faceSprite, '.')
        if #faceSpriteData ~= 3 then
            error("SetFaceSprite needs an argument which is exactly composed of the name of the type of the entity, a dot, the name of the entity, a dot and the name of the faceSprite.\nExample: Players.Ralsei.Normal, Monsters.Poseur.Pissed")
        end
        CYK.TxtMgr.faceSprite.alpha = 1
        CYK.TxtMgr.faceSprite.Set("CreateYourKris/" .. faceSpriteData[1] .. "/" .. faceSpriteData[2] .. "/FaceSprite/" .. faceSpriteData[3])
    end

    return self
end