import 'gameover'

-- Setting up consts
local pd <const> = playdate
local gfx <const> = pd.graphics
local smp <const> = pd.sound.sampleplayer
local text <const> = gfx.getLocalizedText
local floor <const> = math.floor
local sin <const> = math.sin
local rad <const> = math.rad
local cos <const> = math.cos
local random <const> = math.random
local abs <const> = math.abs

class('game').extends(gfx.sprite) -- Create the scene's class
function game:init(...)
	game.super.init(self)
	local args = {...} -- Arguments passed in through the scene management will arrive here
	gfx.sprite.setAlwaysRedraw(true) -- Should this scene redraw the sprites constantly?

	function pd.gameWillPause() -- When the game's paused...
		local menu = pd.getSystemMenu()
		menu:removeAllMenuItems()
		if not scenemanager.transitioning then
			if vars.practice then
				menu:addMenuItem(text('end_tutorial'), function()
					vars.in_progress = false
					pulp.audio.stopSong()
					scenemanager:transitionscene(title)
					save.seen_tutorial = true
				end)
			else
				menu:addMenuItem(text('end_game'), function()
					vars.lives = 0
					vars.in_progress = false
					pulp.audio.stopSong()
					pulp.audio.playSound('crash')
					scenemanager:transitionscene(gameover, vars.score, vars.level, vars.bpm, vars.hardcore)
				end)
			end
			menu:addCheckmarkMenuItem(text('react_sfx'), save.react_sfx, function(value)
				save.react_sfx = value
			end)
		end
	end

	assets = { -- All assets go here. Images, sounds, fonts, etc.
		nd = gfx.font.new('fonts/nd'),
		c = gfx.font.new('fonts/c'),
		bg = gfx.image.new('images/bg'),
		bg_plus = gfx.image.new('images/bg'),
		worker = gfx.image.new('images/worker'),
	    sign_right = gfx.imagetable.new('images/sign_right'),
		sign_left = gfx.imagetable.new('images/sign_left'),
		sign_flip = gfx.image.new('images/sign_flip'),
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
		chunk_counter = 0,
		chunk_car = 1,
		chunk_chunk = 1,
		warn_left = pd.timer.new(0, 0, 0),
		warn_right = pd.timer.new(0, 0, 0),
		right = false,
		show_info = false,
		crank = 0,
		last_crank = 0,
		practice_step = 1,
		practice_cue_open = false,
		practice_can_proceed = false,
		practice_cars_dropped = 0,
		practice_cars_passed = 0,
		practice_crank = 0,
		y_anim = pd.timer.new(200, 185, 180),
	}
	vars.gameHandlers = {
		AButtonDown = function()
			if vars.practice_can_proceed then
				if vars.practice_step == 5 or vars.practice_step == 7 then
					vars.practice_cue_open = false
					vars.practice_can_proceed = false
					vars.practice_step += 1
					pulp.audio.playSound('select')
					pd.timer.performAfterDelay(500, function()
						vars.practice_cue_open = true
						pd.timer.performAfterDelay(1000, function()
							game:startround()
						end)
					end)
				elseif vars.practice_step == 11 then
					scenemanager:transitionscene(title)
					save.seen_tutorial = true
				else
					vars.practice_cue_open = false
					vars.practice_can_proceed = false
					vars.practice_step += 1
					pulp.audio.playSound('select')
					pd.timer.performAfterDelay(500, function()
						vars.practice_cue_open = true
						if vars.practice_step == 3 then
							vars.crank_touched = false
						else
							pd.timer.performAfterDelay(1000, function()
								vars.practice_can_proceed = true
							end)
						end
					end)
				end
			end
		end,
	}
	if vars.practice then
		pd.inputHandlers.push(vars.gameHandlers)
		vars.crank_touched = true
	else
		vars.crank_touched = false
	end

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
	vars.timing.discardOnCompletion = false
	vars.y_anim.repeats = true

	gfx.sprite.setBackgroundDrawingCallback(function(x, y, width, height)
		if vars.show_info then
			assets.bg_plus:draw(0, 0)
		else
			assets.bg:draw(0, 0)
		end
		if not vars.practice then
			assets.nd:drawText(commalize(vars.score), 10, 10)
			if vars.hardcore then
				if vars.lives >= 1 then
					gfx.fillCircleAtPoint(15, 40, 5)
				else
					gfx.drawCircleAtPoint(15, 40, 5)
				end
			else
				if vars.lives >= 1 then
					gfx.fillCircleAtPoint(15, 40, 5)
				else
					gfx.drawCircleAtPoint(15, 40, 5)
				end
				if vars.lives >= 2 then
					gfx.fillCircleAtPoint(30, 40, 5)
				else
					gfx.drawCircleAtPoint(30, 40, 5)
				end
				if vars.lives == 3 then
					gfx.fillCircleAtPoint(45, 40, 5)
				else
					gfx.drawCircleAtPoint(45, 40, 5)
				end
			end
		else
			if vars.practice_cue_open then
				if vars.practice_can_proceed then
					gfx.fillRect(0, 0, 400, 70)
					gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
						assets.c:drawTextAligned(text('Acontinue'), 200, 54, kTextAlignment.center)
					gfx.setImageDrawMode(gfx.kDrawModeCopy)
				else
					gfx.fillRect(0, 0, 400, 55)
				end
				gfx.setColor(gfx.kColorWhite)
				gfx.fillRect(0, 0, 400, 53)
				gfx.setColor(gfx.kColorBlack)
				assets.c:drawTextAligned(text('tutorial' .. vars.practice_step), 200, 10, kTextAlignment.center)
			end
		end
	end)

	class('car', _, classes).extends(gfx.sprite)
	function classes.car:init() -- type is num (1-4), direction is bool
		classes.car.super.init(self)
		self:setZIndex(1)
		self:setCenter(0.5, 1)
	end
	function classes.car:run(type, direction)
		if vars.lives <= 0 then return end
		self.type = type
		self.direction = direction
		self.exists = true
		if self.direction then
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
		self:add()
		if vars.practice then vars.practice_cars_dropped += 1 end
		if self.type == 1 then
			self.windup = vars.beat * 4
			self.timer_duration = vars.beat * 4
			pulp.audio.playSound('metro1')
			vars['warn_' .. self.warn]:resetnew(vars.beat / 4, 100, 0)
			self.prep_timer_1 = pd.timer.performAfterDelay(vars.beat, function()
				if vars.lives <= 0 then return end
				pulp.audio.playSound('metro2')
				vars['warn_' .. self.warn]:resetnew(vars.beat / 4, 100, 0)
			end)
			self.prep_timer_2 = pd.timer.performAfterDelay(vars.beat * 2, function()
				if vars.lives <= 0 then return end
				pulp.audio.playSound('metro2')
				vars['warn_' .. self.warn]:resetnew(vars.beat / 4, 100, 0)
			end)
			self.prep_timer_3 = pd.timer.performAfterDelay(vars.beat * 3, function()
				if vars.lives <= 0 then return end
				pulp.audio.playSound('metro2')
				vars['warn_' .. self.warn]:resetnew(vars.beat / 4, 100, 0)
			end)
			self.prep_timer_4 = pd.timer.performAfterDelay(vars.beat * 4, function()
				if vars.lives <= 0 then return end
				pulp.audio.playSound('car1drive')
			end)
		elseif type == 2 then
			self.windup = vars.beat * 2
			self.timer_duration = vars.beat * 2
			pulp.audio.playSound('metro1')
			vars['warn_' .. self.warn]:resetnew(vars.beat / 4, 100, 0)
			self.prep_timer_1 = pd.timer.performAfterDelay(vars.beat / 2, function()
				if vars.lives <= 0 then return end
				pulp.audio.playSound('metro2')
				vars['warn_' .. self.warn]:resetnew(vars.beat / 4, 100, 0)
			end)
			self.prep_timer_2 = pd.timer.performAfterDelay(vars.beat, function()
				if vars.lives <= 0 then return end
				pulp.audio.playSound('metro2')
				vars['warn_' .. self.warn]:resetnew(vars.beat / 4, 100, 0)
			end)
			self.prep_timer_3 = pd.timer.performAfterDelay(vars.beat * 2, function()
				if vars.lives <= 0 then return end
				pulp.audio.playSound('car2drive')
			end)
		elseif type == 3 then
			self.windup = vars.beat * 3
			self.timer_duration = vars.beat
			pulp.audio.playSound('metro1')
			vars['warn_' .. self.warn]:resetnew(vars.beat / 4, 100, 0)
			self.prep_timer_1 = pd.timer.performAfterDelay(vars.beat, function()
				if vars.lives <= 0 then return end
				pulp.audio.playSound('metro1')
				vars['warn_' .. self.warn]:resetnew(vars.beat / 4, 100, 0)
			end)
			self.prep_timer_2 = pd.timer.performAfterDelay(vars.beat * 2, function()
				if vars.lives <= 0 then return end
				pulp.audio.playSound('rev')
			end)
			self.prep_timer_3 = pd.timer.performAfterDelay(vars.beat * 3, function()
				if vars.lives <= 0 then return end
				pulp.audio.playSound('car2drive')
			end)
		elseif type == 4 then
			self.windup = vars.beat * 2
			self.timer_duration = vars.beat * 6
			pulp.audio.playSound('metro1')
			vars['warn_' .. self.warn]:resetnew(vars.beat / 4, 100, 0)
			self.prep_timer_1 = pd.timer.performAfterDelay(vars.beat / 1.4, function()
				if vars.lives <= 0 then return end
				pulp.audio.playSound('metro2')
				vars['warn_' .. self.warn]:resetnew(vars.beat / 4, 100, 0)
			end)
			self.prep_timer_2 = pd.timer.performAfterDelay(vars.beat * 1.5, function()
				if vars.lives <= 0 then return end
				pulp.audio.playSound('metro2')
				vars['warn_' .. self.warn]:resetnew(vars.beat / 4, 100, 0)
				pulp.audio.playSound('car4drive')
			end)
		end
		self:moveTo(self.timer_start, 185)
		self.play_timer = pd.timer.performAfterDelay(self.windup, function()
			if vars.lives <= 0 then return end
			self.points_timer = pd.timer.new(self.timer_duration / 2, self.timer_start, self.timer_end)
			self.points_timer.timerEndedCallback = function()
				if vars.lives > 0 then
					local crank = pd.getCrankPosition()
					if direction and crank >= 180 then
						vars.score += 1
						save.cars_passed += 1
						if save.react_sfx then
							pulp.audio.playSound('yea')
							if vars.practice then vars.practice_cars_passed += 1 end
						end
					elseif not direction and crank < 180 then
						vars.score += 1
						save.cars_passed += 1
						if save.react_sfx then
							pulp.audio.playSound('yea')
							if vars.practice then vars.practice_cars_passed += 1 end
						end
					else
						if vars.practice then
							shakies()
							shakies_y()
							if save.react_sfx then pulp.audio.playSound('nah') end
						else
							vars.lives -= 1
							shakies()
							shakies_y()
							if vars.lives == 0 then
								vars.warn = self.warn
								pulp.audio.playSound('rev_long')
								vars.in_progress = false
								pulp.audio.stopSong()
								pd.timer.performAfterDelay(1000, function()
									pulp.audio.playSound('crash')
									if vars.warn == "right" then
										scenemanager:crashscenel(gameover, vars.score, vars.level, vars.bpm, vars.hardcore)
									else
										scenemanager:crashscener(gameover, vars.score, vars.level, vars.bpm, vars.hardcore)
									end
								end)
							elseif save.react_sfx then
								pulp.audio.playSound('nah')
							end
						end
					end
				end
			end
			self.x_anim = pd.timer.new(self.timer_duration, self.timer_start, self.timer_end)
			self.x_anim.timerEndedCallback = function()
				self.exists = false
				self:remove()
			end
		end)
	end
	function classes.car:update()
		if self.x_anim ~= nil then
			self:moveTo(self.x_anim.value, vars.y_anim.value)
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
		vars.crank = pd.getCrankPosition()
		local crank = vars.crank
		if crank >= 90 and crank <= 270 then
			crank = -crank
			crank += 180
			crank %= 360
		end
		if vars.last_crank > 180 and vars.crank < 180 or vars.last_crank < 180 and vars.crank > 180 then
			assets.sign_flip:draw(170, -80 + vars.timing.value)
		else
			if crank > 180 then
				assets.sign_left[floor(crank/2) + 1]:draw(floor((89 + (sin(rad(crank)) * 70)) / 2) * 2, floor((-10 - (cos(rad(crank)) * 70) + vars.timing.value) / 2) * 2)
			else
				assets.sign_right[floor(crank/2) + 1]:draw(floor((89 + (sin(rad(crank)) * 70)) / 2) * 2, floor((-10 - (cos(rad(crank)) * 70) + vars.timing.value) / 2) * 2)
			end
		end
		vars.last_crank = vars.crank
		assets.worker:draw(158, vars.timing.value - (cos(rad(crank)) * 3) + 10)
		if vars.warn_left.value ~= 0 then
			assets.warn:draw(10, 120)
		end
		if vars.warn_right.value ~= 0 then
			assets.warn:draw(325, 120, gfx.kImageFlippedX)
		end
	end

	sprites.playfield = classes.playfield()
	sprites.car_1 = classes.car()
	sprites.car_2 = classes.car()
	sprites.car_3 = classes.car()
	sprites.car_4 = classes.car()
	self:add()

	pd.timer.performAfterDelay(2000, function()
		if vars.practice then
			vars.practice_cue_open = true
			pd.timer.performAfterDelay(1000, function()
				vars.practice_can_proceed = true
			end)
		else
			self:startround()
		end
	end)
