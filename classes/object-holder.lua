local ObjectHolder = Object:extend()

function ObjectHolder:new(owner)
    self.objects = {}
    self.objects.by_id = {}
    self.owner = owner
end

function ObjectHolder:update(dt, ...)
    for i = #self.objects, 1, -1 do
        local object = self.objects[i]
        if not object.dead then object:update(dt) end
        if object.dead then
            object:destroy()
            self.objects.by_id[object.id] = nil
            table.remove(self.objects, i)
        end
    end
end

function ObjectHolder:draw()
    for i = 1, #self.objects do
        local object = self.objects[i]
        if not object.dead then object:draw() end
    end
end

function ObjectHolder:draw2d()
    for i = 1, #self.objects do
        local object = self.objects[i]
        if not object.dead and object.draw2d then object:draw2d() end
    end
end

function ObjectHolder:draw_only_class(class)
    for i = 1, #self.objects do
        local object = self.objects[i]
        if object:is(class) then
            if not object.dead then object:draw() end
        end
    end
end

function ObjectHolder:draw_except_class(class)
    for i = 1, #self.objects do
        local object = self.objects[i]
        if not object:is(class) then
            if not object.dead then object:draw() end
        end
    end
end

function ObjectHolder:add(object, ...)
    local instance = object(self.owner, ...)
    instance.id = random:uid()
    self.objects.by_id[instance.id] = instance
    self:push(instance)
    return instance
end

function ObjectHolder:push(instance)
    table.insert(self.objects, instance)
end

function ObjectHolder:get_alive_objects()
    local objects = {}
    for _, v in ipairs(self.objects) do
        if not v.dead then table.insert(objects, v) end
    end
    return objects
end

function ObjectHolder:get_objects_by_class(class)
    assert(class:is(Object), 'id must be Object, got ' .. type(class)) -- broken, but work just as well
    local objects = {}
    for i = 1, #self.objects do
        local object = self.objects[i]
        if object:is(class) then
            table.insert(objects, object)
        end
    end
    return objects
end

function ObjectHolder:get_object_by_id(id)
    return self.objects.by_id[id]
end

function ObjectHolder:is_object_alive(id)
    return (self.objects.by_id[id] and not self.objects.by_id[id].dead) or false
end

function ObjectHolder:kill_object(id)
    self.objects.by_id[id].dead = true
end

function ObjectHolder:pop_front()
    return table.remove(self.objects, 1)
end

function ObjectHolder:destroy()
    for _, object in ipairs(self.objects) do object:destroy() end
    self.objects.by_id = {}
    self.objects = {}
end

return ObjectHolder