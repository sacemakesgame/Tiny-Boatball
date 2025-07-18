--[[ EQUATIONS
	F sping		= -k * (x - x rest)		; k = Spring3D constant (stiffness), x = current position
	F damping	= -c * v				; c = damping coefficient, v = velocity
	F total		= F sping + F damping
]]

local Spring3D = Object:extend()

function Spring3D:new(x_rest, k, c)
	self.x = vec3()
	if x_rest then self.x:set(x_rest) end
	self.k = k or 100
	self.c = c or 10
	self.x_rest = self.x:clone()
	self.v = vec3()
end

function Spring3D:update(dt)
    local a = ((self.x - self.x_rest) * (-self.k)) + (self.v * (-self.c))
    self.v:add(a * dt)
    self.x:add(self.v * dt)
end

-- function Spring3D:update(dt)
--     local damping_factor = math.exp(-self.c * dt) -- Exponential damping
--     local displacement = self.x - self.x_rest
--     local spring_force = displacement * -self.k
--     local damping_force = self.v * -self.c 

--     -- Apply forces
--     local acceleration = spring_force + damping_force
--     self.v = self.v * damping_factor + acceleration * dt -- Velocity decay + force application
--     self.x = self.x + self.v * dt -- Position update
-- end


function Spring3D:pull(x_add)
    self.x:add(x_add)
end

function Spring3D:animate(x_rest)
    self.x_rest:set(x_rest)
end

function Spring3D:stabilize()
	self.x:set(self.x_rest)
end

function Spring3D:set_kc(k, c)
	self.k, self.c = k, c
end

return Spring3D