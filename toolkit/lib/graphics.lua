local graphics = {}
local g = love.graphics


function graphics.line(...)
	g.line(...)
end

-- need work
-- function graphics.dashline(p1, p2, dash, gap)
-- 	local dy, dx = p2.y - p1.y, p2.x - p1.x
-- 	local an, st = math.atan2(dy, dx), dash + gap
-- 	local len    = math.sqrt(dx * dx + dy * dy)
-- 	local nm     = (len - dash) / st
-- 	g.push()
-- 	love.gr.translate(p1.x, p1.y)
-- 	gr.rotate(an)
-- 	for i = 0, nm do
-- 		gr.line(i * st, 0, i * st + dash, 0)
-- 	end
-- 	gr.line(nm * st, 0, nm * st + dash, 0)
-- 	gr.pop()
-- end


function graphics.triangle_isosceles(mode, cx, cy, width, height)
	local widthRadius = width / 2
	local heightRadius = height / 2
	local x1 = cx
	local y1 = cy - heightRadius
	local x2 = cx + widthRadius
	local y2 = cy + heightRadius
	local x3 = cx - widthRadius
	local y3 = y2
	g.polygon(mode, x1, y1, x2, y2, x3, y3)
end

function graphics.triangle_right(mode, cx, cy, width, height)
	local widthRadius = width / 2
	local heightRadius = height / 2
	local x1 = cx - widthRadius
	local y1 = cy - heightRadius
	local x2 = cx + widthRadius
	local y2 = cy + heightRadius
	local x3 = x1
	local y3 = y2
	g.polygon(mode, x1, y1, x2, y2, x3, y3)
end

function graphics.rectangle(mode, cx, cy, width, height, iscentered)
	if not iscentered then
		g.rectangle(mode, cx, cy, width, height)
		return
	end
	local widthRadius = width / 2
	local heightRadius = height / 2
	local left = cx - widthRadius
	local right = cx + widthRadius
	local top = cy - heightRadius
	local bottom = cy + heightRadius
	local vertices = { left, top, right, top, right, bottom, left, bottom }
	g.rectangle(mode, vertices[1], vertices[2], width, height)
end

function graphics.capsule(mode, cx, cy, width, height, iscentered, roundness_scale) --roundness_scale: 0-1
	if not iscentered then
		g.rectangle(mode, cx, cy, width, height, height * (roundness_scale or .5))
		return
	end
	local widthRadius = width / 2
	local heightRadius = height / 2
	local left = cx - widthRadius
	local right = cx + widthRadius
	local top = cy - heightRadius
	local bottom = cy + heightRadius
	local vertices = { left, top, right, top, right, bottom, left, bottom }
	g.rectangle(mode, vertices[1], vertices[2], width, height, height * (roundness_scale or .5))
end

function graphics.polygon(...)
	g.polygon(...)
end

function graphics.rhombus(mode, cx, cy, width, height)
	local widthRadius = width / 2
	local heightRadius = height / 2
	local vertices = {
		cx - widthRadius, cy,
		cx, cy - heightRadius,
		cx + widthRadius, cy,
		cx, cy + heightRadius
	}
	g.polygon(mode, vertices)
end

function graphics.circle(mode, cx, cy, diameter, segments)
	g.circle(mode, cx, cy, diameter * .5, segments)
end

function graphics.arc(...)
	g.arc(...)
end

function graphics.ellipse(...)
	g.ellipse(...)
end

-- Love2D glue

function graphics.resize_canvas(s, flags)
	-- width,
	love.window.setMode(width * s, height * s, flags)
	canvas_scale = s
end

function graphics.set_default_filter(...)
	g.setDefaultFilter(...)
end

function graphics.set_line_style(style)
	g.setLineStyle(style)
end

function graphics.set_line_width(width)
	g.setLineWidth(width)
end

function graphics.get_line_width()
	return g.getLineWidth()
end

function graphics.print(...)
	g.print(...)
end

function graphics.printmid(text, x, y, r, sx, sy)
	g.print(text, x, y, r, sx, sy, g.getFont():getWidth(text) / 2, g.getFont():getHeight() / 2)
end

function graphics.new_canvas(...)
	return g.newCanvas(...)
end

function graphics.set_canvas(...)
	g.setCanvas(...)
end

function graphics.new_image(filename, settings)
	return g.newImage(filename, settings)
end

function graphics.clear(...)
	g.clear(...)
end

function graphics.set_blend_mode(mode, alphamode)
	g.setBlendMode(mode, alphamode)
end

function graphics.new_font(filename, size)
	return g.newFont(filename, size)
end

function graphics.set_font(font)
	g.setFont(font)
