local collision = require(pigic.collision)

Home = {}

function Home:enter(prev, type, active_block)
    self.font = love.graphics.newFont('game-assets/Schoolbell-Regular.ttf', 192*height/1440)
    love.graphics.setFont(self.font)

    love.graphics.setMeshCullMode('none')
    self.timer = class.timer(self)

    self.sound = class.sound(self, {'music', 'sfx', 'oreo'})
    self.sound:randomize_pitch('sfx', .95, 1.05)
    self.sound:add('oreo', 'oreo', 'game-assets/audio/oreo.wav', 'static') -- special for oreo :O
    self.sound:add('music', 'music', 'game-assets/audio/HeatleyBros - HeatleyBros V - 16 Brassy Jazz.mp3', 'stream')
    self.sound:add('nos', 'sfx', 'game-assets/audio/nos.ogg', 'static')
    self.sound:add('ball-bounce', 'sfx', 'game-assets/audio/ball-bounce.ogg', 'static')
    self.sound:add('blunder-snare', 'sfx', 'game-assets/audio/blunder-snare.wav', 'static')

    self.sound:play('music', 0, 0, true)

    self.sound:set_volume('sfx', 0)
    self.timer:after(2, function()
        if self.type ~= TYPE.CAREER then
            self.sound:set_volume('sfx', 1)
        end
    end)
    
    -- eye aka camera
    self.eye = {}
    self.eye.transform = mat4()
    self.eye.shake = class.shake3d()
    self.eye.shader = graphics.new_shader(pigic.unlit)
    self.eye.projection = mat4.from_perspective(30, width/height, .01, 300)
    self.eye.shader:send('projectionMatrix', 'column', self.eye.projection)
    self.eye.target = vec3()
    self.eye.spring = class.spring3d(nil, 100, 30)
    self.eye.offset = vec3(0, 30 * 1.7, 40 * 1.7)
    
    self.world = pigic.world()
    
    self.ally_holder = class.holder(self)
    self.opponent_holder = class.holder(self)
    self.stuff_holder = class.holder(self)
    
    self.water = pigic.model('game-assets/obj/aquarium-water.obj')
    self.table = pigic.character('game-assets/obj/aquarium-table.obj', 'game-assets/png/palette.png')
    self.wall = pigic.character('game-assets/obj/wall.obj', 'game-assets/png/wall-texture.png')
    self.floor = pigic.character('game-assets/obj/floor.obj', 'game-assets/png/floor.png')
    self.glass = pigic.character('game-assets/obj/aquarium-glass.obj', 'game-assets/png/palette.png')

    local list 
    local index = CAREER_PROGRESSION_INDEX
    if index == 1 then        
        list = random:chance_list({'axolotl', 1})
    elseif index == 2 then
        list = random:chance_list({'axolotl', 1}, {'frog', 1})
    elseif index == 3 then
        list = random:chance_list({'snail', 1}, {'axolotl', 1}, {'frog', 1})
    elseif index == 4 then
        list = random:chance_list({'axolotl', 2}, {'frog', 2}, {'snail', 2}, {'worm', 2})
    elseif index == 5 then -- post game
        list = random:chance_list({'axolotl', 2}, {'frog', 2}, {'snail', 2}, {'worm', 2}, {'pelican', 2})
    end

    -- ENEMIES
    self.opponent_holder:add(EnemyBoat, vec3(random:float(13, 15), random:float(40, 60), random:float(-5, 5)), 'def', list:pop()) -- keeper
    for i = 2, 4 do
        self.opponent_holder:add(EnemyBoat, vec3(random:float(-5, 5), random:float(40, 60), random:float(-5, 5)), 'atk', list:pop())
    end

    -- ALLIES
    self.ally_holder:add(AllyBoat, vec3(random:float(-15, -13), random:float(40, 60), random:float(-5, 5)), 'def', list:pop()) -- keeper
    for i = 2, 4 do
        self.ally_holder:add(AllyBoat, vec3(random:float(-15, -13), random:float(40, 60), random:float(-5, 5)), 'atk', list:pop()) -- outfields
    end

    self.ball = self.stuff_holder:add(Ball, 0, 30, 0, vec3())
    self.stuff_holder:add(Net, -15, 0, 0)
    self.stuff_holder:add(Net, 15, 0, 0, true)


    self.water_shader = graphics.new_shader(pigic.water)
    self.water_shader:send('projectionMatrix', 'column', self.eye.projection)
    self.water_shader:send('ballRadius', self.ball.radius * .9) -- make it a bit smaller
    self.water_shader:send('ballPosition', {self.ball.translation.x, self.ball.translation.y, self.ball.translation.z})

    self.sun = {}
    self.sun.transform = mat4()
    self.sun.shader = graphics.new_shader(pigic.glsl_depth)
    self.sun.canvas = graphics.new_canvas(1024 * 1.5 * 1.5, 1024 * 1.5, {format = "depth24", readable = true})
	self.sun.canvas:setFilter("nearest", "nearest")
    self.sun.aspect_ratio = 1.5
    self.sun.fov = 30
    self.sun.near = 1
    self.sun.far = 200
    self.sun.size = 20
    self.sun.projection = mat4.from_ortho(self.sun.fov, self.sun.aspect_ratio, self.sun.size, self.sun.near, self.sun.far)
    self.sun.view = mat4()
    self.sun.shader:send('projectionMatrix', 'column', self.sun.projection)
    self.water_shader:send('shadowProjectionMatrix', 'column', self.sun.projection)
    self.sun.transform:look_at(vec3(-50, 50, 50), vec3(0), vec3(0, 1, 0))

    local cp, ctp = vec3(0, 50, .01), vec3(0)
    local normalized = (cp - ctp):normalize()
    self.water_shader:send('shadowMapDir', {normalized.x, normalized.y, normalized.z})
    self.sun.view:set(self.sun.transform)

    self.outline = {}
    self.outline.canvas = graphics.new_canvas(width, height)
    self.outline.filter = graphics.new_shader(pigic.outline_filter)
    self.outline.filter_2d = graphics.new_shader(pigic.outline_filter_2d)
    self.outline.filter:send('projectionMatrix', 'column', self.eye.projection)
    self.outline.shader = graphics.new_shader(pigic.outline)
    local thickness = height/720
    self.outline.shader:send("pixelSize", {thickness/width, thickness/height})
    self.outline.shader:send("outlineColor", color.palette.dark)


    
    local water_trail_mesh = love.graphics.newMesh(pigic.model.vertex_format, pigic.objloader('game-assets/obj/water-trail.obj'), "triangles")
    self.trail = class.particle(self, 150)
    self.trail:set_velocities(0):set_sizes(.3, .1):set_lifetime(.1):set_direction(0, 0, 0):set_colors(color.palette.water)
    self.trail:set_mesh(water_trail_mesh)

    -- gotta be its own unique mesh object
    local basic_nos_particle = love.graphics.newMesh(pigic.model.vertex_format, pigic.objloader('game-assets/obj/trail-particle.obj'), "triangles")
    local ally_nos_particle = love.graphics.newMesh(pigic.model.vertex_format, pigic.objloader('game-assets/obj/trail-particle.obj'), "triangles")
    local opponent_nos_particle = love.graphics.newMesh(pigic.model.vertex_format, pigic.objloader('game-assets/obj/trail-particle.obj'), "triangles")
    self.basic_nos = class.particle(self, 200)
    self.basic_nos:set_velocities(1):set_sizes(.1, .05):set_lifetime(.3):set_colors(color.palette.light)
    self.basic_nos:set_mesh(basic_nos_particle)
    self.ally_nos = class.particle(self, 200)
    self.ally_nos:set_velocities(2):set_sizes(.2, .05):set_lifetime(.5):set_colors(color.palette.ally)
    self.ally_nos:set_mesh(ally_nos_particle)
    self.opponent_nos = class.particle(self, 200)
    self.opponent_nos:set_spread(math.pi/4, .5, .5, 0):set_velocities(0):set_sizes(.3, .1):set_lifetime(.1):set_direction(0, 0, 0):set_colors(color.palette.opponent)
    self.opponent_nos:set_mesh(opponent_nos_particle)

    -- MENU STUFF
    self.ui_holder = class.holder(self)
    self.main_menu = self.ui_holder:add(MainMenu)
    self.career_menu = self.ui_holder:add(CareerMenu)
    self.options_menu = self.ui_holder:add(OptionsMenu)
    self.credit_menu = self.ui_holder:add(CreditMenu)
    self.character_display = CharacterDisplay(self)
    self.chat_holder = class.holder(self)

    self.type = type
    if type == TYPE.MAIN then
        self.main_menu:enter(1)
    elseif type == TYPE.CAREER then
        self.career_menu:enter()
    elseif type == TYPE.OPTIONS then
        self.options_menu:enter(active_block)
    elseif type == TYPE.CREDIT then
        self.credit_menu:enter()
    end
    self.eye.spring.x:set(self.eye.target)

    self.is_keyboard_info = false
    self.is_control_info = false
