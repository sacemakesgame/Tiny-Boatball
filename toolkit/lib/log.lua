local log = {}
local NewLog = Object:extend()

function NewLog:new(text, duration)
    self.id = random:uid()
    self.text = tostring(text)
    if duration then log.timer:after(duration, function()
        self.dead = true
    end) end
end



function log:init()
    self.logs = {}
    self.text = ''
    self.color = {1, 1, 1, 1}
    self.timer = class.timer(self)
end

function log:set_color(color)
    self.color = color
end

function log:add(text, duration) -- plural
     local nlog = NewLog(text, duration)
    table.insert(self.logs,nlog)
    return nlog.id
end

function log:print(text) -- singular
    self.text = tostring(text)
end

function log:time()
    self.is_time = true
end

function log:fps()
    self.is_fps = true
end

function log:update(dt)
    self.timer:update(dt)
    for i = #self.logs, 1, -1 do
        local log = self.logs[i]
        if log.dead then
            table.remove(self.logs, i)
        end
    end
end

function log:draw()
    if self.is_time then
        local time = tostring(love.timer.getTime())
        graphics.set_color(.2, .2, .2, 1)
        graphics.rectangle('fill', 10, 20, graphics.get_font():getWidth(time), graphics.get_font():getHeight())
        graphics.set_color(1, 1, 1, 1)
        graphics.print(time, 10, 20)
        self.is_time = false -- reset each frame
    elseif self.is_fps then
        local fps = tostring(love.timer.getFPS())
        graphics.set_color(.2, .2, .2, 1)
        graphics.rectangle('fill', 10, 20, graphics.get_font():getWidth(fps), graphics.get_font():getHeight())
        graphics.set_color(1, 1, 1, 1)
        graphics.print(fps, 10, 20)
    else
        graphics.set_color(.2, .2, .2, 1)
        graphics.rectangle('fill', 10, 20, graphics.get_font():getWidth(self.text), graphics.get_font():getHeight())
        graphics.set_color(1, 1, 1, 1)
        graphics.print(self.text, 10, 20)
    end
    for i = 1, #self.logs do
        local nlog = self.logs[i]
        graphics.set_color(1, 1, 1, 1)
        graphics.rectangle('fill', 10, 30 + 30 * i, graphics.get_font():getWidth(nlog.text), graphics.get_font():getHeight())
        graphics.set_color(.2, .2, .2, 1)
        graphics.print(nlog.text, 10, 30 + 30 * i)
        graphics.set_color(1, 1, 1, 1)
    end
    graphics.set_color(1, 1, 1, 1)

end

return log
