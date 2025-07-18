local Verlet = Object:extend()


function Verlet:new()
    self.tick_period = 1/60 -- seconds per tick
    self.accumulator = 0

	self.bounce = .9
	self.gravity = 1.2
	self.friction = .95

    self.bodies = {}
end

function Verlet:update(dt)
    -- update physics at constant rate, independent to FPS
	self.accumulator = self.accumulator + dt
    if self.accumulator >= self.tick_period then
        self.accumulator = self.accumulator - self.tick_period
      -- Here be your fixed timestebody.
		self:update_points()
		for i = 1, 3 do
			self:update_sticks()
			self:constrain_points()		
		end	
    end
end

function Verlet:draw()
    self:draw_points()
    self:draw_sticks()
end


function Verlet:update_points()
    for object, body in pairs(self.bodies) do
        if body.type == 'r' then
            for _, p in ipairs(body.points) do
                local vel = (p.t - p.t_old) * self.friction
                p.t_old:set(p.t)
                p.t:add(vel)
                p.t:add(0, self.gravity, 0)
            end
        end
    end
end

function Verlet:draw_points()
    for object, body in pairs(self.bodies) do
        for _, p in ipairs(body.points) do 
            pass.push()
            -- draw ballz
            pass.translate(p.t)
            pass.scale(p.r)
            pass.sphere()
            pass.pop()
        end
    end
end

function Verlet:update_sticks()
    for object, body in pairs(self.bodies) do
        if body.sticks and (body.type == 'r') then
            for _, s in ipairs(body.sticks) do
                local dist = s.pa.t:dist(s.pb.t)
                local diff = body.len - dist
                local percent = diff / dist / 2
                local dir = s.pb.t - s.pa.t
                local offset = dir:scale(percent)
                
                s.pa.t:sub(offset)
                s.pb.t:add(offset)
            end
        end
    end
end

function Verlet:draw_sticks()
    for object, body in pairs(self.bodies) do
        if body.sticks then
            for _, s in ipairs(body.sticks) do
                pass.line(s.pa.t, s.pb.t, s.pa.r*2)
            end
        end
    end
end

function Verlet:constrain_points()
    for object, body in pairs(self.bodies) do
        if body.type == 'r' then
            for _, p in ipairs(body.points) do
                local vel = (p.t - p.t_old) * self.friction
                --[[
                local hw, hl = 1000/2, 1000/2  -- half width, half length
                if body.t.x > hw then
                    body.t.x = hw
                    body.t_old.x = body.t.x + vel.x * self.bounce
                elseif body.t.x < -hw then
                    body.t.x = -hw
                    body.t_old.x = body.t.x + vel.x * self.bounce
                end
                if body.t.z > hl then
                    body.t.z = hl
                    body.t_old.z = body.t.z + vel.z * self.bounce
                elseif body.t.z < -hl then
                    body.t.z = -hl
                    body.t_old.z = body.t.z + vel.z * self.bounce
                end
                ]]
                if p.t.y + p.r > 0 then
                    p.t.y = -p.r
                    p.t_old.y = p.t.y + vel.y * self.bounce
                    p.t_old.x = p.t.x + vel.x * self.friction
                    p.t_old.z = p.t.z + vel.z * self.friction
                end
            end
        end
    end
end

function Verlet:set_type(object, type)
    self.bodies[object].type = type
    if type == 'r' then
        for _, p in ipairs(self.bodies[object].points) do
            p.t_old:set(p.t)
        end
    end
end


local function add_point(body, t, r)
    table.insert(body.points, {
        t = t:clone(),
        t_old = t:clone(),
        r = r,
    })
end

local function add_stick(body, ia, ib)
    table.insert(body.sticks, {
        pa = body.points[ia],
        pb = body.points[ib],
    })
end


function Verlet:point(object, translation, radius)
    local body = {
        points = {},
        type = 'r',
    }
    add_point(body, translation, radius)
    self.bodies[object] = body
end


function Verlet:stick(object, translation, len, pivot, radius)
    -- pivot: range 0 to 1, 0 means at point1, 1 means at point2
    local body = {
        points = {},
        sticks = {},
        type = 'r',
        len = len,
        pivot = pivot,
    }
    add_point(body, translation + vec3(0, 1-pivot, 0):scale(len), radius)
    add_point(body, translation + vec3(0, -pivot, 0):scale(len), radius)
    add_stick(body, 1, 2)
    self.bodies[object] = body
end


function Verlet:apply_force(object, v_force)
    local body = self.bodies[object]
    assert(body.type == 'r', 'ERROR (World.apply_force): body type must be rigid.')
    for _, p in ipairs(body.points) do
        p.t_old:add(v_force * self.tick_period)
    end
end

function Verlet:apply_impulse(object, v_force)
    local body = self.bodies[object]
    assert(body.type == 'r', 'ERROR (World.apply_force): body type must be rigid.')
    for _, p in ipairs(body.points) do
        p.t_old:add(v_force)
    end
end

function Verlet:get_translation(object)
    local body = self.bodies[object]
    if body.sticks then
        return (body.points[1].t + (body.points[2].t - body.points[1].t)*body.pivot)
    else
        return body.points[1].t
    end
end

function Verlet:set_translation(object, translation)
    local body = self.bodies[object]
    assert(body.type == 'k', 'ERROR (World.set_transform): body type must be kinematic.')
    if body.sticks then
        body.points[1].t:set(translation + vec3(0, body.pivot, 0) * body.len)
        body.points[2].t:set(translation + vec3(0, -1+body.pivot, 0) * body.len)
    else
        body.points[1].t:set(translation)
    end
end


function Verlet:set_transform(object, transform)
    local body = self.bodies[object]
    assert(body.type == 'k', 'ERROR (World.set_transform): body type must be kinematic.')
    if body.sticks then
        body.points[1].t:set(transform * vec3(0, body.pivot, 0):scale(body.len))
        body.points[2].t:set(transform * vec3(0, -1+body.pivot, 0):scale(body.len))
        -- body.points[1].t:set(mat4():rotate(love.timer.getTime() * 10, 1, 1, 0) * vec3(0, body.pivot, 0):scale(body.len))
        -- body.points[2].t:set(mat4():rotate(love.timer.getTime() * 10, 1, 1, 0) * vec3(0, -1+body.pivot, 0):scale(body.len))
    else
        body.points[1].t:set(transform)
    end
end



return Verlet