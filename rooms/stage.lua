local collision = require(pigic.collision)


Stage = {}

function Stage:enter(prev, type)
    self.font = love.graphics.newFont('game-assets/Schoolbell-Regular.ttf', 192*height/1440)
    love.graphics.setFont(self.font)

    love.graphics.setMeshCullMode('none')
    self.timer = class.timer(self)

    self.sound = class.sound(self, {'music', 'sfx'})
    self.sound:randomize_pitch('sfx', .95, 1.05)
    self.sound:add('oreo', 'sfx', 'game-assets/audio/oreo.wav', 'static')
    self.sound:add('nos', 'sfx', 'game-assets/audio/nos.ogg', 'static')
    self.sound:add('ball-bounce', 'sfx', 'game-assets/audio/ball-bounce.ogg', 'static')
    self.sound:add('start-whistle', 'sfx', 'game-assets/audio/start-whistle.ogg', 'static')
    self.sound:add('end-whistle', 'sfx', 'game-assets/audio/end-whistle.ogg', 'static')
    self.sound:add('goal-crowd', 'sfx', 'game-assets/audio/goal-crowd.ogg', 'static')
    self.sound:add('blunder-crowd', 'sfx', 'game-assets/audio/blunder-crowd.ogg', 'static')
    self.sound:add('goal-snare', 'sfx', 'game-assets/audio/goal-snare.wav', 'static')
    self.sound:add('blunder-snare', 'sfx', 'game-assets/audio/blunder-snare.wav', 'static')
    self.sound:add('wow', 'sfx', 'game-assets/audio/wow.ogg', 'static')

    -- eye aka camera
    self.eye = {}
    self.eye.transform = mat4()
    self.eye.shake = class.shake3d()
    self.eye.shake_rotate = class.shake3d()
    self.eye.shader = graphics.new_shader(pigic.unlit)
    -- local scale = 100
    self.eye.projection = mat4.from_perspective(50, width/height, .01, 300)
    self.eye.shader:send('projectionMatrix', 'column', self.eye.projection)    
    
    self.world = pigic.world(self)
    
    self.ally_holder = class.holder(self)
    self.opponent_holder = class.holder(self)
    self.stuff_holder = class.holder(self)

    self.water = pigic.model('game-assets/obj/aquarium-water.obj')
    self.table = pigic.character('game-assets/obj/aquarium-table.obj', 'game-assets/png/palette.png')
    self.wall = pigic.character('game-assets/obj/wall.obj', 'game-assets/png/wall-texture.png')
    self.floor = pigic.character('game-assets/obj/floor.obj', 'game-assets/png/floor.png')
    self.glass = pigic.character('game-assets/obj/aquarium-glass.obj', 'game-assets/png/palette.png')

    -- MENU STUFF
    self.ui_holder = class.holder(self)
    self.chat_holder = class.holder(self)

    -- set stuff based on match-type
    local character_list
    if type == TYPE.CAREER then
        self.stats_menu = self.ui_holder:add(CareerStats)
        CAREER_CHARACTER_LIST.opponent = CAREER_OPPONENT_LIST[CAREER_MATCH_COUNTER] -- update opponent list
        character_list = CAREER_CHARACTER_LIST
    elseif type == TYPE.QUICKMATCH then
        self.stats_menu = self.ui_holder:add(QuickMatchStats)
        character_list = QUICKMATCH_CHARACTER_LIST
    end

    self.pause_menu = self.ui_holder:add(PauseMenu) -- gotta declared before any other menu, cuz it needs to overlay it all


    -- LOAD GUYS
    -- opponents
    local opponent_positions = {
        [1] = vec3(14, 3, 0),
        [2] = vec3(14*2/3, 3, -10/2),
        [3] = vec3(14/3, 3, 0),
        [4] = vec3(14*2/3, 3, 10/2),
    }
    self.opponent_holder:add(EnemyBoat, opponent_positions[1], 'def', character_list.opponent[1]) -- keeper
    for i = 2, 4 do
        self.opponent_holder:add(EnemyBoat, opponent_positions[i], 'atk', character_list.opponent[i])
    end
    
    local positions = {
        [1] = vec3(-14, 3, 0),
        [2] = vec3(-14*2/3, 3, -10/2),
        [3] = vec3(-14/3, 3, 0),
        [4] = vec3(-14*2/3, 3, 10/2),
    }
    -- allies
    if character_list.player_index == 1 then -- player is the lkeeper
        self.player = self.ally_holder:add(PlayerBoat, positions[1], character_list.ally[1])
        for i = 2, 4 do
            self.ally_holder:add(AllyBoat, positions[i], 'atk', character_list.ally[i])
        end
    else -- player is outfield
        self.ally_holder:add(AllyBoat, positions[1], 'def', character_list.ally[1]) -- keeper
        for i = 2, 4 do
            if (i == character_list.player_index) then
                self.player = self.ally_holder:add(PlayerBoat, positions[i], character_list.ally[i])
            else
                self.ally_holder:add(AllyBoat, positions[i], 'atk', character_list.ally[i])
            end
        end
    end

    for _, v in ipairs(self.opponent_holder.objects) do
        self.world:deactivate(v)
    end
    for _, v in ipairs(self.ally_holder.objects) do
        self.world:deactivate(v)
    end

    self.ball = self.stuff_holder:add(Ball, 0, 10, 0)
    self.stuff_holder:add(Net, -15, 0, 0)
    self.stuff_holder:add(Net, 15, 0, 0, true)

    local w = 6 -- for x
    local h = 11.3 -- for y
    local d = 20/3 -- for z

    self.goal_left = {from = vec3(-15 - w, -h/2, -d/2), size = vec3(w, h, d)}
    self.goal_right = {from = vec3(15, -h/2, -d/2), size = vec3(w, h, d)}

    self.eye.offset = vec3()
    self.eye.from = vec3(0, 30, 40)
    self.eye.from_lerpweight = 0
    self.eye.offset_lerpweight = 0
    self.timer:tween(1, self.eye, {from_lerpweight = .2, offset_lerpweight = .5}, math.quint_in)

    self.blue_score = 0
    self.red_score = 0
    self.is_goal_pause = true

    self.water_shader = graphics.new_shader(pigic.water)
    self.water_shader:send('projectionMatrix', 'column', self.eye.projection)
    self.water_shader:send('ballRadius', self.ball.radius * .9) -- make it a bit smaller
    self.water_shader:send('ballPosition', {self.ball.translation.x, self.ball.translation.y, self.ball.translation.z})

    self.sun = {}
    self.sun.transform = mat4()
    self.sun.shader = graphics.new_shader(pigic.glsl_depth)
    self.sun.canvas = graphics.new_canvas(1000 * 1.5 * 1.5, 1000 * 1.5, {format = "depth24", readable = true})
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

    self.eye.intro_offset = vec3(0, 20, 0)
    self.is_counting = false
    -- hang it there for a sec
    self.world:deactivate(self.ball)
    self.world:set_translation(self.ball, 0, 10, 0)
    self.world:reset(self.ball)

    self.time_counter = 60 * 2 -- 2 mintues per round
    -- self.time_counter = 5 -- for testing only
    self.is_counting = false

    local title = {
        [1] = { 'Q', 'U', 'A', 'L', 'I', 'F', 'I', 'E', 'R' },
        [2] = { 'Q', 'U', 'A', 'R', 'T', 'E', 'R', 'F', 'I', 'N', 'A', 'L' },
        [3] = { 'S', 'E', 'M', 'I', 'F', 'I', 'N', 'A', 'L' },
        [4] = { 'F', 'I', 'N', 'A', 'L', '!'},
    }
    self.chat_holder:add(EventChat, vec2(width/2, height/2), title[CAREER_MATCH_COUNTER], .5, .1)

    self.can_process_stats_input = false
    
    self.score_board = ScoreBoard(self)

    self.timer:after(1, self.start_match)
