-- Setting up consts
local pd <const> = playdate
local gfx <const> = pd.graphics
local smp <const> = pd.sound.sampleplayer
local text <const> = gfx.getLocalizedText

class('game').extends(gfx.sprite) -- Create the scene's class
function game:init(...)
	game.super.init(self)
	local args = {...} -- Arguments passed in through the scene management will arrive here
	gfx.sprite.setAlwaysRedraw(false) -- Should this scene redraw the sprites constantly?

	assets = { -- All assets go here. Images, sounds, fonts, etc.
		nd = gfx.font.new('fonts/nd'),
		bg = gfx.image.new('images/bg'),
		worker = gfx.image.new('images/worker'),
		sign_stop = gfx.image.new('images/sign_stop'),
		sign_slow = gfx.image.new('images/sign_slow'),
		car = gfx.imagetable.new('images/car'),
		tick = smp.new('audio/sfx/tick'),
		rev = smp.new('audio/sfx/rev'),
		car4drive = smp.new('audio/sfx/car4drive'),
		bgtick = smp.new('audio/sfx/bgtick'),
	}

	vars = { -- All variables go here. Args passed in from earlier, scene variables, etc.
		speed = 1, -- multiplier!
		test = 1,
	}
	vars.gameHandlers = {
		AButtonDown = function()
			local random = math.random(1, 8)
			local num = (random % 4) + 1
			local dir
			if math.ceil(random / 4) == 1 then
				dir = true
			else
				dir = false
			end
			sprites['test_' .. vars.test] = car(num, dir)
			vars.test += 1
		end
	}
	pd.inputHandlers.push(vars.gameHandlers)

	gfx.sprite.setBackgroundDrawingCallback(function(x, y, width, height)
		assets.bg:draw(0, 0)
		assets.nd:drawText('0', 10, 10)
	end)

	class('car').extends(gfx.sprite)
	function car:init(type, direction) -- type is num (1-4), direction is bool
		self:setImage(assets.car[type])
		self:setZIndex(1)
		self:setCenter(0.5, 1)
		if type == 1 then
			self.windup = 2000
			self.timer_duration = 2000
			assets.tick:play()
			pd.timer.performAfterDelay(500 * vars.speed, function()
				assets.tick:play()
			end)
			pd.timer.performAfterDelay(1000 * vars.speed, function()
				assets.tick:play()
			end)
			pd.timer.performAfterDelay(1500 * vars.speed, function()
				assets.tick:play()
			end)
		elseif type == 2 then
			self.windup = 1000
			self.timer_duration = 1000
			assets.tick:play()
			pd.timer.performAfterDelay(250 * vars.speed, function()
				assets.tick:play()
			end)
			pd.timer.performAfterDelay(500 * vars.speed, function()
				assets.tick:play()
			end)
		elseif type == 3 then
			self.windup = 1500
			self.timer_duration = 500
			assets.tick:play()
			pd.timer.performAfterDelay(500 * vars.speed, function()
				assets.tick:play()
			end)
			pd.timer.performAfterDelay(1000 * vars.speed, function()
				assets.rev:play()
			end)
		elseif type == 4 then
			self.windup = 1000
			self.timer_duration = 3000
			assets.tick:play()
			pd.timer.performAfterDelay(350 * vars.speed, function()
				assets.tick:play()
			end)
			pd.timer.performAfterDelay(750 * vars.speed, function()
				assets.tick:play()
				assets.car4drive:play()
			end)
		end
		if direction then
			self:setImageFlip("flipX")
			self.timer_start = 485
			self.timer_end = -85
		else
			self.timer_start = -85
			self.timer_end = 485
		end
		self:moveTo(self.timer_start, 185)
		pd.timer.performAfterDelay(self.windup * vars.speed, function()
			self.x_anim = pd.timer.new(self.timer_duration * vars.speed, self.timer_start, self.timer_end)
			self.x_anim.timerEndedCallback = function()
				self:remove()
			end
		end)
		self.y_anim = pd.timer.new(200, 185, 180)
		self.y_anim.repeats = true
		self:add()
	end
	function car:update()
		if self.x_anim ~= nil then
			self:moveTo(self.x_anim.value, self.y_anim.value)
		end
	end

	class('playfield').extends(gfx.sprite)
	function playfield:init()
		playfield.super.init(self)
		self:setSize(400, 240)
		self:setZIndex(3)
		self:moveTo(0, 0)
		self:setCenter(0, 0)
		self.worker_anim = pd.timer.new(500 * vars.speed, 145, 140, pd.easingFunctions.outSine)
		self.worker_anim.timerEndedCallback = function()
			assets.bgtick:play()
		end
		self.worker_anim.repeats = true
		self:add()
	end
	function playfield:draw()
		assets.worker:draw(158, self.worker_anim.value)
	end
	function playfield:update()
		self:markDirty()
	end

	sprites.playfield = playfield()
	self:add()
end