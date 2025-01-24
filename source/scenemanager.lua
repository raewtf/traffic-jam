local pd <const> = playdate
local gfx <const> = pd.graphics

class('scenemanager').extends()

function scenemanager:init()
    self.transitiontime = 450
	self.crashtime = 900
    self.transitioning = false
	self.crash_l = gfx.imagetable.new('images/crash_l')
	self.crash_r = gfx.imagetable.new('images/crash_r')
end

function scenemanager:switchscene(scene, ...)
    self.newscene = scene
    self.sceneargs = {...}
    -- Pop any rogue input handlers, leaving the default one.
    local inputsize = #playdate.inputHandlers - 1
    for i = 1, inputsize do
        pd.inputHandlers.pop()
    end
    self:loadnewscene()
    self.transitioning = false
end

-- This function will transition the scene with an animated effect.
function scenemanager:transitionscene(scene, ...)
	if self.transitioning then return end -- If there's already a scene transition, go away.
	self.transitioning = true -- Set this to true
	local rand = math.random(1, 4)
	self.transimage = gfx.imagetable.new('images/trans' .. rand)
	pulp.audio.playSound('car2drive')
	self.newscene = scene
	self.sceneargs = {...}
	-- Pop any rogue input handlers, leaving the default one.
	local inputsize = #playdate.inputHandlers - 1
	for i = 1, inputsize do
		pd.inputHandlers.pop()
	end
	-- IMPORTANT! These two numbers in the timer determine which frames of
	-- your image table will play during the FIRST HALF of transition period. It
	-- should be able to go backwards, but they MUST be whole numbers and it
	-- MUST be within the range of your image table's image count.
	local transitiontimer = self:transition(1, 10)
	-- After the first timer ends...
	transitiontimer.timerEndedCallback = function()
		-- Load the scene, and create a second timer for the other half.
		self:loadnewscene()
		-- These two numbers work the same way as the previous, but will
		-- determine which frames of your image table will play during
		-- the SECOND HALF of the transition period.
		transitiontimer = self:transition(10, 15)
		transitiontimer.timerEndedCallback = function()
			-- After this timer's over, remove the transition and the sprites.
			self.transitioning = false
			self.sprite:remove()
		end
	end
end

-- This function will transition the scene with an animated effect.
function scenemanager:crashscenel(scene, ...)
	if self.transitioning then return end -- If there's already a scene transition, go away.
	self.transitioning = true -- Set this to true
	self.transimage = self.crash_l
	self.newscene = scene
	self.sceneargs = {...}
	-- Pop any rogue input handlers, leaving the default one.
	local inputsize = #playdate.inputHandlers - 1
	for i = 1, inputsize do
		pd.inputHandlers.pop()
	end
	-- IMPORTANT! These two numbers in the timer determine which frames of
	-- your image table will play during the FIRST HALF of transition period. It
	-- should be able to go backwards, but they MUST be whole numbers and it
	-- MUST be within the range of your image table's image count.
	local transitiontimer = self:transitioncrash(1, 10)
	-- After the first timer ends...
	transitiontimer.timerEndedCallback = function()
		-- Load the scene, and create a second timer for the other half.
		self:loadnewscene()
		-- These two numbers work the same way as the previous, but will
		-- determine which frames of your image table will play during
		-- the SECOND HALF of the transition period.
		transitiontimer = self:transitioncrash(10, 15)
		transitiontimer.timerEndedCallback = function()
			-- After this timer's over, remove the transition and the sprites.
			self.transitioning = false
			self.sprite:remove()
		end
	end
end

-- This function will transition the scene with an animated effect.
function scenemanager:crashscener(scene, ...)
	if self.transitioning then return end -- If there's already a scene transition, go away.
	self.transitioning = true -- Set this to true
	self.transimage = self.crash_r
	self.newscene = scene
	self.sceneargs = {...}
	-- Pop any rogue input handlers, leaving the default one.
	local inputsize = #playdate.inputHandlers - 1
	for i = 1, inputsize do
		pd.inputHandlers.pop()
	end
	-- IMPORTANT! These two numbers in the timer determine which frames of
	-- your image table will play during the FIRST HALF of transition period. It
	-- should be able to go backwards, but they MUST be whole numbers and it
	-- MUST be within the range of your image table's image count.
	local transitiontimer = self:transitioncrash(1, 10)
	-- After the first timer ends...
	transitiontimer.timerEndedCallback = function()
		-- Load the scene, and create a second timer for the other half.
		self:loadnewscene()
		-- These two numbers work the same way as the previous, but will
		-- determine which frames of your image table will play during
		-- the SECOND HALF of the transition period.
		transitiontimer = self:transitioncrash(10, 15)
		transitiontimer.timerEndedCallback = function()
			-- After this timer's over, remove the transition and the sprites.
			self.transitioning = false
			self.sprite:remove()
		end
	end
end

function scenemanager:transition(table_start, table_end)
	self.sprite = self:newsprite()
	local newtimer = pd.timer.new(self.transitiontime, table_start, table_end)
	newtimer.updateCallback = function(timer) self.sprite:setImage(self.transimage[math.floor(timer.value)]) end
	return newtimer
end

function scenemanager:transitioncrash(table_start, table_end)
	self.sprite = self:newsprite()
	local newtimer = pd.timer.new(self.crashtime, table_start, table_end)
	newtimer.updateCallback = function(timer) self.sprite:setImage(self.transimage[math.floor(timer.value)]) end
	return newtimer
end

function scenemanager:newsprite()
	local loading = gfx.sprite.new()
	-- If there's already a sprite from the first half, set the start image to the last image of the table.
	-- This prevents any unwanted jitter when passing the baton from the first half to the second.
	if self.sprite then
		loading:setImage(self.sprite:getImage())
	else
		loading:setImage(self.transimage[1])
	end
	loading:setZIndex(26000) -- Putting it above every other sprite,
	loading:moveTo(0, 0)
	loading:setCenter(0, 0)
	loading:setIgnoresDrawOffset(true) -- Making sure it draws regardless of display offset.
	loading:add()
	return loading
end

function scenemanager:loadnewscene()
    self:cleanupscene()
    self.newscene(table.unpack(self.sceneargs))
end

function scenemanager:cleanupscene()
	if classes ~= nil then
		for i = #classes, 1, -1 do
			classes[i] = nil
		end
		classes = nil
	end
	classes = {}
    gfx.sprite:removeAll()
    if sprites ~= nil then
        for i = 1, #sprites do
            sprites[i] = nil
        end
    end
    sprites = {}
    if assets ~= nil then
        for i = 1, #assets do
            assets[i] = nil
        end
        assets = nil -- Nil all the assets,
    end
    if vars ~= nil then
        for i = 1, #vars do
            vars[i] = nil
        end
    end
    vars = nil -- and nil all the variables.
    self:removealltimers() -- Remove every timer,
    collectgarbage('collect') -- and collect the garbage.
    gfx.setDrawOffset(0, 0) -- Lastly, reset the drawing offset. just in case.
	pulp.audio.stopSong()
end

function scenemanager:removealltimers()
    local alltimers = pd.timer.allTimers()
    for _, timer in ipairs(alltimers) do
        timer:remove()
        timer = nil
    end
end