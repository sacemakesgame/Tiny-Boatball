Blank = Object:extend()


function Blank:new(owner, w, h)
    self.w = w
    self.h = h
    self.tag = 'blank'
end


function Blank:update(dt)
    
end


function Blank:draw(x, y)
    -- graphics.rectangle('line', x, y, self.w, self.h)
end