end

function graphics.get_font()
	return g.getFont()
end

function graphics.set_background_color(...)
	g.setBackgroundColor(...)
end

function graphics.set_color(...)
	g.setColor(...)
end

function graphics.get_color()
	return g.getColor()
end

function graphics.draw(...)
	g.draw(...)
end

function graphics.pop()
	g.pop()
end

function graphics.push(...)
	g.push(...)
end

function graphics.scale(...)
	g.scale(...)
end

function graphics.translate(...)
	g.translate(...)
end

function graphics.rotate(...)
	g.rotate(...)
end

function graphics.origin()
	g.origin()
end

function graphics.new_shader(...)
	return g.newShader(...)
end

function graphics.set_shader(...)
	g.setShader(...)
end

----------------------------------------------------
-- Extra utilities
----------------------------------------------------
function graphics.push_rotate_scale(x, y, r, sx, sy, keep_translation)
	local sx = sx or 1
	local sy = sy or sx
	g.push()
	g.translate(x, y)
	g.scale(sx, sy)
	g.rotate(r or 0)
	if not keep_translation then
		g.translate(-x, -y)
	end
end

graphics.point_list = {}

function graphics.draw_point_at(x, y)
	table.insert(graphics.point_list, { x = x, y = y })
end

function graphics.draw_point_list()
	g.setColor(1, 0, 0, 1)
	for _, v in ipairs(graphics.point_list) do
		g.circle('fill', v.x, v.y, 5)
	end
	graphics.point_list = {}
	g.setColor(1, 1, 1, 1)
end

for k, v in pairs(color.sass) do
	graphics[k] = function(alpha)
		color.sass[k][4] = alpha or 1
		g.setColor(color.sass[k])
	end
end


--[[
	Bunch of dashed-thing functions by a327ex: https://github.com/a327ex/Anchor-dashed-lines/blob/main/anchor/layer.lua
]]
function graphics.centered_dashed_line(x1, y1, x2, y2, dash_size, gap_size, color, line_width, phase)
	local r, g, b, a = love.graphics.getColor()
	if color then love.graphics.setColor(color.r, color.g, color.b, color.a) end
	if line_width then love.graphics.setLineWidth(line_width) end

	local angle = math.angle_to_point(x1, y1, x2, y2)
	local total_length = math.distance(x1, y1, x2, y2)
	local pattern_length = dash_size + gap_size

	-- Apply phase (looped so it wraps around the pattern length)
	phase = (phase or 0) % pattern_length

	-- Offset initial position backwards by phase
	local offset = -phase
	local x = x1 + offset * math.cos(angle)
	local y = y1 + offset * math.sin(angle)

	while true do
		local dash_end_x = x + dash_size * math.cos(angle)
		local dash_end_y = y + dash_size * math.sin(angle)

		-- Stop if the next dash would go beyond the line's length
		if math.distance(x1, y1, dash_end_x, dash_end_y) > total_length then
			break
		end

		-- Draw the dash
		love.graphics.line(x, y, dash_end_x, dash_end_y)

		-- Move to next segment
		x = x + pattern_length * math.cos(angle)
		y = y + pattern_length * math.sin(angle)
	end

	-- Restore color and line width if needed
	if color then love.graphics.setColor(r, g, b, a) end
	if line_width then love.graphics.setLineWidth(1) end
end


local function array_concat(t1, t2)
	for _, v in ipairs(t2) do
		table.insert(t1, v)
	end
	return t1
end

