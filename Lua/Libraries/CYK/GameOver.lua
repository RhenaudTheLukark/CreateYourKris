-- WD200019's Deltarune Game Over recreation
-- For CYK v1.1 and above
local self = { }

self.active = false        -- Will be true whenever the game over sequence is active
self.layer = "Top"         -- The layer to create all of the sprites on
self.animTimer = 0         -- Used to keep track of the progress of the game over animation
self.music = "AUDIO_DRONE" -- The music to play
self.choice = nil          -- Whether the player chooses "Yes"

self.fakePlayer = nil      -- Fake Player soul used in the soul break animation
self.cover = nil           -- Covers the entire screen to hide CYK during the Game Over animation
self.shards = { }          -- A table of player soul fragments to animate
self.oldUpdate = nil       -- Old Update() function used in the CYK mod

self.textProgress = 0      -- The progress for the text object
self.textObject = nil      -- Game over text object

self.heart = nil           -- Choice soul
self.yes = nil             -- YES text for the choice
self.no = nil              -- NO text for the choice

self.cover2 = nil          -- Cover sprite used if the Player selects "NO"

-- Text to be displayed on death
self.text = {
    "IT APPEARS YOU\nHAVE REACHED[w:25]\n\n    [charspacing:0] [charspacing:13]AN [charspacing:0] [charspacing:11]END.",
    "WILL[charspacing:18] [charspacing:13]YOU[charspacing:18] [charspacing:13]TRY[charspacing:18] [charspacing:13]AGAIN?",
    "[w:4]THEN,[w:5] THE FUTURE\nIS IN YOUR HANDS.",          "[w:4]THEN THE WORLD[w:20]\nWAS COVERED[w:20]\nIN DARKNESS."
}

for i = 1, #self.text do
    self.text[i] = "[noskip][font:uidialog][novoice][color:ffffff][charspacing:13][linespacing:10][speed:0.75]" .. self.text[i]
end

