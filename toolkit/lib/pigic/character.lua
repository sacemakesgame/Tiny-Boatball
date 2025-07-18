local function load_texture(path)
	local texture = love.graphics.newImage(path)
	texture:setFilter('nearest')
	texture:setWrap('repeat')
	return texture
end

local Character = Object:extend()

Character.vertex_format = {
    {'VertexPosition', 'float', 3},
    {'VertexTexCoord', 'float', 2},
    {'VertexNormal', 'float', 3},
    {'VertexColor', 'float', 3},
}


function Character:new(path, texture, load_vertex_colors)
	local extension = path:sub(-4,-1)
	local load_vertex_colors = load_vertex_colors or false
	self.verts = pigic.objloader(path, false, true, false, load_vertex_colors)    
	self.mesh = love.graphics.newMesh(self.vertex_format, self.verts, "triangles")

    if texture then
        self.texture = texture and love.graphics.newImage(texture)
        self.texture:setFilter('nearest')
        self.texture:setWrap('repeat')
        self.mesh:setTexture(self.texture)
    end
end


function Character:update(dt)
end


function Character:draw(scale)
    pass.push()
	local shader = gamestate.current().active_shader
    if scale then pass.scale(scale) end
    shader:send('modelMatrix', 'column', pass.transform)
	if shader:hasUniform("modelMatrixInverse") then
        shader:send("modelMatrixInverse", 'column', mat4():transpose(mat4():invert(pass.transform)))
    end

    love.graphics.draw(self.mesh)

    pass.pop()
end



return Character