end


function Home:update(dt)
    self.timer:update(dt)
    self.sound:update(dt)

    local offset = vec3()
    if self.type == TYPE.MAIN then
        offset:add(math.sin(love.timer.getTime()) * .25, math.sin(love.timer.getTime() *.5) * .25, math.sin(love.timer.getTime() *2) * .25)
    end
    self.eye.spring:animate(self.eye.target + offset)
    self.eye.transform:look_at(vec3(self.eye.offset.x, self.eye.offset.y, self.eye.offset.z), self.eye.spring.x, vec3(0, 1, 0))

    self.eye.transform:translate(self.eye.shake.x, self.eye.shake.y, self.eye.shake.z)
    self.eye.shake:update(dt)
    self.eye.spring:update(dt)

    self.world:update(dt)

    self.trail:update(dt)
    self.ally_nos:update(dt)
    self.basic_nos:update(dt)
    self.opponent_nos:update(dt)

    self.ally_holder:update(dt)
    self.opponent_holder:update(dt)
    self.stuff_holder:update(dt)

    -- MENU STUFF
    -- update input
    if self.type == TYPE.MAIN then
        self.main_menu:process_input()
    elseif self.type == TYPE.CAREER then
        self.career_menu:process_input()
    elseif self.type == TYPE.OPTIONS then
        self.options_menu:process_input()
    elseif self.type == TYPE.CREDIT then
        self.credit_menu:process_input()
    end


    self.character_display:update(dt)
    self.ui_holder:update(dt)
    self.chat_holder:update(dt)
    self.chat_holder:update(dt)

    -- setting a block's active status gotta be after it's update() call
    if self.type == TYPE.MAIN then
        self.main_menu:set_active()
    elseif self.type == TYPE.CAREER then
        self.career_menu:set_active()
    elseif self.type == TYPE.OPTIONS then
        self.options_menu:set_active()
    elseif self.type == TYPE.CREDIT then
        self.credit_menu:set_active()
    end
