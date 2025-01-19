-- Setting up consts
local pd <const> = playdate
local gfx <const> = pd.graphics
local smp <const> = pd.sound.sampleplayer
local text <const> = gfx.getLocalizedText

class('stats').extends(gfx.sprite) -- Create the scene's class
function stats:init(...)
	stats.super.init(self)
	local args = {...} -- Arguments passed in through the scene management will arrive here
	gfx.sprite.setAlwaysRedraw(false) -- Should this scene redraw the sprites constantly?

	assets = { -- All assets go here. Images, sounds, fonts, etc.
		c = gfx.font.new('fonts/c'),
		nd = gfx.font.new('fonts/nd'),
		nld = gfx.font.new('fonts/nld'),
		stats = gfx.image.new('images/stats'),
		stats_locked = gfx.image.new('images/stats_locked'),
	}

	vars = { -- All variables go here. Args passed in from earlier, scene variables, etc.
	}
	vars.statsHandlers = {
		BButtonDown = function()
			scenemanager:switchscene(title)
		end,
	}
	pd.inputHandlers.push(vars.statsHandlers)

	gfx.sprite.setBackgroundDrawingCallback(function(x, y, width, height)
		if save.score >= 50 then
			assets.stats:draw(0, 0)
		else
			assets.stats_locked:draw(0, 0)
		end
		assets.nd:drawText(text('normalmode'), 20, 22)
		assets.nd:drawTextAligned(text('hardcoremode'), 380, 22, kTextAlignment.right)
		assets.c:drawText(text('bestscore') .. commalize(save.score), 20, 55)
		assets.c:drawText(text('highestbpm') .. commalize(save.highest_bpm), 20, 75)
		assets.c:drawText(text('highestlevel') .. commalize(save.highest_level), 20, 95)
		if save.score >= 50 then
			assets.c:drawTextAligned(text('bestscore') .. commalize(save.hardcore_score), 380, 55, kTextAlignment.right)
			assets.c:drawTextAligned(text('highestbpm') .. commalize(save.hardcore_highest_bpm), 380, 75, kTextAlignment.right)
			assets.c:drawTextAligned(text('highestlevel') .. commalize(save.hardcore_highest_level), 380, 95, kTextAlignment.right)
		else
			assets.c:drawTextAligned(text('hardcorereq'), 295, 69, kTextAlignment.center)
		end
		assets.c:drawTextAligned(text('carspassed') .. commalize(save.cars_passed), 200, 135, kTextAlignment.center)
		assets.c:drawTextAligned(text('crankage') .. commalize(save.crankage) .. text('deg'), 200, 155, kTextAlignment.center)
		assets.c:drawTextAligned(text('crankage_net') .. commalize(save.crankage_net) .. text('deg'), 200, 175, kTextAlignment.center)
		gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
		assets.c:drawText(text('Bback'), 10, 222)
		gfx.setImageDrawMode(gfx.kDrawModeCopy)
	end)

	self:add()
end