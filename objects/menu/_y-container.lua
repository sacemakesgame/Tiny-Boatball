YContainer = Object:extend()
-- x axis
YContainer.LEFT = 0
YContainer.RIGHT = 1
YContainer.CENTER = 2
-- y axis
YContainer.TOP = 3
YContainer.BOTTOM = 4
YContainer.MIDDLE = 5


function YContainer:new(owner, x, y)
    self.owner = owner
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


function YContainer:update(dt)
   self.holder:update(dt) 
end


function YContainer:draw(x, y)
    if (self.x_align == self.LEFT) and (self.y_align == self.TOP) then -- left top
        if x then
            self.x, self.y = x, y
        end
        local y_offset = 0
        for _, v in ipairs(self.holder.objects) do
            v:draw(self.x, self.y + y_offset)
            y_offset = y_offset + v.h
        end
        
    elseif (self.x_align == self.LEFT) and (self.y_align == self.MIDDLE) then -- left middle
        if x then
            self.x = x
            self.y = y + self.h/2
        end
        local y_offset = 0
        for i, v in ipairs(self.holder.objects) do
            v:draw(self.x, self.y - self.h/2 + y_offset)
            y_offset = y_offset + v.h
        end
    
    elseif (self.x_align == self.LEFT) and (self.y_align == self.BOTTOM) then -- left bottom
        local y_offset = 0
        for _, v in ipairs(self.holder.objects) do
            v:draw(self.x, self.y - self.h + y_offset)
            y_offset = y_offset + v.h
        end

    elseif (self.x_align == self.CENTER) and (self.y_align == self.TOP) then -- center top
        local y_offset = 0
        for _, v in ipairs(self.holder.objects) do
            v:draw(self.x - self.w/2 + (self.w - v.w)/2, self.y + y_offset)
            y_offset = y_offset + v.h
        end

    elseif (self.x_align == self.CENTER) and (self.y_align == self.MIDDLE) then -- center middle
        if x then
            self.x = x + self.w/2
            self.y = y + self.h/2
        end
        local y_offset = 0
        for i, v in ipairs(self.holder.objects) do
            v:draw(self.x - self.w/2 + (self.w - v.w)/2, self.y - self.h/2 + y_offset)
            y_offset = y_offset + v.h
        end
    
    elseif (self.x_align == self.CENTER) and (self.y_align == self.BOTTOM) then -- center bottom
        local y_offset = 0
        for _, v in ipairs(self.holder.objects) do
            v:draw(self.x - self.w/2 + (self.w - v.w)/2, self.y - self.h + y_offset)
            y_offset = y_offset + v.h
        end
    
    elseif (self.x_align == self.RIGHT) and (self.y_align == self.TOP) then -- right top
        local y_offset = 0
        for _, v in ipairs(self.holder.objects) do
            v:draw(self.x - v.w, self.y + y_offset)
            y_offset = y_offset + v.h
        end
    
    elseif (self.x_align == self.RIGHT) and (self.y_align == self.MIDDLE) then -- right middle
        if x then
            self.x = x + self.w
            self.y = y + self.h/2
        end
        local y_offset = 0
        for i, v in ipairs(self.holder.objects) do
            v:draw(self.x - v.w, self.y - self.h/2 + y_offset)
            y_offset = y_offset + v.h
        end
    
    elseif (self.x_align == self.RIGHT) and (self.y_align == self.BOTTOM) then -- right bottom
        local y_offset = 0
        for _, v in ipairs(self.holder.objects) do
            v:draw(self.x - v.w, self.y - self.h + y_offset)
            y_offset = y_offset + v.h
        end
    end

    -- pivot debug
    if self.pivot_debug then
        graphics.circle('fill', self.x, self.y, 20, 20)
    end
    
    -- area debug
    if self.area_debug then
        graphics.set_line_width(4)
        if (self.x_align == self.LEFT) and (self.y_align == self.TOP) then
            graphics.rectangle('line', self.x, self.y, self.w, self.h)
        elseif (self.x_align == self.LEFT) and (self.y_align == self.MIDDLE) then
            graphics.rectangle('line', self.x, self.y - self.h/2, self.w, self.h)
        elseif (self.x_align == self.LEFT) and (self.y_align == self.BOTTOM) then
            graphics.rectangle('line', self.x, self.y - self.h, self.w, self.h)
        elseif (self.x_align == self.CENTER) and (self.y_align == self.TOP) then
            graphics.rectangle('line', self.x - self.w/2, self.y, self.w, self.h)
        elseif (self.x_align == self.CENTER) and (self.y_align == self.MIDDLE) then
            graphics.rectangle('line', self.x - self.w/2, self.y - self.h/2, self.w, self.h)
        elseif (self.x_align == self.CENTER) and (self.y_align == self.BOTTOM) then
            graphics.rectangle('line', self.x - self.w/2, self.y - self.h, self.w, self.h)
        elseif (self.x_align == self.RIGHT) and (self.y_align == self.TOP) then
            graphics.rectangle('line', self.x - self.w, self.y, self.w, self.h)
        elseif (self.x_align == self.RIGHT) and (self.y_align == self.MIDDLE) then
            graphics.rectangle('line', self.x - self.w, self.y - self.h/2, self.w, self.h)
        elseif (self.x_align == self.RIGHT) and (self.y_align == self.BOTTOM) then
            graphics.rectangle('line', self.x - self.w, self.y - self.h, self.w, self.h)
        end
        graphics.set_line_width(1)
    end
end


function YContainer:add(object, ...)
    local obj = self.holder:add(object, ...)
    self.w = (self.w < obj.w) and obj.w or self.w
    self.h = self.h + obj.h
    
    self.by_tag[obj.tag] = obj
    return obj
end

function YContainer:push(container)
    container.id = random:uid()
    self.holder.objects.by_id[container.id] = container
    self.holder:push(container)
    self.w = (self.w < container.w) and container.w or self.w
    self.h = self.h + container.h
end


function YContainer:set_align(x, y)
    self.x_align, self.y_align = x, y
end