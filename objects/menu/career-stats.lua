CareerStats = YContainer:extend()


function CareerStats:new(owner)
    CareerStats.super.new(self, owner, 0, 0)
    self:set_align(YContainer.CENTER, YContainer.TOP)
    self.spring = class.spring2d(width/2, height*2, 100, 20)
    self.blue_stats_spring = class.spring2d(width/2 - width/2, height*2.25/4, 100, 20)
    self.red_stats_spring = class.spring2d(width/2 + width/2, height*2.25/4, 100, 20)
    self.timer = class.timer(self)
    
    self.action_button = self:add(Button, width/5, height/20, 'rematch')
    self:add(Button, width/5, height/20, 'home')

    self.active_block = 1
end



function CareerStats:update(dt)
    self.super.update(self, dt)
    self.spring:update(dt)
    self.blue_stats_spring:update(dt)
    self.red_stats_spring:update(dt)
    self.timer:update(dt)
end


function CareerStats:draw()
    --[[
    -- stats thing
    graphics.push()
    graphics.translate(self.blue_stats_spring.x, self.blue_stats_spring.y)

    local xpadding = 250 * scale
    local ypadding = 100 * scale
    for i = 1, 4 do
        local dude = gamestate.current().ally_holder.objects[i]
        -- shadow
        graphics.set_color(color.palette.dark)
        graphics.capsule('fill', (5-i) * -xpadding + xpadding/2, -ypadding/1.5 + 10 * scale, 200 * scale, 100 * scale, true, .3)
        graphics.capsule('fill', (5-i) * -xpadding + xpadding/2, ypadding/2 + 10 * scale, 100 * scale, 200 * scale, true, .2)
        -- background
        graphics.set_color(color.palette.ally)
        graphics.capsule('fill', (5-i) * -xpadding + xpadding/2, -ypadding/1.5, 200 * scale, 100 * scale, true, .3)
        graphics.capsule('fill', (5-i) * -xpadding + xpadding/2, ypadding/2, 100 * scale, 200 * scale, true, .2)
        graphics.white()
        if i == CAREER_CHARACTER_LIST.player_index then
            graphics.push_rotate_scale((5-i) * -xpadding + xpadding/2, -ypadding*1.3, math.sin(love.timer.getTime() * 2) * math.pi/20, 1, 1, true)
            graphics.capsule('fill', 0, 0, 110 * scale, 55 * scale, true, .3)
            graphics.pop()
        end
        -- text
        graphics.set_color(color.palette.dark)
        if i == CAREER_CHARACTER_LIST.player_index then
            graphics.push_rotate_scale((5-i) * -xpadding + xpadding/2, -ypadding*1.3, math.sin(love.timer.getTime() * 2) * math.pi/20, 1, 1, true)
            graphics.printmid('(you!)', 0, 0, 0, .25)
            graphics.pop()
        end
        graphics.white()
        graphics.printmid(dude.character, (5-i) * -xpadding + xpadding/2, -ypadding/1.5, 0, .3)
        graphics.printmid(dude.goal_count == 0 and '-' or dude.goal_count, (5-i) * -xpadding + xpadding/2, 0, 0, .4)
        graphics.printmid(dude.blunder_count == 0 and '-' or dude.blunder_count, (5-i) * -xpadding + xpadding/2, ypadding, 0, .4)
    end

    graphics.pop()

    graphics.push()
    graphics.translate(self.red_stats_spring.x, self.red_stats_spring.y)
    
    for i = 1, 4 do
        local dude = gamestate.current().opponent_holder.objects[i]
        -- shadow
        graphics.set_color(color.palette.dark)
        graphics.capsule('fill', (5-i) * xpadding - xpadding/2, -ypadding/1.5 + 10 * scale, 200 * scale, 100 * scale, true, .3)
        graphics.capsule('fill', (5-i) * xpadding - xpadding/2, ypadding/2 + 10 * scale, 100 * scale, 200 * scale, true, .2)
        -- background
        graphics.set_color(color.palette.opponent)
        graphics.capsule('fill', (5-i) * xpadding - xpadding/2, -ypadding/1.5, 200 * scale, 100 * scale, true, .3)
        graphics.capsule('fill', (5-i) * xpadding - xpadding/2, ypadding/2, 100 * scale, 200 * scale, true, .2)
        -- text
        graphics.white()
        graphics.printmid(dude.character, (5-i) * xpadding - xpadding/2, -ypadding/1.5, 0, .3)
        graphics.printmid(dude.goal_count == 0 and '-' or dude.goal_count, (5-i) * xpadding - xpadding/2, 0, 0, .4)
        graphics.printmid(dude.blunder_count == 0 and '-' or dude.blunder_count, (5-i) * xpadding - xpadding/2, ypadding, 0, .4)
    end

    graphics.pop()

    -- buttons
    graphics.push()
    graphics.translate(self.spring.x, self.spring.y)
    CareerStats.super.draw(self)
    graphics.pop()

    ]]
