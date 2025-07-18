--[[
    Play sounds..
    a modified version of: https://github.com/Jeepzor/Sound-and-Music/blob/main/sound.lua
    modified by PIGIC
]]

local Sound = Object:extend()


-- Examples:
--      self.sound = class.sound(self, {'music', 'sfx'})
function Sound:new(owner, channel_list)
    assert(channel_list ~= nil, 'Sound instantiation need a channel-list bro :,)')
    assert(type(channel_list) == 'table', 'Channel-list\'s gotta be a table')
    assert(#channel_list ~= 0, 'Sound instance need at least 1 channel')
    self.owner = owner
    self.active = {}
    self.source = {}
    self.channels = {}
    self.id_to_channel = {}
    for _, v in ipairs(channel_list) do
        self.channels[v] = {
            volume = 1,
            pitch = 1,
            randomize_pitch = false
        }
    end
end

function Sound:update()
   for k, channel in pairs(self.active) do
      if channel[1] ~= nil and not channel[1]:isPlaying() then
         table.remove(channel, 1)
      end
   end
end

-- Examples:
--      sound:add('hi', 'sfx', 'sfx/chill-dude-saying-hi.ogg', 'static') for sfx
--  sound:add('ambatukan_song', 'music', 'music/ambatukan-1-hour-loop.ogg', 'stream') for music
function Sound:add(id, channel, source, sound_type)
    assert(self.source[id] == nil, 'Sound with ID: ' .. id .. ' already exists!')
    assert(self.channels[channel] ~= nil, 'Channel with name: ' .. channel .. ' does not exist.')
    if type(source) == 'table' then
        self.source[id] = {}
        for i = 1, #source do
            self.source[id][i] = love.audio.newSource(source[i], sound_type)
        end
    else
        self.source[id] = love.audio.newSource(source, sound_type)
    end
    self.id_to_channel[id] = channel
end

-- Examples:
--      sound:play('hi', 1, random:float(-.75, 1.25), false) for sfx
--      sound:play('ambatukan_song', 1, nil, true) for music
function Sound:play(id, volume_add, pitch_add, loop)
    local source
    if type(self.source[id]) == 'table' then
        source = self.source[id][math.random(1, #self.source[id])]
    else
        source = self.source[id]
    end

    local channel = self.channels[self.id_to_channel[id]]
    local clone = source:clone()
    -- clone:setVolume(math.clamp(channel.volume + (volume_add or 0), 0, 1))
    clone:setVolume(math.clamp((channel.volume + (volume_add or 0)) * math.remap(SFX_SCALE, 0, 4, 0, 1), 0, 1)) -- apply master volume scale in a 'bad' way ;)
    if channel.randomize_pitch then
        clone:setPitch(random:float(channel.min_pitch, channel.max_pitch) + (pitch_add or 0))
    else
        clone:setPitch(math.clamp(channel.pitch + (pitch_add or 0), 0, 1))
    end
    clone:setLooping(loop or false)
    clone:play()

    if self.active[channel] == nil then
        self.active[channel] = {}
    end
    table.insert(self.active[channel], clone)

    return clone
end


function Sound:set_volume(channel, volume)
    assert(self.channels[channel] ~= nil, 'Channel with name: ' .. channel .. ' does not exist.')
    if self.active[channel] then
        for k, sound in pairs(self.active[channel]) do
            sound:setVolume(volume)
        end
    end
    self.channels[channel].volume = volume
end

function Sound:set_pitch(channel, pitch)
    assert(self.channels[channel] ~= nil, 'Channel with name: ' .. channel .. ' does not exist.')
    if self.active[channel] then
        for k, sound in pairs(self.active[channel]) do
            sound:setPitch(pitch)
        end
    end
    self.channels[channel].pitch = pitch
end

function Sound:randomize_pitch(channel, min, max)
    assert(self.channels[channel] ~= nil, 'Channel with name: ' .. channel .. ' does not exist.')
    self.channels[channel].min_pitch = min
    self.channels[channel].max_pitch = max
end
    
function Sound:stop(channel)
   assert(self.active[channel] ~= nil, 'Channel with name: ' .. channel .. ' does not exist.')
   for k, sound in pairs(Sound.active[channel]) do
      sound:stop()
   end
end


function Sound:clean(id)
   self.source[id] = nil
end





return Sound