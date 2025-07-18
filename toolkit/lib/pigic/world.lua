-- Verlet Integration for capsule-like shape

local World = Object:extend()

local function add_point(body, t, t_old)
    table.insert(body.points, {
        t = t,
        t_old = t_old and t_old:add(t) or t:clone(),
        water_vel = vec3(),
        water_gravity = vec3(),
        in_water = false,
    })
end

local function add_stick(body, ia, ib)
    table.insert(body.sticks, {
    pa = body.points[ia],
    pb = body.points[ib],
    len = body.points[ia].t:dist(body.points[ib].t)
    })
end


function World:new(owner)
    self.owner = owner
    self.tick_period = 1/50 -- seconds per tick
    self.accumulator = 0

	self.vbounce = .9 -- hbounce is calculated on collide_points
	-- local constant_gravity = -.01
	local constant_gravity = -40
	self.gravity = constant_gravity * self.tick_period * self.tick_period
	local constant_buoyancy = 200
    self.buoyancy_force = constant_buoyancy * self.tick_period * self.tick_period
	self.friction = .97
	self.frictiony = .98

    self.bodies = {}

    self.alpha = 1
end

function World:update(dt)
    -- local dt = math.min(dt, 1/20)
    -- update physics at constant rate, independent to FPS
    self.accumulator = self.accumulator + dt
    while self.accumulator >= self.tick_period do
        self.accumulator = self.accumulator - self.tick_period
        self:update_points()
        for i = 1, 3 do
            self:update_sticks()
            self:collide_points()
        end
    end

    self.alpha = self.accumulator / self.tick_period
end

function World:draw()
    graphics.teal()
    self:draw_points()
    graphics.orange()
    self:draw_sticks()
    graphics.white()
end


function World:update_points()
    for object, body in pairs(self.bodies) do
        if body.active then
            -- update physics from object
            if object.update_physics then
                object:update_physics()
            end

            for _, p in ipairs(body.points) do
                local vel = vec3()
                -- limit max velocity
                -- if object:is(Ball) then log:print(p.t:dist(p.t_old)) end
                if object:is(Ball) then
                    local threshold = .5
                    if p.t:dist(p.t_old) > threshold then
                        local dir = (p.t - p.t_old):normalize()
                        p.t:set(p.t_old + dir:scale(threshold))
                    end
                end
                vel.x = (p.t.x - p.t_old.x) * self.friction
                vel.y = (p.t.y - p.t_old.y) * self.frictiony
                vel.z = (p.t.z - p.t_old.z) * self.friction
                p.t_old:set(p.t)
                p.t.x = p.t.x + vel.x
                p.t.z = p.t.z + vel.z
                if not p.in_water then
                    p.t.y = p.t.y + vel.y
                    p.t:add(0, self.gravity, 0)
                else
                    local vely = vel.y
                    vely = vely * .95
                    local new_y = p.t:add(vec3(0, vely, 0)):add(p.water_gravity)
                    p.t:set(new_y)
                end
            end
        end
    end
end

function World:draw_points()
    for object, body in pairs(self.bodies) do
        for _, p in ipairs(body.points) do 
            -- pass.push()
            -- -- draw ballz
            -- pass.translate(p.t)
            -- pass.scale(body.radius or 5)
            -- pass.sphere()
            -- pass.pop()
            
            pass.push()
            local x = math.lerp(p.t_old.x, p.t.x, self.alpha)
            local y = math.lerp(p.t_old.y, p.t.y, self.alpha)
            local z = math.lerp(p.t_old.z, p.t.z, self.alpha)
            pass.translate(x, y, z)
            pass.scale(body.radius or 5)
            pass.sphere()
            pass.pop()
        end
    end
end

function World:get_points_interpolated(object)
    local body = self.bodies[object]
    local t = {}
    for _, p in ipairs(body.points) do 
        local x = math.lerp(p.t_old.x, p.t.x, self.alpha)
        local y = math.lerp(p.t_old.y, p.t.y, self.alpha)
        local z = math.lerp(p.t_old.z, p.t.z, self.alpha)
        table.insert(t, vec3(x, y, z))
    end
    return t
