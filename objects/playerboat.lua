PlayerBoat = Boat:extend()

function PlayerBoat:new(owner, v, character)
    PlayerBoat.super.new(self, owner, v, character)

    self.arrow_angle = 0
    self.last_target_dir = vec3()


    self.skill_counter = 1
    self.is_skill_available = false
end


function PlayerBoat:update(dt)
    if not self.is_skill_available then
        self.skill_counter = self.skill_counter + dt
        if self.skill_counter >= self.cooldown then
            self.is_skill_available = true
        end
    end

    PlayerBoat.super.update(self, dt)

    if not self.owner.can_process_stats_input then
        if input:pressed('nos') then -- dash
            if self.is_skill_available then
                -- local target_pos = self.owner:get_aim_position()
                -- local target_dir = (target_pos - self.translation):normalize()
                self:nos(self.last_target_dir)
                self:wheelie()
                self.owner.sound:play('nos')
                self.is_skill_available = false
                self.skill_counter = 0
                
                self:nos_particle(dt)
                --[[self.timer:every_immediate(dt, function()
                    -- kick particle
                    self.owner.ally_nos:set_direction(-self.dir)
                    self.owner.ally_nos:set_position(self.translation + self.dir:clone():rotate(math.pi/4, 0, 1, 0) * -.5)
                    self.owner.ally_nos:emit(10)
                    self.owner.ally_nos:set_position(self.translation + self.dir:clone():rotate(-math.pi/4, 0, 1, 0) * -.5)
                    self.owner.ally_nos:emit(10)
                    self.owner.basic_nos:set_direction(-self.dir)
                    self.owner.basic_nos:set_position(self.translation + self.dir:clone():rotate(math.pi/4, 0, 1, 0) * -.5)
                    self.owner.basic_nos:emit(1)
                    self.owner.basic_nos:set_position(self.translation + self.dir:clone():rotate(-math.pi/4, 0, 1, 0) * -.5)
                    self.owner.basic_nos:emit(1)
                end, math.floor(10 / (dt / (1/60))))]]
            end
        end 
    end

    -- self.owner.trail:set_position(self.translation + self.dir:clone():rotate(math.pi/16, 0, 1, 0) * -.5)
    -- self.owner.trail:emit(1)
    -- self.owner.trail:set_position(self.translation + self.dir:clone():rotate(-math.pi/16, 0, 1, 0) * -.5)
    -- self.owner.trail:emit(1)
    self:trail_particle()
end

function PlayerBoat:update_physics()
    if not self.owner.can_process_stats_input then
        local world = self.owner.world

        -- local target_pos = self.owner:get_aim_position()
        -- local target_dir = (target_pos - self.translation):normalize()
        -- local cross = self.dir:cross(target_dir)
        -- local sign = math.sign(cross.y)
        -- self.owner.world:apply_angular_force(self, vec3(0, sign, 0):scale(.15))

        local target_dir = vec3()
        if input:down('up') then
            target_dir:add(0, 0, -1)
        end
        if input:down('down') then
            target_dir:add(0, 0, 1)
        end
        if input:down('right') then
            target_dir:add(1, 0, 0)
        end
        if input:down('left') then
            target_dir:add(-1, 0, 0)
        end

        -- target_dir:add(0, .01, 0) 
        target_dir:normalize()
        
        if target_dir:len() > 0 then
            local cross = self.dir:cross(target_dir)
            local sign = math.sign(cross.y)
            self.owner.world:apply_angular_force(self, 0, sign * .3, 0)
            -- self.owner.world:apply_angular_force(self, 0, sign, 0)
            self.last_target_dir:set(target_dir)
            self.owner.world:apply_force(self, self.dir.x * -self.speed, self.dir.y * -self.speed, self.dir.z * -self.speed)
        else
            self.last_target_dir:set(self.dir)
            self.owner.world:apply_force(self, self.dir.x * -self.speed/4, self.dir.y * -self.speed/4, self.dir.z * -self.speed/4) -- keep moving slowly

        end
    else
        -- self.owner.world:apply_force(self, self.dir:clone():scale(-self.speed/4)) -- keep moving slowly
        self.owner.world:apply_force(self, self.dir.x * -self.speed/4, self.dir.y * -self.speed/4, self.dir.z * -self.speed/4) -- keep moving slowly
    end
end


function PlayerBoat:draw()
    if self.owner.active_shader:hasUniform("boatColor") then
        self.owner.active_shader:send('boatColor', color.palette.ally)
    end

    PlayerBoat.super.draw(self)
    -- pass.push()
    -- pass.translate(self.translation)
    -- pass.cube(mat4():scale(.8, .2, .8))
    -- pass.pop()
end


function PlayerBoat:draw2d()
    local scale = width/2400
    local playerdot = self.translation:clone()
    playerdot = mat4.mul_vec3_perspective(playerdot, self.owner.eye.transform, playerdot)

    local playerdot_projected = mat4.project(playerdot, self.owner.eye.projection, {0, 0, width, height})
    playerdot_projected.y = height - playerdot_projected.y
    -- graphics.printmid(self.hp, playerdot_projected.x, playerdot_projected.y - 60)
    graphics.capsule('fill', playerdot_projected.x - 20 * scale, playerdot_projected.y - 100 * scale, 130 * scale, 80 * scale, true)
    graphics.set_color(color.palette.ally)
    graphics.printmid('you', playerdot_projected.x - 20 * scale, playerdot_projected.y - 105 * scale, 0, 1/3)
    graphics.white()

    -- outer white
    graphics.circle('fill', playerdot_projected.x + 50 * scale, playerdot_projected.y - 100 * scale, (30 + 8 + 15) * scale)
    graphics.set_line_width(8 * scale)
    local percentage = self.skill_counter / self.cooldown
    -- cool color lerp
    graphics.set_color(color.lerp(color.palette.water, color.palette.ally, percentage))
    -- round bar
    love.graphics.arc('line', 'open', playerdot_projected.x + 50 * scale, playerdot_projected.y - 100 * scale, 15 * scale, 0, percentage * (2*math.pi))
    -- grow bar
    graphics.circle('fill', playerdot_projected.x + 50 * scale, playerdot_projected.y - 100 * scale, percentage * 23 * scale)
    graphics.set_line_width(1 * scale)
    graphics.white()
end


function PlayerBoat:destroy()
    self.owner.world:remove_body(self)    
end


function PlayerBoat:nos(dir)
    local dir = dir:clone()
    local to_ball_dir = (self.owner.ball.translation - self.translation):normalize()

    self.owner.world:reset(self)
    -- if (self.translation:dist(self.owner.ball.translation) < 4) and (dir:dot(to_ball_dir) > -.5) then
    if (self.translation:dist(self.owner.ball.translation) < 5) and (dir:dot(to_ball_dir) > -.5) then
        dir:set(self.owner.ball.translation - self.translation)
        dir:normalize()
    else
        if self.character == 'pelican' then
            self.owner.world:apply_force(self, 0, -10, 0)
        end
    end
    dir:scale(-self.force)
    self.owner.world:apply_force(self, dir.x, dir.y, dir.z)
end


function PlayerBoat:fix_stuff()
    self.owner.world:apply_angular_force(self, 0, .15, 0) -- dk meh it fix stuff bruh
end