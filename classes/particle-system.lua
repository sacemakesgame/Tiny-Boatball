local ParticleSystem = Object:extend()


function ParticleSystem:new(owner, limit)
    self.shader = love.graphics.newShader([[
    uniform mat4 projectionMatrix;
    uniform mat4 viewMatrix;      
    uniform mat4 modelMatrix;     
    
    attribute vec3 VertexNormal;
    attribute vec3 InstancePosition;
    attribute vec3 InstanceRotation;
    attribute float InstanceScale;
    attribute vec3 InstanceColor;
    
    varying vec4 worldPosition;
    varying vec4 viewPosition;
    varying vec4 screenPosition;
    varying vec3 instanceColor;
    
    vec4 position(mat4 transformProjection, vec4 vertexPosition) {
        instanceColor = InstanceColor;
        vec3 instanceRotation = InstanceRotation;
    
        mat4 rotationMatrixX = mat4(
            1.0, 0.0, 0.0, 0.0,
            0.0, cos(instanceRotation.x), -sin(instanceRotation.x), 0.0,
            0.0, sin(instanceRotation.x), cos(instanceRotation.x), 0.0,
            0.0, 0.0, 0.0, 1.0
        );
    
        mat4 rotationMatrixY = mat4(
            cos(instanceRotation.y), 0.0, sin(instanceRotation.y), 0.0,
            0.0, 1.0, 0.0, 0.0,
            -sin(instanceRotation.y), 0.0, cos(instanceRotation.y), 0.0,
            0.0, 0.0, 0.0, 1.0
        );
    
        mat4 rotationMatrixZ = mat4(
            cos(instanceRotation.z), -sin(instanceRotation.z), 0.0, 0.0,
            sin(instanceRotation.z), cos(instanceRotation.z), 0.0, 0.0,
            0.0, 0.0, 1.0, 0.0,
            0.0, 0.0, 0.0, 1.0
        );
    
    
        float instanceScale = InstanceScale;
        mat4 scalingMatrix = mat4(
            instanceScale, 0.0, 0.0, 0.0,
            0.0, instanceScale, 0.0, 0.0,
            0.0, 0.0, instanceScale, 0.0,
            0.0, 0.0, 0.0, 1.0
        );
    
        vertexPosition = rotationMatrixX * vertexPosition; // rotate the vector by rotation matrix X
        vertexPosition = rotationMatrixY * vertexPosition; // rotate the vector by rotation matrix Y
        vertexPosition = rotationMatrixZ * vertexPosition; // rotate the vector by rotation matrix Z
        vertexPosition = scalingMatrix * vertexPosition;
    
        vertexPosition.xyz += InstancePosition;
    
        worldPosition = modelMatrix * vertexPosition;
        viewPosition = viewMatrix * worldPosition;
        screenPosition = projectionMatrix * viewPosition;
    
        screenPosition.y *= -1.0;
    
        return screenPosition;
    }
    ]], [[
        varying vec3 instanceColor;
        vec4 effect(vec4 color, Image tex, vec2 texcoord, vec2 pixcoord) {
            vec4 texcolor = Texel(tex, texcoord);    
            if (texcolor.a == 0.0) discard; // get rid of transparent pixels
        
            //return texcolor * color;
            return vec4(instanceColor, 1.);
        }
    ]])
    self.position = vec3()
    self.sizes = {1}
    self.colors = {color.red(), color.blue(), color.orange()}
    self.velocities = {20}
    self.direction = vec3(1, 0, 0)
    self.spread = {r = 0, x = 0, y = 0, z = 0}
    self.lifetime = 1
    self.limit = limit or 80

    self.instanceposition = {}
    self.instancerotation = {}
    self.instancescale = {}
    self.instancecolor = {}
    
    self._instancedirection = {}
    self._instancelifetime = {}
    
    for i = 1, self.limit do
        table.insert(self.instanceposition, {})
        table.insert(self.instancerotation, {})
        table.insert(self.instancescale, {})
        table.insert(self.instancecolor, {})
        table.insert(self._instancedirection, {})
        table.insert(self._instancelifetime, 0)
    end

    self.active_count = 0


    self.instanceposition_mesh = love.graphics.newMesh({ { "InstancePosition", "float", 3 } }, self.instanceposition, nil, "dynamic")
    self.instancerotation_mesh = love.graphics.newMesh({ { "InstanceRotation", "float", 3 } }, self.instancerotation, nil, "dynamic")
    self.instancescale_mesh = love.graphics.newMesh({ { "InstanceScale", "float", 1 } }, self.instancescale, nil, "dynamic")
    self.instancecolor_mesh = love.graphics.newMesh({ { "InstanceColor", "float", 3 } }, self.instancecolor, nil, "dynamic")

    -- self.mesh = pass.primitives.sphere
    self.mesh = love.graphics.newMesh(pigic.model.vertex_format, pigic.objloader('game-assets/_primitive/sphere.obj', false, true, false), "triangles")
    self.mesh:attachAttribute("InstancePosition", self.instanceposition_mesh, "perinstance")
    self.mesh:attachAttribute("InstanceRotation", self.instancerotation_mesh, "perinstance")
    self.mesh:attachAttribute("InstanceScale", self.instancescale_mesh, "perinstance")
    self.mesh:attachAttribute("InstanceColor", self.instancecolor_mesh, "perinstance")

    self.shader:send("projectionMatrix", "column", gamestate.current().eye.projection)
    self.shader:send("modelMatrix", "column", mat4())
