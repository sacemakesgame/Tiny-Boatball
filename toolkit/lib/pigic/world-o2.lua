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
        [1] = x,
        [2] = y,
        [3] = z,
        [4] = x, -- previous position
        [5] = y, -- previous position
        [6] = z, -- previous position
        water_vel_x = 0,
        water_vel_y = 0,
        water_vel_z = 0,
        water_gravity_y = 0,
        in_water = false,
    })
end

local function add_stick(body, ia, ib)
    table.insert(body.sticks, {
    a = body.points[ia],
    b = body.points[ib],
    -- len = body.points[ia].t:dist(body.points[ib].t)
    len = vec_dist(body.points[ia][1], body.points[ia][2], body.points[ia][3], body.points[ib][1], body.points[ib][2], body.points[ib][3])
    })
end


function World:new(owner)
    self.owner = owner
    self.tick_period = 1/50 -- seconds per tick
    self.accumulator = 0

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
                    if vec_dist(p[1], p[2], p[3], p[4], p[5], p[6]) > threshold then
                        local dx, dy, dz = vec_normalize(vec_subtract(p[1], p[2], p[3], p[4], p[5], p[6]))
                        p[1] = p[4] + dx * threshold
                        p[2] = p[5] + dy * threshold
                        p[3] = p[6] + dz * threshold
                    end
                end
                vx = (p[1] - p[4]) * self.friction
                vy = (p[2] - p[5]) * self.frictiony
                vz = (p[3] - p[6]) * self.friction

                p[4], p[5], p[6] = p[1], p[2], p[3]

                p[1] = p[1] + vx
                p[3] = p[3] + vz

                if not p.in_water then
                    p[2] = p[2] + vy + self.gravity
                else
                    p[2] = p[2] + (vy * .95) + p.water_gravity_y
                end
            end
        end
    end
end


function World:draw_points()
    for object, body in pairs(self.bodies) do
        for _, p in ipairs(body.points) do 
            pass.push()
            local x = math.lerp(p[4], p[1], self.alpha)
            local y = math.lerp(p[5], p[2], self.alpha)
            local z = math.lerp(p[6], p[3], self.alpha)
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
        local x = math.lerp(p[4], p[1], self.alpha)
        local y = math.lerp(p[5], p[2], self.alpha)
        local z = math.lerp(p[6], p[3], self.alpha)
        table.insert(t, vec3(x, y, z))
    end
    return t
end

function World:update_sticks()
    for object, body in pairs(self.bodies) do
        if body.sticks and body.active then
            for _, s in ipairs(body.sticks) do
                local ax, ay, az = s.a[1], s.a[2], s.a[3]
                local bx, by, bz = s.b[1], s.b[2], s.b[3]
                local dist = vec_dist(ax, ay, az, bx, by, bz)
                local diff = s.len - dist
                local percent = diff / dist / 2
                local dx, dy, dz = vec_subtract(bx, by, bz, ax, ay, az)
                local ofx = dx * percent
                local ofy = dy * percent
                local ofz = dz * percent

                s.a[1] = s.a[1] - ofx
                s.a[2] = s.a[2] - ofy
                s.a[3] = s.a[3] - ofz
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
    local is_inside = aabb_sphere(minx, miny, minz, maxx, maxy, maxz, p[1], p[2], p[3], radius)
    if not is_inside then return end

    local dx_min = abs((p[1] + radius) - minx)
    local dx_max = abs((p[1] - radius) - maxx)
    local dy_min = abs((p[2] + radius) - miny)
    local dy_max = abs((p[2] - radius) - maxy)
    local dz_min = abs((p[3] + radius) - minz)
    local dz_max = abs((p[3] - radius) - maxz)

    local min_dist = min(dx_min, dx_max, dy_min, dy_max, dz_min, dz_max)

    if min_dist == dx_max then
        p[1] = maxx + radius
        vel[1] = -vel[1]
        p[4] = p[1] - vel[1]
    elseif min_dist == dx_min then
        p[1] = minx - radius
        vel[1] = -vel[1]
        p[4] = p[1] - vel[1]
    elseif min_dist == dy_max then
        p[2] = maxy + radius
        vel[2] = -vel[2]
        p[5] = p[2] - vel[2]
    elseif min_dist == dy_min then
        p[2] = miny - radius
        vel[2] = -vel[2]
        p[5] = p[2] - vel[2]
    elseif min_dist == dz_max then
        p[3] = maxz + radius
        vel[3] = -vel[3]
        p[6] = p[3] - vel[3]
    elseif min_dist == dz_min then
        p[3] = minz - radius
        vel[3] = -vel[3]
        p[6] = p[3] - vel[3]
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
    if not ((p[1] - radius) < gl_left_aabb.maxx) then return end
    -- gl_left_aabb
    if bounce_off_aabb(p, vel, gl_left_aabb.minx, gl_left_aabb.miny, gl_left_aabb.minz, gl_left_aabb.maxx, gl_left_aabb.maxy, gl_left_aabb.maxz, radius) then return true end
    -- gl_right_aabb
    if bounce_off_aabb(p, vel, gl_right_aabb.minx, gl_right_aabb.miny, gl_right_aabb.minz, gl_right_aabb.maxx, gl_right_aabb.maxy, gl_right_aabb.maxz, radius) then return true end
    -- gl_top_aabb
    -- if bounce_off_aabb(p, vel, gl_top_aabb.minx, gl_top_aabb.miny, gl_top_aabb.minz, gl_top_aabb.maxx, gl_top_aabb.maxy, gl_top_aabb.maxz, radius) then return true end  
    -- gl_back_aabb
    if bounce_off_aabb(p, vel, gl_back_aabb.minx, gl_back_aabb.miny, gl_back_aabb.minz, gl_back_aabb.maxx, gl_back_aabb.maxy, gl_back_aabb.maxz, radius) then return true end