end


function CareerStats:process_input()
    if self.is_transitioning then return end  -- hacky, but working solution :)

    if input:pressed('up') or input:pressed('left') then
        self.active_block = self.active_block - 1
        if self.active_block < 1 then self.active_block = #self.holder.objects end
        self.holder.objects[self.active_block]:boing(.1)
        self.owner.sound:play('oreo')
    elseif input:pressed('down') or input:pressed('right') then
        self.active_block = self.active_block + 1
        if self.active_block > #self.holder.objects then self.active_block = 1 end
        self.holder.objects[self.active_block]:boing(.1)
        self.owner.sound:play('oreo')
    elseif input:pressed('enter') then
        self.is_transitioning = true -- hacky, but working solution :)
        if self:is_button('next') or self:is_button('rematch') then
            self.holder.objects[self.active_block]:boing(.1)
            self.owner.sound:play('oreo')
            tool:switch(Stage, TYPE.CAREER)
        elseif self:is_button('try again') then
            self.holder.objects[self.active_block]:boing(.1)
            self.owner.sound:play('oreo')
            tool:switch(Home, TYPE.CAREER)
        elseif self:is_button('home') then -- home
            self.holder.objects[self.active_block]:boing(.1)
            self.owner.sound:play('oreo')
            tool:switch(Home, TYPE.MAIN)
        end
        -- if self.active_block == 1 then
        --     self.is_transitioning = true -- hacky, but working solution :)
        --     -- tool:switch(Home, TYPE.CAREER)
        --     if self.action_button.tag == 'next' then
        --         self.owner.sound:play('oreo')
        --         tool:switch(Stage, TYPE.CAREER)
        --     elseif self.action_button.tag == 'try again' then
        --         self.owner.sound:play('oreo')
        --         tool:switch(Home, TYPE.CAREER)
        --     elseif self.action_button.tag == 'rematch' then
        --         self.owner.sound:play('oreo')
        --         tool:switch(Stage, TYPE.CAREER)
        --     end
        -- elseif self.active_block == 2 then -- home
        --     tool:switch(Home, TYPE.MAIN)
        -- end
    end
end
-- function CareerStats:process_input(key)
--     if self.is_transitioning then return end  -- hacky, but working solution :)

--     if key == 'up' or key == 'w' or key == 'left' or key == 'a' then
--         self.active_block = self.active_block - 1
--         if self.active_block < 1 then self.active_block = #self.holder.objects end
--     elseif key == 'down' or key == 's' or key == 'right' or key == 'd' then
--         self.active_block = self.active_block + 1
--         if self.active_block > #self.holder.objects then self.active_block = 1 end

--     elseif key == 'return' then
--         if self.active_block == 1 then
--             self.is_transitioning = true -- hacky, but working solution :)
--             -- tool:switch(Home, TYPE.CAREER)
--             if self.action_button.tag == 'next' then
--                 tool:switch(Stage, TYPE.CAREER)
--             elseif self.action_button.tag == 'try again' then
--                 tool:switch(Home, TYPE.CAREER)
--             elseif self.action_button.tag == 'rematch' then
--                 tool:switch(Stage, TYPE.CAREER)
--             end
--         elseif self.active_block == 2 then -- home
--             tool:switch(Home, TYPE.MAIN)
--         end
--     end
-- end

function CareerStats:set_active()
    self.holder.objects[self.active_block].active = true
end


function CareerStats:enter(status)
    self.active_block = 1
    self.spring:animate(width/2, height * 8.5/10)
    self.blue_stats_spring:animate(width/2, height*2.25/4)
    self.red_stats_spring:animate(width/2, height*2.25/4)

    if CAREER_MATCH_COUNTER >= 5 then
        -- self.a    
    end

    if status == 'win' then
        self.action_button.tag = 'next'
    elseif status == 'lose' then
        self.action_button.tag = 'try again'
    elseif status == 'draw' then
        self.action_button.tag = 'rematch'
    end
end


function CareerStats:exit()
    self.blue_stats_spring:animate(width/2 - width/2, height*2.25/4)
    self.red_stats_spring:animate(width/2 + width/2, height*2.25/4)
end

function CareerStats:is_button(tag)
    return self.holder.objects[self.active_block].tag == tag
end