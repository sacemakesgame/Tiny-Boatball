-- pigic (PIrated G3d mashed wIth Cpml)
--[[
      ___                       ___                       ___
     /\  \          ___        /\  \          ___        /\  \
    /::\  \        /\  \      /::\  \        /\  \      /::\  \
   /:/\:\  \       \:\  \    /:/\:\  \       \:\  \    /:/\:\  \
  /::\~\:\  \      /::\__\  /:/  \:\  \      /::\__\  /:/  \:\  \
 /:/\:\ \:\__\  __/:/\/__/ /:/__/_\:\__\  __/:/\/__/ /:/__/ \:\__\
 \/__\:\/:/  / /\/:/  /    \:\  /\ \/__/ /\/:/  /    \:\  \  \/__/
      \::/  /  \::/__/      \:\ \:\__\   \::/__/      \:\  \
       \/__/    \:\__\       \:\/:/  /    \:\__\       \:\  \
                 \/__/        \::/  /      \/__/        \:\__\
                               \/__/                     \/__/
]]


--[[
-------------------------------------------------------------------------------
RIGHT HAND RULE
      +x: right
	+y: top
	+z: from the screen
-------------------------------------------------------------------------------
]]

local path              = ... .. '/'

pigic                   = {}
pigic.unlit             = path .. 'shaders/unlit.glsl'
pigic.batch             = path .. 'shaders/batch.glsl'
pigic.fxaa              = path .. 'shaders/fxaa.glsl'
pigic.water             = path .. 'shaders/water.glsl'
pigic.glsl_depth        = path .. 'shaders/depth.glsl'
pigic.outline_filter    = path .. 'shaders/outline-filter.glsl'
pigic.outline_filter_2d = path .. 'shaders/outline-filter-2d.glsl'
pigic.outline           = path .. 'shaders/outline.glsl'
pigic.brush             = path .. 'shaders/brush.frag'


pigic.objloader = require(path .. 'objloader')
pigic.model     = require(path .. 'model')
pigic.character = require(path .. 'character')
pigic.pass      = require(path .. 'pass')
pigic.collision = path .. 'collision'
-- pigic.world       = require(path .. 'world')
-- pigic.world       = require(path .. 'world-o1')
pigic.world     = require(path .. 'world-o2')

function pigic:update(dt)
	self.pass.transform:identity()
	self.pass.matrix_stack = {}
end

-- get rid of g3d from the global namespace and return it instead
local pigic = pigic
_G.pigic = nil
return pigic
