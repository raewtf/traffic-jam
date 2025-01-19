-- Setting up consts
local pd <const> = playdate
local gfx <const> = pd.graphics
local smp <const> = pd.sound.sampleplayer
local text <const> = gfx.getLocalizedText

class('leaderboards').extends(gfx.sprite) -- Create the scene's class
function leaderboards:init(...)
	leaderboards.super.init(self)
	local args = {...} -- Arguments passed in through the scene management will arrive here
	gfx.sprite.setAlwaysRedraw(false) -- Should this scene redraw the sprites constantly?

	assets = { -- All assets go here. Images, sounds, fonts, etc.
		c = gfx.font.new('fonts/c'),
		nd = gfx.font.new('fonts/nd'),
		nld = gfx.font.new('fonts/nld'),
	}

	vars = { -- All variables go here. Args passed in from earlier, scene variables, etc.
	}
	vars.leaderboardsHandlers = {
	}
	pd.inputHandlers.push(vars.leaderboardsHandlers)

	gfx.sprite.setBackgroundDrawingCallback(function(x, y, width, height)
	end)

	self:add()
end