local pass = {}
pass.transform = mat4()
pass.matrix_stack = {}

function pass.translate(...)
    pass.transform:translate(...)
end

function pass.rotate(...)
    pass.transform:rotate(...)
end

function pass.scale(...)
    pass.transform:scale(...)
end

function pass.push()    
    table.insert(pass.matrix_stack, pass.transform:clone())

end

function pass.pop()
    assert(pass.matrix_stack[#pass.matrix_stack], 'pigic.pass: more pop than push?')
    pass.transform:set(table.pop(pass.matrix_stack))
end



local vertex_format = {
    {"VertexPosition", "float", 3},
    {"VertexTexCoord", "float", 2},
    {"VertexNormal", "float", 3},
    -- {"VertexColor", "byte", 4},
}

pass.primitives = {
    -- cube = pigic.model('assets/_primitive/cube.obj'),
    -- sphere = pigic.model('assets/_primitive/sphere.obj'),
    -- soccerball = pigic.model('assets/_primitive/soccerball.obj'),
    cube = love.graphics.newMesh(vertex_format, pigic.objloader('game-assets/_primitive/cube.obj', false, true, false), "triangles"),
    sphere = love.graphics.newMesh(vertex_format, pigic.objloader('game-assets/_primitive/sphere.obj', false, true, false), "triangles"),
}

for k, v in pairs(pass.primitives) do
    pass[k] = function(matrix)
        local matrix = matrix or mat4()
        -- local transformed = mat4.mul(matrix, pass.transform, matrix)
        local transformed = mat4.mul(matrix, matrix, pass.transform)
        -- gamestate.current().active_shader:send
        local shader = gamestate.current().active_shader
        shader:send('modelMatrix', 'column', transformed)
        if shader:hasUniform('modelMatrixInverse') then
            shader:send('modelMatrixInverse', 'column', mat4():transpose(mat4():invert(transformed)))
        end
        love.graphics.draw(v)
    end
end


local function flatcircle(segments)
	segments = segments or 32
	local vertices = {}
    -- Each vertex has: {x, y, z, u, v, nx, ny, nz}
    -- The first vertex is at the origin (0, 0) and will be the center of the circle.
	table.insert(vertices, {0, 0, 0, 5, .5, 0, 0, -1})
	for i=0, segments do
		local angle = (i / segments) * math.pi * 2
		local x = math.cos(angle)
		local y = math.sin(angle)
        local u = (x + 1) / 2  -- Scale from [-1, 1] to [0, 1]
        local v = (y + 1) / 2
		table.insert(vertices, {x, y, 0, u, v, 0, 0, -1})
	end	
    return love.graphics.newMesh(pigic.model.vertex_format, vertices, 'fan')
end

local function flatplane(w, h)
    local w = w or 1
    local h = h or 1
    local half_width = w / 2
    local half_height = h / 2
    local vertices = {
        -- Each vertex has: {x, y, z, u, v, nx, ny, nz}
        {-half_width, -half_height, 0, 0, 0, 0, 0, -1}, -- Bottom-left corner
        {half_width,  -half_height, 0, 1, 0, 0, 0, -1}, -- Bottom-right corner
        {-half_width, half_height,  0, 0, 1, 0, 0, -1}, -- Top-left corner
        {half_width,  half_height,  0, 1, 1, 0, 0, -1}, -- Top-right corner
    }
    return love.graphics.newMesh(pigic.model.vertex_format, vertices, 'strip')
end

local function flatline_stream()
    local vertices = {
        -- Each vertex has: {x, y, z, u, v, nx, ny, nz}
        {0, 0, 0, 0, 0, 0, 0, -1}, -- v1 left
        {0, 0, 0, 1, 0, 0, 0, -1}, -- v1 right
        {0, 0, 0, 0, 1, 0, 0, -1}, -- v2 left
        {0, 0, 0, 1, 1, 0, 0, -1}, -- v2 right
    }
    return love.graphics.newMesh(pigic.model.vertex_format, vertices, 'strip', 'stream')
end

local function cylinder(radius, height, segments)
    segments = segments or 32
    radius = radius or 1
    height = height or 1
    
    local vertices = {}
    local half_height = height / 2
    
    -- Create vertices for the bottom and top circles and the side surface
    for i = 0, segments do
        local angle = (i / segments) * math.pi * 2
        local x = math.cos(angle) * radius
        local y = math.sin(angle) * radius
        local u = (i / segments)
        
        -- Bottom circle
        table.insert(vertices, {x, y, -half_height, u, 1, 0, 0, -1}) -- Normal points down
        
        -- Top circle
        table.insert(vertices, {x, y, half_height, u, 0, 0, 0, 1}) -- Normal points up
    end
    
    -- Create the side surface
    for i = 0, segments do
        local angle = (i / segments) * math.pi * 2
        local x = math.cos(angle) * radius
        local y = math.sin(angle) * radius
        local u = (i / segments)
        
        -- Side vertices (two per segment: bottom and top)
        table.insert(vertices, {x, y, -half_height, u, 1, x, y, 0}) -- Normal points outward
        table.insert(vertices, {x, y, half_height, u, 0, x, y, 0})
    end
    
    return love.graphics.newMesh(pigic.model.vertex_format, vertices, 'strip')
end


local function line3d(points_count, segments)
    -- Generate cylinder vertices in local space
    local vertices = {}

    -- Create vertices for the bottom and top circles
    for i = 0, segments do
        -- Bottom circle vertex
        -- table.insert(vertices, {0, 0, 0, 0, 1, 0, 0, -1}) -- Normal points down
        -- -- Top circle vertex
        -- table.insert(vertices, {0, 0, 0, 0, 0, 0, 0, 1}) -- Normal points up

        for j = 1, points_count do
            table.insert(vertices, {0, 0, 0, 0, 0, 0, 0, 1}) -- Normal points up            
        end
    end

    -- Create vertices for the side surface
    for i = 0, segments do
        -- Side vertices (bottom and top for each segment)
        -- table.insert(vertices, {0, 0, 0, 0, 1, 0, 0, 0}) -- Normal points outward
        -- table.insert(vertices, {0, 0, 0, 0, 0, 0, 0, 0})
        
        for j = 1, points_count do
            table.insert(vertices, {0, 0, 0, 0, 0, 0, 0, 1}) -- Normal points up            
        end
    end

    return love.graphics.newMesh(pigic.model.vertex_format, vertices, 'strip', 'stream')
end

-- local function line3d(p1, p2, radius, segments)
--     local segments = segments or 32
--     local radius = radius or 1

--     -- Calculate the direction vector and height
--     local dx, dy, dz = p2.x - p1.x, p2.y - p1.y, p2.z - p1.z
--     local height = math.sqrt(dx * dx + dy * dy + dz * dz)
--     local dir = {dx / height, dy / height, dz / height} -- Normalize direction

--     -- Local cylinder basis (aligned with the z-axis initially)
--     local up = {0, 0, 1}

--     -- Create a rotation matrix to align `up` with `dir`
--     local right = {
--         up[2] * dir[3] - up[3] * dir[2],
--         up[3] * dir[1] - up[1] * dir[3],
--         up[1] * dir[2] - up[2] * dir[1],
--     }
--     local rightLength = math.sqrt(right[1] * right[1] + right[2] * right[2] + right[3] * right[3])
--     if rightLength > 0 then
--         right = {right[1] / rightLength, right[2] / rightLength, right[3] / rightLength}
--     else
--         right = {1, 0, 0} -- Fallback if `dir` is already aligned with `up`
--     end

--     local forward = {
--         dir[2] * right[3] - dir[3] * right[2],
--         dir[3] * right[1] - dir[1] * right[3],
--         dir[1] * right[2] - dir[2] * right[1],
--     }

--     -- Transformation matrix
--     local transform = {
--         right[1], forward[1], dir[1], p1.x,
--         right[2], forward[2], dir[2], p1.y,
--         right[3], forward[3], dir[3], p1.z,
--     }

--     -- Generate cylinder vertices in local space
--     local vertices = {}

--     -- Create vertices for the bottom and top circles
--     for i = 0, segments do
--         local angle = (i / segments) * math.pi * 2
--         local x = math.cos(angle) * radius
--         local y = math.sin(angle) * radius
--         local u = i / segments

--         -- Bottom circle vertex
--         table.insert(vertices, {x, y, 0, u, 1, 0, 0, -1}) -- Normal points down

--         -- Top circle vertex
--         table.insert(vertices, {x, y, height, u, 0, 0, 0, 1}) -- Normal points up
--     end

--     -- Create vertices for the side surface
--     for i = 0, segments do
--         local angle = (i / segments) * math.pi * 2
--         local x = math.cos(angle) * radius
--         local y = math.sin(angle) * radius
--         local u = i / segments

--         -- Side vertices (bottom and top for each segment)
--         table.insert(vertices, {x, y, 0, u, 1, x, y, 0}) -- Normal points outward
--         table.insert(vertices, {x, y, height, u, 0, x, y, 0})
--     end

--     -- Apply the transformation to all vertices
--     local function transformVertex(vertex)
--         local x, y, z = vertex[1], vertex[2], vertex[3]
--         vertex[1] = transform[1] * x + transform[2] * y + transform[3] * z + transform[4]
--         vertex[2] = transform[5] * x + transform[6] * y + transform[7] * z + transform[8]
--         vertex[3] = transform[9] * x + transform[10] * y + transform[11] * z + transform[12]
--     end

--     for _, v in ipairs(vertices) do
--         transformVertex(v)
--     end

--     return love.graphics.newMesh(pigic.model.vertex_format, vertices, 'strip', 'stream')
-- end


pass.primitives.circle = flatcircle()
pass.primitives.circle8 = flatcircle(8)
pass.primitives.plane = flatplane()
pass.primitives.line = flatline_stream()
pass.primitives.cylinder = cylinder()
pass.primitives.line8 = line3d(2, 8)
pass.primitives.line3 = line3d(2, 3)
-- pass.primitives.plane:setTexture(love.graphics.newImage('assets/squixture.jpg'))

function pass.cylinder(matrix)
    local matrix = matrix or mat4()
    pass.push()
    local transformed = mat4.mul(mat4(), matrix, pass.transform)
    local shader = gamestate.current().active_shader
    shader:send('modelMatrix', 'column', transformed)
    if shader:hasUniform('modelMatrixInverse') then
        shader:send('modelMatrixInverse', 'column', mat4():transpose(mat4():invert(transformed)))
    end
    love.graphics.draw(pass.primitives.cylinder)
    pass.pop()
end



function pass.circle(matrix)
    local matrix = matrix or mat4()
    pass.push()
    local transformed = mat4.mul(mat4(), matrix, pass.transform)
    gamestate.current().active_shader:send('modelMatrix', 'column', transformed)
    love.graphics.draw(pass.primitives.circle)
    pass.pop()
end

function pass.circle8(matrix)
    local matrix = matrix or mat4()
    pass.push()
    local transformed = mat4.mul(mat4(), matrix, pass.transform)
    gamestate.current().active_shader:send('modelMatrix', 'column', transformed)
    love.graphics.draw(pass.primitives.circle8)
    pass.pop()
end

function pass.circle_billboard(matrix)
    local matrix = matrix or mat4()
    pass.push()
    local eye = gamestate.current().eye.transform:clone()
    eye:set_translation(vec3())
    pass.transform:mul(mat4():invert(eye), pass.transform)
    local transformed = mat4.mul(mat4(), matrix, pass.transform)
    gamestate.current().active_shader:send('modelMatrix', 'column', transformed)
    love.graphics.draw(pass.primitives.circle)
    pass.pop()
end

function pass.plane(matrix)
    local matrix = matrix or mat4()
    pass.push()
    
    local transformed = mat4.mul(mat4(), matrix, pass.transform)
    gamestate.current().active_shader:send('modelMatrix', 'column', transformed)
    love.graphics.draw(pass.primitives.plane)
    pass.pop()
end

function pass.plane_billboard(matrix)
    local matrix = matrix or mat4()
    pass.push()
    local eye = gamestate.current().eye.transform:clone()
    eye:set_translation(vec3())
    pass.transform:mul(mat4():invert(eye), pass.transform)
    local transformed = mat4.mul(mat4(), matrix, pass.transform)
    gamestate.current().active_shader:send('modelMatrix', 'column', transformed)
    love.graphics.draw(pass.primitives.plane)
    pass.pop()
end

function pass.line(v1, v2, thickness)
    pass.push()
    local eye = gamestate.current().eye.transform
	pass.transform:mul(mat4():invert(eye), pass.transform)
    local v1 = mat4.mul_vec3_perspective(vec3(), eye, v1)
    local v2 = mat4.mul_vec3_perspective(vec3(), eye, v2)
    gamestate.current().active_shader:send('modelMatrix', 'column', pass.transform)
    local thickness = thickness or 20

    local angle = math.atan2(v2.y - v1.y, v2.x - v1.x) + math.pi/2
    local v1xl = v1.x + math.cos(angle) * thickness/2
    local v1xr = v1.x - math.cos(angle) * thickness/2
    local v1yl = v1.y + math.sin(angle) * thickness/2
    local v1yr = v1.y - math.sin(angle) * thickness/2
    local v2xl = v2.x + math.cos(angle) * thickness/2
    local v2xr = v2.x - math.cos(angle) * thickness/2
    local v2yl = v2.y + math.sin(angle) * thickness/2
    local v2yr = v2.y - math.sin(angle) * thickness/2


    local vertices = {
        -- Each vertex has: {x, y, z, u, v, nx, ny, nz}
        {v1xl, v1yl, v1.z, 0, 0, 1, 1, 1}, -- v1 left
        {v1xr, v1yr, v1.z, 1, 0, 1, 1, 1}, -- v1 right
        {v2xl, v2yl, v2.z, 0, 1, 1, 1, 1}, -- v2 left
        {v2xr, v2yr, v2.z, 1, 1, 1, 1, 1}, -- v2 right
    }
    pass.primitives.line:setVertices(vertices)
    love.graphics.draw(pass.primitives.line)
    pass.pop()
end

function pass.line8(p1, p2, radius1, radius2)
    local segments = 8
    local radius1 = radius1 or 1
    local radius2 = radius2 or radius1

    pass.push()
    local shader = gamestate.current().active_shader
    shader:send('modelMatrix', 'column', pass.transform)
    if shader:hasUniform('modelMatrixInverse') then      --dk why, but don't need to?? or.. mustn't?
        shader:send('modelMatrixInverse', 'column', mat4():transpose(mat4():invert(pass.transform)))
    end

    -- Calculate the direction vector and height
    local dx, dy, dz = p2.x - p1.x, p2.y - p1.y, p2.z - p1.z
    local height = math.sqrt(dx * dx + dy * dy + dz * dz)
    local dir = {dx / height, dy / height, dz / height} -- Normalize direction

    -- Local cylinder basis (aligned with the z-axis initially)
    local up = {0, 0, 1}

    -- Create a rotation matrix to align `up` with `dir`
    local right = {
        up[2] * dir[3] - up[3] * dir[2],
        up[3] * dir[1] - up[1] * dir[3],
        up[1] * dir[2] - up[2] * dir[1],
    }
    local rightLength = math.sqrt(right[1] * right[1] + right[2] * right[2] + right[3] * right[3])
    if rightLength > 0 then
        right = {right[1] / rightLength, right[2] / rightLength, right[3] / rightLength}
    else
        right = {1, 0, 0} -- Fallback if `dir` is already aligned with `up`
    end

    local forward = {
        dir[2] * right[3] - dir[3] * right[2],
        dir[3] * right[1] - dir[1] * right[3],
        dir[1] * right[2] - dir[2] * right[1],
    }

    -- Transformation matrix
    local transform = {
        right[1], forward[1], dir[1], p1.x,
        right[2], forward[2], dir[2], p1.y,
        right[3], forward[3], dir[3], p1.z,
    }

    -- Generate cylinder vertices in local space
    local vertices = {}

    -- Create vertices for the bottom and top circles
    for i = 0, segments do
        local angle = (i / segments) * math.pi * 2
        local bx = math.cos(angle) * radius1
        local by = math.sin(angle) * radius1
        local tx = math.cos(angle) * radius2
        local ty = math.sin(angle) * radius2
        local u = i / segments

        -- Bottom circle vertex
        table.insert(vertices, {bx, by, 0, u, 1, 0, 0, -1}) -- Normal points down

        -- Top circle vertex
        table.insert(vertices, {tx, ty, height, u, 0, 0, 0, 1}) -- Normal points up
    end

    -- Create vertices for the side surface
    for i = 0, segments do
        local angle = (i / segments) * math.pi * 2
        local bx = math.cos(angle) * radius1
        local by = math.sin(angle) * radius1
        local tx = math.cos(angle) * radius2
        local ty = math.sin(angle) * radius2
        local u = i / segments

        -- Calculate the outward-facing normal
        local nx, ny = math.cos(angle), math.sin(angle) -- Normal direction
        -- Side vertices (bottom and top for each segment)
        table.insert(vertices, {bx, by, 0, u, 1, nx, ny, 0}) -- Bottom vertex with correct normal
        table.insert(vertices, {tx, ty, height, u, 0, nx, ny, 0}) -- Top vertex with correct normal
    end

    -- Apply the transformation to all vertices
    local function transformVertex(vertex)
        local x, y, z = vertex[1], vertex[2], vertex[3]
        -- Transform the position
        vertex[1] = transform[1] * x + transform[2] * y + transform[3] * z + transform[4]
        vertex[2] = transform[5] * x + transform[6] * y + transform[7] * z + transform[8]
        vertex[3] = transform[9] * x + transform[10] * y + transform[11] * z + transform[12]
    
        -- Transform the normal (ignoring translation)
        local nx, ny, nz = vertex[6], vertex[7], vertex[8]
        vertex[6] = transform[1] * nx + transform[2] * ny + transform[3] * nz
        vertex[7] = transform[5] * nx + transform[6] * ny + transform[7] * nz
        vertex[8] = transform[9] * nx + transform[10] * ny + transform[11] * nz
    
        -- Normalize the normal after transformation
        local length = math.sqrt(vertex[6] * vertex[6] + vertex[7] * vertex[7] + vertex[8] * vertex[8])
        if length > 0 then
            vertex[6] = vertex[6] / length
            vertex[7] = vertex[7] / length
            vertex[8] = vertex[8] / length
        end
    end
    
    for _, v in ipairs(vertices) do
        transformVertex(v)
    end
    pass.primitives.line8:setVertices(vertices)
    love.graphics.draw(pass.primitives.line8)
    pass.pop()
end



function pass.line3(p1, p2, radius1, radius2, angle)
    local segments = 3
    local radius1 = radius1 or 1
    local radius2 = radius2 or radius1
    local angle_offset = angle or 0

    pass.push()
    local shader = gamestate.current().active_shader
    shader:send('modelMatrix', 'column', pass.transform)
    if shader:hasUniform('modelMatrixInverse') then      --dk why, but don't need to?? or.. mustn't?
        shader:send('modelMatrixInverse', 'column', mat4():transpose(mat4():invert(pass.transform)))
    end

    -- Calculate the direction vector and height
    local dx, dy, dz = p2.x - p1.x, p2.y - p1.y, p2.z - p1.z
    local height = math.sqrt(dx * dx + dy * dy + dz * dz)
    local dir = {dx / height, dy / height, dz / height} -- Normalize direction

    -- Local cylinder basis (aligned with the z-axis initially)
    local up = {0, 0, 1}

    -- Create a rotation matrix to align `up` with `dir`
    local right = {
        up[2] * dir[3] - up[3] * dir[2],
        up[3] * dir[1] - up[1] * dir[3],
        up[1] * dir[2] - up[2] * dir[1],
    }
    local rightLength = math.sqrt(right[1] * right[1] + right[2] * right[2] + right[3] * right[3])
    if rightLength > 0 then
        right = {right[1] / rightLength, right[2] / rightLength, right[3] / rightLength}
    else
        right = {1, 0, 0} -- Fallback if `dir` is already aligned with `up`
    end

    local forward = {
        dir[2] * right[3] - dir[3] * right[2],
        dir[3] * right[1] - dir[1] * right[3],
        dir[1] * right[2] - dir[2] * right[1],
    }

    -- Transformation matrix
    local transform = {
        right[1], forward[1], dir[1], p1.x,
        right[2], forward[2], dir[2], p1.y,
        right[3], forward[3], dir[3], p1.z,
    }

    -- Generate cylinder vertices in local space
    local vertices = {}

    -- Create vertices for the bottom and top circles
    for i = 0, segments do
        local angle = (i / segments) * math.pi * 2 + angle_offset
        local bx = math.cos(angle) * radius1
        local by = math.sin(angle) * radius1
        local tx = math.cos(angle) * radius2
        local ty = math.sin(angle) * radius2
        local u = i / segments

        -- Bottom circle vertex
        table.insert(vertices, {bx, by, 0, u, 1, 0, 0, -1}) -- Normal points down

        -- Top circle vertex
        table.insert(vertices, {tx, ty, height, u, 0, 0, 0, 1}) -- Normal points up
    end

    -- Create vertices for the side surface
    for i = 0, segments do
        local angle = (i / segments) * math.pi * 2 + angle_offset
        local bx = math.cos(angle) * radius1
        local by = math.sin(angle) * radius1
        local tx = math.cos(angle) * radius2
        local ty = math.sin(angle) * radius2
        local u = i / segments

        -- Calculate the outward-facing normal
        local nx, ny = math.cos(angle), math.sin(angle) -- Normal direction
        -- Side vertices (bottom and top for each segment)
        table.insert(vertices, {bx, by, 0, u, 1, nx, ny, 0}) -- Bottom vertex with correct normal
        table.insert(vertices, {tx, ty, height, u, 0, nx, ny, 0}) -- Top vertex with correct normal
    end

    -- Apply the transformation to all vertices
    local function transformVertex(vertex)
        local x, y, z = vertex[1], vertex[2], vertex[3]
        -- Transform the position
        vertex[1] = transform[1] * x + transform[2] * y + transform[3] * z + transform[4]
        vertex[2] = transform[5] * x + transform[6] * y + transform[7] * z + transform[8]
        vertex[3] = transform[9] * x + transform[10] * y + transform[11] * z + transform[12]
    
        -- Transform the normal (ignoring translation)
        local nx, ny, nz = vertex[6], vertex[7], vertex[8]
        vertex[6] = transform[1] * nx + transform[2] * ny + transform[3] * nz
        vertex[7] = transform[5] * nx + transform[6] * ny + transform[7] * nz
        vertex[8] = transform[9] * nx + transform[10] * ny + transform[11] * nz
    
        -- Normalize the normal after transformation
        local length = math.sqrt(vertex[6] * vertex[6] + vertex[7] * vertex[7] + vertex[8] * vertex[8])
        if length > 0 then
            vertex[6] = vertex[6] / length
            vertex[7] = vertex[7] / length
            vertex[8] = vertex[8] / length
        end
    end
    
    for _, v in ipairs(vertices) do
        transformVertex(v)
    end
    pass.primitives.line3:setVertices(vertices)
    love.graphics.draw(pass.primitives.line3)
    pass.pop()
end


local function rotateY(v, angle)
    local cosA = math.cos(angle)
    local sinA = math.sin(angle)
    return vec3(
        v.x * cosA - v.z * sinA,
        v.y,
        v.x * sinA + v.z * cosA
    )
end


function pass.wiresphere(center, radius, segments, thickness)
    local segments = segments or 8
    local thickness = thickness or .1
    local points = {}

    -- Horizontal rings (like Saturn's rings), at different Y levels
    for i = 1, segments-1 do
        local phi = (i / segments) * math.pi - math.pi / 2  -- from -90 to +90 degrees
        local r = radius * math.cos(phi)
        local y = radius * math.sin(phi)
        for j = 1, segments do
            local theta1 = (j - 1) / segments * 2 * math.pi
            local theta2 = j / segments * 2 * math.pi

            local x1 = r * math.cos(theta1)
            local z1 = r * math.sin(theta1)
            local x2 = r * math.cos(theta2)
            local z2 = r * math.sin(theta2)
            pass.line3(
                vec3(x1, y, z1):add(center),
                vec3(x2, y, z2):add(center), thickness
            )
        end
    end

    -- XY Plane (like Saturn's rings)
    for i = 1, segments do
        local theta1 = (i - 1) / segments * 2 * math.pi
        local theta2 = i / segments * 2 * math.pi
        local x1 = radius * math.cos(theta1)
        local y1 = radius * math.sin(theta1)
        local x2 = radius * math.cos(theta2)
        local y2 = radius * math.sin(theta2)
        pass.line3(
            vec3(x1, y1, 0):add(center),
            vec3(x2, y2, 0):add(center), thickness
        )
    end

    -- YZ Plane
    for i = 1, segments do
        local theta1 = (i - 1) / segments * 2 * math.pi
        local theta2 = i / segments * 2 * math.pi
        local y1 = radius * math.cos(theta1)
        local z1 = radius * math.sin(theta1)
        local y2 = radius * math.cos(theta2)
        local z2 = radius * math.sin(theta2)
        pass.line3(
            vec3(0, y1, z1):add(center),
            vec3(0, y2, z2):add(center), thickness
        )
    end

    -- -- XZ Plane
    -- for i = 1, segments do
    --     local theta1 = (i - 1) / segments * 2 * math.pi
    --     local theta2 = i / segments * 2 * math.pi
    --     local x1 = radius * math.cos(theta1)
    --     local z1 = radius * math.sin(theta1)
    --     local x2 = radius * math.cos(theta2)
    --     local z2 = radius * math.sin(theta2)
    --     pass.line3(
    --         vec3(x1, 0, z1):add(center),
    --         vec3(x2, 0, z2):add(center), thickness
    --     )
    -- end
end



return pass