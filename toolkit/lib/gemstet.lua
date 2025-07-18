
-- placeholder functionalities. fairly limited, but just enough for this purpose.
--[[
    room:
        enter
        exit
        update
        draw
        paused
        resumed
        update_paused
]]

local gemstet = {}
gemstet._switch_to = nil
gemstet._switch_args = nil
gemstet._current = nil
gemstet._paused = false

function gemstet.init(room, ...)
    gemstet._current = room
    gemstet._current:enter(nil, ...)
end

function gemstet.switch(next, ...)
    gemstet._switch_to = next
    gemstet._switch_args = {...}
end

function gemstet.current()
    return gemstet._current
end

function gemstet.update(dt)
    if not gemstet._paused then
        gemstet._current:update(dt)
    else
        gemstet._current:update_paused(dt)
    end
end

function gemstet.draw()
    gemstet._current:draw()

    if gemstet._switch_to then
        local prev = gemstet._current
        if prev then prev:exit() end
        gemstet._current = gemstet._switch_to
        -- table.remove(gemstet.stack, #gemstet.stack)
        -- table.insert(gemstet.stack, gemstet._switch_to)
        gemstet._current:enter(prev, unpack(gemstet._switch_args))
        gemstet._switch_to = nil
        gemstet._switch_args = nil
    end
end

function gemstet.register_events(callbacks)
    local old_functions = {}
    local empty_function = function() end
    for _, f in ipairs(callbacks) do
        old_functions[f] = love[f] or empty_function
        love[f] = function(...)
            old_functions[f](...)
            if (not gemstet._paused) and gemstet._current[f] then gemstet._current[f](gemstet._current, ...) end
        end
    end
end

function gemstet.pause(bool)
    gemstet._paused = bool
    if gemstet._paused then
        if gemstet._current.paused then gemstet._current:paused() end
    else
        if gemstet._current.resumed then gemstet._current:resumed() end
    end
end

return gemstet