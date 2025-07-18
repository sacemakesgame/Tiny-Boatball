local MeshBatch = Object:extend()
MeshBatch.shader = love.graphics.newShader(pigic.batch)

function MeshBatch:new(owner, json_path, obj_path, obj_texture)
    self.owner = owner
    self.shader:send('projectionMatrix', 'column', self.owner.eye.projection)

    self.instancepositions = {}
    self.instancescale = {}
    self.instancecolor = {}

    self.cubes_data = json.decode(love.filesystem.read(json_path))
    for i, v in ipairs(self.cubes_data) do
        table.insert(self.instancepositions, {v.position[1], v.position[2], v.position[3]})
        table.insert(self.instancescale, {v.scale[1], v.scale[2], v.scale[3]})
        local color = color.teal()
        table.insert(self.instancecolor, {color[1], color[2], color[3], 1})
    end

    local instancemesh = love.graphics.newMesh({ { 'InstancePosition', 'float', 3 } }, self.instancepositions, nil, 'static')
    local instancescale = love.graphics.newMesh({ { 'InstanceScale', 'float', 1 } }, self.instancescale, nil, 'static')
    local instancecolor = love.graphics.newMesh({ { 'InstanceColor', 'float', 4 } }, self.instancecolor, nil, 'static')

    self.mesh = pigic.model(obj_path).mesh
    if obj_texture then
        local texture = love.graphics.newImage(obj_texture)
        texture:setFilter('nearest')
        texture:setWrap('repeat')
        self.mesh:setTexture(texture)
    end
    self.mesh:attachAttribute('InstancePosition', instancemesh, 'perinstance')
    self.mesh:attachAttribute('InstanceScale', instancescale, 'perinstance')
    self.mesh:attachAttribute('InstanceColor', instancecolor, 'perinstance')
    
    self.shader:send('modelMatrix', 'column', pass.transform)
end

function MeshBatch:update(dt)

end

function MeshBatch:draw()
    love.graphics.setShader(self.shader)
    self.shader:send('viewMatrix', 'column', self.owner.eye.transform)

    local instancecount = #self.instancepositions
    love.graphics.drawInstanced(self.mesh, instancecount, 0, 0)

    love.graphics.setShader()
end


return MeshBatch