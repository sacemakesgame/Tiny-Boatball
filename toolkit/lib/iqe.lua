local loader   = {
	_LICENSE     = "Inter-Quake Export Loader is distributed under the terms of the MIT license. See LICENSE.md.",
	_URL         = "https://github.com/excessive/iqe",
	_VERSION     = "1.0.0",
	_DESCRIPTION = "Load an IQE 3D model into Lua.",
}
local IQE      = {}


--[[ Helper Functions ]]--

-- http://wiki.interfaceware.com/534.html
local function string_split(s, d)
	local t = {}
	local i = 0
	local f
	local match = '(.-)' .. d .. '()'

	if string.find(s, d) == nil then
		return {s}
	end

	for sub, j in string.gmatch(s, match) do
		i = i + 1
		t[i] = sub
		f = j
	end

	if i ~= 0 then
		t[i+1] = string.sub(s, f)
	end

	return t
end

local function merge_quoted(t)
	local ret = {}
	local merging = false
	local buf = ""
	for k, v in ipairs(t) do
		local f, l = v:sub(1,1), v:sub(v:len())
		if f == "\"" and l ~= "\"" then
			merging = true
			buf = v
		else
			if merging then
				buf = buf .. " " .. v
				if l == "\"" then
					merging = false
					table.insert(ret, buf:sub(2,-2))
				end
			else
				if f == "\"" and l == f then
					table.insert(ret, v:sub(2, -2))
				else
					table.insert(ret, v)
				end
			end
		end
	end
	return ret
end


--[[ Load File ]]--

function loader.load(file)
	assert(love.filesystem.getInfo(file).type == "file", "File not found: " .. file)

	local get_lines

    local filetext = love.filesystem.read(file)
    get_lines = function(file) return filetext:gmatch("[^\r\n]+") end

	local lines = {}
	for line in get_lines(file) do
		if line == "# Inter-Quake Export" or line[1] ~= "#" then
			line = string.gsub(line, "\t", "")
			table.insert(lines, line)
		end
	end

	if lines[1] == "# Inter-Quake Export" then
		local model = setmetatable({}, {__index = IQE})
		model:init(lines, file)

		return model
	end
end

--[[ Inter-Quake Export ]]--

function IQE:init(lines, file)
	self.lines               = lines
	self.current_mesh        = false
	self.current_material    = false
	self.current_joint       = false
	self.current_animation   = false
	self.current_frame       = false
	self.current_vertexarray = false
	self.paused              = false
	self.data                = {}
	self.materials           = {}
	self.vertex_buffer       = {}
	self.stats               = {}
	self:parse()

    math.random = love.math.random
    self:buffer()
end

function IQE:parse(lines)
	self.lines = self.lines or lines
	for _, line in ipairs(self.lines) do
		local l   = string_split(line, " ")
		local cmd = l[1]
		table.remove(l, 1)

		if self[cmd] then
			self[cmd](self, l)
		end
	end

	self.lines               = nil
	self.current_mesh        = nil
	self.current_material    = nil
	self.current_joint       = nil
	self.current_animation   = nil
	self.current_frame       = nil
	self.current_vertexarray = nil
	self.current_mtl         = nil
end


--[[ Meshes ]]--

function IQE:mesh(line)
	line                   = merge_quoted(line)
	self.current_mesh      = {}
	self.current_mesh.name = line[1]
end

function IQE:material(line)
	line = merge_quoted(line)

	self.data.material          = self.data.material          or {}
	self.data.material[line[1]] = self.data.material[line[1]] or {}
	self.current_material       = self.data.material[line[1]]
	table.insert(self.current_material, self.current_mesh)
end

--[[ Vertex Attributes ]]--