end


function Stage:update(dt)
    if input:pressed('back') then
        gamestate.pause(true)
    end

    if self.win_the_game_escape_enabled and (not self.is_switching_to_home) then    
        if input:down('back') then
            self.win_the_game_escape_holddur = self.win_the_game_escape_holddur + dt
            if self.win_the_game_escape_holddur >= 1 then
                self.is_switching_to_home = true
                tool:switch(Home, TYPE.MAIN)
            end
        end
    end

    self.score_board:update(dt)

    if self.is_counting then
        self.time_counter = self.time_counter - dt
        if self.time_counter <= 0 then
            self.time_counter = 0
            self.is_goal_pause = true
            self.is_counting = false
            self.timer:script(function(wait)
                -- time's up!
                local status
                if self.blue_score > self.red_score then
                    status = 'win'
                elseif self.blue_score < self.red_score then
                    status = 'lose'
                elseif self.blue_score == self.red_score then
                    status = 'draw'
                end

                local unlocked = update_career_status(status)
                if status == 'win' then
                    if CAREER_MATCH_COUNTER >= 5 then -- win the game
                        CAREER_MATCH_COUNTER = 1 -- reset
                        save_career_data() -- bad way to do it, but whatever bro..
                        self.timer:script(function(wait)
                            self.score_board:exit()                            
                            wait(1)
                            self.chat_holder:add(EventChat, vec2(width/2, height/2), {' W ', ' O ', ' W ', ' ! '}, 1.2, .3)
                            self.sound:play('wow')
                            self.timer:after(random:float(.5, 1.4), function() self.sound:play('wow') end)
                            self.timer:after(random:float(.5, 1.4), function() self.sound:play('wow') end)
                            self.timer:after(random:float(.5, 1.4), function() self.sound:play('wow') end)
                            self.timer:after(random:float(.5, 1.4), function() self.sound:play('wow') end)
                            self.timer:after(random:float(.5, 1.4), function() self.sound:play('wow') end)
                            self.timer:after(random:float(.5, 1.4), function() self.sound:play('wow') end)
                            self.timer:after(random:float(.5, 1.4), function() self.sound:play('wow') end)
                            self.timer:after(random:float(.5, 1.4), function() self.sound:play('wow') end)
                            self.timer:after(random:float(.5, 1.4), function() self.sound:play('wow') end)
                            self.timer:after(random:float(.5, 1.4), function() self.sound:play('wow') end)
                            wait(.6)
                            self.chat_holder:add(BubbleChat, vec2(width/5, height/5), 'WOW!', .2, 1.2, 1, color.palette.ally, color.sass.white)
                            wait(.1)
                            self.chat_holder:add(BubbleChat, vec2(width*4/5, height/5), 'WOW!', .2, 1.2, 1, color.palette.ally, color.sass.white)
                            wait(.6)
                            self.chat_holder:add(BubbleChat, vec2(width/5, height*4/5), 'WOW!', .2, .5, 1, color.palette.opponent, color.sass.white)
                            wait(.1)
                            self.chat_holder:add(BubbleChat, vec2(width*4/5, height*4/5), 'WOW!', .2, .5, 1, color.palette.opponent, color.sass.white)
                            wait(1)
                            self.chat_holder:add(BubbleChat, vec2(width/2, height/2 - 150 * scale), 'congrats bro!', .1, 5, 1, color.palette.ally, color.sass.white)
                            if unlocked then
                                wait(.5)
                                self.chat_holder:add(BubbleChat, vec2(width/2, height/2), 'you beat the game!!', .1, 4, .35, color.palette.white, color.sass.dark)
                                wait(2)
                                self.chat_holder:add(BubbleChat, vec2(width/2, height/2 + 150 * scale), 'unlocked: ' .. unlocked .. '!!', .1, 2, .35, color.palette.white, color.sass.dark)
                                wait(5)
                            else
                                wait(.5)
                                self.chat_holder:add(BubbleChat, vec2(width/2, height/2), 'you beat the game again!!', .1, 3, .35, color.palette.white, color.sass.dark)
                                wait(5)
                            end
                            for i = 1, 10 do
                                self.stuff_holder:add(Ball, random:float(-11, 11), random:float(20, 40), random:float(-5, 5))
                            end
                            wait(2)
                            self.chat_holder:add(BubbleChat, vec2(width/2, height*9/10), 'you can play around if you want :v', .067, 2, .35, color.palette.white, color.sass.dark)
                            wait(5)
                            self.win_the_game_escape_enabled = true -- whatever bro
                            self.win_the_game_escape_holddur = 0
                            self.chat_holder:add(BubbleChat, vec2(width/2, height*9/10), 'anyway, you can go home from pause menu (esc)', .067, nil, .35, color.palette.white, color.sass.dark)
                        end)
                    else -- next match
                        self.sound:play('end-whistle')
                        self.chat_holder:add(EventChat, vec2(width/2, height/2), {'T', 'I', 'M', 'E', 'S', 'U', 'P', '!'}, .5)
                        wait(2.5)
                        self.score_board:end_game()
                        self.chat_holder:add(BubbleChat, vec2(width/2, 200 * scale), 'you win! :)', .1, nil, 1, color.palette.ally, color.sass.white)
                        if unlocked then
                            self.timer:after(1, function()
                                self.chat_holder:add(BubbleChat, vec2(width/2, 350 * scale), 'unlocked: ' .. unlocked .. '!!', .1, nil, .35, color.palette.white, color.sass.dark)
                            end)
                        end
                        wait(1)
                        self.stats_menu:enter(status)
                        wait(.5)
                        self.can_process_stats_input = true
                    end
                elseif status == 'lose' then
                    self.sound:play('end-whistle')
                    self.chat_holder:add(EventChat, vec2(width/2, height/2), {'T', 'I', 'M', 'E', 'S', 'U', 'P', '!'}, .5)
                    wait(2.5)
                    self.score_board:end_game()
                    self.chat_holder:add(BubbleChat, vec2(width/2, 200 * scale), 'you lose! :(', .1, nil, 1, color.palette.opponent, color.sass.white)
                    wait(1)
                    self.stats_menu:enter(status)
                    wait(.5)
                    self.can_process_stats_input = true
                elseif status == 'draw' then
                    self.sound:play('end-whistle')
                    self.chat_holder:add(EventChat, vec2(width/2, height/2), {'T', 'I', 'M', 'E', 'S', 'U', 'P', '!'}, .5)
                    wait(2.5)
                    self.score_board:end_game()
                    self.chat_holder:add(BubbleChat, vec2(width/2, 200 * scale), 'draw..', .1, nil, 1, color.palette.dark, color.sass.white)
                    wait(1)
                    self.stats_menu:enter(status)
                    wait(.5)
                    self.can_process_stats_input = true
                end
            end)
        end
    end
    self.timer:update(dt)
    self.sound:update(dt)

    local offset = vec3()
    offset:add(self.ball.translation)
    offset:add(self.player.translation)
    offset:scale(1/2)
    offset:scale(.75)
    
    self.eye.offset:lerp(offset, self.eye.offset_lerpweight)
    
    local offset_y = math.remap((self.player.translation - self.ball.translation):len(), 5, 15, 12, 15)
    self.eye.from:lerp(vec3(self.eye.offset.x, offset_y, 10 + self.eye.offset.z), self.eye.from_lerpweight)

    self.eye.transform:look_at(self.eye.from, vec3(self.eye.offset.x, 0, self.eye.offset.z), vec3(0, 1, 0))

    self.eye.transform:translate(self.eye.shake.x, self.eye.shake.y, self.eye.shake.z)
    self.eye.transform:rotate(self.eye.shake_rotate.x, 1, 0, 0)
    self.eye.transform:rotate(self.eye.shake_rotate.y, 0, 1, 0)
    self.eye.transform:rotate(self.eye.shake_rotate.z, 0, 0, 1)

    self.eye.shake:update(dt)
    self.eye.shake_rotate:update(dt)

    self.world:update(dt)

    self.trail:update(dt)
    self.ally_nos:update(dt)
    self.basic_nos:update(dt)
    self.opponent_nos:update(dt)

    self.ally_holder:update(dt)
    self.opponent_holder:update(dt)
    self.stuff_holder:update(dt)

    -- goal check
    if not self.is_goal_pause then
        if self:sphere_inside_aabb(self.ball.translation, self.ball.radius, self.goal_left) then
            self:reset_ball()
            self.red_score = self.red_score + 1
            self:register_scorer_blue() -- call the "GOAL!" thing inside this 
            self.timer:after(.1, function() self.score_board:animate_red() end)
        elseif self:sphere_inside_aabb(self.ball.translation, self.ball.radius, self.goal_right) then
            self:reset_ball()
            self.blue_score = self.blue_score + 1
            self:register_scorer_red()
            self.timer:after(.1, function() self.score_board:animate_blue() end)
        end
    end

    if self.can_process_stats_input then
        self.stats_menu:process_input()
    end

    self.ui_holder:update(dt)
    self.chat_holder:update(dt)

    self.stats_menu:set_active()
