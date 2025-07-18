local function newShake(amplitude, duration, frequency)
    local self = {
        amplitude = amplitude or 0,
        duration = duration or 0,
        frequency = frequency or 60,
        samples = {},
        start_time = love.timer.getTime() * 1000,
        t = 0,
        shaking = true,
    }

    local sample_count = (self.duration / 1000) * self.frequency
    for i = 1, sample_count do self.samples[i] = 2 * love.math.random() - 1 end

    return self
end

local function updateShake(self, dt)
    self.t = love.timer.getTime() * 1000 - self.start_time
    if self.t > self.duration then self.shaking = false end
end

local function shakeNoise(self, s)
    if s >= #self.samples then return 0 end
    return self.samples[s] or 0
end

local function shakeDecay(self, t)
    if t > self.duration then return 0 end
    return (self.duration - t) / self.duration
end

local function getShakeAmplitude(self, t)
    if not t then
        if not self.shaking then return 0 end
        t = self.t
    end

    local s = (t / 1000) * self.frequency
    local s0 = math.floor(s)
    local s1 = s0 + 1
    local k = shakeDecay(self, t)
    return self.amplitude * (shakeNoise(self, s0) + (s - s0) * (shakeNoise(self, s1) - shakeNoise(self, s0))) * k
end


local Shake = Object:extend()

function Shake:new()
    self.x_shakes = {}
    self.y_shakes = {}
    self.z_shakes = {}
    self.x = 0
    self.y = 0
    self.z = 0
end

--[[
    see https://jonny.morrill.me/en/blog/gamedev-how-to-implement-a-camera-shake-effect/
    perhaps start with this numbers: 1, 16, 60
]]
function Shake:add(duration, amplitude, frequency, axes)
    local axes = axes or 'xyz'
    axes = string.lower(axes)

    if string.find(axes, 'x') then table.insert(self.x_shakes, newShake(amplitude, duration * 1000, frequency)) end
    if string.find(axes, 'y') then table.insert(self.y_shakes, newShake(amplitude, duration * 1000, frequency)) end
    if string.find(axes, 'z') then table.insert(self.z_shakes, newShake(amplitude, duration * 1000, frequency)) end
end

function Shake:update(dt)
    -- Shake --
    local x_shake_amount, y_shake_amount, z_shake_amount = 0, 0, 0
    for i = #self.x_shakes, 1, -1 do
        updateShake(self.x_shakes[i], dt)
        x_shake_amount = x_shake_amount + getShakeAmplitude(self.x_shakes[i])
        if not self.x_shakes[i].shaking then table.remove(self.x_shakes, i) end
    end
    for i = #self.y_shakes, 1, -1 do
        updateShake(self.y_shakes[i], dt)
        y_shake_amount = y_shake_amount + getShakeAmplitude(self.y_shakes[i])
        if not self.y_shakes[i].shaking then table.remove(self.y_shakes, i) end
    end
    for i = #self.z_shakes, 1, -1 do
        updateShake(self.z_shakes[i], dt)
        z_shake_amount = z_shake_amount + getShakeAmplitude(self.z_shakes[i])
        if not self.z_shakes[i].shaking then table.remove(self.z_shakes, i) end
    end

    self.x = x_shake_amount
    self.y = y_shake_amount
    self.z = z_shake_amount
end


return Shake