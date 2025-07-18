XContainer = Object:extend()
-- x axis
XContainer.LEFT = 0
XContainer.RIGHT = 1
XContainer.CENTER = 2
-- y axis
XContainer.TOP = 3
XContainer.BOTTOM = 4
XContainer.MIDDLE = 5


function XContainer:new(owner, x, y)
    self.x, self.y = x, y
    self.x_align = self.LEFT
    self.y_align = self.TOP

    self.w = 0
    self.h = 0

    self.pivot_debug = false
    self.area_debug = false

    self.holder = class.holder(owner)
    self.by_tag = {}
end


function XContainer:update(dt)
   self.holder:update(dt) 
end


function XContainer:draw(x, y)
    if (self.x_align == self.LEFT) and (self.y_align == self.TOP) then -- left top
        if x then
            self.x, self.y = x, y
        end
        local x_offset = 0
        for _, v in ipairs(self.holder.objects) do
            v:draw(self.x + x_offset, self.y)
            x_offset = x_offset + v.w
        end
    
    elseif (self.x_align == self.LEFT) and (self.y_align == self.MIDDLE) then -- left middle
        local x_offset = 0
        for _, v in ipairs(self.holder.objects) do
            v:draw(self.x + x_offset, self.y - self.h/2 + (self.h - v.h)/2)
            x_offset = x_offset + v.w
        end
    
    elseif (self.x_align == self.LEFT) and (self.y_align == self.BOTTOM) then -- left bottom
        local x_offset = 0
        for _, v in ipairs(self.holder.objects) do
            v:draw(self.x + x_offset, self.y - v.h)
            x_offset = x_offset + v.w
        end

    elseif (self.x_align == self.CENTER) and (self.y_align == self.TOP) then -- center top
        local x_offset = 0
        for _, v in ipairs(self.holder.objects) do
            v:draw(self.x - self.w/2 + x_offset, self.y)
            x_offset = x_offset + v.w
        end
        
    elseif (self.x_align == self.CENTER) and (self.y_align == self.MIDDLE) then -- center middle
        if x then
            self.x = x + self.w/2
            self.y = y + self.h/2
        end
        local x_offset = 0
        for _, v in ipairs(self.holder.objects) do
            v:draw(self.x - self.w/2 + x_offset, self.y - self.h/2 + (self.h - v.h)/2)
            x_offset = x_offset + v.w
        end
    
    elseif (self.x_align == self.CENTER) and (self.y_align == self.BOTTOM) then -- center bottom
        local x_offset = 0
        for _, v in ipairs(self.holder.objects) do
            v:draw(self.x - self.w/2 + x_offset, self.y - v.h)
            x_offset = x_offset + v.w
        end
    
    elseif (self.x_align == self.RIGHT) and (self.y_align == self.TOP) then -- right top
        local x_offset = 0
        for _, v in ipairs(self.holder.objects) do
            v:draw(self.x - self.w + x_offset, self.y)
            x_offset = x_offset + v.w
        end
    
    elseif (self.x_align == self.RIGHT) and (self.y_align == self.MIDDLE) then -- right middle
        local x_offset = 0
        for _, v in ipairs(self.holder.objects) do
            v:draw(self.x - self.w + x_offset, self.y - self.h/2 + (self.h - v.h)/2)
            x_offset = x_offset + v.w
        end
    
    elseif (self.x_align == self.RIGHT) and (self.y_align == self.BOTTOM) then -- right bottom
        local x_offset = 0
        for _, v in ipairs(self.holder.objects) do
            v:draw(self.x - self.w + x_offset, self.y - v.h)
            x_offset = x_offset + v.w
        end
    end

    -- pivot debug
    if self.pivot_debug then
        graphics.circle('fill', self.x, self.y, 20, 20)
    end
    
    -- area debug
    if self.area_debug then
        graphics.set_line_width(4)
        if (self.x_align == self.LEFT) and (self.y_align == self.TOP) then -- left top
            graphics.rectangle('line', self.x, self.y, self.w, self.h) -- area debug    
        elseif (self.x_align == self.LEFT) and (self.y_align == self.MIDDLE) then -- left middle
            graphics.rectangle('line', self.x, self.y - self.h/2, self.w, self.h) -- area debug
        elseif (self.x_align == self.LEFT) and (self.y_align == self.BOTTOM) then -- left bottom
            graphics.rectangle('line', self.x, self.y - self.h, self.w, self.h) -- area debug
        elseif (self.x_align == self.CENTER) and (self.y_align == self.TOP) then -- center top
            graphics.rectangle('line', self.x - self.w/2, self.y, self.w, self.h) -- area debug
        elseif (self.x_align == self.CENTER) and (self.y_align == self.MIDDLE) then -- center middle
            graphics.rectangle('line', self.x - self.w/2, self.y - self.h/2, self.w, self.h) -- area debug
        elseif (self.x_align == self.CENTER) and (self.y_align == self.BOTTOM) then -- center bottom
            graphics.rectangle('line', self.x - self.w/2, self.y - self.h, self.w, self.h) -- area debug
        elseif (self.x_align == self.RIGHT) and (self.y_align == self.TOP) then -- right top
            graphics.rectangle('line', self.x - self.w, self.y, self.w, self.h) -- area debug
        elseif (self.x_align == self.RIGHT) and (self.y_align == self.MIDDLE) then -- right middle
            graphics.rectangle('line', self.x - self.w, self.y - self.h/2, self.w, self.h) -- area debug
        elseif (self.x_align == self.RIGHT) and (self.y_align == self.BOTTOM) then -- right bottom
            graphics.rectangle('line', self.x - self.w, self.y - self.h, self.w, self.h) -- area debug
        end
        graphics.set_line_width(1)
    end
end


function XContainer:add(object, ...)
    local obj = self.holder:add(object, ...)
    self.w = self.w + obj.w
    self.h = (self.h < obj.h) and obj.h or self.h
    
    self.by_tag[obj.tag] = obj
    return obj
end

function XContainer:push(container)
    container.id = random:uid()
    self.holder.objects.by_id[container.id] = container
    self.holder:push(container)
    self.w = self.w + container.w
    self.h = (self.h < container.h) and container.h or self.h
end


function XContainer:set_align(x, y)
    self.x_align, self.y_align = x, y
end