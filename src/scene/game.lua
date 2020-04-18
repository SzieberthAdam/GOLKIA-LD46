local conf = require 'conf'

M = {}

M.init = function()
  M.world = {}
  M.turnframes = 12
  M.relaxframes = M.turnframes
  M.setrandom()
end

M.draw = function()
  love.graphics.clear(0, 0, 0, 0)
  for r, worldrow in ipairs(M.world)
  do
    for c, v in ipairs(worldrow)
    do
      love.graphics.setColor(v, v, v, 1)  -- important reset
      love.graphics.rectangle(
        "fill",
        (c-1)*conf.tilew,
        (r-1)*conf.tilew,
        conf.tilew,
        conf.tilew
      )
    end
  end
end

M.update = function()
  M.relaxframes = M.relaxframes - 1
  if M.relaxframes == 0
  then
    M.setrandom()
    M.relaxframes = M.turnframes
  end
end

M.setrandom = function()
  for r = 1, conf.worldrows, 1
  do
    M.world[r]={}
    for c = 1, conf.worldcols, 1
    do
      M.world[r][c] = love.math.random(0, 1)
    end
  end
end

return M
