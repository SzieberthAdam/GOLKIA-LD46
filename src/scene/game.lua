local conf = require 'math'

local conf = require 'conf'

M = {}

M.init = function()
  M.world = {}
  M.card = {}
  M.turnframes = 4
  M.set_random_world()
  M.relaxframes = M.turnframes

  M.background_canvas = love.graphics.newCanvas(
    conf.screen_width, conf.screen_height
  )
  love.graphics.setCanvas(M.background_canvas)
  love.graphics.clear(0, 0, 0, 1)
  love.graphics.setColor(
    0.5333333333333333, 0.13333333333333333, 0.3333333333333333, 1
  )

  love.graphics.rectangle("fill", 1, 1, 638, 358)
  love.graphics.setColor(0, 0, 0, 1)
  love.graphics.rectangle("fill", 2, 2, 66, 88)
  love.graphics.rectangle("fill", 70, 2, 568, 356)
  love.graphics.rectangle("fill", 2, 91, 66, 66)
  love.graphics.rectangle("fill", 2, 158, 66, 66)
  love.graphics.rectangle("fill", 2, 225, 66, 66)
  love.graphics.rectangle("fill", 2, 292, 66, 66)
  love.graphics.setColor(0.5333333333333333, 0.8, 0.9333333333333333, 1)
  love.graphics.rectangle("fill", 3, 3, 64, 86)
  love.graphics.setColor(1,1,1,1) -- important reset!
  love.graphics.rectangle("fill", 3,  92, 64, 64)
  love.graphics.rectangle("fill", 3, 159, 64, 64)
  love.graphics.rectangle("fill", 3, 226, 64, 64)
  love.graphics.rectangle("fill", 3, 293, 64, 64)

  local logo_image = love.graphics.newImage("graphics/status.png")
  love.graphics.draw(logo_image, 2, 2)
  love.graphics.setCanvas()

  M.canvas = love.graphics.newCanvas(
    conf.screen_width, conf.screen_height
  )
  M.world_canvas0 = love.graphics.newCanvas(
    conf.worldcols, conf.worldrows
  )
  M.world_canvas = love.graphics.newCanvas(
    conf.worldcols, conf.worldrows
  )
  M.update_canvas()

  local pixelcode = [[

    int state(Image tex, vec2 texture_coords, vec2 offset) {
      float x = texture_coords[0] * love_ScreenSize.x;
      float y = texture_coords[1] * love_ScreenSize.y;
      x += offset[0];
      y += offset[1];
      if (love_ScreenSize.x < x) {
        x -= love_ScreenSize.x;
      }
      else if (x < 0) {
        x += love_ScreenSize.x;
      }
      if (love_ScreenSize.y < y) {
        return 0;
      }
      else if (y < 0) {
        return 0;
      }
      x /= love_ScreenSize.x;
      y /= love_ScreenSize.y;
      vec2 coord = vec2(x, y);
      vec4 color = Texel(tex, coord);
      return int(color.r);
    }

    vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
    {
      vec4 newcolor;
      vec4 texcolor = Texel(tex, texture_coords);
      int sum =
          state(tex, texture_coords, vec2(-1.0, -1.0))
        + state(tex, texture_coords, vec2(-1.0,  0.0))
        + state(tex, texture_coords, vec2(-1.0,  1.0))
        + state(tex, texture_coords, vec2( 0.0, -1.0))
        + state(tex, texture_coords, vec2( 0.0,  1.0))
        + state(tex, texture_coords, vec2( 1.0, -1.0))
        + state(tex, texture_coords, vec2( 1.0,  0.0))
        + state(tex, texture_coords, vec2( 1.0,  1.0))
      ;
      if (sum == 3) {
        newcolor = vec4(1.0, 1.0, 1.0, 1.0);
      } else if (sum == 2) {
        newcolor = texcolor;
      } else {
        newcolor = vec4(0.0, 0.0, 0.0, 1.0);
      }
      return newcolor;
    }
  ]]
  M.golshader = love.graphics.newShader(pixelcode)
  M.withshader = false
end

M.draw = function()
  love.graphics.setCanvas(M.canvas)
  love.graphics.clear(0, 0, 0, 0)
  love.graphics.draw(M.background_canvas)
  love.graphics.draw(M.world_canvas, 70, 2, 0, conf.tilew, conf.tilew)
  love.graphics.setCanvas()
end

M.update = function()
  M.relaxframes = M.relaxframes - 1
  if M.relaxframes == 0
  then
    M.relaxframes = M.turnframes
    M.update_canvas(M.withshader)
    M.withshader = not M.withshader
    collectgarbage() -- important to avoid memory leak
  end
end

M.update_canvas = function(withshader)
  love.graphics.setCanvas(M.world_canvas0)
  love.graphics.clear(0, 0, 0, 0)
  for r, worldrow in ipairs(M.world)
  do
    for c, v in ipairs(worldrow)
    do
      love.graphics.setColor(v, v, v, 1)
      love.graphics.rectangle("fill", c-1, r-1, 1, 1)
    end
  end
  love.graphics.setColor(1,1,1,1) -- important reset!
  love.graphics.setCanvas(M.world_canvas)
  if M.withshader then love.graphics.setShader(M.golshader) end
  love.graphics.draw(M.world_canvas0)
  if M.withshader then love.graphics.setShader() end
  love.graphics.setCanvas()
  if M.withshader
  then -- update world with this trick
    data = M.world_canvas:newImageData()
    data:mapPixel(M.worldlocationfrompixel)
    data = nil
  end
end

M.set_random_world = function()
  for r = 1, conf.worldrows, 1
  do
    M.world[r] = {}
    for c = 1, conf.worldcols, 1
    do
      M.world[r][c] = love.math.random(0, 1)
    end
  end
end

M.turn = function()
end

M.worldlocationfrompixel = function(x, y, r, g, b, a)
  M.world[y+1][x+1] = math.floor(r)
  return r, g, b, a --do nothing
end

return M
