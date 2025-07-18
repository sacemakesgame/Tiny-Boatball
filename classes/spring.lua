-- A Spring class. This is extremely useful for juicing things up.
-- See this article https://github.com/a327ex/blog/issues/60 for more details.
-- The argument passed in are: the initial value of the spring, its stiffness and damping.

--[[ EQUATIONS
	F sping		= -k * (x - x rest)		; k = spring constant (stiffness), x = current position
	F damping	= -c * v				; c = damping coefficient, v = velocity
	F total		= F sping + F damping
]]

local Spring = Object:extend()

function Spring:new(x_rest, k, c)
	self.x = x_rest or 1
	self.k = k or 100
	self.c = c or 10
	self.x_rest = self.x
	self.v = 0
end

function Spring:update(dt)
	local a = -self.k * (self.x - self.x_rest) - self.c * self.v
	self.v = self.v + a * dt
	self.x = self.x + self.v * dt
end

function Spring:pull(x_add)
	self.x = self.x + x_add
end

function Spring:animate(x_rest)
	self.x_rest = x_rest
end

function Spring:stabilize()
	self.x = self.x_rest
end

function Spring:set_kc(k, c)
	self.k, self.c = k, c
end

-- function Spring:push(x, y, r)
-- 	graphics.push_rotate_scale(x, y, r, self.x)
-- end

return Spring