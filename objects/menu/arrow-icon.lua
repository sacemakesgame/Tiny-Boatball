ArrowIcon = Blank:extend()


function ArrowIcon:new(owner, w, h, r)
    ArrowIcon.super.new(self, owner, w, h)
    self.rotation = r
    self.spring = class.spring(1)
end


function ArrowIcon:update(dt)
    self.spring:update(dt)
end


function ArrowIcon:draw(x, y)
    graphics.push()
    graphics.translate(x + self.w/2, y + self.h/2)
    graphics.rotate(self.rotation)
    graphics.scale(self.spring.x)

    graphics.set_color(color.palette.light)
    graphics.capsule('fill', 0, 0, self.w, self.h, true, .25)
    graphics.set_color(color.palette.dark)

    local thickness = 12 * scale
    graphics.circle('fill', 0, -self.h/5, thickness)
    graphics.circle('fill', -self.w/5, self.h/5, thickness)
    graphics.circle('fill', self.w/5, self.h/5, thickness)

    graphics.set_line_width(thickness)
    graphics.polygon('fill', 0, -self.h/5, -self.w/5, self.h/5, self.w/5, self.h/5)
    graphics.polygon('line', 0, -self.h/5, -self.w/5, self.h/5, self.w/5, self.h/5)
    graphics.set_line_width(1)

    graphics.pop()
end

function ArrowIcon:boing()
    self.spring:pull(.3)
end