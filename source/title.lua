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

	assets = { -- All assets go here. Images, sounds, fonts, etc.
		c = gfx.font.new('fonts/c'),
		nd = gfx.font.new('fonts/nd'),
		nld = gfx.font.new('fonts/nld'),
	}

	vars = { -- All variables go here. Args passed in from earlier, scene variables, etc.
	}
	vars.titleHandlers = {
	}
	pd.inputHandlers.push(vars.titleHandlers)

	gfx.sprite.setBackgroundDrawingCallback(function(x, y, width, height)
		assets.nd:drawText('Traffic Jam', 10, 10)
		assets.nld:drawText('ultimate beta', 10, 35)
		assets.c:drawTextAligned('New Game', 385, 156, kTextAlignment.right)
		assets.c:drawTextAligned('Practice', 385, 171, kTextAlignment.right)
		assets.c:drawTextAligned('Leaderboards', 385, 186, kTextAlignment.right)
		assets.c:drawTextAligned('Options', 385, 201, kTextAlignment.right)
		assets.c:drawTextAligned('Credits', 385, 216, kTextAlignment.right)
	end)

	self:add()
end