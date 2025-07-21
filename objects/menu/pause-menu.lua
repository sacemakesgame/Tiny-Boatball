PauseMenu = YContainer:extend()
PauseMenu.shader = graphics.new_shader([[
    uniform vec3 overlayColor;
    vec4 effect(vec4 color, Image tex, vec2 texcoord, vec2 pixcoord) {
        vec4 texture = Texel(tex, texcoord);
        texture = texture * color;
        if (texture.r == 1.0) {
            discard;
        } else {
            return vec4(overlayColor, 1.);
        }
    }
]])

function PauseMenu:new(owner)
    PauseMenu.super.new(self, owner, 0, 0)
    self:set_align(YContainer.CENTER, YContainer.MIDDLE)
    self.spring = class.spring2d(width/2, height*1.25, 100, 20)
    self.timer = class.timer(self)
    
    -- self:add(ResolutionButton, width / 5, height/15, 'resolution')
    -- self:add(AspectRatioButton, width / 5, height/15, 'aspect ratio')
    -- self:add(Button, width / 5, height/15, 'input remapping')
    self:add(Blank, width/5, height/6)
    self:add(SfxButton, width / 5, height/15, 'sfx volume')
    self:add(MusicButton, width / 5, height/15, 'music volume')
    self:add(Blank, width / 5, height/30)
    self:add(Button, width / 5, height/15, 'resume')
    self:add(Button, width / 5, height/15, 'go home')

    self.active_block = 2
    self.selected_index = nil


    self.shader:send('overlayColor', color.palette.dark)
    self.curtain_scale = 1
    self.button_scale = 0
    self.canvas = graphics.new_canvas(width, height)
end


function PauseMenu:update(dt)
    self.super.update(self, dt)
    self.timer:update(dt)
end


function PauseMenu:draw()
    graphics.set_canvas(self.canvas)
    graphics.clear()
    graphics.set_color(0, 0, 0, 1)
    graphics.rectangle('fill', 0, 0, width, height)
    
    if self.curtain_scale > 0 then
        graphics.set_color(1, 1, 1, 1)
        love.graphics.circle('fill', width/2, height * 2.9/5, width*.8 * self.curtain_scale)
    end
    
    graphics.set_canvas{tool.canvas, depth = false}


    graphics.set_shader(self.shader)
    graphics.draw(self.canvas, 0, 0)
    graphics.set_shader()


    graphics.push()
    graphics.translate(width/2, height/2)
    graphics.scale(self.button_scale)
    PauseMenu.super.draw(self)
    graphics.pop()

    -- floating pause title
    graphics.push()
    graphics.translate(width/2, 190 * scale)
    graphics.rotate(math.sin(love.timer.getTime() * 2) * math.pi/50)
    graphics.scale(self.button_scale)
    graphics.printmid('paused..')
    graphics.dashed_line_can_walk(-300 * scale, 100 * scale, 300 * scale, 100 * scale, 40 * scale, 20 * scale, nil, 10 * scale, -love.timer.getTime() * 50)
    graphics.pop()
end


function PauseMenu:process_input()
    if self.is_transitioning then return end  -- hacky, but working solution :)

    if input:pressed('up') then
        self.active_block = self.active_block - 1
        while (self.holder.objects[self.active_block]:is(Blank)) do
            self.active_block = self.active_block - 1
            if self.active_block < 1 then self.active_block = #self.holder.objects end
        end
        self.holder.objects[self.active_block]:boing(.05)
        self.owner.sound:play('oreo')
    elseif input:pressed('down') then
        self.active_block = self.active_block + 1
        if self.active_block > #self.holder.objects then self.active_block = 1 end
        while (self.holder.objects[self.active_block]:is(Blank)) do
            self.active_block = self.active_block + 1
            if self.active_block > #self.holder.objects then self.active_block = 1 end
        end
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
        if self:is_button('resume') then
            self.holder.objects[self.active_block]:animate_pressed()
        elseif self:is_button('go home') then
            self.holder.objects[self.active_block]:animate_pressed()
            -- self.holder.objects[self.active_block]:head_shake()
        elseif self:is_button('sfx volume') then
            self.holder.objects[self.active_block]:head_shake()
            self.owner.sound:play('blunder-snare')
        elseif self:is_button('music volume') then
            self.holder.objects[self.active_block]:head_shake()
            self.owner.sound:play('blunder-snare')
        end
    elseif input:released('enter') then
        if self:is_button('resume') then
            self.holder.objects[self.active_block]:animate_released()
            self.owner.sound:play('oreo')
            gamestate.pause(false)
        elseif self:is_button('go home') then
            self.holder.objects[self.active_block]:animate_released()
            self.owner.sound:play('oreo')
            self.is_transitioning = true -- hacky, but working solution :)
            gamestate.pause(false)
            tool:switch(Home, TYPE.MAIN)
        end
    elseif input:pressed('back') then
        gamestate.pause(false)
    end
end

function PauseMenu:set_active()
    self.holder.objects[self.active_block].active = true        
end

function PauseMenu:is_button(tag)
    return self.holder.objects[self.active_block].tag == tag
end


-- reverse scale- a shader trick stuff

function PauseMenu:enter()
    self.timer:tween(.5, self, {curtain_scale = .19}, math.cubic_in_out, function()
    
    end, 'curtain-scale')
    
    self.timer:tween(.3, self, {button_scale = 1}, math.cubic_in_out, function()
    
    end, 'button-scale')
end


function PauseMenu:exit()
    self.timer:tween(.5, self, {curtain_scale = 1}, math.cubic_in_out, function()

    end, 'curtain-scale')
    
    self.timer:tween(.25, self, {button_scale = 0}, math.cubic_in_out, function()

    end, 'button-scale')
end