-- Verlet Integration for capsule-like shape

local sqrt = math.sqrt
local abs = math.abs
local min = math.min

local function vec_subtract(v1,v2,v3, v4,v5,v6)
    return v1-v4, v2-v5, v3-v6
end

local function vec_add(v1,v2,v3, v4,v5,v6)
    return v1+v4, v2+v5, v3+v6
end

local function vec_dist(ax, ay, az, bx, by, bz)
	local dx = ax - bx
	local dy = ay - by
	local dz = az - bz
	return sqrt(dx * dx + dy * dy + dz * dz)
end

local function vec_normalize(x ,y, z)
    if not x == 0 and y == 0 and z == 0 then
        local mag = sqrt(x * x + y * y + z * z)
        return x / mag, y / mag, z / mag
    else
        return x, y, z
    end
end

local function vec_cross(a1,a2,a3, b1,b2,b3)
    return a2*b3 - a3*b2, a3*b1 - a1*b3, a1*b2 - a2*b1
end

local function vec_magnitude(x, y, z)
    return sqrt(x * x + y * y + z * z)
end

local function vec_dot(a1,a2,a3, b1,b2,b3)
    return a1*b1 + a2*b2 + a3*b3
end

local function aabb_sphere(aabb_minx, aabb_miny, aabb_minz, aabb_maxx, aabb_maxy, aabb_maxz, sphere_x, sphere_y, sphere_z, sphere_radius)
	local dist2 = sphere_radius * sphere_radius
    -- x
    if sphere_x < aabb_minx then
        dist2 = dist2 - (sphere_x - aabb_minx) * (sphere_x - aabb_minx)
    elseif sphere_x > aabb_maxx then
        dist2 = dist2 - (sphere_x - aabb_maxx) * (sphere_x - aabb_maxx)
    end

    -- y
    if sphere_y < aabb_miny then
        dist2 = dist2 - (sphere_y - aabb_miny) * (sphere_y - aabb_miny)
    elseif sphere_y > aabb_maxy then
        dist2 = dist2 - (sphere_y - aabb_maxy) * (sphere_y - aabb_maxy)
    end

    -- z
    if sphere_z < aabb_minz then
        dist2 = dist2 - (sphere_z - aabb_minz) * (sphere_z - aabb_minz)
    elseif sphere_z > aabb_maxz then
        dist2 = dist2 - (sphere_z - aabb_maxz) * (sphere_z - aabb_maxz)
    end

	return dist2 > 0
end






local World = Object:extend()

local function add_point(body, x, y, z)
    table.insert(body.points, {
        x = x,
        y = y,
        z = z,
        px = x, -- previous position
        py = y, -- previous position
        pz = z, -- previous position
        water_vel_x = 0,
        water_vel_y = 0,
        water_vel_z = 0,
        water_gravity_x = 0,
        water_gravity_y = 0,
        water_gravity_z = 0,
        in_water = false,
    })
end

local function add_stick(body, ia, ib)
    table.insert(body.sticks, {
    a = body.points[ia],
    b = body.points[ib],
    -- len = body.points[ia].t:dist(body.points[ib].t)
    len = vec_dist(body.points[ia].x, body.points[ia].y, body.points[ia].z, body.points[ib].x, body.points[ib].y, body.points[ib].z)
    })
end


function World:new(owner)
    self.owner = owner
    self.tick_period = 1/50 -- seconds per tick
    self.accumulator = 0

	self.vbounce = .9 -- hbounce is calculated on collide_points
	local constant_gravity = -40
	self.gravity = constant_gravity * self.tick_period * self.tick_period
	local constant_buoyancy = 200
    self.buoyancy_force = constant_buoyancy * self.tick_period * self.tick_period
	self.friction = .97
	self.frictiony = .98

    self.bodies = {}
    self.alpha = 1 -- used when calculating point's position by lerping the prev-to-current
end

