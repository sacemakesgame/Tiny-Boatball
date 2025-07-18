CharacterDisplay = Object:extend()
CharacterDisplay.water_model = pigic.model('game-assets/obj/display-water.obj')

function CharacterDisplay:new(owner)
    self.owner = owner
    self.projection = mat4.from_perspective(90, width/height, .01, 300)
    self.view_transform = mat4():look_at(vec3(0, 20, 20), vec3(0, 0, 0), vec3(0, 1, 0))

    self.canvas = graphics.new_canvas()
    self.spring = class.spring2d(width, 0, 100, 20)
    self.boing_spring = class.spring(1, 1000, 50)

    self.character = 'axolotl'
end


function CharacterDisplay:update(dt)
    self.spring:update(dt)
    self.boing_spring:update(dt)
end


function CharacterDisplay:render()
    love.graphics.setDepthMode('lequal', true)
    graphics.set_canvas{self.canvas, depth = true}
    graphics.clear()

    -- water
    graphics.set_shader(self.owner.water_shader)
    self.owner.active_shader = self.owner.water_shader

    pass.push()
    self.owner.active_shader:send('projectionMatrix', 'column', self.projection)
    self.owner.active_shader:send('viewMatrix', 'column', self.view_transform)
    self.owner.active_shader:send('isDisplay', true)
    pass.translate(0, 0, 0)
    pass.rotate(-math.pi/8, 1, 0, 0)
    pass.rotate(love.timer.getTime(), 0, 1, 0)
    -- pass.cube(mat4():translate(0, -10, 0):scale(12, 10, 12))
    pass.scale(8)
    self.water_model:draw()
    pass.pop()
    self.owner.active_shader:send('isDisplay', false)
    self.owner.active_shader:send('projectionMatrix', 'column', self.owner.eye.projection)

    -- sun
    graphics.set_shader(self.owner.sun.shader)
    self.owner.active_shader = self.owner.sun.shader
    self.owner.active_shader:send('viewMatrix', 'column', self.owner.sun.transform)
    
    graphics.set_canvas({depthstencil = self.owner.sun.canvas})
    love.graphics.clear()
    pass.push()
    pass.translate(0, -.5 + math.sin(love.timer.getTime()*5)*.5, 0)
    pass.rotate(-math.pi/8, 1, 0, 0)
    pass.rotate(love.timer.getTime(), 0, 1, 0)
    pass.pop()
    graphics.set_canvas{self.canvas, depth = true}
    
    -- model
    graphics.set_shader(self.owner.eye.shader)
    self.owner.active_shader = self.owner.eye.shader
        
    pass.push()
    self.owner.active_shader:send('projectionMatrix', 'column', self.projection)
    self.owner.active_shader:send('viewMatrix', 'column', self.view_transform)
    pass.translate(0, -.5 + math.sin(love.timer.getTime()*5)*.5, 0)
    pass.rotate(-math.pi/8, 1, 0, 0)
    pass.rotate(love.timer.getTime(), 0, 1, 0)
    -- Boat.pelican:draw(8)
    pass.scale(self.boing_spring.x)
    self.owner.active_shader:send('boatColor', color.palette.ally)
    Boat[self.character]:draw(8)
    pass.pop()
    self.owner.active_shader:send('projectionMatrix', 'column', self.owner.eye.projection)

    graphics.set_canvas()
    -- graphics.set_canvas({depthstencil = self.owner.sun.canvas})

end

function CharacterDisplay:draw()
    graphics.set_shader(self.owner.outline.filter_2d)
    self.owner.outline.filter_2d:send('idColor', color.palette.dark)
    local thickness = height*6/1440
    for i = 0, math.pi*2, math.pi/8 do
       graphics.draw(self.canvas, self.spring.x + math.cos(i) * thickness, self.spring.y + math.sin(i) * thickness)
    end
    graphics.set_shader()
    graphics.draw(self.canvas, self.spring.x, self.spring.y)
end


function CharacterDisplay:enter()
    self.spring:animate(width/4, 0)
end

function CharacterDisplay:exit()
    self.spring:animate(width, 0)
end

function CharacterDisplay:set_character(c)
    -- if self.character ~= c then
        self.character = c
        self.boing_spring:pull(.1)
    -- end
end