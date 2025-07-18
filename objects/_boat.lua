Boat = Object:extend()
-- Boat.model = pigic.character('game-assets/obj/frog.obj', 'game-assets/png/palette.png', true)
Boat.axolotl = pigic.character('game-assets/obj/axolotl.obj', 'game-assets/png/palette.png', true)
Boat.frog = pigic.character('game-assets/obj/frog.obj', 'game-assets/png/palette.png', true)
Boat.snail = pigic.character('game-assets/obj/snail.obj', 'game-assets/png/palette.png', true)
Boat.worm = pigic.character('game-assets/obj/worm.obj', 'game-assets/png/palette.png', true)
Boat.pelican = pigic.character('game-assets/obj/pelican.obj', 'game-assets/png/palette.png', true)
-- Boat.pelican_kick = pigic.character('game-assets/obj/pelican-kick.obj', 'game-assets/png/palette.png', true)

function Boat:new(owner, v, character, flip)
    self.owner = owner
    self.timer = class.timer(self)
    self.scale_spring = class.spring(1)
    self.rotate_spring = class.spring(0, 100, 50)
    self.translation = vec3(v.x, v.y, v.z)
    self.rotation = 0

    self.velocity_dir = vec3()

    self.transform = mat4()
    self.dir = vec3()
    self.up = vec3(0, 1, 0)

    self.goal_count = 0--random:bool(25) and 1 or 0
    self.blunder_count = 0--random:bool(25) and 1 or 0

    local len, radius, weight
    if character == 'axolotl' then
        len, radius, weight = .8, .4, 1
        self.speed = .4
        self.force = 20
        self.cooldown = 1
    elseif character == 'frog' then
        len, radius, weight = .8, .4, 1
        self.speed = .4
        self.force = 22.5
        self.cooldown = 1
    elseif character == 'snail' then
        len, radius, weight = .6, .6, 1.5
        self.speed = .35
        self.force = 20
        self.cooldown = 1
    elseif character == 'worm' then
        len, radius, weight = .7, .3, .75
        self.speed = .5
        self.force = 20
        self.cooldown = .75
    elseif character == 'pelican' then
        len, radius, weight = .8, .5, 1.25
        self.speed = .4
        self.force = 30
        self.cooldown = 1
    end

    self.trail_particle = self.trail_particle_data[character]
    self.nos_particle = self.nos_particle_data[character]


    local flip = flip and -1 or 1
    -- self.owner.world:capsule(self, self.translation - vec3(len/2, 0, 0) * flip, self.translation + vec3(len/2, 0, 0) * flip, radius, weight)
    self.owner.world:capsule(self, self.translation.x - len/2 * flip, self.translation.y, self.translation.z, self.translation.x + len/2 * flip, self.translation.y, self.translation.z, radius, weight)

    self.model = self[character]
    self.character = character -- store it
    -- self.owner.world:cube(self, self.translation, .1)

    -- local mesh = love.graphics.newMesh(pigic.model.vertex_format, pigic.objloader('assets/obj/player.obj'), "triangles")
    -- self.particle = class.particle()
    -- self.particle:set_mesh(mesh)
    -- self.particle:set_spread(math.pi/4, .5, .5, 0):set_velocities(20):set_sizes(.5, .1):set_lifetime(.5):set_direction(0, 0, 1):set_colors({1, 1, 1})

    self.idle_offset = random:float(0, 1000)
end


function Boat:update(dt)
    self.timer:update(dt)
    self.scale_spring:update(dt)
    self.rotate_spring:update(dt)

    local world = self.owner.world

    local points = world:get_points_interpolated(self)
    
    local center = (points[2] + points[1]) / 2
    self.velocity_dir:set(center - self.translation)
    self.velocity_dir:normalize()
    self.translation:set(center)

    self.dir:set((points[2] - points[1]):normalize())

    -- local center = (body.points[2].t + body.points[1].t) / 2
    -- self.velocity_dir:set(center - self.translation)
    -- self.velocity_dir:normalize()
    -- self.translation:set(center)

    -- self.dir:set((body.points[2].t - body.points[1].t):normalize())

    local p1 = points[1]
    local p2 = points[2]
    local center = (p1 + p2) / 2
    self.transform:target(center, p2, self.up)

    
    -- world:apply_force(self, self.dir:clone():scale(-.5))
    
    -- self.particle:set_direction(self.dir)
    -- if input:pressed('kick') then
        -- self.particle:set_position(self.translation)
        -- self.particle:emit(1)
    -- end

    -- self.particle:update(dt)
end