end

local function bounce_goal_right(p, vel, radius)
    if not ((p[1] + radius) > gr_left_aabb.minx) then return end
    -- gr_left_aabb
    if bounce_off_aabb(p, vel, gr_left_aabb.minx, gr_left_aabb.miny, gr_left_aabb.minz, gr_left_aabb.maxx, gr_left_aabb.maxy, gr_left_aabb.maxz, radius) then return true end
    -- gr_right_aabb
    if bounce_off_aabb(p, vel, gr_right_aabb.minx, gr_right_aabb.miny, gr_right_aabb.minz, gr_right_aabb.maxx, gr_right_aabb.maxy, gr_right_aabb.maxz, radius) then return true end
    -- gr_top_aabb
    -- if bounce_off_aabb(p, vel, gr_top_aabb.minx, gr_top_aabb.miny, gr_top_aabb.minz, gr_top_aabb.maxx, gr_top_aabb.maxy, gr_top_aabb.maxz, radius) then return true end  
    -- gr_back_aabb
    if bounce_off_aabb(p, vel, gr_back_aabb.minx, gr_back_aabb.miny, gr_back_aabb.minz, gr_back_aabb.maxx, gr_back_aabb.maxy, gr_back_aabb.maxz, radius) then return true end
end

function World:collide_points()
    for object, body in pairs(self.bodies) do
        if body.active then
            -- collision with other bodies' points
            for other, otherbody in pairs(self.bodies) do
                if (object ~= other) and (otherbody.active) then
                    if (object.translation:dist(other.translation)) < (body.bounding_radius + otherbody.bounding_radius) then
                        for _, p in ipairs(body.points) do
                            for _, op in ipairs(otherbody.points) do
                                local dx = p[1] - op[1]
                                local dy = p[2] - op[2]
                                local dz = p[3] - op[3]
                                local dist_sq = vec_dot(dx, dy, dz, dx, dy, dz)
                                local min_dist = body.radius + otherbody.radius
                                if dist_sq < (min_dist * min_dist) and dist_sq > 0 then
                                    local dist = sqrt(dist_sq)
                                    local penetration = min_dist - dist
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
                                    p[1] = p[1] + to_object_force_x
                                    p[2] = p[2] + to_object_force_y
                                    p[3] = p[3] + to_object_force_z
                                    op[1] = op[1] - to_other_force_x
                                    op[2] = op[2] - to_other_force_y
                                    op[3] = op[3] - to_other_force_z

                                    object:boing(vec_magnitude(to_object_force_x, to_object_force_y, to_object_force_z))
                                    other:boing(vec_magnitude(to_other_force_x, to_other_force_y, to_other_force_z))
        
                                    if object:is(Ball) then
                                        object.last_contact = other
                                    elseif other:is(Ball) then
                                        other.last_contact = object
                                    end
                                end
                            end
                        end
                    end
                end
            end

            for _, p in ipairs(body.points) do
                local vel = {
                    [1] = p[1] - p[4],
                    [2] = p[2] - p[5],
                    [3] = p[3] - p[6]
                }
                
                -- boundaries
                local hw, hl = 15+7, 10   -- half width, half length


                if bounce_goal_left(p, vel, body.radius) then
                    -- boing stuff
                    object:boing(vec_magnitude(vel[1], vel[2], vel[3]))
                end

                if bounce_goal_right(p, vel, body.radius) then
                    -- boing stuff
                    object:boing(vec_magnitude(vel[1], vel[2], vel[3]))
                end

                if (p[1] + body.radius) > hw then
                    p[1] = hw - body.radius
                    vel[1] = -vel[1]
                    p[4] = p[1] - vel[1]
                    object:boing(vec_magnitude(vel[1], vel[2], vel[3]))
                elseif (p[1] - body.radius) < -hw then
                    p[1] = -hw + body.radius
                    vel[1] = -vel[1]
                    p[4] = p[1] - vel[1]
                    object:boing(vec_magnitude(vel[1], vel[2], vel[3]))
                end
    
                if (p[3] + body.radius) > hl then
                    p[3] = hl - body.radius
                    vel[3] = -vel[3]
                    p[6] = p[3] - vel[3]
                    object:boing(vec_magnitude(vel[1], vel[2], vel[3]))
                elseif (p[3] - body.radius) < -hl then
                    p[3] = -hl + body.radius
                    vel[3] = -vel[3]
                    p[6] = p[3] - vel[3]
                    object:boing(vec_magnitude(vel[1], vel[2], vel[3]))
                end
    
    
                p.water_gravity_y = self.gravity
                local water_level = getWaterLevelAt(p[1], p[3])
    
                local margin = .1
                if (p[2]) < (water_level - margin) then
                    p.in_water = true
                else
                    p.in_water = false
                end
                
                if p.in_water then
                    local upper = water_level + margin
                    local lower = water_level - margin
                    local t = math.clamp((p[2] - lower) / (lower - upper), 0, 1)
                    p.water_gravity_y = p.water_gravity_y + self.buoyancy_force * t --Buoyancy
                end
            end
        end
    end