function World:update(dt)
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
    -- self:draw_sticks()
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
                local vx, vy, vz

                -- limit ball's max velocity
                if object:is(Ball) then
                    local threshold = .5
                    if vec_dist(p.x, p.y, p.z, p.px, p.py, p.pz) > threshold then
                        local dx, dy, dz = vec_normalize(vec_subtract(p.x, p.y, p.z, p.px, p.py, p.pz))
                        p.x = p.px + dx * threshold
                        p.y = p.py + dy * threshold
                        p.z = p.pz + dz * threshold
                    end
                end
                vx = (p.x - p.px) * self.friction
                vy = (p.y - p.py) * self.frictiony
                vz = (p.z - p.pz) * self.friction

                p.px, p.py, p.pz = p.x, p.y, p.z

                p.x = p.x + vx
                p.z = p.z + vz

                if not p.in_water then
                    p.y = p.y + vy + self.gravity
                else
                    p.y = p.y + (vy * .95) + p.water_gravity_y
                end
            end
        end
    end
end


function World:draw_points()
    for object, body in pairs(self.bodies) do
        for _, p in ipairs(body.points) do 
            pass.push()
            local x = math.lerp(p.px, p.x, self.alpha)
            local y = math.lerp(p.py, p.y, self.alpha)
            local z = math.lerp(p.pz, p.z, self.alpha)
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
        local x = math.lerp(p.px, p.x, self.alpha)
        local y = math.lerp(p.py, p.y, self.alpha)
        local z = math.lerp(p.pz, p.z, self.alpha)
        table.insert(t, vec3(x, y, z))
    end
    return t
end

function World:update_sticks()
    for object, body in pairs(self.bodies) do
        if body.sticks and body.active then
            for _, s in ipairs(body.sticks) do
                local ax, ay, az = s.a.x, s.a.y, s.a.z
                local bx, by, bz = s.b.x, s.b.y, s.b.z
                local dist = vec_dist(ax, ay, az, bx, by, bz)
                local diff = s.len - dist
                local percent = diff / dist / 2
                local dx, dy, dz = vec_subtract(bx, by, bz, ax, ay, az)
                local ofx = dx * percent
                local ofy = dy * percent
                local ofz = dz * percent

                s.a.x = s.a.x - ofx
                s.a.y = s.a.y - ofy
                s.a.z = s.a.z - ofz
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
    return .3 + .07 * math.sin(x * 2) * math.cos(z * 2)
end


function bounce_off_aabb(p, vel, minx, miny, minz, maxx, maxy, maxz, radius)
    local is_inside = aabb_sphere(minx, miny, minz, maxx, maxy, maxz, p.x, p.y, p.z, radius)
    if not is_inside then return end

    local dx_min = abs((p.x + radius) - minx)
    local dx_max = abs((p.x - radius) - maxx)
    local dy_min = abs((p.y + radius) - miny)
    local dy_max = abs((p.y - radius) - maxy)
    local dz_min = abs((p.z + radius) - minz)
    local dz_max = abs((p.z - radius) - maxz)

    local min_dist = min(dx_min, dx_max, dy_min, dy_max, dz_min, dz_max)

    if min_dist == dx_max then
        p.x = maxx + radius
        vel[1] = -vel[1]
        p.px = p.x - vel[1]
    elseif min_dist == dx_min then
        p.x = minx - radius
        vel[1] = -vel[1]
        p.px = p.x - vel[1]
    elseif min_dist == dy_max then
        p.y = maxy + radius
        vel[2] = -vel[2]
        p.py = p.y - vel[2]
    elseif min_dist == dy_min then
        p.y = miny - radius
        vel[2] = -vel[2]
        p.py = p.y - vel[2]
    elseif min_dist == dz_max then
        p.z = maxz + radius
        vel[3] = -vel[3]
        p.pz = p.z - vel[3]
    elseif min_dist == dz_min then
        p.z = minz - radius
        vel[3] = -vel[3]
        p.pz = p.z - vel[3]
    end

    return true -- for boing effect thingy
end

-- goal aabb boxes
local width = 8 -- for x
local height = 197.5 -- for y
local depth = 20/3 -- for z

local goal_left = {from = vec3(-15 - width, -height/2, -depth/2), size = vec3(width, height, depth)}

