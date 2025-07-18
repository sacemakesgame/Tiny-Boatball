QuickMatchMenu = YContainer:extend()


function QuickMatchMenu:new(owner)
    QuickMatchMenu.super.new(self, owner, 0, 0)
    self:set_align(YContainer.CENTER, YContainer.TOP)
    self.spring = class.spring2d(-width/2, height*1/3, 100, 20)
    self.timer = class.timer(self)
    
    self:add(CharacterButton, width/5, height/20, 'keeper')
    self:add(CharacterButton, width/5, height/20, 'outfield')
    self:add(CharacterButton, width/5, height/20, 'outfield')
    self:add(CharacterButton, width/5, height/20, 'outfield')
    self:add(Blank, width / 5, height/20)
    -- self.start_button = self:add(Button, width / 5, height/20, 'start')

    self.active_block = QUICKMATCH_CHARACTER_LIST.player_index
    self.selected_index = nil

    -- load last character_list
    self.holder.objects[1]:set_active_character(QUICKMATCH_CHARACTER_LIST.ally.keeper)
    for i = 2, 4 do
        self.holder.objects[i]:set_active_character(QUICKMATCH_CHARACTER_LIST.ally.outfields[i-1])
    end
end


function QuickMatchMenu:update(dt)
    self.super.update(self, dt)
    self.timer:update(dt)
    self.spring:update(dt)

    -- self.owner.character_display:set_character(self.holder.objects[self.active_block]:get())
end


function QuickMatchMenu:draw()
    graphics.push()
    graphics.translate(self.spring.x, self.spring.y)
    QuickMatchMenu.super.draw(self)
    graphics.pop()
end


function QuickMatchMenu:process_input(key)
    if self.is_transitioning then return end  -- hacky, but working solution :)
    
    if key == 'up' or key == 'w' then
        if self.selected_index then
            self.active_block = self.selected_index
            self.holder.objects[self.selected_index]:switch_left()
            self.owner.character_display:set_character(self.holder.objects[self.active_block]:get())
        else
            self.active_block = self.active_block - 1
            if self.active_block < 1 then self.active_block = #self.holder.objects end
            if self.holder.objects[self.active_block]:is(Blank) then self.active_block = self.active_block - 1 end
            self.owner.character_display:set_character(self.holder.objects[self.active_block]:get())
        end
    elseif key == 'down' or key == 's' then
        if self.selected_index then
            self.active_block = self.selected_index
            self.holder.objects[self.selected_index]:switch_right()
            self.owner.character_display:set_character(self.holder.objects[self.active_block]:get())
        else
            self.active_block = self.active_block + 1
            if self.active_block > #self.holder.objects then self.active_block = 1 end
            if self.holder.objects[self.active_block]:is(Blank) then self.active_block = self.active_block + 1 end
            if self.active_block > #self.holder.objects then self.active_block = 1 end
            self.owner.character_display:set_character(self.holder.objects[self.active_block]:get())
        end
    elseif key == 'left' or key == 'a' then
        if (self.active_block >= 1 and self.active_block <= 4) then
            self.holder.objects[self.active_block]:switch_left()
            self.owner.character_display:set_character(self.holder.objects[self.active_block]:get())
        else
            self.active_block = self.selected_index
        end
    elseif key == 'right' or key == 'd' then
        if (self.active_block >= 1 and self.active_block <= 4) then
            self.holder.objects[self.active_block]:switch_right()
            self.owner.character_display:set_character(self.holder.objects[self.active_block]:get())
        else
            self.active_block = self.selected_index
        end
    elseif key == 'return' then
        if self.selected_index then
            if not (self.active_block == 6) then
                self.active_block = 6
            else
                self.is_transitioning = true -- hacky, but working solution :)
                self.owner.eye.target:set(0, 0, 0)
                self.owner.timer:tween(1.5, self.owner.eye.offset, {z = 1, y = 1}, math.cubic_in_out)
                -- local t = {
                --     opponent = {
                --         keeper = 'frog',
                --         outfields = {'frog', 'axolotl', 'axolotl', 'axolotl'},
                --     },
                --     ally = {
                --         keeper = 'axolotl',
                --         outfields = {'frog', 'frog', 'frog'},
                --     },
                --     player = 'axolotl',
                -- }
                -- local selected = self.holder.objects[self.selected_index]
                -- if selected.tag == 'keeper' then
                    
                -- end
                -- self.character_list.player = self.holder.objects[self.selected_index]:get()
                -- local t = {}
                -- t.ally = {}
                -- t.ally.outfields = {}
                -- t.opponent = {}
                -- t.opponent.keeper = 'frog'
                -- t.opponent.outfields = {'frog', 'axolotl', 'axolotl'}
                -- for i = 1, 4 do
                --     local character = self.holder.objects[i]
                --     if (i == self.selected_index) then
                --         t.player = character:get()
                --     else
                --         if character.tag == 'keeper' then
                --             t.ally.keeper = character:get()
                --         else
                --             table.insert(t.ally.outfields, character:get())
                --         end
                --     end
                    
                -- end
                -- QUICKMATCH_CHARACTER_LIST = t -- store it to global variable
                -- QUICKMATCH_CHARACTER_LIST.ally.keeper = t.ally.keeper or t.player
                -- QUICKMATCH_CHARACTER_LIST.ally.outfields = {}
                
                QUICKMATCH_CHARACTER_LIST.ally.keeper = self.holder.objects[1]:get()
                for i = 2, 4 do
                    QUICKMATCH_CHARACTER_LIST.ally.outfields[i-1] = self.holder.objects[i]:get()
                end
                QUICKMATCH_CHARACTER_LIST.player_index = self.selected_index

                -- opponents
                QUICKMATCH_CHARACTER_LIST.opponent.keeper = 'frog'
                QUICKMATCH_CHARACTER_LIST.opponent.outfields = {'frog', 'axolotl', 'axolotl'}

                self.timer:after(.5, function()
                    tool:switch(Stage, TYPE.QUICKMATCH)
                end)
            end
        else
            if (self.active_block >= 1 and self.active_block <= 4) then
                self.holder.objects[self.active_block].selected = true
                self.selected_index = self.active_block
                -- add start button
                self.start_button = self:add(Button, width / 5, height/20, 'start')
                self.active_block = 6
            end
        end
    elseif key == 'escape' then
        if self.selected_index then
            if (self.active_block == 6) then
                self.active_block = self.selected_index
            else
                self.holder.objects[self.selected_index].selected = false
                self.selected_index = nil
                -- remove start butto
                self.start_button.dead = true
                self.start_button = nil
            end
        else
            self.owner.type = TYPE.MAIN
            self.owner.eye.target:set(0, 0, 0)
            self:exit()
            self.owner.main_menu:enter(2)
        end
    end
end

function QuickMatchMenu:set_active()
    assert(self.holder.objects[self.active_block], self.active_block)
    self.holder.objects[self.active_block].active = true        
end


function QuickMatchMenu:enter()
    self.active_block = QUICKMATCH_CHARACTER_LIST.player_index
    self.spring:animate(width*1/3, height*1/3)
    self.owner.character_display:enter()
    self.owner.character_display:set_character(self.holder.objects[self.active_block]:get())
end


function QuickMatchMenu:exit()
    QUICKMATCH_CHARACTER_LIST.player_index = self.active_block
    self.spring:animate(-width/2, height*1/3)
    self.owner.character_display:exit()
end