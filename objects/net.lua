Net = Object:extend()
-- Net.model = pigic.character('game-assets/obj/goal.obj')
Net.model = pigic.character('game-assets/obj/net.obj')

function Net:new(owner, x, y, z, flip)
    self.owner = owner
    self.translation = vec3(x, y, z)
    self.flip = flip or false
end


function Net:update(dt)
    
end


function Net:draw()
    pass.push()
    pass.translate(self.translation)
    pass.translate(0, -.3 + math.sin(love.timer.getTime() * 1) * .3, 0)
    pass.scale(self.flip and -1 or 1, 1, 1)
    graphics.set_color(self.flip and color.palette.opponent or color.palette.ally)
    self.model:draw()
    graphics.white()
    pass.pop()
end


function Net:destroy()

end