end

function game:update()
	if vars.practice_step == 3 then
		vars.practice_crank += abs(pd.getCrankChange())
		if vars.practice_crank > 720 then
			vars.practice_cue_open = false
			vars.practice_can_proceed = false
			vars.practice_step += 1
			pd.timer.performAfterDelay(500, function()
				vars.practice_cue_open = true
				pd.timer.performAfterDelay(1000, function()
					vars.practice_can_proceed = true
				end)
			end)
		end
	end
	save.crankage += abs(pd.getCrankChange())
	save.crankage_net += pd.getCrankChange()
	if vars.crank <= 180 then
		vars.right = true
	else
		vars.right = false
	end
	vars.beat = (60000 / vars.bpm) * (0.960 - ((vars.bpm - 120)) * 0.00032)
end

function game:startround()
	if vars.lives <= 0 then return end
	pd.timer.performAfterDelay(vars.beat, function()
		if vars.practice then
			pulp.audio.playSong('theme_0', true)
		else
			if vars.level < 4 then
				pulp.audio.playSong('theme_' .. vars.level - 1, true)
			else
				pulp.audio.playSong('theme_' .. 3, true)
			end
		end
		pulp.audio.setBpm(vars.bpm)
		assets.bg_plus = gfx.image.new('images/bg')
		gfx.pushContext(assets.bg_plus)
			assets.nd:drawTextAligned(text('level') .. commalize(vars.level), 200, 10, kTextAlignment.center)
			if vars.level <= 5 then
				assets.c:drawTextAligned(text('level' .. vars.level .. 'tag'), 200, 35, kTextAlignment.center)
			else
				assets.c:drawTextAligned(text('levelspeed'), 200, 35, kTextAlignment.center)
			end
		gfx.popContext()
		vars.show_info = true
	end)
	vars.in_progress = true
	vars.timing:resetnew(vars.beat, 145, 140, pd.easingFunctions.outBack)
	vars.timing.timerEndedCallback = function()
		if vars.current_beat == 32 then
			if vars.practice then
				if vars.practice_cars_passed == vars.practice_cars_dropped then
					vars.timing.repeats = false
					vars.in_progress = false
					vars.timing:resetnew(vars.beat, 145, 145)
					vars.current_beat = -8
					vars.level += 1
					vars.chunk_in_use = false
					vars.chunk_counter = 0
					pulp.audio.stopSong()
					pulp.audio.playSound('ding')
					vars.practice_cue_open = false
					vars.practice_step += 1
					pd.timer.performAfterDelay(500, function()
						vars.practice_cue_open = true
						if vars.practice_step == 7 or vars.practice_step == 11 then
							pd.timer.performAfterDelay(1000, function()
								vars.practice_can_proceed = true
							end)
						elseif vars.practice_step == 9 or vars.practice_step == 10 then
							pd.timer.performAfterDelay(1000, function()
								self:startround()
							end)
						end
					end)
					return
				else
					vars.practice_cars_passed = 0
					vars.practice_cars_dropped = 0
					vars.chunk_in_use = false
					vars.chunk_counter = 0
					vars.current_beat = 0
				end
			else
				vars.timing.repeats = false
				vars.in_progress = false
				vars.timing:resetnew(vars.beat, 145, 145)
				vars.current_beat = -8
				vars.level += 1
				vars.chunk_in_use = false
				vars.chunk_counter = 0
				pulp.audio.stopSong()
				if vars.level > 5 or vars.hardcore then
					vars.bpm += 5
				end
				pulp.audio.playSound('ding')
				pd.timer.performAfterDelay(1500, function()
					self:startround()
				end)
				return
			end
		end
		pulp.audio.playSound('tick')
		vars.timing.duration = vars.beat
		vars.current_beat += 1
		if vars.current_beat == 1 then
			if vars.practice then
				pulp.audio.playSong('theme_1')
			else
				if vars.level < 4 then
					pulp.audio.playSong('theme_' .. vars.level)
				else
					pulp.audio.playSong('theme_' .. 4)
				end
			end
			pulp.audio.setBpm(vars.bpm)
			vars.show_info = false
		end
		if vars.current_beat > 0 then
			if vars.level % 5 == 0 then
				if vars.level % 10 == 0 then
					if vars.current_beat % 4 == 1 then
						game:gimmecar(random(1, 4), game:random_dir())
					end
				else
					if vars.current_beat % 8 == 1 then
						game:gimmecar(random(1, 4), game:random_dir())
					end
				end
			else
				if vars.chunk_in_use then
					vars.chunk_counter += 1
				else
					vars.chunk_counter = 0
				end
				if vars.level == 1 then
					if vars.current_beat >= 1 and vars.current_beat <= 15 then
						game:gimmechunk(1, 1)
					elseif vars.current_beat >= 16 and vars.current_beat <= 31 then
						game:gimmechunk(1, 2)
					end
				elseif vars.level == 2 then
					if vars.current_beat >= 1 and vars.current_beat <= 15 then
						game:gimmechunk(2, 1)
					elseif vars.current_beat >= 16 and vars.current_beat <= 31 then
						game:gimmechunk(2, 2)
					end
				elseif vars.level == 3 then
					if vars.current_beat >= 1 and vars.current_beat <= 15 then
						game:gimmechunk(3, 1)
					elseif vars.current_beat >= 16 and vars.current_beat <= 31 then
						game:gimmechunk(3, 2)
					end
				elseif vars.level == 4 then
					if vars.current_beat >= 1 and vars.current_beat <= 15 then
						game:gimmechunk(4, 1)
					elseif vars.current_beat >= 16 and vars.current_beat <= 31 then
						game:gimmechunk(4, 2)
					end
				else
					if not vars.chunk_in_use then
						if vars.level <= 10 then
							vars.chunk_car = random(1, 2)
							vars.chunk_chunk = random(1, 2)
						elseif vars.level <= 15 then
							vars.chunk_car = random(1, 3)
							vars.chunk_chunk = random(1, 3)
						else
							vars.chunk_car = random(1, 4)
							vars.chunk_chunk = random(1, 4)
						end
					end
					game:gimmechunk(vars.chunk_car, vars.chunk_chunk)
				end
			end
		end
	end
	vars.timing.repeats = true