end

function World:update_sticks()
    for object, body in pairs(self.bodies) do
        if body.sticks and body.active then
            for _, s in ipairs(body.sticks) do
                local dist = s.pa.t:dist(s.pb.t)
                local diff = s.len - dist
                local percent = diff / dist / 2
                local dir = s.pb.t - s.pa.t
                local offset = dir:scale(percent)
                
                s.pa.t:sub(offset)
                s.pb.t:add(offset)
            end
        end
    end
end

function World:draw_sticks()
    for object, body in pairs(self.bodies) do
        if body.sticks then
            for _, s in ipairs(body.sticks) do
                pass.line(s.pa.t, s.pb.t, .05)
            end
        end
    end
end


local collision = require(pigic.collision)
local function getWaterLevelAt(x, z)
    -- return 0
    -- return 1.0 + 0.5 * math.sin(x * 0.5) * math.cos(z * 0.5)
    -- return .3 + 0.2 * math.sin(x * 2) * math.cos(z * 2)
    -- return .3 + 0.1 * math.sin(x * 2) * math.cos(z * 2)
    return .3 + 0.07 * math.sin(x * 2) * math.cos(z * 2)
end

function bounce_off_aabb(p, vel, aabb, hbounce, radius)
    local min = aabb.from
    local max = aabb.from + aabb.size

    -- local is_inside = (p.t.x >= min.x and p.t.x <= max.x)
    --    and (p.t.y >= min.y and p.t.y <= max.y)
    --    and (p.t.z >= min.z and p.t.z <= max.z)
    local is_inside = intersect.aabb_sphere({min = min, max = max}, {position = p.t, radius = radius})
    if not is_inside then return end

    local dx_min = math.abs((p.t.x + radius) - min.x)
    local dx_max = math.abs((p.t.x - radius) - max.x)
    local dy_min = math.abs((p.t.y + radius) - min.y)
    local dy_max = math.abs((p.t.y - radius) - max.y)
    local dz_min = math.abs((p.t.z + radius) - min.z)
    local dz_max = math.abs((p.t.z - radius) - max.z)

    local min_dist = math.min(dx_min, dx_max, dy_min, dy_max, dz_min, dz_max)
    -- local min_dist = math.min(dx_min, dx_max, dz_min, dz_max)

    -- if (p.t.x + radius) > max.x then
    if min_dist == dx_max then
        p.t.x = max.x + radius
        vel.x = -vel.x * hbounce
        p.t_old.x = p.t.x - vel.x
    -- elseif (p.t.x - radius) < min.x then
    elseif min_dist == dx_min then
        p.t.x = min.x - radius
        vel.x = -vel.x * hbounce
        p.t_old.x = p.t.x - vel.x
    elseif min_dist == dy_max then
        p.t.y = max.y + radius
        vel.y = -vel.y * hbounce
        p.t_old.y = p.t.y - vel.y
    elseif min_dist == dy_min then
        p.t.y = min.y - radius
        vel.y = -vel.y * hbounce
        p.t_old.y = p.t.y - vel.y
    -- elseif (p.t.z - radius) < max.z then
    elseif min_dist == dz_max then
        p.t.z = max.z + radius
        vel.z = -vel.z * hbounce
        p.t_old.z = p.t.z - vel.z
    -- elseif (p.t.z + radius) > min.z then
    elseif min_dist == dz_min then
        p.t.z = min.z - radius
        vel.z = -vel.z * hbounce
        p.t_old.z = p.t.z - vel.z
    -- elseif (p.t.z + radius) > max.z then
    --     p.t.z = max.z - radius
    --     vel.z = -vel.z * hbounce
    --     p.t_old.z = p.t.z - vel.z
    -- elseif (p.t.z - radius) < min.z then
    --     p.t.z = min.z + radius
    --     vel.z = -vel.z * hbounce
    --     p.t_old.z = p.t.z - vel.z
    end

    return true
