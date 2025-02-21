import 'game'
import 'credits'
import 'stats'
import 'leaderboards'

-- Setting up consts
local pd <const> = playdate
local gfx <const> = pd.graphics
local smp <const> = pd.sound.sampleplayer
local text <const> = gfx.getLocalizedText

class('title').extends(gfx.sprite) -- Create the scene's class
function title:init(...)
	title.super.init(self)
	local args = {...} -- Arguments passed in through the scene management will arrive here
	gfx.sprite.setAlwaysRedraw(false) -- Should this scene redraw the sprites constantly?

	function pd.gameWillPause() -- When the game's paused...
		local menu = pd.getSystemMenu()
		menu:removeAllMenuItems()
	end

	assets = { -- All assets go here. Images, sounds, fonts, etc.
		c = gfx.font.new('fonts/c'),
		nd = gfx.font.new('fonts/nd'),
		nld = gfx.font.new('fonts/nld'),
		title = gfx.image.new('images/title'),
		title_cars = gfx.imagetable.new('images/title_cars'),
		logo = gfx.image.new('images/logo'),
		bar = gfx.image.new('images/bar'),
	}

	vars = { -- All variables go here. Args passed in from earlier, scene variables, etc.
		play_intro = args[1],
	}
	vars.titleHandlers = {
		upButtonDown = function()
			if vars.selection ~= 0 then
				if vars.keytimer ~= nil then vars.keytimer:remove() end
				vars.keytimer = pd.timer.keyRepeatTimerWithDelay(150, 150, function()
					if vars.selection > 1 then
						vars.selection -= 1
					else
						vars.selection = #vars.selections
					end
					pulp.audio.playSound('move')
					vars.selection_timer = pd.timer.new(200, vars.selection_timer.value, -30 * vars.selection + 60, pd.easingFunctions.outBack)
				end)
			end
		end,

		upButtonUp = function()
			if vars.keytimer ~= nil then vars.keytimer:remove() end
		end,

		downButtonDown = function()
			if vars.selection ~= 0 then
				if vars.keytimer ~= nil then vars.keytimer:remove() end
				vars.keytimer = pd.timer.keyRepeatTimerWithDelay(150, 150, function()
					if vars.selection < #vars.selections then
						vars.selection += 1
					else
						vars.selection = 1
					end
					pulp.audio.playSound('move')
					vars.selection_timer = pd.timer.new(200, vars.selection_timer.value, -30 * vars.selection + 60, pd.easingFunctions.outBack)
				end)
			end
		end,

		downButtonUp = function()
			if vars.keytimer ~= nil then vars.keytimer:remove() end
		end,

		AButtonDown = function()
			if not scenemanager.transitioning then
				if vars.selections[vars.selection] == 'newgame' then
					scenemanager:transitionscene(game, false)
				elseif vars.selections[vars.selection] == 'hardcore' then
					scenemanager:transitionscene(game, false, true)
				elseif vars.selections[vars.selection] == 'practice' then
					scenemanager:transitionscene(game, true)
				elseif vars.selections[vars.selection] == 'leaderboards' then
					scenemanager:transitionscene(leaderboards)
				elseif vars.selections[vars.selection] == 'stats' then
					scenemanager:transitionscene(stats)
				elseif vars.selections[vars.selection] == 'credits' then
					scenemanager:transitionscene(credits)
				end
				pulp.audio.playSound('select')
			end
		end,
	}
	pd.inputHandlers.push(vars.titleHandlers)

	if vars.play_intro then
		vars.intro_anim = pd.timer.new(500, 50, 0, pd.easingFunctions.outBack)
	else
		vars.intro_anim = pd.timer.new(1, 0, 0)
	end

	vars.selections = {'newgame'}

	if save.score >= 50 then
		table.insert(vars.selections, 'hardcore')
	end

	table.insert(vars.selections, 'practice')

	if catalog then
		table.insert(vars.selections, 'leaderboards')
	end

	table.insert(vars.selections, 'stats')
	table.insert(vars.selections, 'credits')

	if save.seen_tutorial then
		vars.selection = 1
		vars.selection_timer = pd.timer.new(1, 30, 30)
	else
		if save.score >= 50 then
			vars.selection = 3
			vars.selection_timer = pd.timer.new(1, -30, -30)
		else
			vars.selection = 2
			vars.selection_timer = pd.timer.new(1, 00, 00)
		end
	end

	vars.selection_timer.destroyOnCompletion = false

	gfx.sprite.setBackgroundDrawingCallback(function(x, y, width, height)
		gfx.setColor(gfx.kColorWhite)
		gfx.setDitherPattern(0.5, gfx.image.kDitherTypeBayer2x2)
		gfx.fillRect(0, 0, 400, 240)
		gfx.setColor(gfx.kColorWhite)
		gfx.fillRect(0, 125 + vars.intro_anim.value, 400, 30)
		gfx.setColor(gfx.kColorBlack)

		if vars.selection == 1 then
			assets.nd:drawText(text(vars.selections[1]), 30, 100 + vars.selection_timer.value + (vars.intro_anim.value * 1.5))
		else
			assets.nld:drawText(text(vars.selections[1]), 30, 100 + vars.selection_timer.value + (vars.intro_anim.value * 1.5))
		end
		if vars.selection == 2 then
			assets.nd:drawText(text(vars.selections[2]), 30, 130 + vars.selection_timer.value + (vars.intro_anim.value * 1.5))
		else
			assets.nld:drawText(text(vars.selections[2]), 30, 130 + vars.selection_timer.value + (vars.intro_anim.value * 1.5))
		end
		if vars.selection == 3 then
			assets.nd:drawText(text(vars.selections[3]), 30, 160 + vars.selection_timer.value + (vars.intro_anim.value * 1.5))
		else
			assets.nld:drawText(text(vars.selections[3]), 30, 160 + vars.selection_timer.value + (vars.intro_anim.value * 1.5))
		end
		if vars.selection == 4 then
			assets.nd:drawText(text(vars.selections[4]), 30, 190 + vars.selection_timer.value + (vars.intro_anim.value * 1.5))
		else
			assets.nld:drawText(text(vars.selections[4]), 30, 190 + vars.selection_timer.value + (vars.intro_anim.value * 1.5))
		end
		if vars.selections[5] ~= nil then
			if vars.selection == 5 then
				assets.nd:drawText(text(vars.selections[5]), 30, 220 + vars.selection_timer.value + (vars.intro_anim.value * 1.5))
			else
				assets.nld:drawText(text(vars.selections[5]), 30, 220 + vars.selection_timer.value + (vars.intro_anim.value * 1.5))
			end
		end
		if vars.selections[6] ~= nil then
			if vars.selection == 6 then
				assets.nd:drawText(text(vars.selections[6]), 30, 250 + vars.selection_timer.value + (vars.intro_anim.value * 1.5))
			else
				assets.nld:drawText(text(vars.selections[6]), 30, 250 + vars.selection_timer.value + (vars.intro_anim.value * 1.5))
			end
		end
		assets.title:draw(0, -274 + (vars.intro_anim.value * 3))
		assets.logo:draw(25, 6 + vars.intro_anim.value)
		assets.bar:draw(0, 0)
		assets.c:drawText(text('headphones'), 30, 80 + (vars.intro_anim.value * 3))
		if vars.selections[vars.selection] == 'newgame' then
			assets.c:drawTextAligned(text('score') .. commalize(save.score), 370, 80 + (vars.intro_anim.value * 3), kTextAlignment.right)
		elseif vars.selections[vars.selection] == 'hardcore' then
			assets.c:drawTextAligned(text('score') .. commalize(save.hardcore_score), 370, 80 + (vars.intro_anim.value * 3), kTextAlignment.right)
		end
		gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
		assets.c:drawText(text('madebyrae'), 10, 222)
		assets.c:drawTextAligned('v' .. pd.metadata.version, 390, 222, kTextAlignment.right)
		gfx.setImageDrawMode(gfx.kDrawModeCopy)
	end)

	class('title_car', _, classes).extends(gfx.sprite)
	function classes.title_car:init()
		self.timernum = math.random(3000, 6000)
		self.timer_y = pd.timer.new(200, 204, 202)
		self.timer_y.repeats = true
		if math.random(1, 2) == 1 then
			self.dir = true
			self:moveTo(-50, 200)
			self:setImage(assets.title_cars[math.random(1, 4)])
			self.timer = pd.timer.new(self.timernum, -50, 450)
		else
			self.dir = false
			self:moveTo(450, 200)
			self:setImage(assets.title_cars[math.random(1, 4)], "flipX")
			self.timer = pd.timer.new(self.timernum, 450, -50)
		end
		self.timer.timerEndedCallback = function()
			self:remove()
			pd.timer.performAfterDelay(math.random(2500, 3500), function()
				sprites.car = classes.title_car()
			end)
		end
		self:add()
	end
	function classes.title_car:update()
		self:moveTo(self.timer.value, self.timer_y.value)
	end

	pd.timer.performAfterDelay(math.random(1500, 3500), function()
		sprites.car = classes.title_car()
	end)

	self:add()
	pulp.audio.playSong('title')
	pd.getCrankTicks(4)
end

function title:update()
	local ticks = pd.getCrankTicks(4)
	if ticks ~= 0 then
		vars.selection += ticks
		if vars.selection < 1 then
			vars.selection = #vars.selections
		elseif vars.selection > #vars.selections then
			vars.selection = 1
		end
		pulp.audio.playSound('move')
		vars.selection_timer = pd.timer.new(200, vars.selection_timer.value, -30 * vars.selection + 60, pd.easingFunctions.outBack)
	end
	gfx.sprite.redrawBackground()
end