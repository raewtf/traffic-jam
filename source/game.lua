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
	gfx.sprite.setAlwaysRedraw(false) -- Should this scene redraw the sprites constantly?

	pd.datastore.write(save)

	function pd.gameWillPause() -- When the game's paused...
		local menu = pd.getSystemMenu()
		menu:removeAllMenuItems()
		if not scenemanager.transitioning then
			if vars.tutorial then
				menu:addMenuItem(text('end_tutorial'), function()
					vars.in_progress = false
					pulp.audio.stopSong()
					scenemanager:transitionscene(title)
					if save.tilt then pd.stopAccelerometer() end
					save.seen_tutorial = true
				end)
			else
				menu:addMenuItem(text('end_game'), function()
					vars.lives = 0
					vars.in_progress = false
					pulp.audio.stopSong()
					pulp.audio.playSound('crash')
					if save.tilt then pd.stopAccelerometer() end
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
		sign_flip = gfx.imagetable.new('images/sign_flip'),
		sign_flipper = gfx.imagetable.new('images/sign_flipper'),
		car = gfx.imagetable.new('images/car'),
		car_flip = gfx.imagetable.new('images/car_flip'),
		warn = gfx.image.new('images/warn'),
		clouds = gfx.imagetable.new('images/clouds'),
	}

	vars = { -- All variables go here. Args passed in from earlier, scene variables, etc.
		tutorial = args[1],
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
		tutorial_step = 1,
		tutorial_cue_open = false,
		tutorial_can_proceed = false,
		tutorial_cars_dropped = 0,
		tutorial_cars_passed = 0,
		tutorial_crank = 0,
		y_anim = pd.timer.new(200, 185, 180),
		sign_flip_anim = pd.timer.new(1, 0, 0),
		clouds_anim = pd.timer.new(120000, 0, -800),
		clouds_last = 0,
		clouds = 8,
		buttons_anim = pd.timer.new(1, -45, -45),
		bpm_raising = false,
		rand = 1,
	}
	vars.gameHandlers = {
		AButtonDown = function()
			if save.buttons then
				vars.buttons_anim:resetnew(300, vars.buttons_anim.value, 45, pd.easingFunctions.outBack)
			end
			if vars.tutorial and vars.tutorial_can_proceed then
				if vars.tutorial_step == 5 or vars.tutorial_step == 7 then
					vars.tutorial_cue_open = false
					vars.tutorial_can_proceed = false
					vars.tutorial_step += 1
					pulp.audio.playSound('select')
					pd.timer.performAfterDelay(500, function()
						vars.tutorial_cue_open = true
						pd.timer.performAfterDelay(1000, function()
							game:startround()
						end)
					end)
				elseif vars.tutorial_step == 11 then
					if save.tilt then pd.stopAccelerometer() end
					scenemanager:transitionscene(title)
					save.seen_tutorial = true
					updatecheevos()
				else
					vars.tutorial_cue_open = false
					vars.tutorial_can_proceed = false
					if vars.tutorial_step == 2 and (save.buttons or save.tilt) then
						vars.tutorial_step = 4
					else
						vars.tutorial_step += 1
					end
					pulp.audio.playSound('select')
					pd.timer.performAfterDelay(500, function()
						vars.tutorial_cue_open = true
						if vars.tutorial_step == 3 then
							vars.crank_touched = false
						else
							pd.timer.performAfterDelay(1000, function()
								vars.tutorial_can_proceed = true
							end)
						end
					end)
				end
			end
		end,

		BButtonDown = function()
			if save.buttons then
				vars.buttons_anim:resetnew(300, vars.buttons_anim.value, -45, pd.easingFunctions.outBack)
			end
		end,

		leftButtonDown = function()
			if save.buttons then
				vars.buttons_anim:resetnew(300, vars.buttons_anim.value, -45, pd.easingFunctions.outBack)
			end
		end,

		rightButtonDown = function()
			if save.buttons then
				vars.buttons_anim:resetnew(300, vars.buttons_anim.value, 45, pd.easingFunctions.outBack)
			end
		end
	}
	pd.inputHandlers.push(vars.gameHandlers)
	if vars.tutorial then
		vars.crank_touched = true
		vars.bpm = 120
		vars.lives = 1
	else
		vars.crank_touched = false
		if vars.hardcore then
			vars.lives = 1
			vars.bpm = tonumber(save.bpm + 30)
		else
			vars.lives = 3
			vars.bpm = tonumber(save.bpm)
		end
		vars.start_bpm = math.min(vars.bpm, 120)
	end

	vars.warn_left.discardOnCompletion = false
	vars.warn_right.discardOnCompletion = false
	vars.sign_flip_anim.discardOnCompletion = false
	vars.clouds_anim.repeats = true
	vars.beat = (60000 / vars.bpm)
	vars.timing.discardOnCompletion = false
	vars.y_anim.repeats = true
	vars.buttons_anim.discardOnCompletion = false
	vars.clouds_anim.timerEndedCallback = function()
		local rand = random(1, 17)
		if rand <= 8 then
			vars.clouds = rand
		else
			vars.clouds = 8
		end
	end

	if save.tilt then pd.startAccelerometer() end

	gfx.sprite.setBackgroundDrawingCallback(function(x, y, width, height)
		if vars.show_info then
			assets.bg_plus:draw(0, 0)
		else
			assets.bg:draw(0, 0)
		end
		assets.clouds[vars.clouds]:draw(vars.clouds_anim.value // 2 * 2, 0)
		if not vars.tutorial then
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
			if vars.tutorial_cue_open then
				if vars.tutorial_can_proceed then
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
				assets.c:drawTextAligned(text('tutorial' .. vars.tutorial_step), 200, 10, kTextAlignment.center)
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
		self.rand = math.random(1, 10)
		if self.direction then
			if self.rand >= 1 and self.rand <= 7 then
				self:setImage(assets.car_flip[(type * 3) - 2])
			elseif self.rand >= 8 and self.rand <= 9 then
				self:setImage(assets.car_flip[(type * 3) - 1])
			elseif self.rand == 10 then
				self:setImage(assets.car_flip[(type * 3)])
			end
			self.timer_start = 485
			self.timer_end = -85
			self.warn = "right"
		else
			if self.rand >= 1 and self.rand <= 7 then
				self:setImage(assets.car[(type * 3) - 2])
			elseif self.rand >= 8 and self.rand <= 9 then
				self:setImage(assets.car[(type * 3) - 1])
			elseif self.rand == 10 then
				self:setImage(assets.car[(type * 3)])
			end
			self.timer_start = -85
			self.timer_end = 485
			self.warn = "left"
		end
		self:add()
		if vars.tutorial then vars.tutorial_cars_dropped += 1 end
		if self.type == 1 then
			self.windup = vars.beat * 4
			self.timer_duration = vars.beat * 4
			if self.direction then pulp.audio.playSound('metro3') else pulp.audio.playSound('metro1') end
			vars['warn_' .. self.warn]:resetnew(vars.beat / 4, 100, 0)
			self.prep_timer_1 = pd.timer.performAfterDelay(vars.beat * 1.005, function()
				if vars.lives <= 0 then return end
				if self.direction then pulp.audio.playSound('metro4') else pulp.audio.playSound('metro2') end
				vars['warn_' .. self.warn]:resetnew(vars.beat / 4, 100, 0)
			end)
			self.prep_timer_2 = pd.timer.performAfterDelay(vars.beat * 2.0225, function()
				if vars.lives <= 0 then return end
				if self.direction then pulp.audio.playSound('metro4') else pulp.audio.playSound('metro2') end
				vars['warn_' .. self.warn]:resetnew(vars.beat / 4, 100, 0)
			end)
			self.prep_timer_3 = pd.timer.performAfterDelay(vars.beat * 3.075, function()
				if vars.lives <= 0 then return end
				if self.direction then pulp.audio.playSound('metro4') else pulp.audio.playSound('metro2') end
				vars['warn_' .. self.warn]:resetnew(vars.beat / 4, 100, 0)
			end)
			self.prep_timer_4 = pd.timer.performAfterDelay(vars.beat * 4.03, function()
				if vars.lives <= 0 then return end
				pulp.audio.playSound('car1drive')
			end)
		elseif type == 2 then
			self.windup = vars.beat * 2
			self.timer_duration = vars.beat * 2
			if self.direction then pulp.audio.playSound('metro3') else pulp.audio.playSound('metro1') end
			vars['warn_' .. self.warn]:resetnew(vars.beat / 4, 100, 0)
			self.prep_timer_1 = pd.timer.performAfterDelay(vars.beat / 2, function()
				if vars.lives <= 0 then return end
				if self.direction then pulp.audio.playSound('metro4') else pulp.audio.playSound('metro2') end
				vars['warn_' .. self.warn]:resetnew(vars.beat / 4, 100, 0)
			end)
			self.prep_timer_2 = pd.timer.performAfterDelay(vars.beat, function()
				if vars.lives <= 0 then return end
				if self.direction then pulp.audio.playSound('metro4') else pulp.audio.playSound('metro2') end
				vars['warn_' .. self.warn]:resetnew(vars.beat / 4, 100, 0)
			end)
			self.prep_timer_3 = pd.timer.performAfterDelay(vars.beat * 2, function()
				if vars.lives <= 0 then return end
				pulp.audio.playSound('car2drive')
			end)
		elseif type == 3 then
			self.windup = vars.beat * 3
			self.timer_duration = vars.beat
			if self.direction then pulp.audio.playSound('metro3') else pulp.audio.playSound('metro1') end
			vars['warn_' .. self.warn]:resetnew(vars.beat / 4, 100, 0)
			self.prep_timer_1 = pd.timer.performAfterDelay(vars.beat, function()
				if vars.lives <= 0 then return end
				if self.direction then pulp.audio.playSound('metro3') else pulp.audio.playSound('metro1') end
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
			if self.direction then pulp.audio.playSound('metro3') else pulp.audio.playSound('metro1') end
			vars['warn_' .. self.warn]:resetnew(vars.beat / 4, 100, 0)
			self.prep_timer_1 = pd.timer.performAfterDelay(vars.beat / 1.4, function()
				if vars.lives <= 0 then return end
				if self.direction then pulp.audio.playSound('metro4') else pulp.audio.playSound('metro2') end
				vars['warn_' .. self.warn]:resetnew(vars.beat / 4, 100, 0)
			end)
			self.prep_timer_2 = pd.timer.performAfterDelay(vars.beat * 1.5, function()
				if vars.lives <= 0 then return end
				if self.direction then pulp.audio.playSound('metro4') else pulp.audio.playSound('metro2') end
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
					if direction and not vars.right then
						vars.score += 1
						save.cars_passed += 1
						if save.react_sfx then
							pulp.audio.playSound('yea')
						end
						if vars.tutorial then vars.tutorial_cars_passed += 1 end
						if vars.score % 100 == 0 and not vars.hardcore then
							vars.lives += 1
							if vars.lives > 3 then vars.lives = 3 end
							gfx.sprite.redrawBackground()
						end
						gfx.sprite.redrawBackground()
					elseif not direction and vars.right then
						vars.score += 1
						save.cars_passed += 1
						if save.react_sfx then
							pulp.audio.playSound('yea')
						end
						if vars.tutorial then vars.tutorial_cars_passed += 1 end
						if vars.score % 100 == 0 and not vars.hardcore then
							vars.lives += 1
							if vars.lives > 3 then vars.lives = 3 end
							gfx.sprite.redrawBackground()
						end
						gfx.sprite.redrawBackground()
					else
						if vars.tutorial then
							shakies()
							shakies_y()
							if save.react_sfx then pulp.audio.playSound('nah') end
						else
							vars.lives -= 1
							gfx.sprite.redrawBackground()
							shakies()
							shakies_y()
							if vars.lives == 0 then
								vars.warn = self.warn
								pulp.audio.playSound('rev_long')
								vars.in_progress = false
								pulp.audio.stopSong()
								pd.timer.performAfterDelay(1000, function()
									pulp.audio.playSound('crash')
									if save.tilt then pd.stopAccelerometer() end
									shakies()
									shakies_y()
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
		self:setSize(400, 185)
		self:setZIndex(3)
		self:moveTo(0, 55)
		self:setCenter(0, 0)
		self:add()
	end
	function classes.playfield:update()
		if math.floor(vars.timing.value) >= 140 or vars.warn_left.value > 0 or vars.warn_right.value > 0 or ((not save.buttons and not save.tilt) and pd.getCrankChange() ~= 0) or vars.buttons_anim.timeLeft > 0 or save.tilt then
			self:markDirty()
		end
	end
	function classes.playfield:draw()
		if save.tilt then
			if pd.accelerometerIsRunning() then
				local x, y, z = pd.readAccelerometer()
				vars.crank = (x *= 90) % 360
				if vars.crank == 360 then vars.crank = 0 end
			end
		elseif save.buttons then
			vars.crank = vars.buttons_anim.value % 360
		else
			vars.crank = pd.getCrankPosition()
		end
		local crank = vars.crank
		if crank >= 90 and crank <= 270 then
			crank = -crank
			crank += 180
			crank %= 360
		end
		if vars.last_crank > 180 and vars.crank < 180 or vars.last_crank < 180 and vars.crank > 180 then
			vars.sign_flip_anim:resetnew(100, 2.99, 0)
		end
		if floor(vars.sign_flip_anim.value) == 2 then
			assets.sign_flip[floor(crank/2) + 1]:draw(floor((89 + (sin(rad(crank)) * 70)) / 2) * 2, floor((-10 - (cos(rad(crank)) * 70) + vars.timing.value) / 2) * 2 - 55)
		elseif floor(vars.sign_flip_anim.value) == 1 then
			assets.sign_flipper[floor(crank/2) + 1]:draw(floor((89 + (sin(rad(crank)) * 70)) / 2) * 2, floor((-10 - (cos(rad(crank)) * 70) + vars.timing.value) / 2) * 2 - 55)
		else
			if crank > 180 then
				assets.sign_left[floor(crank/2) + 1]:draw(floor((89 + (sin(rad(crank)) * 70)) / 2) * 2, floor((-10 - (cos(rad(crank)) * 70) + vars.timing.value) / 2) * 2 - 55)
			else
				assets.sign_right[floor(crank/2) + 1]:draw(floor((89 + (sin(rad(crank)) * 70)) / 2) * 2, floor((-10 - (cos(rad(crank)) * 70) + vars.timing.value) / 2) * 2 - 55)
			end
		end
		vars.last_crank = vars.crank
		assets.worker:draw(158, vars.timing.value - (cos(rad(crank)) * 3) - 45)
		if vars.warn_left.value > 25 then
			assets.warn:draw(10, 120 - 55)
		end
		if vars.warn_right.value > 25 then
			assets.warn:draw(325, 120 - 55, gfx.kImageFlippedX)
		end
	end

	sprites.playfield = classes.playfield()
	sprites.car_1 = classes.car()
	sprites.car_2 = classes.car()
	sprites.car_3 = classes.car()
	sprites.car_4 = classes.car()
	self:add()

	pd.timer.performAfterDelay(2000, function()
		if vars.tutorial then
			vars.tutorial_cue_open = true
			pd.timer.performAfterDelay(1000, function()
				vars.tutorial_can_proceed = true
			end)
		else
			self:startround()
		end
	end)
end

function game:update()
	if vars.tutorial_step == 3 then
		vars.tutorial_crank += abs(pd.getCrankChange())
		if vars.tutorial_crank > 720 then
			vars.tutorial_cue_open = false
			vars.tutorial_can_proceed = false
			vars.tutorial_step += 1
			pd.timer.performAfterDelay(500, function()
				vars.tutorial_cue_open = true
				pd.timer.performAfterDelay(1000, function()
					vars.tutorial_can_proceed = true
				end)
			end)
		end
	end
	if not save.buttons and not save.tilt then
		save.crankage += abs(pd.getCrankChange())
		save.crankage_net += pd.getCrankChange()
	end
	if vars.crank <= 180 then
		vars.right = true
	else
		vars.right = false
	end
	vars.beat = (60000 / vars.bpm) * (0.960 - ((vars.bpm - 120)) * 0.00032)
	if vars.clouds_last ~= vars.clouds_anim.value // 2 * 2 then
		gfx.sprite.redrawBackground()
		vars.clouds_last = vars.clouds_anim.value // 2 * 2
	end
end

function game:startround()
	if vars.lives <= 0 then return end
	pd.timer.performAfterDelay(vars.beat, function()
		if save.music == 6 then
			vars.rand = math.random(1, 5)
			if vars.tutorial then
				pulp.audio.playSong('theme' .. vars.rand .. '_0', true)
			else
				if vars.level < 4 then
					pulp.audio.playSong('theme' .. vars.rand .. '_' .. vars.level - 1, true)
				else
					pulp.audio.playSong('theme' .. vars.rand .. '_' .. 3, true)
				end
			end
		else
			if vars.tutorial then
				pulp.audio.playSong('theme' .. save.music .. '_0', true)
			else
				if vars.level < 4 then
					pulp.audio.playSong('theme' .. save.music .. '_' .. vars.level - 1, true)
				else
					pulp.audio.playSong('theme' .. save.music .. '_' .. 3, true)
				end
			end
		end
		pulp.audio.setBpm(vars.bpm)
		assets.bg_plus = gfx.image.new('images/bg')
		gfx.pushContext(assets.bg_plus)
			assets.nd:drawTextAligned(text('level') .. commalize(vars.level), 200, 10, kTextAlignment.center)
			if vars.level <= 4 then
				assets.c:drawTextAligned(text('level' .. vars.level .. 'tag'), 200, 35, kTextAlignment.center)
			else
				if vars.bpm_raising then
					assets.c:drawTextAligned(text('levelspeed'), 200, 35, kTextAlignment.center)
				else
					assets.c:drawTextAligned(text('levelgo'), 200, 35, kTextAlignment.center)
				end
			end
		gfx.popContext()
		vars.show_info = true
		gfx.sprite.redrawBackground()
	end)
	vars.in_progress = true
	vars.timing:resetnew(vars.beat, 145, 140, pd.easingFunctions.outBack)
	vars.timing.timerEndedCallback = function()
		if vars.current_beat == 32 then
			if vars.tutorial then
				if vars.tutorial_cars_passed == vars.tutorial_cars_dropped then
					vars.timing.repeats = false
					vars.in_progress = false
					vars.timing:resetnew(vars.beat, 145, 145)
					vars.current_beat = -8
					vars.level += 1
					vars.chunk_in_use = false
					vars.chunk_counter = 0
					pulp.audio.stopSong()
					pulp.audio.playSound('ding')
					vars.tutorial_cue_open = false
					vars.tutorial_step += 1
					pd.timer.performAfterDelay(500, function()
						vars.tutorial_cue_open = true
						if vars.tutorial_step == 7 or vars.tutorial_step == 11 then
							pd.timer.performAfterDelay(1000, function()
								vars.tutorial_can_proceed = true
							end)
						elseif vars.tutorial_step == 9 or vars.tutorial_step == 10 then
							pd.timer.performAfterDelay(1000, function()
								self:startround()
							end)
						end
					end)
					return
				else
					vars.tutorial_cars_passed = 0
					vars.tutorial_cars_dropped = 0
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
				vars.start_bpm += 10
				if vars.start_bpm > vars.bpm then
					vars.bpm = vars.start_bpm
					vars.bpm_raising = true
				else
					vars.bpm_raising = false
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
			if save.music == 6 then
				if vars.tutorial then
					pulp.audio.playSong('theme' .. vars.rand .. '_1', true)
				else
					if vars.level < 4 then
						pulp.audio.playSong('theme' .. vars.rand .. '_' .. vars.level, true)
					else
						pulp.audio.playSong('theme' .. vars.rand .. '_' .. 4, true)
					end
				end
			else
				if vars.tutorial then
					pulp.audio.playSong('theme' .. save.music .. '_1', true)
				else
					if vars.level < 4 then
						pulp.audio.playSong('theme' .. save.music .. '_' .. vars.level, true)
					else
						pulp.audio.playSong('theme' .. save.music .. '_' .. 4, true)
					end
				end
			end
			pulp.audio.setBpm(vars.bpm)
			vars.show_info = false
			gfx.sprite.redrawBackground()
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