end

function game:random_dir()
	local random = random(1, 2)
	if random == 1 then
		return true
	else
		return false
	end
end

function game:gimmechunk(car, chunk)
	return game['chunk' .. car .. '_' .. chunk]()
end

function game:gimmecar(type, direction)
	if not sprites.car_1.exists then
		sprites.car_1:run(type, direction)
	elseif not sprites.car_2.exists then
		sprites.car_2:run(type, direction)
	elseif not sprites.car_3.exists then
		sprites.car_3:run(type, direction)
	elseif not sprites.car_4.exists then
		sprites.car_4:run(type, direction)
	else
		print('somehow ... we\'re out of cars!!!')
	end
end

function game:chunk1_1()
	vars.chunk_in_use = true
	if vars.chunk_counter == 0 then
		game:gimmecar(1, game:random_dir())
	elseif vars.chunk_counter == 8 then
		game:gimmecar(1, game:random_dir())
	elseif vars.chunk_counter == 15 then
		vars.chunk_in_use = false
	end
end

function game:chunk1_2()
	vars.chunk_in_use = true
	if vars.chunk_counter == 0 then
		game:gimmecar(1, game:random_dir())
	elseif vars.chunk_counter == 4 then
		game:gimmecar(1, game:random_dir())
	elseif vars.chunk_counter == 8 then
		game:gimmecar(1, game:random_dir())
	elseif vars.chunk_counter == 15 then
		vars.chunk_in_use = false
	end
