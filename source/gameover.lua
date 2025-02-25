-- Setting up consts
local pd <const> = playdate
local gfx <const> = pd.graphics
local smp <const> = pd.sound.sampleplayer
local text <const> = gfx.getLocalizedText

class('gameover').extends(gfx.sprite) -- Create the scene's class
function gameover:init(...)
	gameover.super.init(self)
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
		gameover = gfx.image.new('images/gameover'),
	}

	vars = { -- All variables go here. Args passed in from earlier, scene variables, etc.
		score = args[1],
		level = args[2],
		bpm = args[3],
		hardcore = args[4],
		holdscore = save.score,
		holdhardscore = save.hardcore_score,
	}
	vars.gameoverHandlers = {
		AButtonDown = function()
			if not scenemanager.transitioning then
				pulp.audio.playSound('select')
				if vars.hardcore then
					scenemanager:transitionscene(game, false, true)
				else
					scenemanager:transitionscene(game, false)
				end
			end
		end,

		BButtonDown = function()
			if not scenemanager.transitioning then
				pulp.audio.playSound('back')
				scenemanager:transitionscene(title)
			end
		end,
	}
	pd.inputHandlers.push(vars.gameoverHandlers)

	gfx.sprite.setBackgroundDrawingCallback(function(x, y, width, height)
		assets.gameover:draw(0, 0)
		assets.nd:drawTextAligned(text('gameover'), 200, 22, kTextAlignment.center)
		if vars.hardcore then
			if vars.score > vars.holdhardscore then
				assets.c:drawTextAligned(text('youscored') .. vars.score .. text('points') .. '\n' .. text('newbest') .. '\n' .. text('tolevel') .. vars.level .. text('thats') .. vars.bpm .. text('thatsbpm'), 200, 55, kTextAlignment.center)
			else
				assets.c:drawTextAligned(text('youscored') .. vars.score .. text('points') .. '\n' .. text('yourcurrentbestis') .. vars.holdhardscore .. text('points') .. '\n' .. text('tolevel') .. vars.level .. text('thats') .. vars.bpm .. text('thatsbpm'), 200, 55, kTextAlignment.center)
			end
		else
			if vars.score > vars.holdscore then
				assets.c:drawTextAligned(text('youscored') .. vars.score .. text('points') .. '\n' .. text('newbest') .. '\n' .. text('tolevel') .. vars.level .. text('thats') .. vars.bpm .. text('thatsbpm'), 200, 55, kTextAlignment.center)
			else
				assets.c:drawTextAligned(text('youscored') .. vars.score .. text('points') .. '\n' .. text('yourcurrentbestis') .. vars.holdscore .. text('points') .. '\n' .. text('tolevel') .. vars.level .. text('thats') .. vars.bpm .. text('thatsbpm'), 200, 55, kTextAlignment.center)
			end
			if vars.score >= 100 and vars.holdscore < 100 then
				assets.c:drawTextAligned(text('unlockedhardcore'), 200, 115, kTextAlignment.center)
			end
		end
		gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
		assets.c:drawTextAligned(text('Aretry') .. text('Bback'), 200, 222, kTextAlignment.center)
		gfx.setImageDrawMode(gfx.kDrawModeCopy)
	end)

	if vars.hardcore then
		if vars.score > save.hardcore_score then save.hardcore_score = vars.score end
		if vars.level > save.hardcore_highest_level then save.hardcore_highest_level = vars.level end
		if vars.bpm > save.hardcore_highest_bpm then save.hardcore_highest_bpm = vars.bpm end
		if catalog then pd.scoreboards.addScore('hardcore', vars.score) end
	else
		if vars.score > save.score then save.score = vars.score end
		if vars.level > save.highest_level then save.highest_level = vars.level end
		if vars.bpm > save.highest_bpm then save.highest_bpm = vars.bpm end
		if catalog then pd.scoreboards.addScore('normal', vars.score) end
	end

	self:add()
	pulp.audio.playSong('title_lower')
	pd.datastore.write(save)
end