end



function World:collide_points()
    for object, body in pairs(self.bodies) do
        if body.active then
            local hbounce = 1--object:is(Ball) and .8 or .8--1.35
            local ring_bounce_multiplier = 1--object:is(Ball) and .8 or .8--1.35
    
            for _, p in ipairs(body.points) do
                -- collision with other bodies' points
                for other, otherbody in pairs(self.bodies) do
                    if (object ~= other) and (otherbody.active) then
                        for _, op in ipairs(otherbody.points) do
                            local delta = p.t - op.t
                            local dist_sq = delta:dot(delta)
                            local min_dist = (body.radius) + (otherbody.radius)
                            local min_dist_sq = min_dist * min_dist
    
                            if dist_sq < min_dist_sq and dist_sq > 0 then
                                local dist = math.sqrt(dist_sq)
                                local penetration = min_dist - dist
                                local correction = delta:normalize() * (penetration) --* hbounce
                                
                                local to_object_force
                                local to_other_force
                                -- push both points away
                                if body.is_kinematic then
                                    op.t:sub(correction)
                                elseif otherbody.is_kinematic then
                                    p.t:add(correction)
                                else
                                    to_object_force = correction * otherbody.weight / body.weight
                                    to_other_force = correction * body.weight / otherbody.weight
                                    p.t:add(to_object_force)
                                    op.t:sub(to_other_force)
                                end

                                object:boing(to_object_force)
                                other:boing(to_other_force)
    
                                if object:is(Ball) then
                                    object.last_contact = other
                                    -- if to_object_force:len() > .25 then
                                    --     self.owner.sound:play('ball-kick')
                                    -- end
                                elseif other:is(Ball) then
                                    other.last_contact = object
                                    -- if to_other_force:len() > .25 then
                                    --     self.owner.sound:play('ball-kick')
                                    -- end
                                end
                            end
                        end
                    end
                end
                
                local vel = p.t - p.t_old
                
                -- boundaries
                -- local hw, hl = 13.5, 6   -- half width, half length
                -- local hw, hl = 14.5, 9.5   -- half width, half length
                local hw, hl = 15+7, 10   -- half width, half length
                
                local width = 8 -- for x
                local height = 197.5 -- for y
                local depth = 20/3 -- for z
                local goal_left = {from = vec3(-15 - width, -height/2, -depth/2), size = vec3(width, height, depth)}
                local gl_left_aabb = {from = goal_left.from - vec3(0, 0, 20/3/10), size = vec3(width, height, 20/3/10)}
                local gl_right_aabb = {from = goal_left.from + vec3(0, 0, goal_left.size.z), size =vec3(width, height, 20/3/10)}
                local gl_top_aabb = {from = goal_left.from + vec3(0, 197.5/2 + 7.5/2, 0), size = goal_left.size}
                local gl_back_aabb = {from = goal_left.from + vec3(1, 0, 0), size = vec3(width/10, height, depth)}
                
                local goal_right = {from = vec3(15, -height/2, -depth/2), size = vec3(width, height, depth)}
                local gr_left_aabb = {from = goal_right.from - vec3(0, 0, 20/3/10), size = vec3(width, height, 20/3/10)}
                local gr_right_aabb = {from = goal_right.from + vec3(0, 0, goal_right.size.z), size = vec3(width, height, 20/3/10)}
                local gr_top_aabb = {from = goal_right.from + vec3(0, 197.5/2 + 7.5/2, 0), size = goal_right.size}
                local gr_back_aabb = {from = goal_right.from + vec3(goal_right.size.x - width/10 - 1, 0, 0), size = vec3(width/10, height, depth)}
                
                if bounce_off_aabb(p, vel, gl_left_aabb, ring_bounce_multiplier, body.radius) then object:boing(vel/3) end
                if bounce_off_aabb(p, vel, gl_right_aabb, ring_bounce_multiplier, body.radius) then object:boing(vel/3) end
                if bounce_off_aabb(p, vel, gl_top_aabb, ring_bounce_multiplier, body.radius) then object:boing(vel/3) end
                if bounce_off_aabb(p, vel, gl_back_aabb, ring_bounce_multiplier, body.radius) then object:boing(vel/3) end
                if bounce_off_aabb(p, vel, gr_left_aabb, ring_bounce_multiplier, body.radius) then object:boing(vel/3) end
                if bounce_off_aabb(p, vel, gr_right_aabb, ring_bounce_multiplier, body.radius) then object:boing(vel/3) end
                if bounce_off_aabb(p, vel, gr_top_aabb, ring_bounce_multiplier, body.radius) then object:boing(vel/3) end
                if bounce_off_aabb(p, vel, gr_back_aabb, ring_bounce_multiplier, body.radius) then object:boing(vel/3) end
    
                if (p.t.x + body.radius) > hw then
                    p.t.x = hw - body.radius
                    vel.x = -vel.x * hbounce
                    p.t_old.x = p.t.x - vel.x
                    object:boing(vel/3)
                elseif (p.t.x - body.radius) < -hw then
                    p.t.x = -hw + body.radius
                    vel.x = -vel.x * hbounce
                    p.t_old.x = p.t.x - vel.x
                    object:boing(vel/3)
                end
    
                if (p.t.z + body.radius) > hl then
                    p.t.z = hl - body.radius
                    vel.z = -vel.z * hbounce
                    p.t_old.z = p.t.z - vel.z
                    object:boing(vel/3)
                elseif (p.t.z - body.radius) < -hl then
                    p.t.z = -hl + body.radius
                    vel.z = -vel.z * hbounce
                    p.t_old.z = p.t.z - vel.z
                    object:boing(vel/3)
                end
    
    
                p.water_gravity:set(0, self.gravity, 0)
                local water_level = getWaterLevelAt(p.t.x, p.t.z)
    
                
                local margin = .1
                if (p.t.y) < (water_level - margin) then
                    p.in_water = true
                else
                    p.in_water = false
                end
                
                if p.in_water then
                    local dx = 0.1
                    local dz = 0.1
        
                    local cx, cz = p.t.x, p.t.z
        
                    -- Sample water height in X and Z directions
                    local hL = getWaterLevelAt(cx - dx, cz)
                    local hR = getWaterLevelAt(cx + dx, cz)
                    local hB = getWaterLevelAt(cx, cz - dz)
                    local hF = getWaterLevelAt(cx, cz + dz)
        
                    -- Compute water surface gradient
                    local grad_x = (hR - hL) / (2 * dx)
                    local grad_z = (hF - hB) / (2 * dz)
                    
                    local slide_force = vec3(-grad_x, 0, -grad_z)
                    slide_force:normalize()
                    local submersion_ratio = .5
                    slide_force:scale(submersion_ratio * 0.01) -- scale by how submerged & strength
    
                    -- p.water_gravity:add(slide_force)  -- or apply to velocity if you're not using gravity directly
    
                    local upper = water_level + margin
                    local lower = water_level - margin
                    local t = math.clamp((p.t.y - lower) / (lower - upper), 0, 1)
                    -- p.water_vel.y = vel.y
                    -- p.water_vel.y = p.water_vel.y * 0.95 --drag
                    p.water_gravity.y = p.water_gravity.y + self.buoyancy_force * t --Buoyancy
                end
            end
        end
    end
