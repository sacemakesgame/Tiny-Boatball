tool = require 'toolkit'
lume = require 'toolkit/lib/lume'
local min_dt, next_time

TYPE = {
    MAIN = 1,
    CAREER = 2,
    OPTIONS = 3,
    CREDIT = 4,
}

local t = {}
t.ally = {}
t.ally.keeper = 'axolotl'
t.ally.outfields = {'axolotl', 'axolotl', 'axolotl'}
t.player_index = 1
t.opponent = {}
t.opponent.keeper = ''
t.opponent.outfields = {}


CAREER_OPPONENT_LIST = {
    [1] = {'axolotl', 'axolotl', 'frog', 'frog'},
    [2] = {'snail', 'axolotl', 'frog', 'frog'},
    [3] = {'snail', 'worm', 'worm', 'worm'},
    [4] = {'pelican', 'pelican', 'axolotl', 'frog'},
}

CAREER_PROGRESSION_INDEX = 1 -- meta game progression, eg how many characters has been unlocked
CAREER_MATCH_COUNTER = 1 -- per run match counter

CAREER_CHARACTER_LIST = {
    -- ally = {'axolotl', 'frog', 'snail', 'pelican'},
    -- ally = {'frog', 'frog', 'frog', 'frog'},
    -- ally = {'snail', 'snail', 'snail', 'snail'},
    -- ally = {'worm', 'worm', 'worm', 'worm'},
    ally = {'axolotl', 'worm', 'pelican', 'snail'},
    opponent = {},
    player_index = 3
}

function update_career_status(status)
    local return_string
    if status == 'win' then
        CAREER_MATCH_COUNTER = CAREER_MATCH_COUNTER + 1
        -- progression
        if CAREER_MATCH_COUNTER > CAREER_PROGRESSION_INDEX then
            CAREER_PROGRESSION_INDEX = CAREER_MATCH_COUNTER
            if CAREER_PROGRESSION_INDEX == 2 then
                -- log:add('frog unlocked!', 2)
                return_string = 'FROG'
            elseif CAREER_PROGRESSION_INDEX == 3 then
                -- log:add('snail unlocked!', 2)
                return_string = 'SNAIL'
            elseif CAREER_PROGRESSION_INDEX == 4 then
                -- log:add('worm unlocked!', 2)
                return_string = 'WORM'
            elseif CAREER_PROGRESSION_INDEX == 5 then
                -- log:add('pelican unlocked!', 2)
                return_string = 'PELICAN'
            end
        end
        -- if win, reset (now from stage.lua instead)
        -- if CAREER_MATCH_COUNTER >= 5 then
        --     CAREER_MATCH_COUNTER = 1
        -- end
    elseif status == 'lose' then
        CAREER_MATCH_COUNTER = 1
    elseif status == 'draw' then
        
    end
    
    save_career_data()
    return return_string
end


RESOLUTION_QUALITY = 2
ASPECT_RATIO = 1
IS_FULLSCREEN = 1
SFX_SCALE = 4 -- 0-4, default is 4
MUSIC_SCALE = 2 -- 0-4, default is 2



function love.load()
    -- love.mouse.setVisible(false)
    love.graphics.setLineWidth(1)
    love.graphics.setLineJoin('bevel')
    love.graphics.setDefaultFilter('linear')
    
    load_career_data()
    load_options_data()
    tool:init()    
    input:bind('w', 'up')
    input:bind('s', 'down')
    input:bind('a', 'left')
    input:bind('d', 'right')
    input:bind('up', 'up')
    input:bind('down', 'down')
    input:bind('left', 'left')
    input:bind('right', 'right')
    
    input:bind('z', 'nos')
    input:bind('return', 'nos')

    input:bind('return', 'enter')
    input:bind('z', 'enter')
    input:bind('escape', 'back')

    -- input:bind('tab', 'fast-forward')
    
    love.graphics.setBackgroundColor(color.palette.wall)


    gamestate.init(Home, TYPE.MAIN)
    -- gamestate.init(Stage, TYPE.CAREER)
    
    min_dt = 1/60
    next_time = love.timer.getTime()

    love.window.setVSync(true)
end

function love.update(dt)
    --[[if input:down('fast-forward') then
        tool.time_scale = 2
    else
        tool.time_scale = 1
    end]]

    next_time = next_time + min_dt

    tool:update(dt)
end


function love.draw()
    -- log:fps()
    tool:draw()

    --[[
    graphics.set_color(color.palette.dark)
    graphics.print('progression: ' .. CAREER_PROGRESSION_INDEX, 50, 50 * scale, 0, .2)
    graphics.print('counter: ' .. CAREER_MATCH_COUNTER, 50, 100 * scale, 0, .2)
    graphics.print('sfx scale: ' .. SFX_SCALE, 50, 150 * scale, 0, .2)
    ]]

    local cur_time = love.timer.getTime()
    if next_time <= cur_time then
       next_time = cur_time
       return
    end
    love.timer.sleep(next_time - cur_time)

end

--[[
function love.keypressed(key)
    if key == '`' then -- since espace is used to open menu
        love.event.quit()
    elseif key == 'f5' then
        love.event.quit('restart')
    end
end--]]



function recursive_enumerate(folder, t)
	local items = love.filesystem.getDirectoryItems(folder)
	for _, item in ipairs(items) do
		local file = folder .. '/' .. item
		local info = love.filesystem.getInfo(file)
		if info.type == 'file' then
			table.insert(t, file)
		elseif info.type == 'directory' then
			recursive_enumerate(file, t)
		end
	end
end

function require_files(t)
	for _, file in ipairs(t) do
		local file = file:sub(1, -5)
		require(file)
	end
end


function save_career_data()
    local data = {}
    data.CAREER_PROGRESSION_INDEX = CAREER_PROGRESSION_INDEX
    data.CAREER_MATCH_COUNTER = CAREER_MATCH_COUNTER
    local serialized = lume.serialize(data)
    love.filesystem.write('career-data', serialized)
end

function save_options_data()
    local data = {}
    data.RESOLUTION_QUALITY = RESOLUTION_QUALITY
    data.ASPECT_RATIO = ASPECT_RATIO
    data.IS_FULLSCREEN = IS_FULLSCREEN
    data.SFX_SCALE = SFX_SCALE
    data.MUSIC_SCALE = MUSIC_SCALE
    local serialized = lume.serialize(data)
    love.filesystem.write('options-data', serialized)
end

function load_career_data()
    if love.filesystem.getInfo('career-data') then
        local string_data = love.filesystem.read('career-data')
        local data = lume.deserialize(string_data)
        if data.CAREER_PROGRESSION_INDEX then CAREER_PROGRESSION_INDEX = data.CAREER_PROGRESSION_INDEX end
        if data.CAREER_MATCH_COUNTER then CAREER_MATCH_COUNTER = data.CAREER_MATCH_COUNTER end
    end
end

function load_options_data()
    if love.filesystem.getInfo('options-data') then
        local string_data = love.filesystem.read('options-data')
        local data = lume.deserialize(string_data)
        if data.RESOLUTION_QUALITY then RESOLUTION_QUALITY = data.RESOLUTION_QUALITY end
        if data.ASPECT_RATIO then ASPECT_RATIO = data.ASPECT_RATIO end
        if data.IS_FULLSCREEN then IS_FULLSCREEN = data.IS_FULLSCREEN end
        if data.SFX_SCALE then SFX_SCALE = data.SFX_SCALE end
        if data.MUSIC_SCALE then MUSIC_SCALE = data.MUSIC_SCALE end
    end
end