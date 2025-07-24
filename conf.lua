-- 16:9
-- width = 1280
-- height = 720
width = 1920
height = 1080
-- width = 2560
-- height = 1440

-- 16:10
-- width = 1280
-- height = 800
-- width = 1920
-- height = 1200
-- width = 2560
-- height = 1600

--  21:9
-- width = 1680
-- height = 720
-- width = 2560
-- height = 1080
-- width = 3440
-- height = 1440

--
function love.conf(t)
    t.identity = nil                   -- The name of the save directory (string)
    t.version = '11.4'                 -- The LÖVE version this game was made for (string)
    -- t.console = true                  -- Attach a console (boolean, Windows only)`
    t.console = false                  -- Attach a console (boolean, Windows only)`

    t.window.title = 'tiny boatball!' -- The window title (string)
    t.window.icon = nil                -- Filepath to an image to use as the window's icon (string)
    t.window.width = width                -- The window width (number)
    t.window.height = height               -- The window height (number)
    t.window.fullscreen = false         -- Enable fullscreen (boolean)
    t.window.resizable = false          -- Let the window be user-resizable (boolean)
    t.window.borderless = false
    t.window.fullscreentype = 'desktop' -- Standard fullscreen or desktop fullscreen mode (string)
    t.window.vsync = true              -- Enable vertical sync (boolean)
    t.window.msaa = 0                  -- The number of samples to use with multi-sampled antialiasing (number)
    t.window.display = 1               -- Index of the monitor to show the window in (number)
    t.window.highdpi = false           -- Enable high-dpi mode for the window on a Retina display (boolean)
    t.window.usedpiscale = false
    t.window.srgb = false              -- Enable sRGB gamma correction when drawing to the screen (boolean)
    t.window.x = nil                   -- The x-coordinate of the window's position in the specified display (number)
    t.window.y = nil                   -- The y-coordinate of the window's position in the specified display (number)
    t.window.depth = 16
    
    t.modules.audio = true             -- Enable the audio module (boolean)
    t.modules.event = true             -- Enable the event module (boolean)
    t.modules.graphics = true          -- Enable the graphics module (boolean)
    t.modules.image = true             -- Enable the image module (boolean)
    t.modules.joystick = false          -- Enable the joystick module (boolean)
    t.modules.keyboard = true          -- Enable the keyboard module (boolean)
    t.modules.math = true              -- Enable the math module (boolean)
    t.modules.mouse = true             -- Enable the mouse module (boolean)
    t.modules.physics = false           -- Enable the physics module (boolean)
    t.modules.sound = true             -- Enable the sound module (boolean)
    t.modules.system = true            -- Enable the system module (boolean)
    t.modules.timer = true             -- Enable the timer module (boolean), Disabling it will result 0 delta time in love.update
    t.modules.window = true            -- Enable the window module (boolean)
    t.modules.thread = true            -- Enable the thread module (boolean)    
end