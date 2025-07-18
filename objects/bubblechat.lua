local ConsoleLine -- implemented below

BubbleChat = Object:extend()

function BubbleChat:new(owner, position, text, tick, exit_after, scale, back_color, text_color)
    self.owner = owner
    self.timer = class.timer(self)
    self.rotate_spring = class.spring(0, 500, 10)
    self.position = position
    self.full_text = text
    self.scale = scale or .5 -- .5 as default, dont ask me why :)
    self.tick = tick or .067
    self.back_color = back_color or color.sass.white
    self.text_color = text_color or color.palette.dark
    self.consoleline = ConsoleLine(self, text, self.tick, exit_after or false)
    self:enter()
end

function BubbleChat:get_total_dur()
    local dur = self.full_text:len() * self.tick
    return dur
end

function BubbleChat:update(dt)
    self.timer:update(dt)
    self.rotate_spring:update(dt)
end

function BubbleChat:draw()    
    local scene = self.owner

    graphics.push()
    graphics.translate(self.position.x, self.position.y)
    graphics.rotate(math.sin(love.timer.getTime()) * math.pi/100)
    -- graphics.scale(.5)
    graphics.rotate(self.rotate_spring.x)
    graphics.scale(self._scale)
    graphics.scale(self.scale)

    -- background
    local text_width = scene.font:getWidth(self.consoleline.text)
    local text_height = scene.font:getHeight()

    graphics.set_color(color.palette.dark)
    graphics.capsule('fill', 0, 20 * scale, text_width + 100 * scale, text_height + 10 * scale, true, .25)
    graphics.set_color(self.back_color)
    graphics.capsule('fill', 0, 0, text_width + 100 * scale, text_height + 10 * scale, true, .25)
    
    
    graphics.set_color(self.text_color)
    
    local thickness = 2*height/1440
    for i = 0, math.pi*2, math.pi/8 do
        -- graphics.printmid(tostring(self.owner.blue_score), width/2 - 115 * scale + math.cos(i) * thickness, 105 * scale + math.sin(i) * thickness, 0, .5)
        graphics.printmid(self.consoleline.text, math.cos(i) * thickness, math.sin(i) * thickness)
    end

    graphics.set_line_width(20)
    -- graphics.line(-text_width/2, text_height*1/3, text_width/2, text_height*1/3) -- underline
    graphics.set_line_width(1)

    graphics.pop()
    graphics.white()
end

function BubbleChat:destroy()
    -- self.target = nil
    self.timer:destroy()
end

function BubbleChat:enter()
    self._scale = 0
    self.timer:tween(.25, self, {_scale = 1}, math.cubic_in_out)
end

function BubbleChat:exit()
    self.timer:tween(.25, self, {_scale = 0}, math.cubic_in_out, function()
        self.dead = true
    end)
end

function BubbleChat:play_sfx(who)
    local sfx = self['_' .. who]:clone()
    sfx:setPitch(random:float(.95, 1.05))-- * pitch)
    sfx:play()
end


local utf8 = require 'utf8'
ConsoleLine = Object:extend()

function ConsoleLine:new(owner, text, tick, exit_after)
    self.owner = owner
    self.full_text = text
    self.text = ''
    self.i = 0

    local text_per_tick = 1 -- how many the text added up every tick
    if exit_after then
        self.owner.timer:every_immediate(tick, function()
            self.i = self.i + text_per_tick
            self.text = self.full_text:sub(1, self.i)
            -- if (self.i % 4 == 0) then self.owner.spring:pull(.2) end
            if (self.i % 2 == 0) then self.owner.owner.sound:play('oreo') end
        end, self.full_text:len(),
        function()
            self.owner.timer:after(exit_after, self.owner.exit)
        end)
    else
        self.owner.timer:every_immediate(tick, function()
            self.i = self.i + text_per_tick
            self.text = self.full_text:sub(1, self.i)
            if (self.i % 2 == 0) then self.owner.owner.sound:play('oreo') end
            -- if (self.i % 4 == 0) then self.owner.spring:pull(.2) end
        end, self.full_text:len())
    end
end