end


function World:ball(object, translation, radius, weight, is_kinematic)
    local body = {
        shape = 'point',
        radius = radius or 100,
        points = {},
        weight = weight or 1,
        is_kinematic = is_kinematic or false,
        active = true,
    }
    local translation = translation:clone()
    add_point(body, translation)
    self.bodies[object] = body
end

function World:capsule(object, translation1, translation2, radius, weight, is_kinematic)
    local body = {
        shape = 'capsule',
        radius = radius or 100,
        points = {},
        sticks = {},
        weight = weight or 1,
        is_kinematic = is_kinematic or false,
        active = true,
    }
    add_point(body, translation1:clone())
    add_point(body, translation2:clone())
    add_stick(body, 1, 2)
    self.bodies[object] = body
end


function World:get_translation(object)
    local sum = vec3()
    for _, p in ipairs(self.bodies[object].points) do
        sum = sum + p.t
    end
    sum = sum / #self.bodies[object].points
    return sum
end


function World:get_transform(object)
    local body = self.bodies[object]
    if body.shape == 'cube' then
        local forward = ((body.points[4].t - body.points[8].t)/2):normalize()
        local up = ((body.points[8].t - body.points[5].t)/2):normalize()
        local mat = mat4()
        local mid = self:get_translation(object)
        mat:target(mid, mid + forward, up)
        return mat
    elseif body.shape == 'plane' then
        local side = ((body.points[4].t - body.points[1].t)/2):normalize()
        local up = ((body.points[2].t - body.points[1].t)/2):normalize()
        local forward = side:cross(up)
        local mat = mat4()
        local mid = self:get_translation(object)
        mat:target(mid, mid + forward, up)
        return mat
    end
