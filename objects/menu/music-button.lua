MusicButton = Button:extend()

function MusicButton:new(owner, w, h, tag)
    MusicButton.super.new(self, owner, w, h, tag)
    self.active_character = MUSIC_SCALE
    self.timer = class.timer(self)
end


function MusicButton:update(dt)
    self.timer:update(dt)
    if self.active then
        self.h = height/9
    else
        self.h = height/15
    end

    MusicButton.super.update(self, dt)
end


function MusicButton:draw_arrow(x, y, r, active)
    local size = self.h/2
    graphics.push()
    graphics.translate(x, y)
    graphics.rotate(r)

    if active then
        graphics.set_color(color.palette.dark)
        graphics.capsule('fill', 0, 0, size, size, true, .25)
        graphics.set_color(color.palette.light)
    else
        graphics.set_color(color.palette.light)
        graphics.capsule('fill', 0, 0, size, size, true, .25)
        graphics.set_color(color.palette.dark)
    end

    
    local thickness = 12 * scale
    graphics.circle('fill', 0, -size/5, thickness)
    graphics.circle('fill', -size/5, size/5, thickness)
    graphics.circle('fill', size/5, size/5, thickness)
    
    graphics.set_line_width(thickness)
    graphics.polygon('fill', 0, -size/5, -size/5, size/5, size/5, size/5)
    graphics.polygon('line', 0, -size/5, -size/5, size/5, size/5, size/5)
    graphics.set_line_width(1)
    
    graphics.pop() 
    graphics.set_color(color.palette.dark)
end

function MusicButton:draw(x, y)    
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
        -- self:draw_arrow(x - 50 * scale, y + self.h/2, -math.pi/2, self.arrow_left and self.scale_spring.x * 1.1 or 1)
        -- self:draw_arrow(x + self.w + 50 * scale, y + self.h/2, math.pi/2, self.arrow_right and self.scale_spring.x * 1.1 or 1)
        self:draw_arrow(x - 50 * scale, y + self.h/2, -math.pi/2, self.arrow_left)
        self:draw_arrow(x + self.w + 50 * scale, y + self.h/2, math.pi/2, self.arrow_right)

        graphics.capsule('fill', x + self.w/2, y + self.h/4, self.w*.8, h, true, .15) -- lil on top
        graphics.set_color(color.palette.light)
        graphics.dashed_rectangle(x + self.w/2, y + self.h/2, self.w-12*height/1440, h-12*height/1440, 40 * scale, 20 * scale, nil, 5 * scale, -love.timer.getTime() * 50)
        -- graphics.printmid(self.list[self.active_character], x + self.w/2, y + self.h/2, 0, 1/3)
        graphics.printmid(self.active_character, x + self.w/2, y + self.h/2 + math.sin(love.timer.getTime() * 10) * self.h/20, 0, 1/3)
        graphics.set_color(color.palette.light)
        graphics.printmid(self.tag, x + self.w/2, y + self.h/10, 0, 1/4)
    else
        graphics.set_color(color.palette.dark)
        graphics.printmid(self.tag, x + self.w/2, y + self.h/2, 0, 1/3)
        graphics.white()
    end
    graphics.pop()
end

function MusicButton:switch_right()
    if self.active_character < 4 then
        self.active_character = self.active_character + 1
        self:boing(.05)
        self.arrow_right = true -- meh, glue shit
        self.timer:after(.1, function()
            self.arrow_right = false
        end, 'arrow-right')
        self.owner.sound:play('oreo')
    else
        self.owner.sound:play('blunder-snare')
        self:head_shake()
    end
    MUSIC_SCALE = self.active_character
    gamestate.current().sound:set_volume('music', MUSIC_SCALE)
end

function MusicButton:switch_left()
    if self.active_character > 0 then
        self.active_character = self.active_character - 1
        self:boing(.05)
        self.arrow_left = true -- meh, glue shit
        self.timer:after(.1, function()
            self.arrow_left = false
        end, 'arrow-left')
        self.owner.sound:play('oreo')
    else
        self.owner.sound:play('blunder-snare')
        self:head_shake()
    end
    MUSIC_SCALE = self.active_character
    gamestate.current().sound:set_volume('music', MUSIC_SCALE)
end
