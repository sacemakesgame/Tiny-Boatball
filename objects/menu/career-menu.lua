CareerMenu = YContainer:extend()


function CareerMenu:new(owner)
    CareerMenu.super.new(self, owner, 0, 0)
    self:set_align(YContainer.CENTER, YContainer.TOP)
    self.spring = class.spring2d(-width/2, height*.4, 100, 20)
    self.timer = class.timer(self)
    
    self.arrow_up = self:add(ArrowIcon, height/30, height/30, 0)
    self:add(CareerCharacterButton, width/5, height/12.5, 'keeper')
    self:add(CareerCharacterButton, width/5, height/12.5, 'outfield')
    self:add(CareerCharacterButton, width/5, height/12.5, 'outfield')
    self:add(CareerCharacterButton, width/5, height/12.5, 'outfield')
    self.arrow_down = self:add(ArrowIcon, height/30, height/30, math.pi)
    self:add(Blank, width/5, height/20)

    self.active_block = 2
    self.selected_index = nil

    self:randomize_guys()

    local diagonalLength = width + height
    self.curtain_spacing = width/7
    self.curtain_count = math.ceil(diagonalLength / self.curtain_spacing)
    self.curtain_percentage = {}
    for i = -self.curtain_count, self.curtain_count do
        self.curtain_percentage[i] = 0
    end
end


function CareerMenu:update(dt)
    self.super.update(self, dt)
    self.timer:update(dt)
    self.spring:update(dt)
end


function CareerMenu:draw()
    graphics.push()
    graphics.translate(self.spring.x, self.spring.y)
    graphics.rotate(math.sin(love.timer.getTime()) * math.pi/200)
    graphics.translate(-self.spring.x, -self.spring.y)

    -- "choose one"
    graphics.push()
    graphics.set_color(color.palette.dark)
    graphics.translate(self.spring.x, self.spring.y - 150 * scale)
    graphics.rotate(math.sin(love.timer.getTime() * 10) * math.pi/100)
    graphics.scale(self.arrow_up.spring.x + self.arrow_down.spring.x - 1)
    local w = width/5
    local h = height/12.5*4 + height/30*2
    local thickness = 1 * scale
    for i = 0, math.pi*2, math.pi/8 do
        graphics.printmid('choose one!', math.cos(i) * thickness, math.sin(i) * thickness, 0, .4)
    end
    graphics.pop()
    graphics.printmid('(enter to confirm)', self.spring.x, self.spring.y - 150 * scale + 75 * scale, 0, .2 + (self.arrow_up.spring.x + self.arrow_down.spring.x - 2) * .25)
    
    -- "back" text info
    graphics.push()
    graphics.set_color(color.palette.dark)
    graphics.translate(self.spring.x, 0)
    graphics.print('(esc) to back', -800 * scale, height - 100 * scale, 0, .3)
    graphics.pop()


    graphics.capsule('fill', self.spring.x, self.spring.y + h/2, w * 2, h * 1.1, true, .1)
    graphics.push()
    graphics.translate(self.spring.x, self.spring.y)
    CareerMenu.super.draw(self)
    graphics.white()
    graphics.pop()
    
    graphics.pop()
end


function CareerMenu:draw_curtain()
    graphics.set_line_width(width/7)

    local colors = {color.palette.light, color.palette.wall}    
    for i = -self.curtain_count, self.curtain_count do
        local curtain_offset = math.remap(self.curtain_percentage[i], 0, 1, -.5, 1)
        local offset = i * self.curtain_spacing

        local x1, y1 = (love.timer.getTime()*50) % self.curtain_spacing*2 + math.remap(curtain_offset, -.5, 1, 0, 1) * offset, -self.curtain_spacing/2
        local x2, y2 = (love.timer.getTime()*50) % self.curtain_spacing*2 + offset - height, (height +self.curtain_spacing/2) * curtain_offset

        -- Alternate colors
        graphics.set_color(colors[(i % 2 == 0) and 1 or 2])
        love.graphics.line(x1, y1, x2, y2)
        graphics.circle('fill', x1, y1, self.curtain_spacing)
        graphics.circle('fill', x2, y2, self.curtain_spacing)
    end

    graphics.white()
end

