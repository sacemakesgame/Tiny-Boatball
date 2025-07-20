OptionsMenu = YContainer:extend()


function OptionsMenu:new(owner)
    OptionsMenu.super.new(self, owner, 0, 0)
    self:set_align(YContainer.CENTER, YContainer.MIDDLE)
    self.spring = class.spring2d(width/2, height*1.25, 100, 20)
    self.timer = class.timer(self)

    self:add(ResolutionButton, width / 5, height/15, 'resolution')
    self:add(AspectRatioButton, width / 5, height/15, 'aspect ratio')
    self:add(FullscreenButton, width / 5, height/15, 'fullscreen')
    self:add(SfxButton, width / 5, height/15, 'sound effects')
    -- self:add(Button, width / 5, height/15, 'input remapping')
    self:add(Blank, width / 5, height/30)
    self:add(Button, width / 5, height/15, 'back')

    self.active_block = 1
    self.selected_index = nil
end


function OptionsMenu:update(dt)
    self.super.update(self, dt)
    self.spring:update(dt)
    self.timer:update(dt)
end


function OptionsMenu:draw()
    graphics.push()
    graphics.translate(self.spring.x, self.spring.y)
    OptionsMenu.super.draw(self)
    graphics.pop()
end


function OptionsMenu:process_input()
    if input:pressed('up') then
        self.active_block = self.active_block - 1
        if self.active_block < 1 then self.active_block = #self.holder.objects end
        if self.holder.objects[self.active_block]:is(Blank) then self.active_block = self.active_block - 1 end
        self.holder.objects[self.active_block]:boing(.05)
        self.owner.sound:play('oreo')
    elseif input:pressed('down') then
        self.active_block = self.active_block + 1
        if self.active_block > #self.holder.objects then self.active_block = 1 end
        if self.holder.objects[self.active_block]:is(Blank) then self.active_block = self.active_block + 1 end
        if self.active_block > #self.holder.objects then self.active_block = 1 end
        self.holder.objects[self.active_block]:boing(.05)
        self.owner.sound:play('oreo')
    elseif input:pressed('left') then
        if self.holder.objects[self.active_block].switch_left then
            self.holder.objects[self.active_block]:switch_left()
        end
    elseif input:pressed('right') then
        if self.holder.objects[self.active_block].switch_right then
            self.holder.objects[self.active_block]:switch_right()         
        end
    elseif input:pressed('enter') then
        if self:is_button('back') then -- back
            self.holder.objects[self.active_block]:animate_pressed()
        -- gotta animate some no-wiggle thing
        elseif self:is_button('resolution') or self:is_button('aspect ratio') or self:is_button('fullscreen') or self:is_button('input remapping') or self:is_button('sound effects') then
            self.holder.objects[self.active_block]:head_shake()
            self.owner.sound:play('blunder-snare')
        end
    elseif input:released('enter') then
        if self:is_button('back') then -- back
            self.owner.sound:play('oreo')
            self.holder.objects[self.active_block]:animate_released()
            self.owner.type = TYPE.MAIN
            self.owner.eye.target:set(0, 0, 0)
            self:exit()
            self.owner.main_menu:enter(2)
        end
    elseif input:pressed('back') then
        self.owner.type = TYPE.MAIN
        self.owner.eye.target:set(0, 0, 0)
        self:exit()
        self.owner.main_menu:enter(2)
    end
end


function OptionsMenu:set_active()
    self.holder.objects[self.active_block].active = true        
end


function OptionsMenu:enter(active)
    -- self.timer:tween(1, self.owner.eye.offset, {y = 20, z = 10}, math.cubic_in_out, nil, 'eye-offset')
    self.timer:tween(1, self.owner.eye.offset, {y = 20 * 1.7, z = 10 * 1.7}, math.cubic_in_out, nil, 'eye-offset')
    self.owner.eye.target:set(0, 0, 0)
    self.active_block = active or 1
    self.spring:animate(width/2, height * 7.5/10)
end


function OptionsMenu:exit()
    save_options_data()
    -- self.timer:tween(1, self.owner.eye.offset, {y = 30, z = 40}, math.cubic_in_out, nil, 'eye-offset')
    self.timer:tween(1, self.owner.eye.offset, {y = 30 * 1.7, z = 40 * 1.7}, math.cubic_in_out, nil, 'eye-offset')
    self.spring:animate(width/2, height*1.25)
end


function OptionsMenu:is_button(tag)
    return self.holder.objects[self.active_block].tag == tag
end