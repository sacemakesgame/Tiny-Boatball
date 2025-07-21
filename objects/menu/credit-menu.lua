CreditMenu = YContainer:extend()


function CreditMenu:new(owner)
    CreditMenu.super.new(self, owner, 0, 0)
    self:set_align(YContainer.CENTER, YContainer.MIDDLE)
    self.spring = class.spring2d(width/2, height*1.25, 100, 20)
    self.timer = class.timer(self)

    self:add(Button, width / 5, height/15, 'art')
    self:add(Button, width / 5, height/15, 'sfxs')
    self:add(Button, width / 5, height/15, 'music')
    self:add(Button, width / 5, height/15, 'code')
    -- self:add(Button, width / 5, height/15, 'input remapping')
    self:add(Blank, width / 5, height/30)
    self:add(Button, width / 5, height/15, 'back')

    self.active_block = 1
    self.selected_index = nil
end


function CreditMenu:update(dt)
    self.super.update(self, dt)
    self.spring:update(dt)
    self.timer:update(dt)
end


function CreditMenu:draw()
    graphics.push()
    graphics.translate(self.spring.x, self.spring.y)
    CreditMenu.super.draw(self)
    graphics.pop()
end


function CreditMenu:process_input()
    if input:pressed('up') or input:pressed('left') then
        self.active_block = self.active_block - 1
        if self.active_block < 1 then self.active_block = #self.holder.objects end
        if self.holder.objects[self.active_block]:is(Blank) then self.active_block = self.active_block - 1 end
        self.holder.objects[self.active_block]:boing(.05)
        self.owner.sound:play('oreo')
        self:view_credit()
    elseif input:pressed('down') or input:pressed('right') then
        self.active_block = self.active_block + 1
        if self.active_block > #self.holder.objects then self.active_block = 1 end
        if self.holder.objects[self.active_block]:is(Blank) then self.active_block = self.active_block + 1 end
        if self.active_block > #self.holder.objects then self.active_block = 1 end
        self.holder.objects[self.active_block]:boing(.05)
        self.owner.sound:play('oreo')
        self:view_credit()
    elseif input:pressed('enter') then
        if self:is_button('back') then
            self.holder.objects[self.active_block]:animate_pressed()
        elseif self:is_button('sfxs') then
            love.system.openURL('https://freesound.org/')
        elseif self:is_button('music') then
            love.system.openURL('https://www.youtube.com/user/HeatleyBros')
        elseif self:is_button('art') or self:is_button('code') then
            love.system.openURL('https://x.com/sacemakesgame')
        end
    elseif input:released('enter') then
        if self:is_button('back') then -- back
            self.owner.sound:play('oreo')
            self.holder.objects[self.active_block]:animate_released()
            self.owner.type = TYPE.MAIN
            self.owner.eye.target:set(0, 0, 0)
            self:exit()
            self.owner.main_menu:enter(3)
        end
    elseif input:pressed('back') then
        self.owner.type = TYPE.MAIN
        self.owner.eye.target:set(0, 0, 0)
        self:exit()
        self.owner.main_menu:enter(3)
    end
end


function CreditMenu:set_active()
    self.holder.objects[self.active_block].active = true        
end


function CreditMenu:enter()
    self.timer:tween(1, self.owner.eye.offset, {y = 20 * 1.7, z = 60 * 1.7}, math.cubic_in_out, nil, 'eye-offset')
    self.active_block = 6
    self.spring:animate(width/2, height * 8/10)
    self.owner.chat_holder:add(BubbleChat, vec2(width/2, height/2), 'a game by SaceMakesGame')
end


function CreditMenu:exit()
    save_options_data()
    self.timer:tween(1, self.owner.eye.offset, {y = 30 * 1.7, z = 40 * 1.7}, math.cubic_in_out, nil, 'eye-offset')
    self.spring:animate(width/2, height*1.25)
    for _, v in ipairs(self.owner.chat_holder.objects) do
        v:exit()
    end
end


function CreditMenu:is_button(tag)
    return self.holder.objects[self.active_block].tag == tag
end


function CreditMenu:view_credit()
    for _, v in ipairs(self.owner.chat_holder.objects) do
        v:exit()
    end
    if self:is_button('art') then
        self.owner.chat_holder:add(BubbleChat, vec2(width/2, height/2), 'art by SaceMakesGame')
    elseif self:is_button('sfxs') then
        self.owner.chat_holder:add(BubbleChat, vec2(width/2, height/2), 'sfxs from freesound.org')    
    elseif self:is_button('music') then
        local padding = 150 * scale
        self.owner.chat_holder:add(BubbleChat, vec2(width/2, height/2 - padding * 1.3), 'music by HeatleyBros:')
        self.owner.chat_holder:add(BubbleChat, vec2(width/2, height/2), '- Brassy Jazz')
        self.owner.chat_holder:add(BubbleChat, vec2(width/2, height/2 + padding), '- Play It Cool')
    elseif self:is_button('code') then
        self.owner.chat_holder:add(BubbleChat, vec2(width/2, height/2), 'code by SaceMakesGame (with help of buncha cool guys!)')    
    end
end