end

function game:chunk1_3()
	vars.chunk_in_use = true
	if vars.chunk_counter == 0 then
		game:gimmecar(1, game:random_dir())
	elseif vars.chunk_counter == 4 then
		game:gimmecar(1, game:random_dir())
	elseif vars.chunk_counter == 8 then
		game:gimmecar(1, game:random_dir())
	elseif vars.chunk_counter == 12 then
		game:gimmecar(1, game:random_dir())
	elseif vars.chunk_counter == 15 then
		vars.chunk_in_use = false
	end
end

function game:chunk1_4()
	vars.chunk_in_use = true
	if vars.chunk_counter == 0 then
		game:gimmecar(1, game:random_dir())
	elseif vars.chunk_counter == 3 then
		game:gimmecar(1, game:random_dir())
	elseif vars.chunk_counter == 6 then
		game:gimmecar(1, game:random_dir())
	elseif vars.chunk_counter == 9 then
		game:gimmecar(1, game:random_dir())
	elseif vars.chunk_counter == 12 then
		game:gimmecar(1, game:random_dir())
	elseif vars.chunk_counter == 15 then
		vars.chunk_in_use = false
	end
end

function game:chunk2_1()
	vars.chunk_in_use = true
	if vars.chunk_counter == 0 then
		game:gimmecar(1, game:random_dir())
	elseif vars.chunk_counter == 8 then
		game:gimmecar(2, game:random_dir())
	elseif vars.chunk_counter == 12 then
		game:gimmecar(2, game:random_dir())
	elseif vars.chunk_counter == 15 then
		vars.chunk_in_use = false
	end
