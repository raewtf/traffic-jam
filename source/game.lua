import 'gameover'

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
		c = gfx.font.new('fonts/c'),
		bg = gfx.image.new('images/bg'),
		worker = gfx.image.new('images/worker'),
		sign_stop = gfx.image.new('images/sign_stop'),
		sign_slow = gfx.image.new('images/sign_slow'),
		car = gfx.imagetable.new('images/car'),
		car_flip = gfx.imagetable.new('images/car_flip'),
		warn = gfx.image.new('images/warn'),
	}

	vars = { -- All variables go here. Args passed in from earlier, scene variables, etc.
		practice = args[1],
		hardcore = args[2],
		score = 0,
		bpm = 120,
		level = 1,
		current_beat = -8,
		in_progress = false,
		timing = pd.timer.new(5000, 145, 145),
		chunk_in_use = false,
		warn_left = pd.timer.new(0, 0, 0),
		warn_right = pd.timer.new(0, 0, 0),
		right = false,
		show_info = false,
		crank_touched = false,
	}
	vars.gameHandlers = {

	}
	pd.inputHandlers.push(vars.gameHandlers)

	if vars.hardcore then
		vars.lives = 1
		vars.bpm = 150
	else
		vars.lives = 3
		vars.bpm = 120
	end
	vars.warn_left.discardOnCompletion = false
	vars.warn_right.discardOnCompletion = false
	vars.beat = (60000 / vars.bpm)

	gfx.sprite.setBackgroundDrawingCallback(function(x, y, width, height)
		assets.bg:draw(0, 0)
		assets.nd:drawText(commalize(vars.score), 10, 10)
		if vars.show_info then
			assets.nd:drawTextAligned(text('level') .. commalize(vars.level), 200, 10, kTextAlignment.center)
			if vars.level <= 5 then
				assets.c:drawTextAligned(text('level' .. vars.level .. 'tag'), 200, 35, kTextAlignment.center)
			else
				assets.c:drawTextAligned(text('levelspeed'), 200, 35, kTextAlignment.center)
			end
		end
	end)

	class('car', _, classes).extends(gfx.sprite)
	function classes.car:init(type, direction) -- type is num (1-4), direction is bool
		classes.car.super.init(self)
		self:setZIndex(1)
		self:setCenter(0.5, 1)
		self.exists = true
		if direction then
			self:setImage(assets.car_flip[type])
			self.timer_start = 485
			self.timer_end = -85
			self.warn = "right"
		else
			self:setImage(assets.car[type])
			self.timer_start = -85
			self.timer_end = 485
			self.warn = "left"
		end
		if type == 1 then
			self.windup = vars.beat * 4
			self.timer_duration = vars.beat * 4
			pulp.audio.playSound('metro1')
			vars['warn_' .. self.warn]:resetnew(vars.beat / 4, 100, 0)
			pd.timer.performAfterDelay(vars.beat, function()
				pulp.audio.playSound('metro2')
				vars['warn_' .. self.warn]:resetnew(vars.beat / 4, 100, 0)
			end)
			pd.timer.performAfterDelay(vars.beat * 2, function()
				pulp.audio.playSound('metro2')
				vars['warn_' .. self.warn]:resetnew(vars.beat / 4, 100, 0)
			end)
			pd.timer.performAfterDelay(vars.beat * 3, function()
				pulp.audio.playSound('metro2')
				vars['warn_' .. self.warn]:resetnew(vars.beat / 4, 100, 0)
			end)
			pd.timer.performAfterDelay(vars.beat * 4, function()
				pulp.audio.playSound('car1drive')
			end)
		elseif type == 2 then
			self.windup = vars.beat * 2
			self.timer_duration = vars.beat * 2
			pulp.audio.playSound('metro1')
			vars['warn_' .. self.warn]:resetnew(vars.beat / 4, 100, 0)
			pd.timer.performAfterDelay(vars.beat / 2, function()
				pulp.audio.playSound('metro2')
				vars['warn_' .. self.warn]:resetnew(vars.beat / 4, 100, 0)
			end)
			pd.timer.performAfterDelay(vars.beat, function()
				pulp.audio.playSound('metro2')
				vars['warn_' .. self.warn]:resetnew(vars.beat / 4, 100, 0)
			end)
			pd.timer.performAfterDelay(vars.beat * 2, function()
				pulp.audio.playSound('car2drive')
			end)
		elseif type == 3 then
			self.windup = vars.beat * 3
			self.timer_duration = vars.beat
			pulp.audio.playSound('metro1')
			vars['warn_' .. self.warn]:resetnew(vars.beat / 4, 100, 0)
			pd.timer.performAfterDelay(vars.beat, function()
				pulp.audio.playSound('metro1')
				vars['warn_' .. self.warn]:resetnew(vars.beat / 4, 100, 0)
			end)
			pd.timer.performAfterDelay(vars.beat * 2, function()
				pulp.audio.playSound('rev')
			end)
			pd.timer.performAfterDelay(vars.beat * 3, function()
				pulp.audio.playSound('car2drive')
			end)
		elseif type == 4 then
			self.windup = vars.beat * 2
			self.timer_duration = vars.beat * 6
			pulp.audio.playSound('metro1')
			vars['warn_' .. self.warn]:resetnew(vars.beat / 4, 100, 0)
			pd.timer.performAfterDelay(vars.beat / 1.4, function()
				pulp.audio.playSound('metro2')
				vars['warn_' .. self.warn]:resetnew(vars.beat / 4, 100, 0)
			end)
			pd.timer.performAfterDelay(vars.beat * 1.5, function()
				pulp.audio.playSound('metro2')
				vars['warn_' .. self.warn]:resetnew(vars.beat / 4, 100, 0)
				pulp.audio.playSound('car4drive')
			end)
		end
		self:moveTo(self.timer_start, 185)
		pd.timer.performAfterDelay(self.windup, function()
			self.points_timer = pd.timer.new(self.timer_duration / 2, self.timer_start, self.timer_end)
			self.points_timer.timerEndedCallback = function()
				local crank = pd.getCrankPosition()
				if direction and crank >= 180 then
					vars.score += 1
					save.cars_passed += 1
				elseif not direction and crank < 180 then
					vars.score += 1
					save.cars_passed += 1
				else
					vars.lives -= 1
					shakies()
					shakies_y()
					if vars.lives == 0 then
						pulp.audio.playSound('rev_long')
						vars.in_progress = false
						pulp.audio.stopSong()
						pd.timer.performAfterDelay(500, function()
							pulp.audio.playSound('crash')
							scenemanager:switchscene(gameover, vars.score, vars.level, vars.bpm, vars.hardcore)
						end)
					else
						pulp.audio.playSound('rev')
					end
				end
			end
			self.x_anim = pd.timer.new(self.timer_duration, self.timer_start, self.timer_end)
			self.x_anim.timerEndedCallback = function()
				self.exists = false
				self:remove()
			end
		end)
		self.y_anim = pd.timer.new(200, 185, 180)
		self.y_anim.repeats = true
		self:add()
	end
	function classes.car:update()
		if self.x_anim ~= nil then
			self:moveTo(self.x_anim.value, self.y_anim.value)
		end
	end

	class('playfield', _, classes).extends(gfx.sprite)
	function classes.playfield:init()
		classes.playfield.super.init(self)
		self:setSize(400, 240)
		self:setZIndex(3)
		self:moveTo(0, 0)
		self:setCenter(0, 0)
		self:add()
	end
	function classes.playfield:draw()
		local crank = pd.getCrankPosition()
		if crank < 180 then
			crank += (vars.timing.value - 140)
		else
			crank -= (vars.timing.value - 140)
		end
		if crank >= 90 and crank <= 270 then
			crank = -crank
			crank -= 180
		end
		save.crankage += math.abs(pd.getCrankChange())
		save.crankage_net += pd.getCrankChange()
		assets.sign_slow:drawRotated(200 + (math.sin(math.rad(crank)) * 70), 100 - (math.cos(math.rad(crank)) * 70) + vars.timing.value, crank)
		assets.worker:draw(158, vars.timing.value - (math.cos(math.rad(crank)) * 3) + 10)
		if vars.warn_left.value ~= 0 then
			assets.warn:draw(10, 120)
		end
		if vars.warn_right.value ~= 0 then
			assets.warn:draw(325, 120, gfx.kImageFlippedX)
		end
	end
	function classes.playfield:update()
		self:markDirty()
	end

	sprites.playfield = classes.playfield()
	self:add()

	pd.timer.performAfterDelay(2000, function()
		self:startround()
	end)