local gl_left_aabb = {}
gl_left_aabb.minx = goal_left.from.x
gl_left_aabb.miny = goal_left.from.y
gl_left_aabb.minz = goal_left.from.z - 20/3/10
gl_left_aabb.maxx = gl_left_aabb.minx + width   
gl_left_aabb.maxy = gl_left_aabb.miny + height
gl_left_aabb.maxz = gl_left_aabb.minz + 20/3/10

local gl_right_aabb = {}
gl_right_aabb.minx = goal_left.from.x
gl_right_aabb.miny = goal_left.from.y
gl_right_aabb.minz = goal_left.from.z + goal_left.size.z
gl_right_aabb.maxx = gl_right_aabb.minx + width   
gl_right_aabb.maxy = gl_right_aabb.miny + height
gl_right_aabb.maxz = gl_right_aabb.minz + 20/3/10

local gl_top_aabb = {}
gl_top_aabb.minx = goal_left.from.x + 197.5/2
gl_top_aabb.miny = goal_left.from.y + 7.5/2
gl_top_aabb.minz = goal_left.from.z
gl_top_aabb.maxx = gl_top_aabb.minx + width   
gl_top_aabb.maxy = gl_top_aabb.miny + height
gl_top_aabb.maxz = gl_top_aabb.minz + depth

local gl_back_aabb = {}
gl_back_aabb.minx = goal_left.from.x + 1
gl_back_aabb.miny = goal_left.from.y
gl_back_aabb.minz = goal_left.from.z
gl_back_aabb.maxx = gl_back_aabb.minx + width/10
gl_back_aabb.maxy = gl_back_aabb.miny + height
gl_back_aabb.maxz = gl_back_aabb.minz + depth


local goal_right = {from = vec3(15, -height/2, -depth/2), size = vec3(width, height, depth)}
-- local gr_left_aabb = {from = goal_right.from - vec3(0, 0, 20/3/10), size = vec3(width, height, 20/3/10)}
-- local gr_right_aabb = {from = goal_right.from + vec3(0, 0, goal_right.size.z), size = vec3(width, height, 20/3/10)}
-- local gr_top_aabb = {from = goal_right.from + vec3(0, 197.5/2 + 7.5/2, 0), size = goal_right.size}
-- local gr_back_aabb = {from = goal_right.from + vec3(goal_right.size.x - width/10 - 1, 0, 0), size = vec3(width/10, height, depth)}



local gr_left_aabb = {}
gr_left_aabb.minx = goal_right.from.x
gr_left_aabb.miny = goal_right.from.y
gr_left_aabb.minz = goal_right.from.z - 20/3/10
gr_left_aabb.maxx = gr_left_aabb.minx + width   
gr_left_aabb.maxy = gr_left_aabb.miny + height
gr_left_aabb.maxz = gr_left_aabb.minz + 20/3/10

local gr_right_aabb = {}
gr_right_aabb.minx = goal_right.from.x
gr_right_aabb.miny = goal_right.from.y
gr_right_aabb.minz = goal_right.from.z + goal_right.size.z
gr_right_aabb.maxx = gr_right_aabb.minx + width   
gr_right_aabb.maxy = gr_right_aabb.miny + height
gr_right_aabb.maxz = gr_right_aabb.minz + 20/3/10

local gr_top_aabb = {}
gr_top_aabb.minx = goal_right.from.x + 197.5/2
gr_top_aabb.miny = goal_right.from.y + 7.5/2
gr_top_aabb.minz = goal_right.from.z
gr_top_aabb.maxx = gr_top_aabb.minx + width   
gr_top_aabb.maxy = gr_top_aabb.miny + height
gr_top_aabb.maxz = gr_top_aabb.minz + depth

local gr_back_aabb = {}
gr_back_aabb.minx = goal_right.from.x + (goal_right.size.x - width/10 - 1)
gr_back_aabb.miny = goal_right.from.y
gr_back_aabb.minz = goal_right.from.z
gr_back_aabb.maxx = gr_back_aabb.minx + width/10
gr_back_aabb.maxy = gr_back_aabb.miny + height
gr_back_aabb.maxz = gr_back_aabb.minz + depth


