FullscreenButton = Button:extend()
FullscreenButton.list = {
    'no',
    'yes',
}

function FullscreenButton:new(owner, w, h, tag)
    FullscreenButton.super.new(self, owner, w, h, tag)
    self.active_character = IS_FULLSCREEN
end


function FullscreenButton:update(dt)
    if self.active then
        self.h = height/9
    else
        self.h = height/15
    end

    FullscreenButton.super.update(self, dt)
end

function FullscreenButton:draw_arrow(x, y, r)
    local size = self.h/2
    graphics.push()
    graphics.translate(x, y)
    graphics.rotate(r)

    graphics.set_color(color.palette.light)
    graphics.capsule('fill', 0, 0, size, size, true, .25)
    graphics.set_color(color.palette.dark)

    local thickness = 12 * scale
    graphics.circle('fill', 0, -size/5, thickness)
    graphics.circle('fill', -size/5, size/5, thickness)
    graphics.circle('fill', size/5, size/5, thickness)

    graphics.set_line_width(thickness)
    graphics.polygon('fill', 0, -size/5, -size/5, size/5, size/5, size/5)
    graphics.polygon('line', 0, -size/5, -size/5, size/5, size/5, size/5)
    graphics.set_line_width(1)

    graphics.pop() 
end

function FullscreenButton:draw(x, y)    
    graphics.push()
    graphics.translate(x+self.w/2, y+self.h/2)
    graphics.rotate(self.rotate_spring.x)
    graphics.scale(self.scale_spring.x)
    graphics.translate(-x-self.w/2, -y-self.h/2) -- too lazy to rewrite the stuff

    if self.active then
        local h = height/15
        graphics.set_color(color.palette.dark)
        graphics.capsule('fill', x + self.w/2, y + self.h/2, self.w, h, true, .25)
        
        -- graphics.circle('fill', x - 10, y + self.h/2, 10)
        -- graphics.circle('fill', x + self.w + 10, y + self.h/2, 10)
        self:draw_arrow(x - 50 * scale, y + self.h/2, -math.pi/2)
        self:draw_arrow(x + self.w + 50 * scale, y + self.h/2, math.pi/2)

        graphics.capsule('fill', x + self.w/2, y + self.h/4, self.w*.8, h, true, .15) -- lil on top
        graphics.set_color(color.palette.light)
        graphics.dashed_rectangle(x + self.w/2, y + self.h/2, self.w-12*height/1440, h-12*height/1440, 40 * scale, 20 * scale, nil, 5 * scale, -love.timer.getTime() * 50)
        -- graphics.printmid(self.list[self.active_character], x + self.w/2, y + self.h/2, 0, 1/3)
        graphics.printmid(self.list[self.active_character], x + self.w/2, y + self.h/2 + math.sin(love.timer.getTime() * 10) * self.h/20, 0, 1/3)
        graphics.set_color(color.palette.light)
        graphics.printmid(self.tag, x + self.w/2, y + self.h/10, 0, 1/4)
    else
        graphics.set_color(color.palette.dark)
        graphics.printmid(self.tag, x + self.w/2, y + self.h/2, 0, 1/3)
        graphics.white()
    end
    graphics.pop()
end

function FullscreenButton:switch_right()
    self.active_character = self.active_character + 1
    if self.active_character > #self.list then
        self.active_character = 1
    end
    IS_FULLSCREEN = self.active_character
    love.window.setFullscreen(not (IS_FULLSCREEN == 1))
end

function FullscreenButton:switch_left()
    self.active_character = self.active_character - 1
    if self.active_character < 1 then
        self.active_character = #self.list
    end
    IS_FULLSCREEN = self.active_character
    love.window.setFullscreen(not (IS_FULLSCREEN == 1))
end