end


function World:ball(object, x, y, z, radius, weight)
    local body = {
        shape = 'point',
        radius = radius,
        points = {},
        weight = weight or 1,
        active = true,
    }
    add_point(body, x, y, z)
    body.bounding_radius = body.radius
    self.bodies[object] = body
end


function World:capsule(object, ax, ay, az, bx, by, bz, radius, weight)
    local body = {
        shape = 'capsule',
        radius = radius,
        points = {},
        sticks = {},
        weight = weight or 1,
        active = true,
    }
    add_point(body, ax, ay, az)
    add_point(body, bx, by, bz)
    add_stick(body, 1, 2)
    body.bounding_radius = body.sticks[1].len + body.radius/2
    self.bodies[object] = body
end


function World:apply_force(object, fx, fy, fz)
    local body = self.bodies[object]
    if body.active then
        for _, p in ipairs(body.points) do
            p[4] = p[4] + fx * self.tick_period
            p[5] = p[5] + fy * self.tick_period
            p[6] = p[6] + fz * self.tick_period
        end
    end
end


function World:apply_angular_force(object, tx, ty, tz) -- rn just for capsule tho
    local body = self.bodies[object]

    local t_force = vec3(tx, ty, tz)

    local a = body.points[1]
    local b = body.points[2]
    local cx = (a[1] + b[1]) / 2
    local cy = (a[2] + b[2]) / 2
    local cz = (a[3] + b[3]) / 2

    local rax = a[1] - cx
    local ray = a[2] - cy
    local raz = a[3] - cz
    local rbx = b[1] - cx
    local rby = b[2] - cy
    local rbz = b[3] - cz

    local r1 = vec3(rax, ray, raz)
    local r2 = vec3(rbx, rby, rbz)

    local f1 = r1:cross(t_force):normalize() * t_force:len()
    local f2 = r2:cross(t_force):normalize() * t_force:len()

    a[4] = a[4] + f1.x * self.tick_period
    a[5] = a[5] + f1.y * self.tick_period
    a[6] = a[6] + f1.z * self.tick_period

    b[4] = b[4] + f2.x * self.tick_period
    b[5] = b[5] + f2.y * self.tick_period
    b[6] = b[6] + f2.z * self.tick_period
end


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

        p[4], p[5], p[6] = p[1], p[2], p[3]
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
        p[1] = x
        p[2] = y
        p[3] = z
    end
end

function World:activate(object)
    self.bodies[object].active = true
end

function World:deactivate(object)
    self.bodies[object].active = false
end


return World