end

function game:update()
	if pd.getCrankPosition() <= 180 then
		vars.right = true
	else
		vars.right = false
	end
	vars.beat = (60000 / vars.bpm) * (0.960 - ((vars.bpm - 120)) * 0.00032)
end

function game:startround()
	pd.timer.performAfterDelay(vars.beat, function()
		if vars.level < 4 then
			pulp.audio.playSong('theme_' .. vars.level - 1, true)
		else
			pulp.audio.playSong('theme_' .. 3, true)
		end
		pulp.audio.setBpm(vars.bpm)
		vars.show_info = true
	end)
	vars.in_progress = true
	vars.timing:resetnew(vars.beat, 145, 140, pd.easingFunctions.outBack)
	vars.timing.timerEndedCallback = function()
		if vars.current_beat == 32 then
			vars.timing.repeats = false
			vars.in_progress = false
			vars.timing:resetnew(vars.beat, 145, 145)
			vars.current_beat = -8
			vars.level += 1
			pulp.audio.stopSong()
			if vars.level > 5 then
				vars.bpm += 5
			end
			pulp.audio.playSound('ding')
			pd.timer.performAfterDelay(1500, function()
				self:startround()
			end)
			return
		end
		pulp.audio.playSound('tick')
		vars.timing.duration = vars.beat
		vars.current_beat += 1
		if vars.current_beat == 1 then
			if vars.level < 4 then
				pulp.audio.playSong('theme_' .. vars.level)
			else
				pulp.audio.playSong('theme_' .. 4)
			end
			pulp.audio.setBpm(vars.bpm)
			vars.show_info = false
		end
				if vars.current_beat % 4 == 1 then
					vars.car = classes.car(math.random(1, 4), game:random_dir())
				end
		if vars.level % 5 == 0 then
			if vars.level % 10 == 0 then
			else
				if vars.current_beat % 8 == 1 then
					vars.car = classes.car(math.random(1, 4), game:random_dir())
				end
			end
		end
	end
	vars.timing.repeats = true
