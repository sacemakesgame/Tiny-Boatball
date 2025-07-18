-- written by groverbuger for g3d
-- september 2021
-- MIT license

-- pirated by PIGIC --


local function load_texture(path)
	local texture = love.graphics.newImage(path)
	texture:setFilter('nearest')
	texture:setWrap('repeat')
	return texture
end

local Model = Object:extend()

Model.textures = {}
Model.textures.palette = load_texture('game-assets/png/palette.png')

Model.vertex_format = {
    {'VertexPosition', 'float', 3},
    {'VertexTexCoord', 'float', 2},
    {'VertexNormal', 'float', 3},
}


function Model:new(path)
	local objects = pigic.objloader(path, false, true, true)
	self.verts = {}
	self.points = {}
	for name, vert in pairs(objects) do
		if name:find('COLLIDER') then 
			self.collider = vert
		elseif name:find('_') then
			self.points[name] = vec3(vert[1][1], vert[1][2], vert[1][3]) -- first vert's position (hacky way tho)
		else
			if not self.verts[name] then self.verts[name] = vert
			else for _, v in ipairs(vert) do table.insert(self.verts[name], v) end end
		end
	end
	self.meshes = {}
	for k, v in pairs(self.verts) do
		self.meshes[k] = love.graphics.newMesh(self.vertex_format, v, 'triangles')
		for tag, texture in pairs(self.textures) do
			if k:find(tag) then
				self.meshes[k]:setTexture(texture)
				break
			end
		end
	end
end


function Model:update(dt)

end


function Model:draw(scale)
    pass.push()
	local shader = gamestate.current().active_shader
    if scale then pass.scale(scale) end
    shader:send('modelMatrix', 'column', pass.transform)
	if shader:hasUniform("modelMatrixInverse") then
        shader:send("modelMatrixInverse", 'column', mat4():transpose(mat4():invert(pass.transform)))
    end

	for _, v in pairs(self.meshes) do
		love.graphics.draw(v)
	end

    pass.pop()
end


return Model