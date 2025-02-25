-- Setting up consts
local pd <const> = playdate
local gfx <const> = pd.graphics
local smp <const> = pd.sound.sampleplayer
local text <const> = gfx.getLocalizedText

class('credits').extends(gfx.sprite) -- Create the scene's class
function credits:init(...)
	credits.super.init(self)
	local args = {...} -- Arguments passed in through the scene management will arrive here
	gfx.sprite.setAlwaysRedraw(false) -- Should this scene redraw the sprites constantly?

	pd.datastore.write(save)

	function pd.gameWillPause() -- When the game's paused...
	end

	assets = { -- All assets go here. Images, sounds, fonts, etc.
		c = gfx.font.new('fonts/c'),
		nd = gfx.font.new('fonts/nd'),
		credits = gfx.image.new('images/credits'),
	}

	vars = { -- All variables go here. Args passed in from earlier, scene variables, etc.
	}
	vars.creditsHandlers = {
		BButtonDown = function()
			if not scenemanager.transitioning then
				pulp.audio.playSound('back')
				scenemanager:transitionscene(title)
			end
		end,
	}
	pd.inputHandlers.push(vars.creditsHandlers)

	gfx.sprite.setBackgroundDrawingCallback(function(x, y, width, height)
		assets.credits:draw(0, 0)
		assets.nd:drawTextAligned(text('thankyouforplaying'), 200, 22, kTextAlignment.center)
		assets.c:drawTextAligned(text('fullcredits'), 200, 55, kTextAlignment.center)
		gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
		assets.c:drawText(text('Bback'), 10, 222)
		gfx.setImageDrawMode(gfx.kDrawModeCopy)
	end)

	self:add()
	pulp.audio.playSong('title_lower')
end