end



function ParticleSystem:update(dt)
    for i = self.active_count, 1, -1 do
        self._instancelifetime[i] = self._instancelifetime[i] - dt
        if self._instancelifetime[i] <= 0 then
            table.remove(self.instanceposition, 1)
            table.remove(self.instancerotation, 1)
            table.remove(self.instancecolor, 1)
            table.remove(self.instancescale, 1)
            table.remove(self._instancedirection, 1)
            table.remove(self._instancelifetime, 1)

            table.insert(self.instanceposition, {})
            table.insert(self.instancerotation, {})
            table.insert(self.instancecolor, {})
            table.insert(self.instancescale, {})
            table.insert(self._instancedirection, {})
            table.insert(self._instancelifetime, 0)
            
            self.active_count = self.active_count - 1
        else
            local t = 1 - (self._instancelifetime[i] / self.lifetime) -- useful for velocity & size interpolations
    
            -- translation
            local velocity
            if #self.velocities > 1 then
                local s = math.remap(t, 0, 1, 1, #self.velocities)
                local j = math.floor(s)
                s = s - j 
                velocity = math.lerp(self.velocities[j], self.velocities[j + 1], s)
            else 
                velocity = self.velocities[1]
            end
            self.instanceposition[i][1] = self.instanceposition[i][1] + self._instancedirection[i][1] * velocity * dt
            self.instanceposition[i][2] = self.instanceposition[i][2] + self._instancedirection[i][2] * velocity * dt
            self.instanceposition[i][3] = self.instanceposition[i][3] + self._instancedirection[i][3] * velocity * dt

            -- scale
            local size
            if #self.sizes > 1 then
                local s = math.remap(t, 0, 1, 1, #self.sizes)
                local j = math.floor(s)
                j = math.clamp(j, 1, #self.sizes - 1)
                s = s - j
                assert(self.sizes[j+1], j)
                size = math.lerp(self.sizes[j], self.sizes[j + 1], s)
            else
                size = self.sizes[1]
            end 
            self.instancescale[i][1] = size
        
    
    
            -- colors
            local clr
            if #self.colors > 1 then
                local s = math.remap(t, 0, 1, 1, #self.colors)
                local j = math.floor(s)
                j = math.clamp(j, 1, #self.colors - 1)
                s = s - j
                clr = color.lerp(self.colors[j], self.colors[j + 1], s)
            else
                clr = self.colors[1]
            end
            self.instancecolor[i][1] = clr[1]
            self.instancecolor[i][2] = clr[2]
            self.instancecolor[i][3] = clr[3]
        end
    end

    self.instanceposition_mesh:setVertices(self.instanceposition)
    self.instancerotation_mesh:setVertices(self.instancerotation)
    self.instancescale_mesh:setVertices(self.instancescale)
    self.instancecolor_mesh:setVertices(self.instancecolor)
end


function ParticleSystem:draw()
    local shader = love.graphics.getShader()

    love.graphics.setShader(self.shader)
    self.shader:send('viewMatrix', 'column', gamestate.current().eye.transform)
    love.graphics.drawInstanced(self.mesh, self.active_count, 0, 0)

    love.graphics.setShader(shader)
end


function ParticleSystem:emit(amount)
    for i = 1, amount do
        self.instanceposition[self.active_count + 1][1] = self.position.x
        self.instanceposition[self.active_count + 1][2] = self.position.y
        self.instanceposition[self.active_count + 1][3] = self.position.z

        self.instancerotation[self.active_count + 1][1] = 0
        self.instancerotation[self.active_count + 1][2] = 0
        self.instancerotation[self.active_count + 1][3] = 0

        self.instancescale[self.active_count + 1][1] = self.sizes[1]

        self.instancecolor[self.active_count + 1][1] = self.colors[1][1]
        self.instancecolor[self.active_count + 1][2] = self.colors[1][2]
        self.instancecolor[self.active_count + 1][3] = self.colors[1][3]
        self.instancecolor[self.active_count + 1][4] = 1
        
        self._instancedirection[self.active_count + 1][1] = self.direction.x + random:float(-self.spread.r, self.spread.r) * self.spread.x
        self._instancedirection[self.active_count + 1][2] = self.direction.y + random:float(-self.spread.r, self.spread.r) * self.spread.y
        self._instancedirection[self.active_count + 1][3] = self.direction.z + random:float(-self.spread.r, self.spread.r) * self.spread.z
        
        self._instancelifetime[self.active_count + 1] = self.lifetime

        if self.active_count >= (self.limit-1) then
            table.remove(self.instanceposition, 1)
            table.remove(self.instancerotation, 1)
            table.remove(self.instancecolor, 1)
            table.remove(self.instancescale, 1)
            table.remove(self._instancedirection, 1)
            table.remove(self._instancelifetime, 1)

            table.insert(self.instanceposition, {})
            table.insert(self.instancerotation, {})
            table.insert(self.instancecolor, {})
            table.insert(self.instancescale, {})
            table.insert(self._instancedirection, {})
            table.insert(self._instancelifetime, 0)
        else
            self.active_count = self.active_count + 1
        end
    end
end


function ParticleSystem:set_position(x, y, z)
    if vec3.is_vec3(x) then
        self.position:set(x)
    else
        self.position:set(x, y, z)
    end
    return self
end

function ParticleSystem:set_spread(rad, x, y, z)
    self.spread.r = rad
    self.spread.x = x or 1
    self.spread.y = y or 1
    self.spread.z = z or 1
    local len =  math.sqrt(self.spread.x * self.spread.x + self.spread.y * self.spread.y + self.spread.z * self.spread.z)
    self.spread.x = self.spread.x / len
    self.spread.y = self.spread.y / len
    self.spread.z = self.spread.z / len
    return self
end

function ParticleSystem:set_velocities(...)
    self.velocities = {...}
    return self
end

function ParticleSystem:set_lifetime(d)
    self.lifetime = d
    return self
end

function ParticleSystem:set_sizes(...)
    self.sizes = {...}
    return self
end

function ParticleSystem:set_colors(...)
    self.colors = {...}
    return self
end

function ParticleSystem:set_direction(x, y, z)
    if vec3.is_vec3(x) then
        self.direction:set(x)
    else
        self.direction:set(x, y, z)
    end
    self.direction:normalize()
    return self
end

function ParticleSystem:set_mesh(m)
    self.mesh = m
    self.mesh:attachAttribute("InstancePosition", self.instanceposition_mesh, "perinstance")
    self.mesh:attachAttribute("InstanceRotation", self.instancerotation_mesh, "perinstance")
    self.mesh:attachAttribute("InstanceScale", self.instancescale_mesh, "perinstance")
    self.mesh:attachAttribute("InstanceColor", self.instancecolor_mesh, "perinstance")
    return self
 end
   



return ParticleSystem