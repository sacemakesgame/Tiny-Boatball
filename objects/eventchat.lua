EventChat = Object:extend()


function EventChat:new(owner, position, table_text, hold_dur, tick)
    self.owner = owner
    self.timer = class.timer(self)
    self.spring = class.spring(1)
    self.position = position
    self.scale = 1
    
    self.texts = table_text
    --[[ like, 
    { 'G', 'O', 'A', 'L', '!' }
    ]]

    local text_width = self.owner.font:getWidth(table.concat(self.texts)) * self.scale / .5
    -- local text_width = self.owner.font:getWidth('TIMESUP!!') * self.scale / .5
    local from = -text_width/2

    self.tick = tick or .25 -- time gap duration per BubbleChat
    self.total_dur = self.tick * #self.texts + (hold_dur or 0)
    self.i = 1

    self.timer:every_immediate(self.tick, function()
        local character_width = self.owner.font:getWidth(self.texts[self.i]) * self.scale / .5
        from = from + character_width/2
        local bubble = self.owner.chat_holder:add(BubbleChat, vec2(self.position.x + from, self.position.y), self.texts[self.i], nil, self.total_dur - (self.tick * (self.i-1)), self.scale)
        bubble.rotate_spring:pull(math.pi/2)
        from = from + character_width/2
        -- from = from + self.owner.font:getWidth(self.texts[self.i]) * self.scale / .5
        self.i = self.i + 1
    end, #self.texts)
end

function EventChat:update(dt)
    self.timer:update(dt)
    self.spring:update(dt)
end

function EventChat:draw()    
end