end

function game:chunk2_2()
	vars.chunk_in_use = true
	if vars.chunk_counter == 0 then
		game:gimmecar(2, game:random_dir())
	elseif vars.chunk_counter == 4 then
		game:gimmecar(2, game:random_dir())
	elseif vars.chunk_counter == 8 then
		game:gimmecar(2, game:random_dir())
	elseif vars.chunk_counter == 12 then
		game:gimmecar(2, game:random_dir())
	elseif vars.chunk_counter == 15 then
		vars.chunk_in_use = false
	end
end

function game:chunk2_3()
	vars.chunk_in_use = true
	if vars.chunk_counter == 0 then
		game:gimmecar(2, game:random_dir())
	elseif vars.chunk_counter == 4 then
		game:gimmecar(2, game:random_dir())
	elseif vars.chunk_counter == 8 then
		game:gimmecar(2, game:random_dir())
	elseif vars.chunk_counter == 10 then
		game:gimmecar(2, game:random_dir())
	elseif vars.chunk_counter == 12 then
		game:gimmecar(2, game:random_dir())
	elseif vars.chunk_counter == 15 then
		vars.chunk_in_use = false
	end
end

function game:chunk2_4()
	vars.chunk_in_use = true
	if vars.chunk_counter == 0 then
		game:gimmecar(2, game:random_dir())
	elseif vars.chunk_counter == 2 then
		game:gimmecar(2, game:random_dir())
	elseif vars.chunk_counter == 4 then
		game:gimmecar(1, game:random_dir())
	elseif vars.chunk_counter == 10 then
		game:gimmecar(2, game:random_dir())
	elseif vars.chunk_counter == 12 then
		game:gimmecar(2, game:random_dir())
	elseif vars.chunk_counter == 15 then
		vars.chunk_in_use = false
	end
