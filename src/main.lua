var_dump = require 'lib/var_dump'  -- for debugging

local gameloop = require 'gameloop'

local conf = require 'conf'
local state = require 'state'

scene = require 'scene'

function love.draw()
  if love.report then print(love.report) end--profile info DEBUG
  scene.curr.draw()
  love.graphics.push() -- stores the default coordinate system
  love.graphics.scale(state.scale) -- zoom the camera
  -- use the new coordinate system to draw the viewed scene
  local bgx, bgy = unpack(state.background_offset)
  love.graphics.draw(scene.curr.canvas, bgx+0, bgy+0)
  love.graphics.pop() -- return to the default coordinates
end

function love.keypressed(key, isrepeat)
  if key == "escape" then
    love.event.quit(0)
    --love.profiler.stop()
  elseif key == "f11" then
    love.window.setFullscreen(not love.window.getFullscreen(), "desktop")
    love.resize() -- without this the scale do not comes back
  end
end

function love.load()
  --love.profiler = require('profile')
  --love.profiler.start()

  love.graphics.setDefaultFilter("nearest")

  scene.curr = scene.game
  scene.curr.init()

  local w, h, flags = love.window.getMode()
  love.resize(w, h)  -- called to set initial scale and offset
end

function love.resize(w, h)
  local w_, h_ = love.graphics.getDimensions( )
  w = w or w_
  h = h_ or h
  local mcw, mch = conf.screen_width, conf.screen_height
  local scale = math.floor(math.min(w/mcw, h/mch))
  -- Now I update the offset of the maincanvas
  local ox = math.floor((w / scale - mcw) / 2)
  local oy = math.floor((h / scale - mch) / 2)
  state.scale = scale
  state.background_offset = {ox, oy}
end

love.frame = 0
function love.update(frames)
  love.frame = love.frame + 1
  scene.curr.update(frames)
  --if love.frame%100 == 0 then
  --  love.report = love.profiler.report(20)
  --  love.profiler.reset()
  --end
end