end

function World:get_transform_scaled(object)
    return self:get_transform(object):scale(self.bodies[object].scale)
end

function World:get_orientation_matrix(object)
    local body = self.bodies[object]
    if body.shape == 'cube' then
        local forward = ((body.points[4].t - body.points[8].t)/2):normalize()
        local up = ((body.points[8].t - body.points[5].t)/2):normalize()
        local mat = mat4()
        local mid = self:get_translation(object)
        mat:target(vec3(), forward, up)
        return mat
    elseif body.shape == 'plane' then
        local side = ((body.points[4].t - body.points[1].t)/2):normalize()
        local up = ((body.points[2].t - body.points[1].t)/2):normalize()
        local forward = side:cross(up)
        local mat = mat4()
        mat:target(vec3(), forward, up)
        return mat
    end
end


function World:apply_force(object, v_force)
    local body = self.bodies[object]
    if body.active then
        for _, p in ipairs(body.points) do
            p.t_old:add(v_force * self.tick_period)
        end
    end
end

function World:apply_angular_force(object, t_force) -- rn just for capsule tho
    local body = self.bodies[object]

    local center = (body.points[1].t + body.points[2].t) / 2

    local p1 = body.points[1]
    local p2 = body.points[2]
    local r1 = p1.t - center
    local r2 = p2.t - center

    -- Create perpendicular force directions to simulate torque
    local f1 = r1:cross(t_force):normalize() * t_force:len()
    local f2 = r2:cross(t_force):normalize() * t_force:len()

    -- Apply them
    p1.t_old:add(f1 * self.tick_period)
    p2.t_old:add(f2 * self.tick_period)
end


function World:set_transform(object, transform)
    local body = self.bodies[object]
    assert(body.type == 'kinematic', 'ERROR (World.set_transform): body type must be kinematic.')
    if body.shape == 'plane' then
        body.points[1].t:set((transform * vec3(-.5, .5, 0):mul(body.scale))) -- bottom left
        body.points[2].t:set((transform * vec3(-.5, -.5, 0):mul(body.scale))) -- top left
        body.points[3].t:set((transform * vec3(.5, -.5, 0):mul(body.scale))) -- top right
        body.points[4].t:set((transform * vec3(.5, .5, 0):mul(body.scale))) -- bottom right
    end
end


function World:remove_body(object)
    self.bodies[object] = nil
end


function World:reset(object)
    local body = self.bodies[object]
    for _, p in ipairs(body.points) do
        p.t_old:set(p.t)
        p.water_vel:set(0, 0, 0)
        p.water_gravity:set(0, 0, 0)
        p.in_water = false
    end
end

function World:set_translation(object, x, y, z)
    local body = self.bodies[object]
    for _, p in ipairs(body.points) do
        p.t:set(x, y, z)
    end
end

function World:activate(object)
    self.bodies[object].active = true
end

function World:deactivate(object)
    self.bodies[object].active = false
end


return World