end



function Stage:draw()
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
    self.wall:draw()
    self.table:draw()
    self.floor:draw()
    self.glass:draw()

    self.trail:draw()
    self.ally_nos:draw()
    self.basic_nos:draw()
    self.opponent_nos:draw()

    -- self.world:draw()
    
    graphics.white()
        
    graphics.set_shader()
    love.graphics.setDepthMode('always', false)
    -- 2d here

    -- graphics.draw(self.sun.canvas, 0, 0, 0, .3) -- shadow map

    self.ally_holder:draw2d()
    self.opponent_holder:draw2d()
    
    self.score_board:draw()
    
    self.chat_holder:draw()
    self.ui_holder:draw()
end


function Stage:exit()
end


function Stage:sphere_inside_aabb(pos, radius, aabb)
    local min = aabb.from
    local max = aabb.from + aabb.size

    return
        ((pos.x + radius) < max.x) and ((pos.x - radius) > min.x)
        and ((pos.y + radius) < max.y) and ((pos.y - radius) > min.y)
        and ((pos.z + radius) < max.z) and ((pos.z - radius) > min.z)
end


function Stage:register_scorer_blue()
    local scorer = self.ball.last_contact
    if self.ally_holder:get_object_by_id(scorer.id) then
        scorer.blunder_count = scorer.blunder_count + 1
        self.chat_holder:add(EventChat, vec2(width/2, height/2), { 'B', 'L', 'U', 'N', 'D', 'E', 'R', '!' })
    elseif self.opponent_holder:get_object_by_id(scorer.id) then
        scorer.goal_count = scorer.goal_count + 1
        self.chat_holder:add(EventChat, vec2(width/2, height/2), { 'G', 'O', 'A', 'L', '!', '!' })
    end
    self.sound:play('blunder-crowd')
    self.sound:play('blunder-snare')
