ResolutionButton = Button:extend()
ResolutionButton.list = {
    [1] = {'1280 x 720', '1920 x 1080', '2560 x 1440'},
    [2] = {'1280 x 800', '1920 x 1200', '2560 x 1600'},
    [3] = {'1680 x 720', '2560 x 1080', '3440 x 1440'}
}

function ResolutionButton:new(owner, w, h, tag)
    ResolutionButton.super.new(self, owner, w, h, tag)
    self.active_character = RESOLUTION_QUALITY
end


function ResolutionButton:update(dt)
    if self.active then
        self.h = height/9
    else
        self.h = height/15
    end

    ResolutionButton.super.update(self, dt)   
end


function ResolutionButton:draw_arrow(x, y, r)
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


function ResolutionButton:draw(x, y)
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
        graphics.dashed_rectangle(x + self.w/2, y + self.h/2, self.w - (12 * scale), h - (12 * scale), 40 * scale, 20 * scale, nil, 5 * scale, -love.timer.getTime() * 50)
        -- graphics.printmid(self.list[self.active_character], x + self.w/2, y + self.h/2, 0, 1/3)
        graphics.printmid(self.list[ASPECT_RATIO][self.active_character], x + self.w/2, y + self.h/2 + math.sin(love.timer.getTime() * 10) * self.h/20, 0, 1/3)
        graphics.set_color(color.palette.light)
        graphics.printmid(self.tag, x + self.w/2, y + self.h/10, 0, 1/4)
    else
        graphics.set_color(color.palette.dark)
        graphics.printmid(self.tag, x + self.w/2, y + self.h/2, 0, 1/3)
        graphics.white()
    end

    graphics.pop()
end

function ResolutionButton:switch_right()
    self.active_character = self.active_character + 1
    if self.active_character > #self.list then
        self.active_character = 1
    end
    RESOLUTION_QUALITY = self.active_character
    self:change_res()
end

function ResolutionButton:switch_left()
    self.active_character = self.active_character - 1
    if self.active_character < 1 then
        self.active_character = #self.list
    end
    RESOLUTION_QUALITY = self.active_character
    self:change_res()
end


function ResolutionButton:change_res()
    if self.active_character == 1 then
        if ASPECT_RATIO == 1 then
            width, height = 1280, 720
        elseif ASPECT_RATIO == 2 then
            width, height = 1280, 800
        elseif ASPECT_RATIO == 3 then
            width, height = 1680, 720
        end
    elseif self.active_character == 2 then
        if ASPECT_RATIO == 1 then
            width, height = 1920, 1080
        elseif ASPECT_RATIO == 2 then
            width, height = 1920, 1200
        elseif ASPECT_RATIO == 3 then
            width, height = 2560, 1080
        end
    elseif self.active_character == 3 then
        if ASPECT_RATIO == 1 then
            width, height = 2560, 1440
        elseif ASPECT_RATIO == 2 then
            width, height = 2560, 1600
        elseif ASPECT_RATIO == 3 then
            width, height = 3440, 1440
        end
    end
    love.window.setMode(width, height, {fullscreen = not (IS_FULLSCREEN == 1)})
    tool.canvas = graphics.new_canvas(width, height)
    tool.canvas_x, tool.canvas_y = 0, 0
    tool.canvas:setFilter('nearest')
    scale = height/1440 -- global scale glue code shit thing
    gamestate.switch(Home, TYPE.OPTIONS, 1)
end