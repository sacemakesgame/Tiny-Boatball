--[[
    just a class for drawing score in a 'fancy' way,
    main logic for scores stuff are still at stage.lua

    this dude access 'em with like,
        self.owner.blue_score
        self.owner.time_counter
        etc.
]]

ScoreBoard = Object:extend()


function ScoreBoard:new(owner)
    self.owner = owner
    self.timer = class.timer(self)
    self.red_spring = class.spring(1)
    self.blue_spring = class.spring(1)
    -- self.rotate_spring = class.spring(0, 100, 30)
    self.rotate_spring = class.spring(0, 100, 5)
    self.position_spring = class.spring2d(width/2, -200 * scale)

    self._scale = 1
end


function ScoreBoard:update(dt)
    self.timer:update(dt)
    self.red_spring:update(dt)
    self.blue_spring:update(dt)
    self.rotate_spring:update(dt)
    self.position_spring:update(dt)
end


function ScoreBoard:draw()
    graphics.push()
    graphics.translate(self.position_spring.x, self.position_spring.y)
    graphics.rotate(math.sin(love.timer.getTime()) * math.pi/150)
    graphics.rotate(self.rotate_spring.x)

    -- (-) sign on mid
    graphics.set_color(color.palette.dark)
    graphics.capsule('fill', 0, -5 * scale, 50 * scale, 15 * scale, true, .25)
    graphics.white()
    graphics.capsule('fill', 0, -15 * scale, 50 * scale, 15 * scale, true, .25)

    -- blue score
    graphics.push_rotate_scale(-115 * scale, 0, 0, self.blue_spring.x)
    graphics.set_color(color.palette.dark)
    graphics.capsule('fill', -115 * scale, 0, 125 * scale, 125 * scale, true, .25)
    graphics.white()
    graphics.capsule('fill', -115 * scale, -15 * scale, 125 * scale, 125 * scale, true, .25)
    graphics.set_color(color.palette.ally)
    local thickness = 4*height/1440
    for i = 0, math.pi*2, math.pi/8 do
        graphics.printmid(tostring(self.owner.blue_score), -115 * scale + math.cos(i) * thickness, -10 * scale + math.sin(i) * thickness, 0, .5)
    end
    graphics.pop()
    
    -- red score
    graphics.push_rotate_scale(115 * scale, 0, 0, self.red_spring.x)
    graphics.set_color(color.palette.dark)
    graphics.capsule('fill', 115 * scale, 0, 125 * scale, 125 * scale, true, .25)
    graphics.white()
    graphics.capsule('fill', 115 * scale, -15 * scale, 125 * scale, 125 * scale, true, .25)
    graphics.set_color(color.palette.opponent)
    for i = 0, math.pi*2, math.pi/8 do
        graphics.printmid(tostring(self.owner.red_score), 115 * scale + math.cos(i) * thickness, -10 * scale + math.sin(i) * thickness, 0, .5)
    end
    graphics.pop()


    -- time
    -- Break into minutes and seconds
    
    local minutes = math.floor(self.owner.time_counter / 60)
    local seconds = self.owner.time_counter % 60

    -- Format: mm:ss (with leading zero if needed)
    local formatted = string.format("%02d:%04.1f", minutes, seconds)

    -- graphics.scale(self._scale)
    -- graphics.translate()
    -- if (self.owner.time_counter <= 10) then
    --     graphics.scale(math.sin(love.timer.getTime() * 2) * .25)
    -- end
    -- graphics.set_color(color.palette.dark)
    -- graphics.capsule('fill', 0, 125 * scale, 200 * scale, 80 * scale, true, .25)
    -- graphics.white()
    -- graphics.capsule('fill', 0, 115 * scale, 200 * scale, 80 * scale, true, .25)
    -- graphics.set_color((self.owner.time_counter <= 10) and color.palette.opponent or color.palette.dark)
    -- graphics.printmid(formatted, 0, 120 * scale, 0, .8 * 1/3)
    graphics.scale(self._scale)
    graphics.translate(0, 120 * scale)
    if (self.owner.time_counter <= 10) then
        graphics.scale(1 + math.sin(love.timer.getTime() * 20) * .1)
    end
    graphics.set_color(color.palette.dark)
    graphics.capsule('fill', 0, 5 * scale, 200 * scale, 80 * scale, true, .25)
    graphics.white()
    graphics.capsule('fill', 0, -5 * scale, 200 * scale, 80 * scale, true, .25)
    graphics.set_color((self.owner.time_counter <= 10) and color.palette.opponent or color.palette.dark)
    graphics.printmid(formatted, 0, 0, 0, .8 * 1/3)

    graphics.pop()
end


function ScoreBoard:animate_red()
    self.red_spring:pull(.3)
    self.rotate_spring:pull(math.pi/12)
end

function ScoreBoard:animate_blue()
    self.blue_spring:pull(.3)
    self.rotate_spring:pull(-math.pi/12)
end


function ScoreBoard:enter()
    self.position_spring:animate(width/2, 115 * scale)
end

function ScoreBoard:exit()
    self.position_spring:animate(width/2, -200 * scale)
end

function ScoreBoard:end_game()
    self.position_spring:animate(width/2, 550 * scale)
    self.timer:tween(.1, self, {_scale = 0}, math.cubic_in_out)
end