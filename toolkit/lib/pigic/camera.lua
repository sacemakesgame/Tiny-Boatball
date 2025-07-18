local Camera = Object:extend()

function Camera:new()
    love.mouse.setRelativeMode(true)
    self.translation = vec3(0, 0, -3)
    self.center = vec3()
    self.transform = mat4()--:look_at(self.translation, self.center, self.up_vector)
    self.movespeed = 10
    self.yaw = 0
    self.pitch = 0
    self.look_dir = vec3()
end

function Camera:update(dt)
    local movespeed = 5
    local forward = self.look_dir * movespeed * dt
    local up = vec3(0, 1, 0)
    local right = self.look_dir:cross(up):normalize() * movespeed * dt

    if input:down('up') then
        self.translation:add(forward)
    end
    if input:down('down') then
        self.translation:sub(forward)
    end
    if input:down('right') then
        self.translation:add(right)
    end
    if input:down('left') then
        self.translation:sub(right)
    end

    local target = vec3(0, 0, 1)
    local camera_rot_matrix = mat4()
    camera_rot_matrix:rotate(self.pitch, 1, 0, 0)
    camera_rot_matrix:rotate(self.yaw, 0, 1, 0)
    self.look_dir = camera_rot_matrix * target
    target = self.translation + self.look_dir
    self.transform:look_at(self.translation, target, up)
end

function Camera:draw()
    
end

function Camera:attach()
    love.graphics.push()
    pigic.shader:send("viewMatrix", "column", self.transform)
end

function Camera:detach(pass)
    love.graphics.pop()
end

function Camera:mousemoved(x, y, dx, dy)
	-- if love.mouse.isDown(1) then
		self.pitch = self.pitch - dy * .004
		self.yaw = self.yaw - dx * .004
        -- end

        -- self.pitch = math.clamp(self.pitch, -math.pi/2, math.pi/2)
        self.pitch = math.clamp(self.pitch, math.rad(-89), math.rad(89))
end

function Camera:move(x, y, z)
	self.translation:add(x, y, z)
end

return Camera