function graphics.dashed_line(x1, y1, x2, y2, dash_size, gap_size, color, line_width)
	local r, g, b, a = love.graphics.getColor()
	if color then love.graphics.setColor(color.r, color.g, color.b, color.a) end
	if line_width then love.graphics.setLineWidth(line_width) end

	local r, l = math.angle_to_point(x1, y1, x2, y2), math.distance(x1, y1, x2, y2)
	local edge_dash_positions = {}
	table.insert(edge_dash_positions, { x = x1, y = y1 })
	table.insert(edge_dash_positions,
		{ x = x2 + dash_size * math.cos(r + math.pi), y = y2 + dash_size * math.sin(r + math.pi) })
	l = l - 2 * dash_size
	local inner_l = l
	local gap_sizes = {}                           -- a list of all calculated gap sizes until dashes can't be added anymore, this is used later to figure out which one is the closest to the target gap_size value
	local gap_size_index_to_inner_dash_positions = {} -- each gap size in the gap_sizes table has an index, that index also indexes the positions of the inner dashes in this table
	local inner_dash_count = 0
	while true do
		if inner_l - dash_size > 0 then
			inner_l = inner_l - dash_size
			inner_dash_count = inner_dash_count + 1
			local g = inner_l / (inner_dash_count + 1)
			table.insert(gap_sizes, g)
			local gap_size_index = #gap_sizes
			gap_size_index_to_inner_dash_positions[gap_size_index] = {}
			local x, y = edge_dash_positions[1].x + dash_size * math.cos(r),
				edge_dash_positions[1].y + dash_size * math.sin(r)
			for i = 1, inner_dash_count do
				table.insert(gap_size_index_to_inner_dash_positions[gap_size_index],
					{ x = x + g * math.cos(r), y = y + g * math.sin(r) })
				x, y = x + (g + dash_size) * math.cos(r), y + (g + dash_size) * math.sin(r)
			end
		else
			break
		end
	end

	local dash_positions = {}
	if #gap_sizes <= 0 then -- there were no gaps added because the line's distance is too small, just make a list with edge positions
		dash_positions[1] = edge_dash_positions[1]
		table.insert(dash_positions, edge_dash_positions[2])
	else
		-- Find the gap size index that points to the gap size that is closest to the one passed in by the user (gap_size)
		local closest_gap_size, closest_gap_size_index = 1000000, 0
		for i, g in ipairs(gap_sizes) do
			if math.abs(gap_size - g) < closest_gap_size then
				closest_gap_size = math.abs(gap_size - g)
				closest_gap_size_index = i
			end
		end

		-- Create the final table by merging edge dash positions and the inner dash positions of the closest gap size index.
		dash_positions[1] = edge_dash_positions[1]
		array_concat(dash_positions, gap_size_index_to_inner_dash_positions[closest_gap_size_index])
		table.insert(dash_positions, edge_dash_positions[2])
	end

	for _, p in ipairs(dash_positions) do
		love.graphics.line(p.x, p.y, p.x + dash_size * math.cos(r), p.y + dash_size * math.sin(r))
	end
end

function graphics.dashed_line_can_walk(x1, y1, x2, y2, dash_size, gap_size, color, line_width, phase)
	local r, g, b, a = love.graphics.getColor()
	if color then love.graphics.setColor(color.r, color.g, color.b, color.a) end
	if line_width then love.graphics.setLineWidth(line_width) end

	local angle = math.angle_to_point(x1, y1, x2, y2)
	local total_length = math.distance(x1, y1, x2, y2)
	local pattern_length = dash_size + gap_size
	phase = (phase or 0) % pattern_length

	local drawn_length = -phase
	while drawn_length < total_length do
		local start_length = math.max(drawn_length, 0)
		local end_length = math.min(drawn_length + dash_size, total_length)

		if end_length > 0 then
			local sx = x1 + start_length * math.cos(angle)
			local sy = y1 + start_length * math.sin(angle)
			local ex = x1 + end_length * math.cos(angle)
			local ey = y1 + end_length * math.sin(angle)
			love.graphics.line(sx, sy, ex, ey)
		end

		drawn_length = drawn_length + pattern_length
	end

	-- Restore color and width
	if color then love.graphics.setColor(r, g, b, a) end
	if line_width then love.graphics.setLineWidth(1) end
end


function graphics.dashed_line_2(x1, y1, x2, y2, dash_size, gap_size, color, line_width)
	local r, g, b, a = love.graphics.getColor()
	if color then love.graphics.setColor(color.r, color.g, color.b, color.a) end
	if line_width then love.graphics.setLineWidth(line_width) end

	local r, l = math.angle_to_point(x1, y1, x2, y2), math.distance(x1, y1, x2, y2)
	if l < dash_size then
		love.graphics.line(x1, y1, x2, y2)
	else
		local gap_sizes = {}                  -- a list of all calculated gap sizes until dashes can't be added anymore, this is used later to figure out which one is the closest to the target gap_size value
		local gap_size_index_to_dash_positions = {} -- each gap size in the gap_sizes table has an index, that index also indexes the positions of the dashes in this table
		local dash_count = 0
		while true do
			if l - dash_size > 0 then
				l = l - dash_size
				dash_count = dash_count + 1
				local g = l / (dash_count + 1)
				table.insert(gap_sizes, g)
				local gap_size_index = #gap_sizes
				gap_size_index_to_dash_positions[gap_size_index] = {}
				local x, y = x1 + g * math.cos(r), y1 + g * math.sin(r)
				for i = 1, dash_count do
					table.insert(gap_size_index_to_dash_positions[gap_size_index], { x = x, y = y })
					x, y = x + (dash_size + g) * math.cos(r), y + (dash_size + g) * math.sin(r)
				end
			else
				break
			end
		end

		-- Find the gap size index that points to the gap size that is closest to the one passed in by the user (gap_size)
		local closest_gap_size, closest_gap_size_index = 1000000, 0
		for i, g in ipairs(gap_sizes) do
			if math.abs(gap_size - g) < closest_gap_size then
				closest_gap_size = math.abs(gap_size - g)
				closest_gap_size_index = i
			end
		end

		local dash_positions = gap_size_index_to_dash_positions[closest_gap_size_index]
		for _, p in ipairs(dash_positions) do
			love.graphics.line(p.x, p.y, p.x + dash_size * math.cos(r), p.y + dash_size * math.sin(r))
		end
	end
