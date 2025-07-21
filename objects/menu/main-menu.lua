MainMenu = YContainer:extend()


function MainMenu:new(owner)
    MainMenu.super.new(self, owner, 0, 0)
    self:set_align(YContainer.CENTER, YContainer.MIDDLE)
    self.spring = class.spring2d(width/2, height * 1.25, 100, 20)

    self:add(Button, width / 5, height/15, 'play')
    self:add(Button, width / 5, height/15, 'options')
    self:add(Button, width / 5, height/15, 'credits')
    self:add(Button, width / 5, height/15, 'quit')

    self.active_block = 1
end


function MainMenu:update(dt)
    self.super.update(self, dt)
    self.spring:update(dt)
end


function MainMenu:draw()
    graphics.push()
    graphics.translate(self.spring.x, self.spring.y)
    MainMenu.super.draw(self)
    graphics.pop()
end


function MainMenu:process_input()
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
        self.holder.objects[self.active_block]:animate_pressed()
    elseif input:released('enter') then
        self.owner.sound:play('oreo')
        self.holder.objects[self.active_block]:animate_released()
        if self:is_button('play') then
            self.owner.type = TYPE.CAREER
            self:exit()
            self.owner.career_menu:enter()
        elseif self:is_button('options') then
            self.owner.type = TYPE.OPTIONS
            self:exit()
            self.owner.options_menu:enter()
        elseif self:is_button('credits') then
            self.owner.type = TYPE.CREDIT
            self:exit()
            self.owner.credit_menu:enter()
        elseif self:is_button('quit') then
            love.event.quit()
        end
    end
end

function MainMenu:set_active()
    self.holder.objects[self.active_block].active = true        
end


function MainMenu:enter(active_block)
    self.owner.eye.target:set(0, 0, 0)
    self.active_block = active_block
    self.spring:animate(width/2, height * 8.5/10)
end


function MainMenu:exit()
    self.spring:animate(width/2, height * 1.25)
end


function MainMenu:is_button(tag)
    return self.holder.objects[self.active_block].tag == tag
end