function Boat:draw()
    pass.push()

    -- pass.translate(self.translation)
    -- pass.translate(0, -.25, 0) -- visual offset
    pass.transform = self.transform * pass.transform 
    pass.rotate(math.pi, 0, 1, 0)
    pass.rotate(self.rotate_spring.x, 1, 0, 0)

    pass.translate(0, math.sin((love.timer.getTime() + self.idle_offset) * 10) * .1, 0)
    pass.rotate(math.sin((love.timer.getTime() + self.idle_offset) * 4) * math.pi/30, 0, 1, 0)

    pass.scale(math.clamp(self.scale_spring.x, 1, 1.5))

    -- if self.character == 'pelican' then
    --     if self.translation.y >= .5 then
    --         self.model = self.pelican_kick
    --     else
    --         self.model = self.pelican
    --     end        
    -- end

    -- if self.blink then
    --     self.owner.eye.shader:send('blink', true)
    -- end
    
    self.model:draw(1.3)

    -- if self.blink then
    --     self.owner.eye.shader:send('blink', false)
    -- end    
    
    pass.pop()
    -- self.particle:draw()
    
    -- pass.wiresphere(self.translation, self.owner.world.bodies[self].bounding_radius, nil, .01)
end


-- function Boat:draw2d()
--     local scale = width/2400
--     local playerdot = self.translation:clone()
--     playerdot = mat4.mul_vec3_perspective(playerdot, self.owner.eye.transform, playerdot)

--     local playerdot_projected = mat4.project(playerdot, self.owner.eye.projection, {0, 0, width, height})
--     playerdot_projected.y = height - playerdot_projected.y
--     graphics.capsule('fill', playerdot_projected.x, playerdot_projected.y - 100 * scale, 200 * scale, 80 * scale, true)
--     graphics.set_color(color.palette.ally)
--     graphics.printmid(tostring(self.goal_count) .. ' - ' .. tostring(self.blunder_count), playerdot_projected.x, playerdot_projected.y - 100 * scale, 0, 1/3)
--     graphics.white()
-- end


--[[
function Boat:draw()
    local world = self.owner.world
    local body = world.bodies[self]

    local forward = ((body.points[4].t - body.points[8].t)/2):normalize()
	local up = ((body.points[8].t - body.points[5].t)/2):normalize()
	local side = ((body.points[7].t - body.points[8].t)/2):normalize()
	self.transform:target(body.points[1].t, body.points[2].t, up)
	
    pass.push()
	
    
    -- pass.translate(self.translation)
    -- pass.translate(0, -.25, 0) -- visual offset
    pass.transform = self.transform * pass.transform 
    pass.translate(.25, .25, -.25) -- idk, just offset stuff to the mid by half of points dist
    pass.rotate(math.pi, 0, 1, 0)
    -- self.model:draw(.6)
    -- self.model_1:draw(.6)
    pass.cube(mat4():scale(.3))
    
    pass.pop()
end
]]

function Boat:destroy()
    self.owner.world:remove_body(self)    
end


function Boat:boing(force_len)
    self.scale_spring:pull(math.remap(force_len, 0, .5, 0, .5))
    
    -- if force:len() > .5 then
    --     self.blink = true
    --     self.timer:after(.1, function() self.blink = false end)
    -- end
end


function Boat:wheelie()
    self.rotate_spring:pull(-math.pi/4)
end


Boat.trail_particle_data = {
    ['axolotl'] = function(self)
        self.owner.trail:set_position(self.translation + self.dir:clone():rotate(math.pi/16, 0, 1, 0) * -.5)
        self.owner.trail:emit(1)
        self.owner.trail:set_position(self.translation + self.dir:clone():rotate(-math.pi/16, 0, 1, 0) * -.5)
        self.owner.trail:emit(1)
    end,

    ['frog'] = function(self)
        self.owner.trail:set_position(self.translation + self.dir:clone() * -.5)

        self.owner.trail:emit(1)
    end,

    ['snail'] = function(self)
        self.owner.trail:set_position(self.translation + self.dir:clone():rotate(math.pi/8, 0, 1, 0) * -.8)
        self.owner.trail:emit(1)
        self.owner.trail:set_position(self.translation + self.dir:clone():rotate(-math.pi/8, 0, 1, 0) * -.8)
        self.owner.trail:emit(1)
        self.owner.trail:set_position(self.translation + self.dir:clone() * -.8)
        self.owner.trail:emit(2)
    end,

    ['worm'] = function(self)
        self.owner.trail:set_position(self.translation + self.dir:clone() * -.5)
        self.owner.trail:emit(2)
    end,

    ['pelican'] = function(self)
        -- self.owner.trail:set_position(self.translation + self.dir:clone():rotate(math.pi/1.5, 0, 1, 0) * -.5)
        -- self.owner.trail:emit(1)
        -- self.owner.trail:set_position(self.translation + self.dir:clone():rotate(-math.pi/1,5, 0, 1, 0) * -.5)
        -- self.owner.trail:emit(1)
        -- self.owner.trail:set_position(self.translation + self.dir:clone() * -.4)
        -- self.owner.trail:emit(2)
    end
}


