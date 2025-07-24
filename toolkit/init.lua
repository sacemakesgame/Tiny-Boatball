local toolkit = {}
local path = ... .. '/'
require(path .. 'errorhandler')



function toolkit:init()
    require (path .. 'lib.math')
    require (path .. 'lib.table')

    Object      = require (path .. 'lib.classic')
    gamestate   = require (path .. 'lib.gemstet')
    color       = require (path .. 'lib.color')
    graphics    = require (path .. 'lib.graphics')
    log         = require (path .. 'lib.log')
    lume        = require (path .. 'lib.lume')
    input       = require (path .. 'lib.input')()
    bump3d      = require (path .. 'lib.bump-3dpd')
    cpml        = require (path .. 'lib.cpml')
    json        = require (path .. 'lib.json')
    mat4        = cpml.mat4
    vec3        = cpml.vec3
    quat        = cpml.quat
    vec2        = cpml.vec2
    intersect   = cpml.intersect
    pigic       = require (path .. 'lib/pigic')
    pass        = pigic.pass
    
    require 'classes'
    
    -- global callables
    random = class.random()
    self.timer = class.timer(self) --srry for the unconsistency ><
    
    -- global canvas and stuff
    self.canvas_scale = 1
    self.canvas_divider = 1

    self:apply_resolution_options()
    scale = height/1440 -- global scale glue code shit thing

    width, height = width/self.canvas_divider, height/self.canvas_divider
    self.canvas = graphics.new_canvas(width, height, {format = "srgba8"})
    self.canvas_x, self.canvas_y = 0, 0
    self.canvas:setFilter('nearest')
    graphics.set_line_style('rough')
    
    self.time_scale = 1

    local controllers = {}
    recursive_enumerate('controllers', controllers)
    require_files(controllers)
    
    local rooms = {}
    recursive_enumerate('rooms', rooms)
    require_files(rooms)
    
    local objects = {}
    recursive_enumerate('objects', objects)
    require_files(objects)
    
    self.font = graphics.new_font(path .. 'andina.ttf', 30)
    
    log:init()

    gamestate.register_events({'mousepressed', 'mousemoved', 'mousereleased', 'keypressed', 'keyreleased', 'wheelmoved'})

    self.fxaa = love.graphics.newShader(pigic.fxaa)
    self.fxaa:send('fxaa_reduce_min', (1.0 / 128.0))
    self.fxaa:send('fxaa_reduce_mul', (1.0 / 8.0))
    self.fxaa:send('fxaa_span_max', 8.0)  

    self.brush = love.graphics.newShader(pigic.brush)
    self.brush:send('flowMap', graphics.new_image('game-assets/png/a-normal-map.jpg'))
    self.brush:send('time', love.timer.getTime())

    self.curtain_scale = 0
end

function toolkit:update(dt)
    self.brush:send('time', love.timer.getTime())
    local dt = math.min(dt, 1/30) -- useful for frame drops due to moving game window

    log:update(dt)
    pigic:update(dt)
    self.timer:update(dt)
    gamestate.update(dt * self.time_scale)
end

function toolkit:draw()	
    graphics.set_canvas{self.canvas, depth = true}
    graphics.clear()
        gamestate.draw()
    graphics.set_canvas()

    graphics.set_blend_mode('alpha', 'premultiplied')
    -- graphics.set_shader(self.fxaa)
    graphics.set_shader(self.brush)
    graphics.draw(self.canvas, self.canvas_x, self.canvas_y, 0, self.canvas_scale * self.canvas_divider)
    graphics.set_shader()
    graphics.set_blend_mode('alpha')

    -- curtain
	if self.curtain_scale > 0 then
		love.graphics.setColor(color.palette.dark)
		love.graphics.circle('fill', width/2 * self.canvas_scale + self.canvas_x, height/2 * self.canvas_scale + self.canvas_y, width*2 * self.curtain_scale)
	end

    -- draw debug point (not so useful tho)
    -- graphics.draw_point_list()
    
    -- draw log
    local previous_font = graphics.get_font()
    graphics.set_font(self.font)
    log:draw()
    graphics.set_font(previous_font)
end

function toolkit:get_mouse_position()
    local mx, my = love.mouse.getPosition()
    return mx / self.canvas_scale, my / self.canvas_scale
end


function toolkit:switch(to, ...)
    local args = {...}
    self.timer:tween(1, self, {curtain_scale = 1}, math.cubic_in_out, function()
        gamestate.switch(to, unpack(args))
        self.timer:tween(.5, self, {curtain_scale = 0}, math.cubic_in_out)
    end)
end

function toolkit:slowmo(dur, scale)
    self.time_scale = scale
    self.timer:after(dur, function()
        self.time_scale = 1
    end, 'slowmo')
end


function love.resize(w, h)
    local default_ratio = width/height
    local new_ratio = w/h
    if new_ratio < default_ratio then
        toolkit.canvas_scale = w / width
        toolkit.canvas_x = 0
        toolkit.canvas_y = h / 2 - (toolkit.canvas_scale * height / 2)
    elseif new_ratio > default_ratio then
        toolkit.canvas_scale = h / height
        toolkit.canvas_x = w / 2 - (toolkit.canvas_scale * width / 2)
        toolkit.canvas_y = 0
    elseif new_ratio == default_ratio then -- either way would works just fine
        toolkit.canvas_scale = w / width
        toolkit.canvas_x = 0
        toolkit.canvas_y = h / 2 - (toolkit.canvas_scale * height / 2)
    end
end


function toolkit:apply_resolution_options()
    if ASPECT_RATIO == 1 then -- 16:9
        if RESOLUTION_QUALITY == 1 then
            width, height = 1280, 720
        elseif RESOLUTION_QUALITY == 2 then
            width, height = 1920, 1080
        elseif RESOLUTION_QUALITY == 3 then
            width, height = 2560, 1440
        end
    elseif ASPECT_RATIO == 2 then -- 16:10
        if RESOLUTION_QUALITY == 1 then
            width, height = 1280, 800
        elseif RESOLUTION_QUALITY == 2 then
            width, height = 1920, 1200
        elseif RESOLUTION_QUALITY == 3 then
            width, height = 2560, 1600
        end
    elseif ASPECT_RATIO == 3 then -- 21:9
        if RESOLUTION_QUALITY == 1 then
            width, height = 1680, 720
        elseif RESOLUTION_QUALITY == 2 then
            width, height = 2560, 1080
        elseif RESOLUTION_QUALITY == 3 then
            width, height = 3440, 1440
        end
    end

    -- width, height
    love.window.setMode(width, height, {fullscreen = not (IS_FULLSCREEN == 1)})
    tool.canvas = graphics.new_canvas(width, height)
end

return toolkit