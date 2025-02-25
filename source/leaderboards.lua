-- Setting up consts
local pd <const> = playdate
local gfx <const> = pd.graphics
local smp <const> = pd.sound.sampleplayer
local text <const> = gfx.getLocalizedText
local random <const> = math.random

class('leaderboards').extends(gfx.sprite) -- Create the scene's class
function leaderboards:init(...)
	leaderboards.super.init(self)
	local args = {...} -- Arguments passed in through the scene management will arrive here
	gfx.sprite.setAlwaysRedraw(false) -- Should this scene redraw the sprites constantly?

	pd.datastore.write(save)

	function pd.gameWillPause() -- When the game's paused...
		local menu = pd.getSystemMenu()
		menu:removeAllMenuItems()
		if not scenemanager.transitioning and not vars.queued then
			menu:addMenuItem(text('refresh'), function()
				leaderboards:refresh()
			end)
		end
	end

	assets = { -- All assets go here. Images, sounds, fonts, etc.
		c = gfx.font.new('fonts/c'),
		nd = gfx.font.new('fonts/nd'),
		nld = gfx.font.new('fonts/nld'),
		n = gfx.font.new('fonts/n'),
		title_cars = gfx.imagetable.new('images/title_cars'),
	}

	vars = { -- All variables go here. Args passed in from earlier, scene variables, etc.
		mode = "normal",
		loading = true,
		queued = false,
		timer1 = pd.timer.new(1, -404, -404),
		timer2 = pd.timer.new(1, -404, -404),
		timer3 = pd.timer.new(1, -404, -404),
		timer4 = pd.timer.new(1, -404, -404),
		timer5 = pd.timer.new(1, -404, -404),
		result = {},
		best = {},
	}
	vars.leaderboardsHandlers = {
		BButtonDown = function()
			if not scenemanager.transitioning then
				scenemanager:transitionscene(title)
				pulp.audio.playSound('back')
			end
		end,

		AButtonDown = function()
			if not vars.loading then
				pulp.audio.playSound('select')
				if save.score >= 100 and not vars.queued then
					if vars.mode == "normal" then
						vars.mode = "hardcore"
					elseif vars.mode == "hardcore" then
						vars.mode = "normal"
					end
				end
				leaderboards:refresh()
			end
		end,
	}
	pd.inputHandlers.push(vars.leaderboardsHandlers)

	vars.timer2.delay = 50
	vars.timer3.delay = 100
	vars.timer4.delay = 150
	vars.timer5.delay = 200

	vars.timer1.discardOnCompletion = false
	vars.timer2.discardOnCompletion = false
	vars.timer3.discardOnCompletion = false
	vars.timer4.discardOnCompletion = false
	vars.timer5.discardOnCompletion = false

	gfx.sprite.setBackgroundDrawingCallback(function(x, y, width, height)
		gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
		assets.nd:drawText(text('bestscores'), 10, 10)
		if vars.result.scores ~= nil and next(vars.result.scores) ~= nil then
			for i = 1, 5 do
				assets.nd:drawText(i, 10 + vars['timer' .. i].value, 25 + (32.5 * i))
				assets.title_cars[vars['randomcar' .. i]]:draw(30 + vars['timer' .. i].value, 25 + (32.5 * i))
				gfx.setDitherPattern(0.25, gfx.image.kDitherTypeBayer2x2)
			end
			gfx.fillRect(0, 53, 400, 162)
			gfx.setColor(gfx.kColorBlack)
			for _, v in ipairs(vars.result.scores) do
				assets.nd:drawText(v.rank, 10 + vars['timer' .. v.rank].value, 25 + (32.5 * v.rank))
				assets.title_cars[vars['randomcar' .. v.rank]]:draw(30 + vars['timer' .. v.rank].value, 25 + (32.5 * v.rank))
				assets.c:drawText(v.player, 80 + vars['timer' .. v.rank].value, 28 + (32.5 * v.rank))
				assets.c:drawTextAligned(v.value, 390 + vars['timer' .. v.rank].value, 28 + (32.5 * v.rank), kTextAlignment.right)
			end
			gfx.setColor(gfx.kColorWhite)
			gfx.setDitherPattern(0.5, gfx.image.kDitherTypeBayer2x2)
			gfx.drawLine(0 + vars.timer1.value, 84, 400 + vars.timer1.value, 84)
			gfx.drawLine(0 + vars.timer2.value, 116, 400 + vars.timer2.value, 116)
			gfx.drawLine(0 + vars.timer3.value, 148, 400 + vars.timer3.value, 148)
			gfx.drawLine(0 + vars.timer4.value, 180, 400 + vars.timer4.value, 180)
			gfx.setColor(gfx.kColorBlack)
		elseif vars.result == "fail" then
			assets.c:drawTextAligned(text('failedscores'), 200, 125, kTextAlignment.center)
		else
			if vars.loading and vars.queued then
				assets.c:drawTextAligned(text('loadingscores'), 200, 125, kTextAlignment.center)
			else
				assets.c:drawTextAligned(text('emptyscores'), 200, 125, kTextAlignment.center)
			end
		end
		if vars.mode == "normal" then
			assets.c:drawText(text('normalmode'), 10, 33)
			assets.c:drawTextAligned(text('score') .. save.score, 390, 10, kTextAlignment.right)
		elseif vars.mode == "hardcore" then
			assets.c:drawText(text('hardcoremode'), 10, 33)
			assets.c:drawTextAligned(text('score') .. save.hardcore_score, 390, 10, kTextAlignment.right)
		end
		if vars.best.rank ~= nil then
			assets.c:drawTextAligned(text('rank') .. ordinal(vars.best.rank), 390, 25, kTextAlignment.right)
		end
		if vars.loading or vars.queued then
			assets.c:drawText(text('Bback'), 10, 222)
		else
			if save.score >= 100 then
				if vars.mode == "normal" then
					assets.c:drawText(text('Ahardcore') .. text('Bback'), 10, 222)
				elseif vars.mode == "hardcore" then
					assets.c:drawText(text('Anormal') .. text('Bback'), 10, 222)
				end
			else
				assets.c:drawText(text('Arefresh') .. text('Bback'), 10, 222)
			end
		end
		gfx.setColor(gfx.kColorWhite)
		gfx.drawLine(0, 51, 400, 51)
		gfx.drawLine(0, 216, 400, 216)
		gfx.setColor(gfx.kColorBlack)
		gfx.setImageDrawMode(gfx.kDrawModeCopy)
	end)

	self:add()
	pulp.audio.playSong('title_lower')
	self:refresh()
