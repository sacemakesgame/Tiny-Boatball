Ball = Object:extend()
Ball.model = pigic.character('game-assets/obj/ball.obj', 'game-assets/png/palette.png')

function Ball:new(owner, x, y, z)
    self.owner = owner
    self.timer = class.timer(self)
    self.spring = class.spring(1)
    self.translation = vec3(x, y, z)
    self.radius = 1.2
    self.owner.world:ball(self, self.translation.x, self.translation.y, self.translation.z, self.radius, .5)
    
    self.last_contact = nil
    
    self.transform = mat4()
end


function Ball:update(dt)
    self.timer:update(dt)
    self.spring:update(dt)

    local world = self.owner.world
    local points = world:get_points_interpolated(self)
    self.translation:set(points[1])
    -- log:print(points[1])

    -- calculate rotation thing
    local point = world.bodies[self].points[1]
    local vel = vec3(point[1], point[2], point[3]) - vec3(point[4], point[5], point[6])
    if vel:len() > 0 then
        local scale = 10
        self.transform:rotate(-vel.x * math.pi * scale * dt, 0, 0, 1)
        self.transform:rotate(vel.z * math.pi * scale * dt, 1, 0, 0)
    end

    -- local target_pos = self.owner:get_aim_position()
    -- local target_dir = (target_pos - self.translation):normalize()
    -- target_dir:scale(.2)
    -- self.owner.world:apply_force(self, vec3(-target_dir.x, 0, -target_dir.z))

    -- if input:pressed('jump') then
    --     self.owner.world:apply_force(self, vec3(0, -20, 0))
    -- end
    -- log:print(self.translation.z)
end


function Ball:draw()
    pass.push()
    
    pass.translate(self.translation)
    -- pass.translate(0, 1.5, 0)
    pass.scale(self.radius)
    pass.scale(math.clamp(self.spring.x, 1, 1.3))
    pass.transform = self.transform * pass.transform 

    
    self.model:draw()

    pass.pop()

    -- pass.wiresphere(self.translation, self.owner.world.bodies[self].bounding_radius * 1.1, nil, .01)
end

function Ball:destroy()
end



function Ball:boing(force_len)
    self.spring:pull(math.remap(force_len, 0, .5, 0, .3))
    if force_len > .3 then
        self.owner.sound:play('ball-bounce')
    end
end