end

function game:random_dir()
	local random = math.random(1, 2)
	if random == 1 then
		return true
	else
		return false
	end
end

function game:gimmechunk(car, dir)
	return game['chunk' .. car .. '_' .. dir]()
end

function game:chunk1_1()
	vars.chunk_in_use = true
	vars.car = classes.car(1, game:random_dir())
	pd.timer.performAfterDelay((vars.beat * 8) / 1.05, function()
		vars.chunk_in_use = false
	end)
end

-- function game:chunk1_2()
-- 	vars.chunk_in_use = true
-- 	vars.car1 = classes.car(, )
-- 	pd.timer.performAfterDelay(, function()
-- 		vars.chunk_in_use = false
-- 	end)
-- end
--
-- function game:chunk1_3()
-- 	vars.chunk_in_use = true
-- 	vars.car1 = classes.car(, )
-- 	pd.timer.performAfterDelay(, function()
-- 		vars.chunk_in_use = false
-- 	end)
-- end
--
-- function game:chunk1_4()
-- 	vars.chunk_in_use = true
-- 	vars.car1 = classes.car(, )
-- 	pd.timer.performAfterDelay(, function()
-- 		vars.chunk_in_use = false
-- 	end)
-- end
--
-- function game:chunk2_1()
-- 	vars.chunk_in_use = true
-- 	vars.car1 = classes.car(, )
-- 	pd.timer.performAfterDelay(, function()
-- 		vars.chunk_in_use = false
-- 	end)
-- end
--
-- function game:chunk2_2()
-- 	vars.chunk_in_use = true
-- 	vars.car1 = classes.car(, )
-- 	pd.timer.performAfterDelay(, function()
-- 		vars.chunk_in_use = false
-- 	end)
-- end
--
-- function game:chunk2_3()
-- 	vars.chunk_in_use = true
-- 	vars.car1 = classes.car(, )
-- 	pd.timer.performAfterDelay(, function()
-- 		vars.chunk_in_use = false
-- 	end)
-- end
--
-- function game:chunk2_4()
-- 	vars.chunk_in_use = true
-- 	vars.car1 = classes.car(, )
-- 	pd.timer.performAfterDelay(, function()
-- 		vars.chunk_in_use = false
-- 	end)
-- end
--
-- function game:chunk3_1()
-- 	vars.chunk_in_use = true
-- 	vars.car1 = classes.car(, )
-- 	pd.timer.performAfterDelay(, function()
-- 		vars.chunk_in_use = false
-- 	end)
-- end
--
-- function game:chunk3_2()
-- 	vars.chunk_in_use = true
-- 	vars.car1 = classes.car(, )
-- 	pd.timer.performAfterDelay(, function()
-- 		vars.chunk_in_use = false
-- 	end)
-- end
--
-- function game:chunk3_3()
-- 	vars.chunk_in_use = true
-- 	vars.car1 = classes.car(, )
-- 	pd.timer.performAfterDelay(, function()
-- 		vars.chunk_in_use = false
-- 	end)
-- end
--
-- function game:chunk3_4()
-- 	vars.chunk_in_use = true
-- 	vars.car1 = classes.car(, )
-- 	pd.timer.performAfterDelay(, function()
-- 		vars.chunk_in_use = false
-- 	end)
-- end
--
-- function game:chunk4_1()
-- 	vars.chunk_in_use = true
-- 	vars.car1 = classes.car(, )
-- 	pd.timer.performAfterDelay(, function()
-- 		vars.chunk_in_use = false
-- 	end)
-- end
--
-- function game:chunk4_2()
-- 	vars.chunk_in_use = true
-- 	vars.car1 = classes.car(, )
-- 	pd.timer.performAfterDelay(, function()
-- 		vars.chunk_in_use = false
-- 	end)
-- end
--
-- function game:chunk4_3()
-- 	vars.chunk_in_use = true
-- 	vars.car1 = classes.car(, )
-- 	pd.timer.performAfterDelay(, function()
-- 		vars.chunk_in_use = false
-- 	end)
-- end
--
-- function game:chunk4_4()
-- 	vars.chunk_in_use = true
-- 	vars.car1 = classes.car(, )
-- 	pd.timer.performAfterDelay(, function()
-- 		vars.chunk_in_use = false
-- 	end)
-- end