function IQE:vp(line)
	local mesh = self.current_material[#self.current_material]
	mesh.vp    = mesh.vp or {}

	local vp = {}
	for _, v in ipairs(line) do
		table.insert(vp, tonumber(v))
	end
	if #vp == 3 then
		table.insert(vp, 1)
	end

	table.insert(mesh.vp, vp)
end

function IQE:vt(line)
	local mesh = self.current_material[#self.current_material]
	mesh.vt    = mesh.vt or {}

	local vt = {}
	for _, v in ipairs(line) do
		table.insert(vt, tonumber(v))
	end

	table.insert(mesh.vt, vt)
end

function IQE:vn(line)
	local mesh = self.current_material[#self.current_material]
	mesh.vn    = mesh.vn or {}

	local vn = {}
	for _, v in ipairs(line) do
		table.insert(vn, tonumber(v))
	end

	table.insert(mesh.vn, vn)
end

function IQE:vx(line)
	local mesh = self.current_material[#self.current_material]
	mesh.vx    = mesh.vx or {}

	local vx = {}
	for _, v in ipairs(line) do
		table.insert(vx, tonumber(v))
	end

	table.insert(mesh.vx, vx)
end

function IQE:vb(line)
	local mesh  = self.current_material[#self.current_material]
	self.rigged = true
	mesh.vb     = mesh.vb or {}

	local vb = {}
	for _, v in ipairs(line) do
		table.insert(vb, tonumber(v))
	end

	table.insert(mesh.vb, vb)
end

function IQE:vc(line)
	local mesh = self.current_material[#self.current_material]
	mesh.vc    = mesh.vc or {}

	local vc = {}
	for _, v in ipairs(line) do
		table.insert(vc, tonumber(v))
	end
	if #vc == 3 then
		table.insert(vc, 1)
	end

	table.insert(mesh.vc, vc)
end

function IQE:v0(line, cmd)
	cmd        = cmd or "v0"
	local mesh = self.current_material[#self.current_material]
	mesh[cmd]  = mesh[cmd] or {}

	local v0 = {}
	for _, v in ipairs(line) do
		table.insert(v0, tonumber(v))
	end

	table.insert(mesh[cmd], v0)
end

function IQE:v1(line)
	IQE:v0(line, "v1")
end

function IQE:v2(line)
	IQE:v0(line, "v2")
end

function IQE:v3(line)
	IQE:v0(line, "v3")
end

function IQE:v4(line)
	IQE:v0(line, "v4")
end

function IQE:v5(line)
	IQE:v0(line, "v5")
end

function IQE:v6(line)
	IQE:v0(line, "v6")
end

function IQE:v7(line)
	IQE:v0(line, "v7")
end

function IQE:v8(line)
	IQE:v0(line, "v8")
end

function IQE:v9(line)
	IQE:v0(line, "v9")
end

--[[ Vertex Arrays ]]--

function IQE:vertexarray(line)
	line                  = merge_quoted(line)
	self.data.vertexarray = self.data.vertexarray or {}

	local va     = {}
	va.type      = line[1]
	va.component = line[2]
	va.size      = tonumber(line[3])
	va.name      = line[4] or line[1]
	table.insert(self.data.vertexarray, va)

	self.current_vertexarray = self.data.vertexarray[#self.data.vertexarray]
end

--[[ Triangle ]]--

function IQE:fa(line)
	local mesh = self.current_material[#self.current_material]
	mesh.fa    = mesh.fa or {}

	local fa = {}
	for k, v in ipairs(line) do
		table.insert(fa, tonumber(v))
	end

	table.insert(mesh.fa, fa)
end

function IQE:fm(line)
	local mesh   = self.current_material[#self.current_material]
	mesh.fm      = mesh.fm or {}
	mesh.indices = mesh.indices or {}

	local fm = {}

	-- CCW Winding
	table.insert(fm, tonumber(line[1]+1))
	table.insert(fm, tonumber(line[3]+1))
	table.insert(fm, tonumber(line[2]+1))
	table.insert(mesh.indices, tonumber(line[1]+1))
	table.insert(mesh.indices, tonumber(line[3]+1))
	table.insert(mesh.indices, tonumber(line[2]+1))

	table.insert(mesh.fm, fm)
end

--[[ Smoothing ]]--

function IQE:smoothuv(line)
	local mesh    = self.current_material[#self.current_material]
	local n       = tonumber(line[1])
	mesh.smoothuv = false

	if n > 0 then
		mesh.smoothuv = true
	end
end

function IQE:smoothgroup(line)
	local mesh       = self.current_material[#self.current_material]
	local n          = tonumber(line[1])
	mesh.smoothgroup = -1

	if n then
		mesh.smoothgroup = n
	end
end

function IQE:smoothangle(line)
	local mesh       = self.current_material[#self.current_material]
	local angle      = tonumber(line[1])
	mesh.smoothangle = 180

	if angle then
		mesh.smoothangle = angle
	end
end

function IQE:fs(line)
	local mesh = self.current_material[#self.current_material]
	mesh.fs    = mesh.fs or {}

	local fs = {}
	for k, v in ipairs(line) do
		table.insert(fs, tonumber(v))
	end

	table.insert(mesh.fs, fs)
end

function IQE:vs(line)
	local mesh = self.current_material[#self.current_material]
	mesh.vs    = mesh.vs or {}
	local vs   = tonumber(line[1])
	table.insert(mesh.vs, vs)
end

--[[ Poses ]]--

function IQE:pq(line)
	local pq = {}
	for _, v in ipairs(line) do
		table.insert(pq, tonumber(v))
	end
	if #pq == 6 then
		table.insert(pq, -1)
	end

	if #pq == 7 then
		table.insert(pq, 1)
		table.insert(pq, 1)
		table.insert(pq, 1)
	end

	local joint
	if not self.current_animation then
		joint    = self.current_joint
		joint.pq = pq
	else
		joint    = self.current_frame
		joint.pq = joint.pq or {}
		table.insert(joint.pq, pq)
	end
end

function IQE:pm(line)
	local pm = {}
	for _, v in ipairs(line) do
		table.insert(pm, tonumber(v))
	end
	if #pm == 12 then
		table.insert(pm, 1)
		table.insert(pm, 1)
		table.insert(pm, 1)
	end

	local joint
	if not self.current_animation then
		joint    = self.current_joint
		joint.pm = pm
	else
		joint    = self.current_frame
		joint.pm = joint.pm or {}
		table.insert(joint.pm, pm)
	end
end

function IQE:pa(line)
	local pa = {}
	for _, v in ipairs(line) do
		table.insert(pa, tonumber(v))
	end
	if #pa == 6 then
		table.insert(pa, 1)
		table.insert(pa, 1)
		table.insert(pa, 1)
	end

	local joint
	if not self.current_animation then
		joint    = self.current_joint
		joint.pa = pa
	else
		joint    = self.current_frame
		joint.pa = joint.pa or {}
		table.insert(joint.pa, pa)
	end
end

--[[ Skeleton ]]--

function IQE:joint(line)
	line            = merge_quoted(line)
	self.data.joint = self.data.joint or {}
	local joint     = {}
	joint.name      = line[1]
	joint.parent    = tonumber(line[2]) + 1 -- fix offset
	table.insert(self.data.joint, joint)

	self.current_joint = joint
end

--[[ Animations ]]--

function IQE:animation(line)
	line                      = merge_quoted(line)
	self.data.animation       = self.data.animation or {}
	local name                = line[1]             or tostring(math.random(0, 99999))
	self.data.animation[name] = {}

	self.current_animation = self.data.animation[name]
	self.current_frame     = false
end

function IQE:loop(line)
	local animation = self.current_animation
	animation.loop  = true
end

function IQE:framerate(line)
	local animation     = self.current_animation
	animation.framerate = tonumber(line[1])
end

function IQE:frame(line)
	local animation    = self.current_animation
	animation.frame    = animation.frame or {}
	table.insert(animation.frame, {})

	self.current_frame = animation.frame[#animation.frame]
end

--[[ Render ]]--

function IQE:buffer()
	-- local cpml  = require "cpml"
	local stats = self.stats

    local sum_data = {}
    local sum_indices = {}
	local vertex_offset = 0
		local sum_layout = {
			{ "VertexPosition", "float", 3 },
			{ "VertexTexCoord", "float", 2 },
			{ "VertexTangent", "float", 4 },
			{ "VertexNormal", "float", 3 },
			{ "VertexBone", "float", 4 },
			{ "VertexWeight", "float", 4 },
		}

		
	for k, material in pairs(self.data.material) do -- only 1??
		for _, mesh in ipairs(material) do
			-- print(lume.serialize((mesh.vb)))
			local layout = {
				{ "VertexPosition", "float", 3 },
				{ "VertexTexCoord", "float", 2 },
				{ "VertexTangent", "float", 4 },
				{ "VertexNormal", "float", 3 },
			}

			if self.rigged then
				table.insert(layout, { "VertexBone", "float", 4 })
				table.insert(layout, { "VertexWeight", "float", 4 })
			end

			local data   = {}
			local bounds = { min = {}, max = {} }
			for i=1, #mesh.vp do
				-- all meshes should have these things...
				local vp = mesh.vp[i]
				local vn = mesh.vn and mesh.vn[i] or {}
				local vc = mesh.vc and { mesh.vc[i][1] * 255, mesh.vc[i][2] * 255, mesh.vc[i][3] * 255, mesh.vc[i][4] * 255 } or { 255, 255, 255, 255 }
				local vt = mesh.vt and mesh.vt[i] or {}

				local current = {
					vp[1], vp[2], vp[3],
					vt[1] or 0, vt[2] or 0,
					vc[1] or 255, vc[2] or 255, vc[3] or 255, vc[4] or 255,
					vn[1] or 0, vn[2] or 1, vn[3] or 0
				}

				bounds.min.x = bounds.min.x and math.min(bounds.min.x, vp[1]) or vp[1]
				bounds.max.x = bounds.max.x and math.max(bounds.max.x, vp[1]) or vp[1]
				bounds.min.y = bounds.min.y and math.min(bounds.min.y, vp[2]) or vp[2]
				bounds.max.y = bounds.max.y and math.max(bounds.max.y, vp[2]) or vp[2]
				bounds.min.z = bounds.min.z and math.min(bounds.min.z, vp[3]) or vp[3]
				bounds.max.z = bounds.max.z and math.max(bounds.max.z, vp[3]) or vp[3]

				-- ...but only rigged ones will have these.
				if self.rigged then
					local vb = mesh.vb[i]
					table.insert(current, vb[1] or 0)
					table.insert(current, vb[3] or 0)
					table.insert(current, vb[5] or 0)
					table.insert(current, vb[7] or 0)
					
					table.insert(current, vb[2] or 0)
					table.insert(current, vb[4] or 0)
					table.insert(current, vb[6] or 0)
					table.insert(current, vb[8] or 0)
				end
				
				table.insert(data, current)
                table.insert(sum_data, current)
				-- print(lume.serialize((current)))
			end

			bounds.min = cpml.vec3(bounds.min)
			bounds.max = cpml.vec3(bounds.max)

			stats.vertices  = (stats.vertices  or 0) + #mesh.vt
			stats.triangles = (stats.triangles or 0) + #mesh.fm

			local m = love.graphics.newMesh(layout, data, "triangles", "static")
			m:setVertexMap(mesh.indices)
			assert(m, "D:")
			table.insert(self.vertex_buffer, { material=k, mesh=m, name=mesh.name, bounds=bounds })
			
			for _, index in ipairs(mesh.indices) do
				table.insert(sum_indices, index + vertex_offset)
			end
			vertex_offset = #sum_data			
		end
	end
	
    local sum_m = love.graphics.newMesh(sum_layout, sum_data, "triangles")
	
    sum_m:setVertexMap(sum_indices) 

    self.ultimate_mesh = sum_m

	-- print(lume.serialize(sum_data[1]))

	self:calc_bounds()

	-- everything after here only applies to models with skeletons.
	if not self.rigged then return end

	local anims = {}
	local skeleton = {}
	for i, joint in ipairs(self.data.joint) do
		local v = joint.pq
		local bone = {
			parent   = joint.parent,
			name     = joint.name,
			position = cpml.vec3(v[1], v[2], v[3]),
			rotation = cpml.quat(v[4], v[5], v[6], v[7]),
			scale    = cpml.vec3(v[8], v[9], v[10])
		}
		skeleton[i], skeleton[bone.name] = bone, bone
	end
	anims.skeleton = skeleton
	
	-- it's entirely possible for a model to be rigged but not animated.
	if not self.data.animation then return end
	
	anims.frames = {}
	
	for k, animation in pairs(self.data.animation) do
		local a = {
			name      = k,
			first     = #anims.frames+1,
			last      = #anims.frames+#animation.frame,
			framerate = animation.framerate,
			loop      = animation.loop or false
		}
		table.insert(anims, a)
		anims[a.name] = a
		
		for _, pose in ipairs(animation.frame) do
			local frame = {}
			for i, v in ipairs(pose.pq) do
				table.insert(frame, {
					translate = cpml.vec3(v[1], v[2], v[3]),
					rotate    = cpml.quat(v[4], v[5], v[6], v[7]),
					scale     = cpml.vec3(v[8], v[9], v[10])
				})
			end
			table.insert(anims.frames, frame)
		end
	end

	self.anims = anims
end

function IQE:dump()
	local function create_dump(file, t)
		local buffer = ""
		local lines  = 0
		local function dump_r(t, level)
			level = level or 1
			for k,v in pairs(t) do
				buffer = buffer .. rpad(" ", 12 * level) .. rpad(tostring(k), 3)  .. " " .. tostring(v) .. "\n"
				lines  = lines + 1
				if lines >= 2048 then
					love.filesystem.append(file, buffer)
					lines  = 0
					buffer = ""
				end
				if type(v) == "table" then
					dump_r(v, level + 1)
				end
			end
		end
		dump_r(t)
		love.filesystem.append(file, buffer)
	end
	local file = "dump.txt"
	love.filesystem.write(file, "")
	create_dump(file, self.data)
end

function IQE:calc_bounds()
	-- local cpml  = require "cpml"
	self.bounds = { min = {}, max = {} }

	for _, buffer in ipairs(self.vertex_buffer) do
		local b = buffer.bounds
		self.bounds.min.x = self.bounds.min.x and math.min(self.bounds.min.x, b.min.x) or b.min.x
		self.bounds.max.x = self.bounds.max.x and math.max(self.bounds.max.x, b.max.x) or b.max.x
		self.bounds.min.y = self.bounds.min.y and math.min(self.bounds.min.y, b.min.y) or b.min.y
		self.bounds.max.y = self.bounds.max.y and math.max(self.bounds.max.y, b.max.y) or b.max.y
		self.bounds.min.z = self.bounds.min.z and math.min(self.bounds.min.z, b.min.z) or b.min.z
		self.bounds.max.z = self.bounds.max.z and math.max(self.bounds.max.z, b.max.z) or b.max.z
	end

	self.bounds.min = cpml.vec3(self.bounds.min)
	self.bounds.max = cpml.vec3(self.bounds.max)
end

return loader