local function bounce_goal_left(p, vel, radius)
    -- gl_left_aabb
    if bounce_off_aabb(p, vel, gl_left_aabb.minx, gl_left_aabb.miny, gl_left_aabb.minz, gl_left_aabb.maxx, gl_left_aabb.maxy, gl_left_aabb.maxz, radius) then return true end
    -- gl_right_aabb
    if bounce_off_aabb(p, vel, gl_right_aabb.minx, gl_right_aabb.miny, gl_right_aabb.minz, gl_right_aabb.maxx, gl_right_aabb.maxy, gl_right_aabb.maxz, radius) then return true end
    -- gl_top_aabb
    if bounce_off_aabb(p, vel, gl_top_aabb.minx, gl_top_aabb.miny, gl_top_aabb.minz, gl_top_aabb.maxx, gl_top_aabb.maxy, gl_top_aabb.maxz, radius) then return true end  
    -- gl_back_aabb
    if bounce_off_aabb(p, vel, gl_back_aabb.minx, gl_back_aabb.miny, gl_back_aabb.minz, gl_back_aabb.maxx, gl_back_aabb.maxy, gl_back_aabb.maxz, radius) then return true end
end

local function bounce_goal_right(p, vel, radius)
    -- gr_left_aabb
    if bounce_off_aabb(p, vel, gr_left_aabb.minx, gr_left_aabb.miny, gr_left_aabb.minz, gr_left_aabb.maxx, gr_left_aabb.maxy, gr_left_aabb.maxz, radius) then return true end
    -- gr_right_aabb
    if bounce_off_aabb(p, vel, gr_right_aabb.minx, gr_right_aabb.miny, gr_right_aabb.minz, gr_right_aabb.maxx, gr_right_aabb.maxy, gr_right_aabb.maxz, radius) then return true end
    -- gr_top_aabb
    if bounce_off_aabb(p, vel, gr_top_aabb.minx, gr_top_aabb.miny, gr_top_aabb.minz, gr_top_aabb.maxx, gr_top_aabb.maxy, gr_top_aabb.maxz, radius) then return true end  
    -- gr_back_aabb
    if bounce_off_aabb(p, vel, gr_back_aabb.minx, gr_back_aabb.miny, gr_back_aabb.minz, gr_back_aabb.maxx, gr_back_aabb.maxy, gr_back_aabb.maxz, radius) then return true end
end

