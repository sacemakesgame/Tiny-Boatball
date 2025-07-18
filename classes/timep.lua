local Timer = Object:extend()

function Timer:new(owner)
    self.owner = owner
    self.timers = {}
end

function Timer:update(dt)
    for tag, timer in pairs(self.timers) do
        timer.time = timer.time + dt

        if timer.type == "run" then
            timer.action(self.owner)
        elseif timer.type == 'after' then
            if timer.time >= timer.delay then
                timer.action(self.owner)
                self.timers[tag] = nil
            end
        elseif timer.type == 'conditional_after' then -- not tested
            if timer.condition(self.owner) then
                timer.action(self.owner)
                self.timers[tag] = nil
            end
        elseif timer.type == 'every' then
            if timer.time >= timer.delay then
                timer.action(self.owner)
                timer.time = timer.time - timer.delay
                if timer.count > 0 then
                    timer.count = timer.count - 1
                    if timer.count <= 0 then
                        if timer.after then timer.after(self.owner) end
                        self.timers[tag] = nil
                    end
                end
            end
        elseif timer.type == 'conditional_every' then -- not tested
            local condition = timer.condition(self.owner)
            if condition and not timer.last_condition then
                timer.action(self.owner)
                if timer.count > 0 then
                    timer.count = timer.count - 1
                    if timer.times <= 0 then
                        if timer.after then timer.after(self.owner) end
                        self.timers[tag] = nil
                    end
                end
            end
            timer.last_condition = condition
        elseif timer.type == 'during' then
            timer.action(self.owner)
            if timer.time >= timer.delay then
                if timer.after then timer.after() end
                self.timers[tag] = nil
            end
        elseif timer.type == 'conditional_during' then -- not tested
            local condition = timer.condition(self.owner)
            if condition then
                timer.action(self.owner)
            end
            if timer.last_condition and not condition then
                if timer.after then timer.after(self.owner) end
                self.timers[tag] = nil
            end
            timer.last_condition = condition
        elseif timer.type == 'tween' then
            local t = timer.method(timer.time / timer.delay)
            for k, v in pairs(timer.variable) do
                timer.object[k] = math.lerp(timer.initial_values[k], v, t)
            end
            if timer.time >= timer.delay then
                for k, v in pairs(timer.variable) do
                    timer.object[k] = v
                end
                if timer.after then timer.after() end
                self.timers[tag] = nil
            end
        end
    end
end

function Timer:after(delay, action, tag)
    local tag = tag or random:uid()
    self.timers[tag] = { type = 'after', time = 0, delay = delay, action = action }
end

function Timer:conditional_after(condition, action, tag)
    local tag = tag or random:uid()
    self.timers[tag] = { type = 'conditional_after', time = 0, condition = condition, action = action }
end

function Timer:every(delay, action, count, after, tag)
    local tag = tag or random:uid()
    self.timers[tag] = {
        type = 'every',
        time = 0,
        delay = delay,
        action = action,
        count = count or 0,
        after = after,
    }
end

function Timer:every_immediate(delay, action, count, after, tag)
    local tag = tag or random:uid()
    self.timers[tag] = {
        type = 'every',
        time = 0,
        delay = delay,
        action = action,
        count = count or 0,
        after = after,
    }
    local timer = self.timers[tag]
    timer.action(self.owner)
    if timer.count > 0 then
        timer.count = timer.count - 1
        if timer.count <= 0 then
            if timer.after then timer.after(self.owner) end
            self.timers[tag] = nil
        end
    end
end

function Timer:during(delay, action, after, tag)
    local tag = tag or random:uid()
    self.timers[tag] = {
        type = 'during',
        time = 0,
        delay = delay,
        action = action,
        after = opts.after
    }
end

function Timer:script(f)
    local co = coroutine.wrap(f)
    co(function(t)
        self:after(t, co)
        coroutine.yield()
    end)
end

function Timer:tween(delay, object, variable, method, after, tag)
    local tag = tag or random:uid()
    local initial_values = {}
    for k, _ in pairs(variable) do initial_values[k] = object[k] end
    self.timers[tag] = {
        type = 'tween',
        time = 0,
        delay = delay,
        object = object,
        variable = variable,
        method = method or math.linear,
        after = after,
        initial_values = initial_values,
    }
end

-- Calls the action every frame until it's cancelled via trigger:cancel.
-- The tag must be passed in otherwise there will be no way to stop this from running.
function Timer:run(action, after, tag)
    local tag = tag or random:uid()
    local after = after or function() end
    self.timers[tag] = {type = "run", time = 0, after = after, action = action}
    return tag
end

function Timer:cancel(tag)
    self.timers[tag] = nil
end

function Timer:is_running(tag)
    return self.timers[tag] and true or false
end

function Timer:destroy()
    self.owner = nil
    self.timers = nil
end


return Timer