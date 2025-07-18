-- written by groverbuger for g3d
-- september 2021
-- MIT license

----------------------------------------------------------------------------------------------------
-- simple obj loader
----------------------------------------------------------------------------------------------------

-- give path of file
-- returns a lua table representation
return function (path, uFlip, vFlip, loadObjects, loadColors)
    -- defaults
    local uFlip = uFlip or false
    local vFlip = vFlip or true
    local loadObjects = loadObjects or false
    local loadColors = loadColors or false

    local positions, uvs, normals, colors = {}, {}, {}, {}
    local result = {}
    local objects, name = {}

    -- go line by line through the file
    for line in love.filesystem.lines(path) do
        local words = {}

        -- split the line into words
        for word in line:gmatch '([^%s]+)' do
            table.insert(words, word)
        end

        local firstWord = words[1]

        if (firstWord == 'o') and loadObjects then
            -- if the first word in this line is a 'o', then this defines an object
            -- compile prev object
            
            if name then
                objects[name] = table.copy(result)
            end
			name = words[2]
            result = {}
        elseif firstWord == 'v' then
            -- if the first word in this line is a 'v', then this defines a vertex's position
            table.insert(positions, {tonumber(words[2]), tonumber(words[3]), tonumber(words[4])})
            if loadColors then
                table.insert(colors, {tonumber(words[5]), tonumber(words[6]), tonumber(words[7])})
            end
        elseif firstWord == 'vt' then
            -- if the first word in this line is a 'vt', then this defines a texture coordinate

            local u, v = tonumber(words[2]), tonumber(words[3])

            -- optionally flip these texture coordinates
            if uFlip then u = 1 - u end
            if vFlip then v = 1 - v end

            table.insert(uvs, {u, v})
        elseif firstWord == 'vn' then
            -- if the first word in this line is a 'vn', then this defines a vertex normal
            table.insert(normals, {tonumber(words[2]), tonumber(words[3]), tonumber(words[4])})
        elseif firstWord == 'f' then

            -- if the first word in this line is a 'f', then this is a face
            -- a face takes three point definitions
            -- the arguments a point definition takes are vertex, vertex texture, vertex normal in that order

            local vertices = {}
            for i = 2, #words do
                local v, vt, vn = words[i]:match '(%d*)/(%d*)/(%d*)'
                v, vt, vn = tonumber(v), tonumber(vt), tonumber(vn)
                -- local v, vt, vn, vc = words[i]:match '(%d*)/(%d*)/(%d*)/(%d*)'
                -- v, vt, vn, vc = tonumber(v), tonumber(vt), tonumber(vn), tonumber(vc)
                table.insert(vertices, {
                    v and positions[v][1] or 0,
                    v and positions[v][2] or 0,
                    v and positions[v][3] or 0,
                    vt and uvs[vt][1] or 0,
                    vt and uvs[vt][2] or 0,
                    vn and normals[vn][1] or 0,
                    vn and normals[vn][2] or 0,
                    vn and normals[vn][3] or 0,
                    loadColors and colors[v][1] or 1,
                    loadColors and colors[v][2] or 1,
                    loadColors and colors[v][3] or 1,
                })
            end

            -- triangulate the face if it's not already a triangle
            if #vertices > 3 then
                -- choose a central vertex
                local centralVertex = vertices[1]

                -- connect the central vertex to each of the other vertices to create triangles
                for i = 2, #vertices - 1 do
                    table.insert(result, centralVertex)
                    table.insert(result, vertices[i])
                    table.insert(result, vertices[i + 1])
                end
            else
                for i = 1, #vertices do
                    table.insert(result, vertices[i])
                end
            end

        end
    end

    if loadObjects then
        -- add last object
        if name then
            objects[name] = table.copy(result)
        end
        return objects
    else
        return result
    end
end