end



function Home:draw()

    love.graphics.setDepthMode('lequal', true)

    -- sun
    graphics.set_shader(self.sun.shader)
    self.active_shader = self.sun.shader
    self.sun.shader:send('viewMatrix', 'column', self.sun.transform)
    
    graphics.set_canvas({depthstencil = self.sun.canvas})
    love.graphics.clear()
    self.ally_holder:draw()
    self.opponent_holder:draw()
    self.stuff_holder:draw()

    -- eye
    graphics.set_canvas{tool.canvas, depth = true}
    graphics.set_shader(self.water_shader)
    self.active_shader = self.water_shader
    self.water_shader:send('viewMatrix', 'column', self.eye.transform)
    self.water_shader:send('shadowViewMatrix', 'column', self.sun.view)
    self.water_shader:send('shadowMapImage', self.sun.canvas)
    self.water_shader:send('time', love.timer.getTime())
    self.water_shader:send('ballPosition', {self.ball.translation.x, self.ball.translation.y, self.ball.translation.z})
    self.water:draw()

    graphics.set_shader(self.eye.shader)
    self.active_shader = self.eye.shader
    self.eye.shader:send('viewMatrix', 'column', self.eye.transform)
    
    self.ally_holder:draw()
    self.opponent_holder:draw()
    self.stuff_holder:draw()
    
    self.trail:draw()
    self.ally_nos:draw()
    self.basic_nos:draw()
    self.opponent_nos:draw()
    self.wall:draw()
    self.table:draw()
    self.floor:draw()
    self.glass:draw()
    
    self.character_display:render()
    
    -- self.world:draw()
    -- self.bump:draw()
    
    graphics.white()

    -- outline
    graphics.set_canvas{self.outline.canvas, depth = true}
    graphics.clear(1, 1, 1, 1)
    graphics.set_shader(self.outline.filter)
    self.active_shader = self.outline.filter
    self.outline.filter:send('viewMatrix', 'column', self.eye.transform)
    self.outline.filter:send('idColor', {1,1,0})
    self.outline.filter:send('time', love.timer.getTime())
    self.outline.filter:send('idColor', {0,0,1})

    if self.type == TYPE.CAREER then
        self.outline.filter:send('isWater', true)
        self.water:draw()
        self.outline.filter:send('isWater', false)
        self.outline.filter:send('idColor', {1,0,0})

        self.ally_holder:draw()
        self.opponent_holder:draw()
        self.trail:draw()
        self.ally_nos:draw()
        self.opponent_nos:draw()
        self.outline.filter:send('idColor', {0,1,0})
        self.stuff_holder:draw()
        self.outline.filter:send('idColor', {0,1,1})
        self.table:draw()
    end

    graphics.set_canvas{tool.canvas, depth = true}
        
    graphics.set_shader()
    love.graphics.setDepthMode('always', false)
    -- 2d here

    -- graphics.draw(self.sun.canvas, 0, 0, 0, .3) -- shadow maps

    -- outline for 2d
    -- graphics.set_canvas{self.outline.canvas, depth = false}
    -- graphics.set_shader(self.outline.filter_2d)
    -- self.active_shader = self.outline.filter_2d
    -- self.outline.filter_2d:send('idColor', {0,1,1})
    -- self.character_display:draw()
    
    graphics.set_canvas{tool.canvas, depth = true}
    graphics.set_shader()

    self.career_menu:draw_curtain()
    
    -- draw outline
    graphics.set_shader(self.outline.shader)
    graphics.draw(self.outline.canvas, 0, 0, 0)
    graphics.set_shader()
    
    self.ui_holder:draw()
    self.character_display:draw()    
    
    self.chat_holder:draw()


    -- title thing
    graphics.push()
    graphics.translate(width/2, height * 1/8)
    graphics.rotate(math.sin(love.timer.getTime()) * math.pi/100)
    graphics.translate(-width/2, -height * 1/8)
    graphics.set_color(color.palette.dark)
    local thickness = height*12/1440
    for i = 0, math.pi*2, math.pi/8 do
       graphics.printmid(self:get_title_string(), width/2 + math.cos(i) * thickness, height * 1/8 + math.sin(i) * thickness + height*15/1440) 
    end

    graphics.set_color(color.palette.light)
    local thickness = height*12/1440
    for i = 0, math.pi*2, math.pi/8 do
       graphics.printmid(self:get_title_string(), width/2 + math.cos(i) * thickness, height * 1/8 + math.sin(i) * thickness) 
    end

    graphics.set_color(color.palette.floor)
    graphics.printmid(self:get_title_string(), width/2, height * 1/8)
    graphics.white()
    graphics.pop()