end

-- function graphics.dashed_rectangle(x, y, w, h, dash_size, gap_size, color, line_width)
-- 	graphics.dashed_line(x - w / 2, y - h / 2, x + w / 2, y - h / 2, dash_size, gap_size, color, line_width)
-- 	graphics.dashed_line(x + w / 2, y - h / 2, x + w / 2, y + h / 2, dash_size, gap_size, color, line_width)
-- 	graphics.dashed_line(x + w / 2, y + h / 2, x - w / 2, y + h / 2, dash_size, gap_size, color, line_width)
-- 	graphics.dashed_line(x - w / 2, y + h / 2, x - w / 2, y - h / 2, dash_size, gap_size, color, line_width)
-- end

-- function graphics.dashed_rectangle(x, y, w, h, dash_size, gap_size, color, line_width, phase)
-- 	graphics.dashed_line_can_walk(x - w / 2, y - h / 2, x + w / 2, y - h / 2, dash_size, gap_size, color, line_width, phase)
-- 	graphics.dashed_line_can_walk(x + w / 2, y - h / 2, x + w / 2, y + h / 2, dash_size, gap_size, color, line_width, phase)
-- 	graphics.dashed_line_can_walk(x + w / 2, y + h / 2, x - w / 2, y + h / 2, dash_size, gap_size, color, line_width, phase)
-- 	graphics.dashed_line_can_walk(x - w / 2, y + h / 2, x - w / 2, y - h / 2, dash_size, gap_size, color, line_width, phase)
-- end

function graphics.dashed_rectangle(x, y, w, h, dash_size, gap_size, color, line_width, phase)
	local roundness_scale = .25
	local offset = math.min(w, h)/2 * roundness_scale

	graphics.dashed_line_can_walk(x - w / 2 + offset, y - h / 2, x + w / 2 - offset, y - h / 2, dash_size, gap_size, color, line_width, phase)
	graphics.dashed_line_can_walk(x + w / 2, y - h / 2 + offset, x + w / 2, y + h / 2 - offset, dash_size, gap_size, color, line_width, phase)
	graphics.dashed_line_can_walk(x + w / 2 - offset, y + h / 2, x - w / 2 + offset, y + h / 2, dash_size, gap_size, color, line_width, phase)
	graphics.dashed_line_can_walk(x - w / 2, y + h / 2 - offset, x - w / 2, y - h / 2 + offset, dash_size, gap_size, color, line_width, phase)

	-- corners
	graphics.dashed_line_can_walk(x + w / 2 - offset, y - h / 2, x + w / 2, y - h / 2 + offset, dash_size, gap_size, color, line_width, phase)
	graphics.dashed_line_can_walk(x + w / 2, y + h / 2 - offset, x + w / 2 - offset, y + h / 2, dash_size, gap_size, color, line_width, phase)
	graphics.dashed_line_can_walk(x - w / 2 + offset, y + h / 2, x - w / 2, y + h / 2 - offset, dash_size, gap_size, color, line_width, phase)
	graphics.dashed_line_can_walk(x - w / 2, y - h / 2 + offset, x - w / 2 + offset, y - h / 2, dash_size, gap_size, color, line_width, phase)

	local width = line_width and line_width/2 or love.graphics.getLineWidth()/2
	love.graphics.circle('fill', x + w / 2 - offset, y - h / 2, width, 6)
	love.graphics.circle('fill', x + w / 2, y - h / 2 + offset, width, 6)
	love.graphics.circle('fill', x + w / 2, y + h / 2 - offset, width, 6)
	love.graphics.circle('fill', x + w / 2 - offset, y + h / 2, width, 6)
	love.graphics.circle('fill', x - w / 2 + offset, y + h / 2, width, 6)
	love.graphics.circle('fill', x - w / 2, y + h / 2 - offset, width, 6)
	love.graphics.circle('fill', x - w / 2, y - h / 2 + offset, width, 6)
	love.graphics.circle('fill', x - w / 2 + offset, y - h / 2, width, 6)
end


return graphics