function World:collide_points()
    for object, body in pairs(self.bodies) do
        if body.active then
            -- local hbounce = 1
            -- local ring_bounce_multiplier = 1
            
            for _, p in ipairs(body.points) do
                -- collision with other bodies' points
                for other, otherbody in pairs(self.bodies) do
                    if (object ~= other) and (otherbody.active) then
                        for _, op in ipairs(otherbody.points) do
                            local dx = p.x - op.x
                            local dy = p.y - op.y
                            local dz = p.z - op.z
                            local dist_sq = vec_dot(dx, dy, dz, dx, dy, dz)
                            local min_dist = body.radius + otherbody.radius
                            if dist_sq < (min_dist * min_dist) and dist_sq > 0 then
                                local dist = sqrt(dist_sq)
                                local penetration = min_dist - dist
                                -- local correction = delta:normalize() * (penetration)
                                local correction_x, correction_y, correction_z = vec_normalize(dx, dy, dz)
                                correction_x = correction_x * penetration
                                correction_y = correction_y * penetration
                                correction_z = correction_z * penetration
                                
                                local to_object_force_x, to_object_force_y, to_object_force_z
                                local to_other_force_x, to_other_force_y, to_other_force_z
                                
                                local object_weight = body.weight
                                local other_weight = otherbody.weight
                                to_object_force_x = correction_x * other_weight / object_weight
                                to_object_force_y = correction_y * other_weight / object_weight
                                to_object_force_z = correction_z * other_weight / object_weight
                                to_other_force_x = correction_x * object_weight / other_weight
                                to_other_force_y = correction_y * object_weight / other_weight
                                to_other_force_z = correction_z * object_weight / other_weight
                                -- push both points away
                                p.x = p.x + to_object_force_x
                                p.y = p.y + to_object_force_y
                                p.z = p.z + to_object_force_z
                                op.x = op.x - to_other_force_x
                                op.y = op.y - to_other_force_y
                                op.z = op.z - to_other_force_z

                                -- object:boing(to_object_force)
                                -- other:boing(to_other_force)
    
                                if object:is(Ball) then
                                    object.last_contact = other
                                elseif other:is(Ball) then
                                    other.last_contact = object
                                end
                            end
                        end
                    end
                end
                
                local vel = {
                    [1] = p.x - p.px,
                    [2] = p.y - p.py,
                    [3] = p.z - p.pz
                }
                
                -- boundaries
                local hw, hl = 15+7, 10   -- half width, half length
                --[[
                
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
                ]]

                if bounce_goal_left(p, vel, body.radius) then
                    -- boing stuff
                end

                if bounce_goal_right(p, vel, body.radius) then
                    -- boing stuff
                end

                if (p.x + body.radius) > hw then
                    p.x = hw - body.radius
                    vel[1] = -vel[1] --* hbounce
                    p.px = p.x - vel[1]
                    -- object:boing(vel/3)
                elseif (p.x - body.radius) < -hw then
                    p.x = -hw + body.radius
                    vel[1] = -vel[1] --* hbounce
                    p.px = p.x - vel[1]
                    -- object:boing(vel/3)
                end
    
                if (p.z + body.radius) > hl then
                    p.z = hl - body.radius
                    vel[3] = -vel[3] --* hbounce
                    p.pz = p.z - vel[3]
                    -- object:boing(vel/3)
                elseif (p.z - body.radius) < -hl then
                    p.z = -hl + body.radius
                    vel[3] = -vel[3] --* hbounce
                    p.pz = p.z - vel[3]
                    -- object:boing(vel/3)
                end
    
    
                p.water_gravity_y = self.gravity
                local water_level = getWaterLevelAt(p.x, p.z)
    
                local margin = .1
                if (p.y) < (water_level - margin) then
                    p.in_water = true
                else
                    p.in_water = false
                end
                
                if p.in_water then
                    local upper = water_level + margin
                    local lower = water_level - margin
                    local t = math.clamp((p.y - lower) / (lower - upper), 0, 1)
                    p.water_gravity_y = p.water_gravity_y + self.buoyancy_force * t --Buoyancy
                end
            end
        end
    end
end


function World:ball(object, x, y, z, radius, weight)
    local body = {
        shape = 'point',
        radius = radius or 100,
        points = {},
        weight = weight or 1,
        active = true,
    }
    add_point(body, x, y, z)
    self.bodies[object] = body
end


function World:capsule(object, ax, ay, az, bx, by, bz, radius, weight)
    local body = {
        shape = 'capsule',
        radius = radius or 100,
        points = {},
        sticks = {},
        weight = weight or 1,
        active = true,
    }
    add_point(body, ax, ay, az)
    add_point(body, bx, by, bz)
    add_stick(body, 1, 2)
    self.bodies[object] = body
end


function World:apply_force(object, fx, fy, fz)
    local body = self.bodies[object]
    if body.active then
        for _, p in ipairs(body.points) do
            p.px = p.px + fx * self.tick_period
            p.py = p.py + fy * self.tick_period
            p.pz = p.pz + fz * self.tick_period
        end
    end
end


