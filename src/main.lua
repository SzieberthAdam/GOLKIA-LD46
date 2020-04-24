var_dump = require 'lib/var_dump'  -- for debugging

local gameloop = require 'gameloop'

local conf = require 'conf'

scene = require 'scene'

function love.draw()
  --print("Current FPS: "..tostring(love.timer.getFPS( )))
  --if love.report then print(love.report) end--profile info DEBUG
  scene.curr.draw()
  love.graphics.push() -- stores the default coordinate system
  love.graphics.scale(conf.scale) -- zoom the camera
  -- use the new coordinate system to draw the viewed scene
  local bgx, bgy = unpack(conf.background_offset)
  love.graphics.draw(scene.curr.canvas, bgx+0, bgy+0)
  love.graphics.pop() -- return to the default coordinates
end

function love.load()
  --love.profiler = require('profile')
  --love.profiler.start()

  love.graphics.setDefaultFilter("nearest")

  scene.curr = scene.game
  scene.curr.init()

  local w, h, flags = love.window.getMode()
  love.resize(w, h)  -- called to set initial scale and offset

  love.mouse.setVisible(true)
  love.mouse.setRelativeMode(false)
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
  conf.scale = scale
  conf.background_offset = {ox, oy}
end

love.frame = 0
function love.update(frames)
  --print('Memory actually used (in kB): ' .. collectgarbage('count'))
  love.frame = love.frame + 1
  scene.curr.update(frames)
  --if love.frame%100 == 0 then
  --  love.report = love.profiler.report(20)
  --  love.profiler.reset()
  --end
end



-----------------------------------  EVENTS  -----------------------------------

function love.keypressed(key, isrepeat)
  if key == "escape" then
    love.event.quit(0)
    --love.profiler.stop()
  elseif key == "f11" then
    love.window.setFullscreen(not love.window.getFullscreen(), "desktop")
    love.resize() -- without this the scale do not comes back
  else
    local f = scene.curr.keypressed
    if f then f(key, isrepeat) end
  end
end

function love.mousemoved(x, y, dx, dy, istouch)
  local f = scene.curr.mousemoved
  if f then f(x, y, dx, dy, istouch) end
end

function love.mousepressed(x, y, button, istouch, presses)
  local f = scene.curr.mousepressed
  if f then f(x, y, button, istouch, presses) end
end

function love.mousereleased(x, y, button, istouch, presses)
  local f = scene.curr.mousereleased
  if f then f(x, y, button, istouch, presses) end
end

function love.wheelmoved(x, y)
  local f = scene.curr.wheelmoved
  if f then f(x, y) end
end
