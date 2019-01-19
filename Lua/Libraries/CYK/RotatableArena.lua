-- Rotatable Arena made by /u/DimitriB1
-- Modified by RhenaudTheLukark to be used within Create Your Kris
-- Donut steal pls, ask RhenaudTheLukark and DimitriB1 if you wanna use it kthxbye

return function()
	_Player.SetControlOverride(true)
	local self = { }

	-- Creates the Arena
	self.arena = CreateSprite('px', "Arena")
	self.arena.color = Encounter["arenacolor"]
	self.arena["inner"] = CreateSprite('px', "Arena")
	self.arena["inner"].color = { 0, 0, 0 }
	self.arena["inner"].SetParent(self.arena)

	self.isactive = true

	self.playerSpeed = 2

	-- Custom Frame-Based movement along fake coordinates
	function self.FakeMovement(speedX)
		local speed = speedX or 2
		if Input.Cancel > 0 then
			speed = speed / 2
		end
		local extraSpeed = speed / 20

		-- Left and right movement
		if Input.Left > 0 and Input.Right == 0 then
			Player.sprite.x = Player.sprite.x - speed
			if Input.Up > 0 or Input.Down > 0 then
				Player.sprite.x = Player.sprite.x - extraSpeed
			end
		elseif Input.Right > 0 and Input.Left == 0 then
			Player.sprite.x = Player.sprite.x + speed
			if Input.Up > 0 or Input.Down > 0 then
				Player.sprite.x = Player.sprite.x + extraSpeed
			end
		end

		-- Up and Down movement
		if Input.Up > 0 and Input.Down == 0 then
			Player.sprite.y = Player.sprite.y + speed
			if Input.Left > 0 or Input.Right > 0 then
				Player.sprite.y = Player.sprite.y + extraSpeed
			end
		elseif Input.Down > 0 and Input.Up == 0 then
			Player.sprite.y = Player.sprite.y - speed
			if Input.Left > 0 or Input.Right > 0 then
				Player.sprite.y = Player.sprite.y - extraSpeed
			end
		end
	end

	-- Transform coordinates in sets and combined from individual numbers.
	function self.Transform(x, y, rotDeg)
		local trans = {0,0}
		trans[1] = x * math.cos(rotDeg) - y * math.sin(rotDeg)
		trans[2] = y * math.cos(rotDeg) + x * math.sin(rotDeg)
		return trans
	end

	-- Add collision to a rotated arena using a fake coordinate set.
	function self.CollideRotatedPlayer()
		local rotDeg = -math.rad(self.arena.rotation)

		-- Transforming x and y onto the rotated arena
		local transCoords = self.Transform(Player.x, Player.y, rotDeg)
		local transX = transCoords[1]
		local transY = transCoords[2]

		-- Collision.
		local coords = nil
		if transX > Arena.width/2 - 8 then       transX = Arena.width/2 - 8   --Right
		elseif transX < -Arena.width/2 + 8 then  transX = -Arena.width/2 + 8  --Left
		end
		if transY > Arena.height/2 - 8 then      transY = Arena.height/2 - 8  --Top
		elseif transY < -Arena.height/2 + 8 then transY = -Arena.height/2 + 8 --Bottom
		end

		coords = self.Transform(transX, transY, -rotDeg)
		_Player.MoveTo(coords[1], coords[2], true)
	end

	-- Destroys the rotatable arena
	function self.Destroy()
		self.arena["inner"].Remove()
		self.arena.Remove()
		self.isactive = false
	end

	-- Rotate the Arena
	function self.RotateArena(rot, isRelative)
		if isRelative then
			self.arena.rotation = self.arena.rotation + rot
			self.arena["inner"].rotation = self.arena["inner"].rotation + rot
		else
			self.arena.rotation = rot
			self.arena["inner"].rotation = rot
		end
	end

	-- Update the library
	function self.Update()
		if self.isactive then
			self.arena.Scale(Arena.currentwidth + 10, Arena.currentheight + 10)
			self.arena["inner"].Scale(Arena.currentwidth, Arena.currentheight)
			self.arena.MoveTo(Arena.currentx, Arena.currenty + Arena.currentheight / 2)

			if not Player.controlOverride then
				self.FakeMovement(self.playerSpeed)
				self.CollideRotatedPlayer()
			end
		end
	end

	return self
end