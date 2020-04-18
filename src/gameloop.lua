local conf = require 'conf'

-- The default function for 11.0, used if you don't supply your own.
-- https://love2d.org/wiki/love.run
local default_love_run = function()
  if love.load then love.load(love.arg.parseGameArguments(arg), arg) end

  -- We don't want the first frame's dt to include time taken by love.load.
  if love.timer then love.timer.step() end

  local dt = 0

  -- Main loop time.
  return function()
    -- Process events.
    if love.event then
      love.event.pump()
      for name, a,b,c,d,e,f in love.event.poll() do
        if name == "quit" then
          if not love.quit or not love.quit() then
            return a or 0
          end
        end
        love.handlers[name](a,b,c,d,e,f)
      end
    end

    -- Update dt, as we'll be passing it to update
    if love.timer then dt = love.timer.step() end

    -- Call update and draw
    if love.update then love.update(dt) end -- will pass 0 if love.timer is disabled

    if love.graphics and love.graphics.isActive() then
      love.graphics.origin()
      love.graphics.clear(love.graphics.getBackgroundColor())

      if love.draw then love.draw() end

      love.graphics.present()
    end

    if love.timer then love.timer.sleep(0.001) end
  end
end


-- I want my game in frames
function love.run()
  if love.load then love.load(love.arg.parseGameArguments(arg), arg) end

  -- We don't want the first frame's dt to include time taken by love.load.
  if love.timer then love.timer.step() end

  local dt = 0

  local acc_dt = 0
  local max_dt = conf.max_update_frames / conf.refresh_rate
  local frames = 0

  -- Main loop time.
  return function()
    -- Process events.
    if love.event then
      love.event.pump()
      for name, a,b,c,d,e,f in love.event.poll() do
        if name == "quit" then
          if not love.quit or not love.quit() then
            return a or 0
          end
        end
        love.handlers[name](a,b,c,d,e,f)
      end
    end

    -- Update dt, as we'll be passing it to update
    if love.timer then dt = love.timer.step() end

    --print(acc_dt, max_dt)
    acc_dt = math.min(acc_dt + dt, max_dt)
    if 1 / conf.refresh_rate <= acc_dt then
      frames = math.floor(acc_dt * conf.refresh_rate)
      --print('frames', frames)
      acc_dt = acc_dt - frames / conf.refresh_rate
      -- Call update and draw
      if love.update then love.update(frames) end -- will pass 0 if love.timer is disabled

      if love.graphics and love.graphics.isActive() then
        love.graphics.origin()
        love.graphics.clear(love.graphics.getBackgroundColor())

        if love.draw then love.draw() end

        love.graphics.present()
      end
    end

    if love.timer then love.timer.sleep(conf.loop_relax) end
  end
end
