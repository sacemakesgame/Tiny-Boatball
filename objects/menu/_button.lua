Button = Object:extend()


function Button:new(owner, w, h, tag)
    self.owner = owner
    self.w = w
    self.h = h
    self.tag = tag
    self.scale_spring = class.spring(1)
    self.rotate_spring = class.spring(0, 500, 10)
end


function Button:update(dt)
    self.active = false
    self.scale_spring:update(dt)
    self.rotate_spring:update(dt)
    -- sooo, setting a block's active status gotta be done after this update
end


function Button:draw(x, y)
    graphics.push()
    graphics.translate(x+self.w/2, y+self.h/2)
    graphics.rotate(self.rotate_spring.x)
    graphics.scale(self.scale_spring.x)
    graphics.translate(-x-self.w/2, -y-self.h/2) -- too lazy to rewrite the stuff
    if self.active then
        graphics.set_color(color.palette.dark)
        graphics.capsule('fill', x, y, self.w, self.h, false, .25)
        graphics.set_color(color.palette.light)
        graphics.dashed_rectangle(x + self.w/2, y + self.h/2, self.w-12*height/1440, self.h-12*height/1440, 40 * scale, 20 * scale, nil, 5 * scale, -love.timer.getTime() * 50)
        graphics.printmid(self.tag, x + self.w/2, y + self.h/2 + math.sin(love.timer.getTime() * 10) * self.h/20, 0, 1/3)
    else
        graphics.set_color(color.palette.dark)
        graphics.printmid(self.tag, x + self.w/2, y + self.h/2, 0, 1/3)
    end
    graphics.white()
    graphics.pop()
end


function Button:destroy()
    
end

function Button:animate_pressed()
    self.scale_spring:animate(1.1)
end

function Button:animate_released()
    self.scale_spring:animate(1)
end

function Button:boing(force)
    self.scale_spring:pull(force or .3)
end

function Button:head_shake()
    self.rotate_spring:pull(math.pi/12)
end