Boat.nos_particle_data = {
    ['axolotl'] = function(self, dt)
        self.timer:every_immediate(dt, function()
            self.owner.ally_nos:set_direction(-self.dir)
            self.owner.ally_nos:set_position(self.translation + self.dir:clone():rotate(math.pi/4, 0, 1, 0) * -.5)
            self.owner.ally_nos:emit(10)
            self.owner.ally_nos:set_position(self.translation + self.dir:clone():rotate(-math.pi/4, 0, 1, 0) * -.5)
            self.owner.ally_nos:emit(10)
            self.owner.basic_nos:set_direction(-self.dir)
            self.owner.basic_nos:set_position(self.translation + self.dir:clone():rotate(math.pi/4, 0, 1, 0) * -.5)
            self.owner.basic_nos:emit(1)
            self.owner.basic_nos:set_position(self.translation + self.dir:clone():rotate(-math.pi/4, 0, 1, 0) * -.5)
            self.owner.basic_nos:emit(1)
        end, math.floor(10 / (dt / (1/60))))
    end,

    ['frog'] = function(self, dt)
        self.timer:every_immediate(dt, function()
            self.owner.ally_nos:set_direction(-self.dir)
            self.owner.ally_nos:set_position(self.translation + self.dir:clone():rotate(math.pi/4, 0, 1, 0) * -.5)
            self.owner.ally_nos:emit(10)
            self.owner.ally_nos:set_position(self.translation + self.dir:clone():rotate(-math.pi/4, 0, 1, 0) * -.5)
            self.owner.ally_nos:emit(10)
            self.owner.basic_nos:set_direction(-self.dir)
            self.owner.basic_nos:set_position(self.translation + self.dir:clone():rotate(math.pi/4, 0, 1, 0) * -.5)
            self.owner.basic_nos:emit(1)
            self.owner.basic_nos:set_position(self.translation + self.dir:clone():rotate(-math.pi/4, 0, 1, 0) * -.5)
            self.owner.basic_nos:emit(1)
        end, math.floor(10 / (dt / (1/60))))
    end,

    ['snail'] = function(self, dt)
        self.timer:every_immediate(dt, function()
            self.owner.ally_nos:set_direction(-self.dir)
            self.owner.ally_nos:set_position(self.translation + self.dir:clone():rotate(math.pi/4, 0, 1, 0) * -.5)
            self.owner.ally_nos:emit(5)
            self.owner.ally_nos:set_position(self.translation + self.dir:clone():rotate(-math.pi/4, 0, 1, 0) * -.5)
            self.owner.ally_nos:emit(5)
            self.owner.ally_nos:set_position(self.translation + self.dir:clone() * -.5)
            self.owner.ally_nos:emit(5)
            self.owner.basic_nos:set_direction(-self.dir)
            self.owner.basic_nos:set_position(self.translation + self.dir:clone():rotate(math.pi/4, 0, 1, 0) * -.5)
            self.owner.basic_nos:emit(1)
            self.owner.basic_nos:set_position(self.translation + self.dir:clone():rotate(-math.pi/4, 0, 1, 0) * -.5)
            self.owner.basic_nos:emit(1)
        end, math.floor(5 / (dt / (1/60))))
    end,

    ['worm'] = function(self, dt)
        self.timer:every_immediate(dt, function()
            self.owner.ally_nos:set_direction(-self.dir)
            self.owner.ally_nos:set_position(self.translation + self.dir:clone() * -.5)
            self.owner.ally_nos:emit(15)
            self.owner.basic_nos:set_direction(-self.dir)
            self.owner.basic_nos:set_position(self.translation + self.dir:clone():rotate(math.pi/4, 0, 1, 0) * -.5)
            self.owner.basic_nos:emit(1)
            self.owner.basic_nos:set_position(self.translation + self.dir:clone():rotate(-math.pi/4, 0, 1, 0) * -.5)
            self.owner.basic_nos:emit(1)
        end, math.floor(15 / (dt / (1/60))))
    end,

    ['pelican'] = function(self, dt)
        self.timer:every_immediate(dt, function()
            self.owner.ally_nos:set_direction(-self.dir)
            self.owner.ally_nos:set_position(self.translation + self.dir:clone():rotate(math.pi/4, 0, 1, 0) * -.5)
            self.owner.ally_nos:emit(2)
            self.owner.ally_nos:set_position(self.translation + self.dir:clone():rotate(-math.pi/4, 0, 1, 0) * -.5)
            self.owner.ally_nos:emit(2)
            self.owner.ally_nos:set_position(self.translation + self.dir:clone() * -.5)
            self.owner.ally_nos:emit(10)
            self.owner.basic_nos:set_direction(-self.dir)
            self.owner.basic_nos:set_position(self.translation + self.dir:clone():rotate(math.pi/4, 0, 1, 0) * -.5)
            self.owner.basic_nos:emit(1)
            self.owner.basic_nos:set_position(self.translation + self.dir:clone():rotate(-math.pi/4, 0, 1, 0) * -.5)
            self.owner.basic_nos:emit(1)
        end, math.floor(10 / (dt / (1/60))))
    end
}