--[[ EQUATIONS
	F sping		= -k * (x - x rest)		; k = Spring2D constant (stiffness), x = current position
	F damping	= -c * v				; c = damping coefficient, v = velocity
	F total		= F sping + F damping
]]

local Spring2D = Object:extend()

function Spring2D:new(x_rest, y_rest, k, c)
	self.x = x_rest or 1
	self.y = y_rest or 1
	self.k = k or 100
	self.c = c or 10
	self.x_rest = self.x
	self.y_rest = self.y
	self.vx = 0
	self.vy = 0
end

function Spring2D:update(dt)
	local a = -self.k * (self.x - self.x_rest) - self.c * self.vx
	self.vx = self.vx + a * dt
	self.x = self.x + self.vx * dt

    local b = -self.k * (self.y - self.y_rest) - self.c * self.vy
	self.vy = self.vy + b * dt
	self.y = self.y + self.vy * dt

end

function Spring2D:pull(x_add, y_add)
	self.x = self.x + x_add
	self.y = self.y + y_add
end

function Spring2D:animate(x_rest, y_rest)
	self.x_rest = x_rest
	self.y_rest = y_rest
end

function Spring2D:set_kc(k, c)
	self.k, self.c = k, c
end

-- function Spring2D:push(x, y, r)
-- 	graphics.push_rotate_scale(x, y, r, self.x)
-- end

return Spring2D