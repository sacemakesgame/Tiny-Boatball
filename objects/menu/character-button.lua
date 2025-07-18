CharacterButton = Button:extend()
CharacterButton.list = {
    'axolotl',
    'frog',
    'snail',
    'worm',
    'pelican',
}


function CharacterButton:new(owner, w, h, tag)
    CharacterButton.super.new(self, owner, w, h, tag)
    self.selected = false
    self.active_character = 1
end


function CharacterButton:update(dt)
    CharacterButton.super.update(self, dt)
end


function CharacterButton:draw(x, y)
    graphics.push()
    graphics.translate(x+self.w/2, y+self.h/2)
    graphics.rotate(self.rotate_spring.x)
    graphics.scale(self.scale_spring.x)
    graphics.translate(-x-self.w/2, -y-self.h/2) -- too lazy to rewrite the stuff

    if self.selected then
        graphics.set_line_width(3)
        graphics.capsule('line', x, y, self.w, self.h)
        graphics.set_line_width(1)
        
        graphics.printmid(self.list[self.active_character], x + self.w/2, y + self.h/2, 0, 1/3)
        graphics.printmid(self.tag, x - self.w/2, y + self.h/2, 0, 1/3)
        graphics.circle('fill', x - 10, y + self.h/2, 10)
        graphics.circle('fill', x + self.w + 10, y + self.h/2, 10)
    else
        if self.active then
            graphics.set_color(color.palette.dark)
            graphics.capsule('fill', x, y, self.w, self.h)
            graphics.circle('fill', x - 10, y + self.h/2, 10)
            graphics.circle('fill', x + self.w + 10, y + self.h/2, 10)
            graphics.white()
        -- else
        --     graphics.circle('fill', x + self.w/2, y + self.h/2, 15)
        end
        graphics.printmid(self.list[self.active_character], x + self.w/2, y + self.h/2, 0, 1/3)
        graphics.printmid(self.tag, x - self.w/2, y + self.h/2, 0, 1/3)
        graphics.set_color(color.palette.dark)
    end

    graphics.pop()
end

function CharacterButton:switch_right()
    self.active_character = self.active_character + 1
    if self.active_character > #self.list then
        self.active_character = 1
    end
end

function CharacterButton:switch_left()
    self.active_character = self.active_character - 1
    if self.active_character < 1 then
        self.active_character = #self.list
    end
end

function CharacterButton:get()
    return self.list[self.active_character]
end

function CharacterButton:set_active_character(string)
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