-- The update function. call from the encounter's Update function!
function self.Update()
    -- Update player soul shards
	if self.active and self.shards ~= nil then
		if self.animTimer > 150 then
			for i = 1, #self.shards do
                if self.shards[i][1] ~= nil then
                    local shard = self.shards[i][1]

                    shard.MoveTo(shard.x + (self.shards[i][2] * shard["xmult"]), shard.y + self.shards[i][3])

                    -- Slow down the shard's horizontal movement
                    if shard["xmult"] > 0 then
                        shard["xmult"] = shard["xmult"] - 0.0125

                        if shard["xmult"] < 0 then
                            shard["xmult"] = 0
                        end
                    end

                    self.shards[i][3] = self.shards[i][3] - 0.05

                    -- Animate the shard
                    if (self.animTimer - 140) % 4 == 0 then
                        shard.Set("UI/Battle/heartshard_" .. tostring(math.floor((self.animTimer - 140) / 8) % 4))
                    end
                end
			end
		end
    end

    -- Update animation timer
	if self.animTimer > 0 and not self.textObject then
		self.animTimer = self.animTimer + 1

        -- Break the heart (1/2)
		if self.animTimer == 80 then
			Audio.PlaySound("heartbeatbreaker")
			self.fakePlayer.Set("ut-heart-broken")
            self.fakePlayer.rotation = 0
        -- Break the heart (2/2)
		elseif self.animTimer == 150 then
			Audio.PlaySound("heartsplosion")
			self.shards = { }

            -- Create shards
			for i = 1, 6 do
				local shard = CreateSprite("UI/Battle/heartshard_0", self.layer)
                shard.MoveTo(self.fakePlayer.absx, self.fakePlayer.absy)
				shard.color = self.fakePlayer.color
				shard.SetVar("xmult", 2)

				local velx = 0
                local vely = 0

                -- Make sure that every shard has a unique x and y velocity
				local prev_velx = { }
                local prev_vely = { }

				for j = 1, #self.shards do
					prev_velx[self.shards[j][2]] = true
					prev_vely[self.shards[j][3]] = true
				end

				repeat
					velx = (math.random(-8, 8) / 3)
				until prev_velx[velx] == nil

				repeat
					vely = (math.random(-3, 6) / 2) + 2
				until prev_vely[vely] == nil

				table.insert(self.shards, { shard, velx, vely })
			end

            -- Remove the fake player
			self.fakePlayer.Remove()
            self.fakePlayer = nil
        -- Start the music and create the "game over" text
		elseif self.animTimer == 250 then
			Audio.LoadFile(self.music and self.music or (deathmusic and deathmusic or "mus_gameover"))
            Audio.Volume(0.75)
        -- Fade out player shards
		elseif self.animTimer > 250 and self.animTimer < 360 then
			for i = 1, #self.shards do
                self.shards[i][1].alpha = self.shards[i][1].alpha - 0.0125
            end
        -- Start the text and remove shards
		elseif self.animTimer == 360 then
            for i = 1, #self.shards do
                self.shards[i][1].Remove()
            end
            self.shards = nil

            self.StartText()
		end
    -- Freeze self.animTimer until the text object is all done
    elseif self.textObject then
        -- Advance timer for fading in soul, "YES", and "NO"
        if self.textProgress == 1 and self.textObject.currentReferenceCharacter >= 9 and self.animTimer < 390 then
            self.animTimer = self.animTimer + 1

            self.heart.alpha = (self.animTimer - 370) / 20
            self.yes.alpha   = (self.animTimer - 370) / 20
            self.no.alpha    = (self.animTimer - 370) / 20
        -- Allow user to pick "YES" or "NO"
        elseif self.textProgress == 1 and self.animTimer == 390 then
            -- No horizontal wrapping
            if Input.Left == 1 and self.choice ~= true then
                self.choice = true
                self.yes.color = {1, 1, 0}
                self.no.color  = {1, 1, 1}
            elseif Input.Right == 1 and self.choice ~= false then
                self.choice = false
                self.yes.color = {1, 1, 1}
                self.no.color  = {1, 1, 0}
            end

            -- Move the player soul to the choice
            local destination = (self.choice == true and 241) or (self.choice == false and 394) or 320

            self.heart.x = self.heart.x + ((destination - self.heart.x) / 4)
            self.heart.x = math.floor(self.heart.x * 10) / 10
        end

        -- Allow pressing Z
        if Input.Confirm == 1 and self.textObject.lineComplete and ((self.textProgress == 1 and self.choice ~= nil) or self.textProgress ~= 1) and self.textProgress < 3 then
            -- Increase progress
            self.textProgress = self.textProgress + 1

            -- Start second line
            if self.textProgress == 1 then
                self.textObject.NextLine()

                self.textObject.MoveTo(105, 294)

                -- Create new soul
                self.heart = CreateSprite("CreateYourKris/dr-heart", self.layer)
                self.heart.MoveTo(320, 100)
                self.heart.alpha = 0

                -- Create "YES"
                self.yes = CreateText("[noskip][instant][font:uidialog]YES", { 221, 94 }, 40, self.layer)
                self.yes.color = { 1, 1, 1, 0 }
                self.yes.HideBubble()
                self.yes.progressmode = "none"

                -- Create "NO"
                self.no = CreateText("[noskip][instant][font:uidialog]NO", { 381, 94 }, 40, self.layer)
                self.no.color = { 1, 1, 1, 0 }
                self.no.HideBubble()
                self.no.progressmode = "none"
            -- start third line (both variants)
            elseif self.textProgress == 2 then
                Audio.Stop()

                self.heart.Remove()
                self.heart = nil
                self.yes.DestroyText()
                self.yes   = nil
                self.no.DestroyText()
                self.no    = nil

                -- "YES"
                if self.choice then
                    self.textObject.MoveTo(124, 294)
                    self.textObject.SetText({self.text[3]})

                    self.textProgress = 3

                    self.cover2 = CreateSprite("UI/sq_white", self.layer)
                    self.cover2.MoveTo(320, 240)
                    self.cover2.Scale(640 / 4, 480 / 4)
                    self.cover2.alpha = 0
                -- "NO"
                else
                    self.textObject.MoveTo(144, 294)
                    self.textObject.SetText({ self.text[4], "" })
                end
            -- Pressed Z after third line
            elseif self.textProgress == 3 and self.choice == false then
                self.textObject.NextLine()
                NewAudio.PlayMusic("src", "AUDIO_DARKNESS", false)
            end
        end

        -- After third line
        if self.textProgress == 3 then
            -- The world was covered in darkness. Oopsies
            if self.choice == false and NewAudio.isStopped("src") then
                self.EndAction()
            -- Fade to white
            elseif self.choice == true then
                self.animTimer = self.animTimer + 1

                self.cover2.alpha = (self.animTimer - 500) / 240

                if self.animTimer == 780 then
                    self.EndAction()
                end
            end
        end
	end
end

-- Call this function to begin the game over!
function self.StartGameOver()
    if not self.active then
        NewAudio.StopAll()
        Audio.PlaySound("hurtsound")

        self.active = true
        self.animTimer = 1

        self.cover = CreateSprite("UI/sq_white", self.layer)
        self.cover.MoveTo(320, 240)
        self.cover.Scale(640/4, 480/4)
        self.cover.color = { 0, 0, 0 }

        self.fakePlayer = CreateSprite(Player.sprite.spritename, self.layer)
        self.fakePlayer.MoveTo(Player.absx, Player.absy)
        self.fakePlayer.color = Player.sprite.color
        self.fakePlayer.rotation = Player.sprite.rotation

        -- CYK does not support State("PAUSE"), so we'll do something else for it
        if not pcall(State, "PAUSE") then
            State("NONE")
        end

        self.oldUpdate = Update
        function Update()
            self.Update()
        end
    end
end

-- This function creates the game over text
function self.StartText()
    self.textObject = CreateText({self.text[1], self.text[2]}, {163, 294}, 450, self.layer)
    self.textObject.HideBubble()
    self.textObject.progressmode = "none"
end

-- This function gets called automatically whenever the game over sequence has ended.
-- Put your code here! Especially recommended for setting globals!
function self.EndAction()
    if self.choice == true then
        self.active = false

        self.cover.Remove()
        self.cover = nil

        self.textObject.DestroyText()
        self.textObject = nil

        self.cover2.Remove()
        self.cover2 = nil
        State("DONE")
    else
        Misc.DestroyWindow()
    end
end

return self