function World:apply_angular_force(object, tx, ty, tz) -- rn just for capsule tho
    local body = self.bodies[object]

    local t_force = vec3(tx, ty, tz)

    local a = body.points[1]
    local b = body.points[2]
    local cx = (a.x + b.x) / 2
    local cy = (a.y + b.y) / 2
    local cz = (a.z + b.z) / 2

    local rax = a.x - cx
    local ray = a.y - cy
    local raz = a.z - cz
    local rbx = b.x - cx
    local rby = b.y - cy
    local rbz = b.z - cz

    local r1 = vec3(rax, ray, raz)
    local r2 = vec3(rbx, rby, rbz)

    local f1 = r1:cross(t_force):normalize() * t_force:len()
    local f2 = r2:cross(t_force):normalize() * t_force:len()

    a.px = a.px + f1.x * self.tick_period
    a.py = a.py + f1.y * self.tick_period
    a.pz = a.pz + f1.z * self.tick_period

    b.px = b.px + f2.x * self.tick_period
    b.py = b.py + f2.y * self.tick_period
    b.pz = b.pz + f2.z * self.tick_period
end

--[[function World:apply_angular_force(object, tx, ty, tz) -- rn just for capsule tho
    local body = self.bodies[object]

    local a = body.points[1]
    local b = body.points[2]
    local cx = (a.x + b.x) / 2
    local cy = (a.y + b.y) / 2
    local cz = (a.z + b.z) / 2

    local rax = a.x - cx
    local ray = a.y - cy
    local raz = a.z - cz
    local rbx = b.x - cx
    local rby = b.y - cy
    local rbz = b.z - cz
    
    local t_len = vec_magnitude(tx, ty, tz)
    
    local fax, fay, faz = vec_cross(rax, ray, raz, tx, ty, tz)
    fax, fay, faz = vec_normalize(fax, fay, faz)
    fax, fay, faz = fax * t_len, fay * t_len, faz * t_len

    local fbx, fby, fbz = vec_cross(rbx, rby, rbz, tx, ty, tz)
    fbx, fby, fbz = vec_normalize(fbx, fby, fbz)
    fbx, fby, fbz = fbx * t_len, fby * t_len, fbz * t_len


    a.px = a.px + fax * self.tick_period
    a.py = a.py + fay * self.tick_period
    a.pz = a.pz + faz * self.tick_period

    b.px = b.px + fbx * self.tick_period
    b.py = b.py + fby * self.tick_period
    b.pz = b.pz + fbz * self.tick_period
end]]


--[[function World:apply_angular_force(object, tx, ty, tz) -- rn just for capsule tho
    local body = self.bodies[object]

    local a = body.points[1]
    local b = body.points[2]
    local cx = (a.x + b.x) / 2
    local cy = (a.y + b.y) / 2
    local cz = (a.z + b.z) / 2

    local rax = a.x - cx
    local ray = a.y - cy
    local raz = a.z - cz
    local rbx = b.x - cx
    local rby = b.y - cy
    local rbz = b.z - cz

    local fax, fay, faz = vec_normalize(vec_cross(rax, ray, raz, tx, ty, tz))
    local fbx, fby, fbz = vec_normalize(vec_cross(rbx, rby, rbz, tx, ty, tz))
    local t_len = vec_magnitude(tx, ty, tz)

    a.px = a.px + fax * t_len * self.tick_period
    a.py = a.py + fay * t_len * self.tick_period
    a.pz = a.pz + faz * t_len * self.tick_period

    b.px = b.px + fbx * t_len * self.tick_period
    b.py = b.py + fby * t_len * self.tick_period
    b.pz = b.pz + fbz * t_len * self.tick_period
end]]


function World:remove_body(object)
    self.bodies[object] = nil
end


function World:reset(object)
    local body = self.bodies[object]
    for _, p in ipairs(body.points) do
        -- p.t_old:set(p.t)
        -- p.water_vel:set(0, 0, 0)
        -- p.water_gravity:set(0, 0, 0)
        p.in_water = false

        p.px, p.py, p.pz = p.x, p.y, p.z
        p.water_vel_x = 0
        p.water_vel_y = 0
        p.water_vel_z = 0
        p.water_gravity_x = 0
        p.water_gravity_y = 0
        p.water_gravity_z = 0
    end
end

function World:set_translation(object, x, y, z)
    local body = self.bodies[object]
    for _, p in ipairs(body.points) do
        p.x = x
        p.y = y
        p.z = z
    end
end

function World:activate(object)
    self.bodies[object].active = true
end

function World:deactivate(object)
    self.bodies[object].active = false
end


return World