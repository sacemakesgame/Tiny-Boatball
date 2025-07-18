EnemyBoat = Boat:extend()
EnemyBoat.home = vec3(15, 0, 0)
EnemyBoat.goal = vec3(-15, 0, 0)

function EnemyBoat:new(owner, v, role, character)
    EnemyBoat.super.new(self, owner, v, character, true)
    self.kick_available = true
    self.role = role
end


function EnemyBoat:update(dt)
    EnemyBoat.super.update(self, dt)
    -- self.owner.trail:set_position(self.translation + self.dir:clone():rotate(math.pi/16, 0, 1, 0) * -.5)
    -- self.owner.trail:emit(1)
    -- self.owner.trail:set_position(self.translation + self.dir:clone():rotate(-math.pi/16, 0, 1, 0) * -.5)
    -- self.owner.trail:emit(1)

    self:trail_particle()
end

function EnemyBoat:update_physics()
    if self.role == 'atk' then
        self:do_attack()
        local world = self.owner.world
        -- world:apply_force(self, self.dir:clone():scale(-self.speed))
        self.owner.world:apply_force(self, self.dir.x * -self.speed, self.dir.y * -self.speed, self.dir.z * -self.speed)
    elseif self.role == 'def' then
        self:do_defend()
    end    
end


function EnemyBoat:draw()
    if self.owner.active_shader:hasUniform("boatColor") then
        self.owner.active_shader:send('boatColor', color.palette.opponent)
    end
    EnemyBoat.super.draw(self)
    -- graphics.red()
    -- if self.tapos then
    --     pass.sphere(mat4():translate(self.tapos):scale(.5, 2, .5))
    -- end
    -- pass.sphere(mat4():translate(self.translation):translate(0, 0, 0):scale(.5, .2, .5))
    -- graphics.white()
end


-- function EnemyBoat:draw2d()
--     local playerdot = self.translation:clone()
--     playerdot = mat4.mul_vec3_perspective(playerdot, self.owner.eye.transform, playerdot)

--     local playerdot_projected = mat4.project(playerdot, self.owner.eye.projection, {0, 0, width, height})
--     playerdot_projected.y = height - playerdot_projected.y
--     -- guess no need to print the enemy ones
--     -- graphics.printmid(self.role, playerdot_projected.x, playerdot_projected.y - 60)
-- end


function EnemyBoat:destroy()
    self.owner.world:remove_body(self)    
end


function EnemyBoat:nos()
    local dir = vec3()
    self.owner.world:reset(self)
    if self.translation:dist(self.owner.ball.translation) < 5 then
        dir:set(self.owner.ball.translation - self.translation)
        dir:normalize()
    else
        dir:set(vec3(self.dir.x, 0, self.dir.z):normalize())
        if self.character == 'pelican' then
            -- self.owner.world:apply_force(self, vec3(0, -1, 0):scale(15))
            self.owner.world:apply_force(self, 0, -10, 0)
        end
    end
    dir:scale(-self.force)
    -- self.owner.world:apply_force(self, dir) 
    self.owner.world:apply_force(self, dir.x, dir.y, dir.z)
    self.kick_available = false
    self.timer:after(self.cooldown, function()
        self.kick_available = true
    end)

    self:emit_nos()
end


function EnemyBoat:do_attack()
    local ball_to_goal = (self.goal - self.owner.ball.translation):normalize()
    local target_pos = self.owner.ball.translation - ball_to_goal:scale(1.5)
    local target_dir = (target_pos - self.translation):normalize()
    -- steer
    local cross = self.dir:cross(target_dir)
    local sign = math.sign(cross.y)
    -- self.owner.world:apply_angular_force(self, vec3(0, sign, 0):scale(.1))
    self.owner.world:apply_angular_force(self, 0, sign * .1, 0)

    if self.kick_available then
        -- check kickable
        local dist = self.translation:dist(target_pos)
        if (dist <= 2) or (dist >= 10) then
            self:nos()
            self:wheelie()
        end
    end
end

function EnemyBoat:do_defend()
    local ball_away_home = (self.owner.ball.translation - self.home):normalize()
    local target_pos = vec3()
    local ballz_inside -- dk bruh
    
    if self.owner.ball.translation.x > 0 then -- inside home area
        target_pos:set(self.owner.ball.translation - ball_away_home:scale(1))
        ballz_inside = true
    else
        local z = math.clamp(self.owner.ball.translation.z, -1, 1)
        target_pos:set(vec3(15, 0, z))
    end
    
    -- self.tapos = target_pos
    
    local target_dir = (target_pos - self.translation):normalize()
    -- steer
    local cross = self.dir:cross(target_dir)
    local sign = math.sign(cross.y)
    -- self.owner.world:apply_angular_force(self, vec3(0, sign, 0):scale(.1))
    self.owner.world:apply_angular_force(self, 0, sign * .1, 0)

    if ballz_inside and self.kick_available then
        -- check kickable
        if self.translation:dist(target_pos) <= 2 then
            self:nos()
            self:wheelie()
        end
    end

    local world = self.owner.world
    if (not ballz_inside) and (self.translation:dist(target_pos) <= 2) then
        -- world:apply_force(self, self.dir:clone():scale(-.1))
        world:apply_force(self, -self.dir.x, -self.dir.y, -self.dir.z)
    else
        -- world:apply_force(self, self.dir:clone():scale(-.4))
        world:apply_force(self, -self.dir.x*.4, -self.dir.y*.4, -self.dir.z*.4)
    end
end


function EnemyBoat:emit_nos()
    self.owner.sound:play('nos', -.5)
    local dt = love.timer.getDelta()

    self:nos_particle(dt)

    -- self.timer:every_immediate(dt, function()
    --     -- kick particle
    --     self.owner.opponent_nos:set_direction(-self.dir)
    --     self.owner.opponent_nos:set_position(self.translation + self.dir:clone():rotate(math.pi/4, 0, 1, 0) * -.5)
    --     self.owner.opponent_nos:emit(10)
    --     self.owner.opponent_nos:set_position(self.translation + self.dir:clone():rotate(-math.pi/4, 0, 1, 0) * -.5)
    --     self.owner.opponent_nos:emit(10)
    --     self.owner.basic_nos:set_direction(-self.dir)
    --     self.owner.basic_nos:set_position(self.translation + self.dir:clone():rotate(math.pi/4, 0, 1, 0) * -.5)
    --     self.owner.basic_nos:emit(1)
    --     self.owner.basic_nos:set_position(self.translation + self.dir:clone():rotate(-math.pi/4, 0, 1, 0) * -.5)
    --     self.owner.basic_nos:emit(1)
    -- end, math.floor(10 / (dt / (1/60))))
end