function CareerMenu:process_input()
    if self.is_transitioning then return end  -- hacky, but working solution :)
    
    if input:pressed('up') or input:pressed('left') then
        self.owner.sound:play('oreo')
        if self.selected_index then
            -- self.active_block = self.selected_index
            -- self.holder.objects[self.selected_index]:switch_left()
            -- self.owner.character_display:set_character(self.holder.objects[self.active_block]:get())
            self.active_block = self.selected_index
            self.holder.objects[self.selected_index].selected = false
            self.selected_index = nil
            -- remove start butto
            self.start_button.dead = true
            self.start_button = nil
        else
            self.arrow_up:boing()
            self.active_block = self.active_block - 1
            while (self.holder.objects[self.active_block]:is(Blank)) do
                self.active_block = self.active_block - 1
                if self.active_block < 1 then self.active_block = #self.holder.objects end
            end
            self.holder.objects[self.active_block]:boing(.1)
            self.owner.character_display:set_character(self.holder.objects[self.active_block]:get())
        end
    elseif input:pressed('down') or input:pressed('right') then
        self.owner.sound:play('oreo')
        if self.selected_index then
            -- self.active_block = self.selected_index
            -- self.holder.objects[self.selected_index]:switch_right()
            -- self.owner.character_display:set_character(self.holder.objects[self.active_block]:get())
            self.active_block = self.selected_index
            self.holder.objects[self.selected_index].selected = false
            self.selected_index = nil
            -- remove start button
            self.start_button.dead = true
            self.start_button = nil
        else
            self.arrow_down:boing()
            self.active_block = self.active_block + 1
            if self.active_block > #self.holder.objects then self.active_block = 1 end
            while (self.holder.objects[self.active_block]:is(Blank)) do
                self.active_block = self.active_block + 1
                if self.active_block > #self.holder.objects then self.active_block = 1 end
            end
            self.holder.objects[self.active_block]:boing(.1)
            self.owner.character_display:set_character(self.holder.objects[self.active_block]:get())
        end
    elseif input:pressed('enter') then
        self.owner.sound:play('oreo')
        if self.selected_index then
            if not self:is_button('START!') then
                self.active_block = 8
            else
                self.is_transitioning = true -- hacky, but working solution :)
                self.owner.eye.target:set(0, 0, 0)
                self.owner.timer:tween(1.5, self.owner.eye.offset, {z = 1, y = 1}, math.cubic_in_out)

                for i = 1, 4 do
                    CAREER_CHARACTER_LIST.ally[i] = self.holder.objects[i+1]:get()
                end
                CAREER_CHARACTER_LIST.player_index = self.selected_index -1 -- minus 1 cuz it stats from 2

                local i = 1
                self.timer:every_immediate(.1, function()
                    i = i - .18
                    self.owner.sound:set_volume('music', i)
                end, 5)
                self.timer:after(.5, function()
                    tool:switch(Stage, TYPE.CAREER)
                end)
            end
        else
            if (self.active_block >= 2 and self.active_block <= 5) then
                self.holder.objects[self.active_block].selected = true
                self.selected_index = self.active_block
                -- add start button
                self.start_button = self:add(Button, width/5, height/10, 'START!')
                self.start_button:boing(.2)
                self.active_block = 8
            end
        end

    elseif input:pressed('back') then
        if self.selected_index then
            self.active_block = self.selected_index
            self.holder.objects[self.selected_index].selected = false
            self.selected_index = nil
            -- remove start button
            self.start_button.dead = true
            self.start_button = nil
        else
            self.owner.type = TYPE.MAIN
            self.owner.eye.target:set(0, 0, 0)
            self:exit()
            self.owner.main_menu:enter(1)
        end
    end
end


function CareerMenu:set_active()
    assert(self.holder.objects[self.active_block], self.active_block)
    self.holder.objects[self.active_block].active = true        
end


function CareerMenu:enter()
    self.owner.sound:set_volume('sfx', 0) -- yea, noisy as hell

    self.owner.eye.target:set(-15, 0, -15)
    self.active_block = 2
    self.spring:animate(width*1/3, height*.4)
    -- self.spring:animate(width*1/3, height*.4)
    self.owner.character_display:enter()
    
    -- self:randomize_guys()
    self.owner.character_display:set_character(self.holder.objects[self.active_block]:get())

    for i = -self.curtain_count, self.curtain_count do
        self.timer:tween((math.abs(i)/self.curtain_count*2) * .75, self.curtain_percentage, {[i] = 1}, math.cubic_out, nil, tostring(i))
    end
    
    self.owner.outline.shader:send("outlineColor", color.palette.floor)
end


function CareerMenu:exit()
    self.owner.sound:set_volume('sfx', 1)

    self.spring:animate(-width/2, height*.4)
    self.owner.character_display:exit()
    for i = -self.curtain_count, self.curtain_count do
        self.timer:tween((math.abs(i)/self.curtain_count*2) * .5, self.curtain_percentage, {[i] = 0}, math.cubic_out, nil, tostring(i))
    end

    self.owner.outline.shader:send("outlineColor", color.palette.dark)
end


function CareerMenu:randomize_guys()
    local list 
    local index = CAREER_PROGRESSION_INDEX
    if index == 1 then        
        list = random:chance_list({'axolotl', 1})
    elseif index == 2 then
        list = random:chance_list({'axolotl', 1}, {'frog', 1})
    elseif index == 3 then
        list = random:chance_list({'snail', 1}, {'axolotl', 1}, {'frog', 1})
    elseif index == 4 then
        list = random:chance_list({'axolotl', 2}, {'frog', 2}, {'snail', 2}, {'worm', 2})
    elseif index == 5 then
        list = random:chance_list({'axolotl', 2}, {'frog', 2}, {'snail', 2}, {'worm', 2}, {'pelican', 2})
    end
    
    for i = 2, 5 do
        self.holder.objects[i]:set_active_character(list:pop())
    end
end


function CareerMenu:is_button(tag)
    return self.holder.objects[self.active_block].tag == tag
end