end

function game:chunk3_1()
	vars.chunk_in_use = true
	if vars.chunk_counter == 0 then
		game:gimmecar(2, game:random_dir())
	elseif vars.chunk_counter == 4 then
		game:gimmecar(2, game:random_dir())
	elseif vars.chunk_counter == 8 then
		game:gimmecar(3, game:random_dir())
	elseif vars.chunk_counter == 15 then
		vars.chunk_in_use = false
	end
end

function game:chunk3_2()
	vars.chunk_in_use = true
	if vars.chunk_counter == 0 then
		game:gimmecar(3, game:random_dir())
	elseif vars.chunk_counter == 4 then
		game:gimmecar(3, game:random_dir())
	elseif vars.chunk_counter == 12 then
		game:gimmecar(3, game:random_dir())
	elseif vars.chunk_counter == 15 then
		vars.chunk_in_use = false
	end
end

function game:chunk3_3()
	vars.chunk_in_use = true
	if vars.chunk_counter == 0 then
		game:gimmecar(1, game:random_dir())
	elseif vars.chunk_counter == 5 then
		game:gimmecar(3, game:random_dir())
	elseif vars.chunk_counter == 8 then
		game:gimmecar(2, game:random_dir())
	elseif vars.chunk_counter == 13 then
		game:gimmecar(3, game:random_dir())
	elseif vars.chunk_counter == 15 then
		vars.chunk_in_use = false
	end