end

function Stage:register_scorer_red()
    local scorer = self.ball.last_contact
    if self.ally_holder:get_object_by_id(scorer.id) then
        scorer.goal_count = scorer.goal_count + 1
        self.chat_holder:add(EventChat, vec2(width/2, height/2), { 'G', 'O', 'A', 'L', '!', '!' })
    elseif self.opponent_holder:get_object_by_id(scorer.id) then
        scorer.blunder_count = scorer.blunder_count + 1    
        self.chat_holder:add(EventChat, vec2(width/2, height/2), { 'B', 'L', 'U', 'N', 'D', 'E', 'R', '!' })
    end
    self.sound:play('goal-crowd')
    self.sound:play('goal-snare')
end

function Stage:reset_ball()
    self.timer:script(function(wait)
        self.is_counting = false
        self.eye.shake:add(.5, 2, 8, 'xyz')
        self.eye.shake_rotate:add(.8, .1, 10, 'xyz')
        self.is_goal_pause = true        
        wait(2)
        self.sound:play('start-whistle')
        self.world:deactivate(self.ball)
        self.world:set_translation(self.ball, 0, 10, 0)
        self.world:reset(self.ball)
        
        wait(1)
        self.world:activate(self.ball)
        self.is_goal_pause = false
        self.is_counting = true
    end)
