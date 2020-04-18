local gameloop = require 'gameloop'

local conf = require 'conf'
local state = require 'state'

scene = require 'scene'

function love.draw()
  scene.curr.draw()
end

function love.load()
  love.graphics.setDefaultFilter("nearest")

  scene.curr = scene.game
  scene.curr.init()

  local w, h, flags = love.window.getMode()
  love.resize(w, h)  -- called to set initial scale and offset
end

function love.resize(w, h)
  local mcw, mch = conf.screen_width, conf.screen_height
  local scale = math.floor(math.min(w/mcw, h/mch))
  -- Now I update the offset of the maincanvas
  local ox = math.floor((w / scale - mcw) / 2)
  local oy = math.floor((h / scale - mch) / 2)
  state.scale = scale
  state.background_offset = {ox, oy}
end

function love.update(frames)
  scene.curr.update(frames)
end