end


function Home:get_title_string()
    if self.type == TYPE.MAIN then
        return 'tiny boatball!'
    elseif self.type == TYPE.CAREER then
        local stages = { 'qualifier', 'quarterfinal', 'semifinal', 'final' }
        return 'next: ' .. stages[CAREER_MATCH_COUNTER]
    elseif self.type == TYPE.OPTIONS then
        return 'options'
    elseif self.type == TYPE.CREDIT then
        return 'credits'
    end
end


function Home:exit()
    self.sound:stop('music')
end


-- info stuff
function Home:keypressed(key)
    if not table.contains({'right', 'left', 'up', 'down', 'w', 'a', 's', 'd', 'z', 'return', 'escape'}, key) then
        if (not self.is_keyboard_info) and (not self.is_control_info) then
            self.timer:script(function(wait)
                self.is_control_info = true
                local padding = 150 * scale
                self.chat_holder:add(BubbleChat, vec2(width/2, height/2 - padding * 1.3), 'controls are..', nil, 3 + 1 + 1 + 1)
                wait(1)
                self.chat_holder:add(BubbleChat, vec2(width/2, height/2), '(enter)/(z) to confirm/nos', nil, 3 + 1 + 1)
                wait(1)
                self.chat_holder:add(BubbleChat, vec2(width/2, height/2 + padding), '(wasd)/(arrow) to move', nil, 3 + 1)
                wait(1)
                self.chat_holder:add(BubbleChat, vec2(width/2, height/2 + padding * 2), '(esc) to back', nil, 3)
                wait(3)
                self.is_control_info = false
            end)
        end
    end
end

-- info stuff
function Home:mousepressed(x, y, button)
    if (not self.is_keyboard_info) and (not self.is_control_info) then
        self.is_keyboard_info = true
        self.chat_holder:add(BubbleChat, vec2(width/2, height/2), 'use keyboard only bro..', nil, 2)
        self.timer:after(2, function()
            self.is_keyboard_info = false
        end)
    end
end


function Home:sphere_inside_aabb(pos, radius, aabb)
    local min = aabb.from
    local max = aabb.from + aabb.size

    return
        ((pos.x + radius) < max.x) and ((pos.x - radius) > min.x)
        and ((pos.y + radius) < max.y) and ((pos.y - radius) > min.y)
        and ((pos.z + radius) < max.z) and ((pos.z - radius) > min.z)
end



function Home:reset_ball()
    self.timer:script(function(wait)
        self.eye.shake:add(.5, 2, 8, 'xyz')
        self.is_goal_pause = true
        log:add('goal!!!', 1)
        log:add('goal!!!', 1)
        log:add('goal!!!', 1)
        log:add('goal!!!', 1)
        log:add('goal!!!', 1)
        
        wait(.25)
        log:add('goal!!!', 1)
        log:add('goal!!!', 1)
        log:add('goal!!!', 1)
        log:add('goal!!!', 1)
        log:add('goal!!!', 1)
        
        wait(.25)
        log:add('goal!!!', 1)
        log:add('goal!!!', 1)
        log:add('goal!!!', 1)
        log:add('goal!!!', 1)
        log:add('goal!!!', 1)
        
        wait(1.5 - .5)
        self.world:deactivate(self.ball)
        self.world:set_translation(self.ball, 0, 5, 0)
        self.world:reset(self.ball)
        
        wait(1)
        self.world:activate(self.ball)
        self.is_goal_pause = false
    end)
end