end

function leaderboards:update()
	if vars.timer1.timeLeft ~= 0 or vars.timer5.timeLeft ~= 0 then
		gfx.sprite.redrawBackground()
	end
end

function leaderboards:refresh()
	if vars.queued then return end
	local delay = 0
	vars.queued = true
	if not vars.loading and next(vars.result.scores or {}) ~= nil and vars.result.scores ~= nil then
		vars.timer1:resetnew(500, vars.timer1.value, 404, pd.easingFunctions.inBack)
		vars.timer2:resetnew(500, vars.timer2.value, 404, pd.easingFunctions.inBack)
		vars.timer3:resetnew(500, vars.timer3.value, 404, pd.easingFunctions.inBack)
		vars.timer4:resetnew(500, vars.timer4.value, 404, pd.easingFunctions.inBack)
		vars.timer5:resetnew(500, vars.timer5.value, 404, pd.easingFunctions.inBack)
		delay = 700
	end
	pd.timer.performAfterDelay(delay, function()
		vars.loading = true
		vars.result = {}
		vars.best = {}
		gfx.sprite.redrawBackground()
		vars.randomcar1 = random(1, 4)
		vars.randomcar2 = random(1, 4)
		vars.randomcar3 = random(1, 4)
		vars.randomcar4 = random(1, 4)
		vars.randomcar5 = random(1, 4)
		pd.scoreboards.getScores(vars.mode, function(status, result)
			if status.code == "OK" then
				vars.result = result
				if vars.timer1 ~= nil then vars.timer1:resetnew(500, -404, 0, pd.easingFunctions.outCubic) end
				if vars.timer2 ~= nil then vars.timer2:resetnew(500, -404, 0, pd.easingFunctions.outCubic) end
				if vars.timer3 ~= nil then vars.timer3:resetnew(500, -404, 0, pd.easingFunctions.outCubic) end
				if vars.timer4 ~= nil then vars.timer4:resetnew(500, -404, 0, pd.easingFunctions.outCubic) end
				if vars.timer5 ~= nil then vars.timer5:resetnew(500, -404, 0, pd.easingFunctions.outCubic) end
				gfx.sprite.redrawBackground()
				pd.scoreboards.getPersonalBest(vars.mode, function(status, result)
					vars.queued = false
					vars.loading = false
					if status.code == "OK" then
						vars.best = result
					end
					gfx.sprite.redrawBackground()
				end)
			else
				vars.result = "fail"
				gfx.sprite.redrawBackground()
			end
		end)
	end)
end