end

function game:chunk3_4()
	vars.chunk_in_use = true
	if vars.chunk_counter == 0 then
		game:gimmecar(3, game:random_dir())
	elseif vars.chunk_counter == 3 then
		game:gimmecar(3, game:random_dir())
	elseif vars.chunk_counter == 6 then
		game:gimmecar(3, game:random_dir())
	elseif vars.chunk_counter == 9 then
		game:gimmecar(3, game:random_dir())
	elseif vars.chunk_counter == 12 then
		game:gimmecar(3, game:random_dir())
	elseif vars.chunk_counter == 15 then
		vars.chunk_in_use = false
	end
end

function game:chunk4_1()
	vars.chunk_in_use = true
	if vars.chunk_counter == 0 then
		game:gimmecar(1, game:random_dir())
	elseif vars.chunk_counter == 6 then
		game:gimmecar(4, game:random_dir())
	elseif vars.chunk_counter == 15 then
		vars.chunk_in_use = false
	end
end

function game:chunk4_2()
	vars.chunk_in_use = true
	if vars.chunk_counter == 0 then
		game:gimmecar(4, game:random_dir())
	elseif vars.chunk_counter == 6 then
		game:gimmecar(4, game:random_dir())
	elseif vars.chunk_counter == 15 then
		vars.chunk_in_use = false
	end
end

function game:chunk4_3()
	vars.chunk_in_use = true
	if vars.chunk_counter == 0 then
		game:gimmecar(3, game:random_dir())
	elseif vars.chunk_counter == 4 then
		game:gimmecar(4, game:random_dir())
	elseif vars.chunk_counter == 10 then
		game:gimmecar(4, game:random_dir())
	elseif vars.chunk_counter == 15 then
		vars.chunk_in_use = false
	end
end

function game:chunk4_4()
	vars.chunk_in_use = true
	if vars.chunk_counter == 0 then
		game:gimmecar(4, game:random_dir())
	elseif vars.chunk_counter == 4 then
		game:gimmecar(4, game:random_dir())
	elseif vars.chunk_counter == 10 then
		game:gimmecar(3, game:random_dir())
	elseif vars.chunk_counter == 12 then
		game:gimmecar(3, game:random_dir())
	elseif vars.chunk_counter == 15 then
		vars.chunk_in_use = false
	end
end