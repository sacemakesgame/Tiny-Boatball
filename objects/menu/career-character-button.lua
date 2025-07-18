CareerCharacterButton = Button:extend()
CareerCharacterButton.list = {
    'axolotl',
    'frog',
    'snail',
    'worm',
    'pelican',
}


function CareerCharacterButton:new(owner, w, h, tag)
    CareerCharacterButton.super.new(self, owner, w, h, tag)
    self.selected = false
    self.active_character = 1
end


function CareerCharacterButton:update(dt)
    CareerCharacterButton.super.update(self, dt)
end


function CareerCharacterButton:draw(x, y)
    graphics.push()
    graphics.translate(x+self.w/2, y+self.h/2)
    graphics.rotate(self.rotate_spring.x)
    graphics.scale(self.scale_spring.x)
    graphics.translate(-x-self.w/2, -y-self.h/2) -- too lazy to rewrite the stuff

    if self.selected then
        graphics.set_color(color.palette.light)
        graphics.set_line_width(5)
        graphics.capsule('line', x + self.w/2 + self.w/2, y + self.h/2, self.w*.8, self.h*.85, true, .25)
        graphics.line(x - self.w/4, y + self.h * .85, x + self.w/4, y + self.h * .85)
        graphics.set_line_width(1)
        -- graphics.dashed_line_can_walk(x - self.w/4, y + self.h * .85, x + self.w/4, y + self.h * .85, 20, 10, nil, 5, -love.timer.getTime() * 50)
        
        graphics.set_color(color.palette.light)
        graphics.printmid(self.list[self.active_character], x + self.w/2 + self.w/2, y + self.h/2, 0, 1/3)
        graphics.printmid(self.tag, x, y + self.h/2, 0, 1/3)
    else
        if self.active then
            graphics.set_color(color.palette.light)
            -- graphics.capsule('fill', x + self.w/2 + self.w/2, y + self.h/2, self.w*.8, self.h*.85, true, .25)
            graphics.dashed_rectangle(x + self.w/2 + self.w/2, y + self.h/2, self.w*.8, self.h*.85, 40 * scale, 20 * scale, nil, 5 * scale, -love.timer.getTime() * 50)

            
            graphics.set_color(color.palette.light)
            graphics.printmid(self.list[self.active_character], x + self.w/2 + self.w/2, y + self.h/2, 0, 1/3)
            -- graphics.set_color(color.palette.light)
            graphics.printmid(self.tag, x, y + self.h/2, 0, 1/3)
            -- underline
            graphics.set_line_width(5)
            -- graphics.line(x - self.w/4, y + self.h * .85, x + self.w/4, y + self.h * .85)
            graphics.dashed_line_can_walk(x - self.w/4, y + self.h * .85, x + self.w/4, y + self.h * .85, 40 * scale, 20 * scale, nil, 5 * scale, -love.timer.getTime() * 50)
            graphics.set_line_width(1)
            
        else
            graphics.set_color(color.palette.light)
            graphics.printmid(self.list[self.active_character], x + self.w/2 + self.w/2, y + self.h/2, 0, 1/3)
            -- graphics.printmid(self.tag, x, y + self.h/2, 0, 1/3)
        end
    end

    graphics.pop()
end

function CareerCharacterButton:get()
    return self.list[self.active_character]
end

function CareerCharacterButton:set_active_character(string)
    if string == 'axolotl' then
        self.active_character = 1
    elseif string == 'frog' then
        self.active_character = 2
    elseif string == 'snail' then
        self.active_character = 3
    elseif string == 'worm' then
        self.active_character = 4
    elseif string == 'pelican' then
        self.active_character = 5
    end
end