end

function Stage:keypressed(key)
    if key == '1' then
        self.sound:play('goal-crowd')
        self.sound:play('goal-snare')
        self.blue_score = self.blue_score + 1
        self.score_board:animate_blue()
        self.chat_holder:add(EventChat, vec2(width/2, height/2), { 'G', 'O', 'A', 'L', '!', '!' })
    elseif key == '2' then
        self.sound:play('blunder-crowd')
        self.sound:play('blunder-snare')
        self.red_score = self.red_score + 1
        self.score_board:animate_red()
        self.chat_holder:add(EventChat, vec2(width/2, height/2), { 'G', 'O', 'A', 'L', '!', '!' })
    end
end


function Stage:update_paused(dt)
    self.pause_menu:process_input()
    self.pause_menu:update(dt)
    self.pause_menu:set_active() 
    if input:pressed('back') then
        gamestate.pause(false)
    end
end


function Stage:paused()
    self.pause_menu:enter()
end


function Stage:resumed()
    self.pause_menu:exit()
end


function Stage:start_match()
    self.timer:script(function(wait)
        wait(1) -- 3...
        self.chat_holder:add(BubbleChat, vec2(width/2, height/2), '3...', .1, .5, 1).rotate_spring:pull(math.pi/2)
        wait(1) -- 2...
        self.chat_holder:add(BubbleChat, vec2(width/2, height/2), '2...', .1, .5, 1).rotate_spring:pull(math.pi/2)
        wait(1) -- 1...
        self.chat_holder:add(BubbleChat, vec2(width/2, height/2), '1...', .1, .5, 1).rotate_spring:pull(math.pi/2)
        wait(1) -- START
        self.chat_holder:add(BubbleChat, vec2(width/2, 150 * scale), 'START!!', .03, 1, .75).rotate_spring:pull(math.pi*2)
        self.sound:play('start-whistle')
        self.is_counting = true
        
        self.world:activate(self.ball)
        for _, v in ipairs(self.opponent_holder.objects) do
            self.world:activate(v)
        end
        for _, v in ipairs(self.ally_holder.objects) do
            self.world:activate(v)
        end
        self.player:fix_stuff()
        self.is_goal_pause = false
        
        wait(2)
        self.score_board:enter()
    end)
end