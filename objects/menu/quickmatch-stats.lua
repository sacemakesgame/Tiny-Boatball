QuickMatchStats = YContainer:extend()



function QuickMatchStats:new(owner)
    QuickMatchStats.super.new(self, owner, 0, 0)
    self:set_align(YContainer.CENTER, YContainer.TOP)
    self.spring = class.spring2d(width/2, height*2, 100, 20)
    
    self:add(Button, width/5, height/20, 'rematch')
    self:add(Button, width/5, height/20, 'home')

    self.active_block = 1
end



function QuickMatchStats:update(dt)
    self.super.update(self, dt)
    self.spring:update(dt)
end


function QuickMatchStats:draw()
    graphics.push()
    graphics.translate(self.spring.x, self.spring.y)
    QuickMatchStats.super.draw(self)
    graphics.pop()
end


function QuickMatchStats:process_input(key)
    if key == 'up' or key == 'w' or key == 'left' or key == 'a' then
        self.active_block = self.active_block - 1
        if self.active_block < 1 then self.active_block = #self.holder.objects end
    elseif key == 'down' or key == 's' or key == 'right' or key == 'd' then
        self.active_block = self.active_block + 1
        if self.active_block > #self.holder.objects then self.active_block = 1 end

    elseif key == 'return' then
        if self.active_block == 1 then -- rematch
            -- tool:switch(Stage, gamestate.current().character_list)
            tool:switch(Home, TYPE.QUICKMATCH)
        elseif self.active_block == 2 then -- home
            tool:switch(Home, TYPE.MAIN)
        end
    end
end

function QuickMatchStats:set_active()
    self.holder.objects[self.active_block].active = true        
end


function QuickMatchStats:enter()
    self.active_block = 1
    self.spring:animate(width/2, height * 8.5/10)
end


function QuickMatchStats:exit()
    self.spring:animate(width/2, height*2)
end