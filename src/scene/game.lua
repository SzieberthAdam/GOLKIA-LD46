local conf = require 'math'

local conf = require 'conf'

M = {}

M.init = function()
  M.world = {}
  M.turnframes = 4
  M.setrandom()
  M.relaxframes = M.turnframes

  M.canvas = love.graphics.newCanvas(
    conf.screen_width, conf.screen_height
  )
  M.golcanvas = love.graphics.newCanvas(
    conf.worldcols, conf.worldrows
    --conf.screen_width, conf.screen_height
  )
  M.golcanvas1 = love.graphics.newCanvas(
    conf.worldcols, conf.worldrows
  )
  M.update_canvas()

  local pixelcode = [[

    vec2 offset_coords(vec2 texture_coords, vec2 offset) {
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
      // map is circular vertically too yet; TODO //
      if (love_ScreenSize.y < y) {
        y -= love_ScreenSize.y;
      }
      else if (y < 0) {
        y += love_ScreenSize.y;
      }
      x /= love_ScreenSize.x;
      y /= love_ScreenSize.y;
      return vec2(x, y);
    }

    vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
    {
      vec4 newcolor;
      vec4 texcolor = Texel(tex, texture_coords);
      int sum =
          int(Texel(tex, offset_coords(texture_coords, vec2(-1.0, -1.0))).r)
        + int(Texel(tex, offset_coords(texture_coords, vec2(-1.0,  0.0))).r)
        + int(Texel(tex, offset_coords(texture_coords, vec2(-1.0,  1.0))).r)
        + int(Texel(tex, offset_coords(texture_coords, vec2( 0.0, -1.0))).r)
        + int(Texel(tex, offset_coords(texture_coords, vec2( 0.0,  1.0))).r)
        + int(Texel(tex, offset_coords(texture_coords, vec2( 1.0, -1.0))).r)
        + int(Texel(tex, offset_coords(texture_coords, vec2( 1.0,  0.0))).r)
        + int(Texel(tex, offset_coords(texture_coords, vec2( 1.0,  1.0))).r)
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
  love.graphics.draw(M.golcanvas1, 0, 0, 0, conf.tilew, conf.tilew)
  love.graphics.setCanvas()
end

M.update = function()
  M.relaxframes = M.relaxframes - 1
  if M.relaxframes == 0
  then
    M.relaxframes = M.turnframes
    M.update_canvas(M.withshader)
    M.withshader = not M.withshader
  end
end

M.update_canvas = function(withshader)
  love.graphics.setCanvas(M.golcanvas)
  love.graphics.clear(0, 0, 0, 0)
  for r, worldrow in ipairs(M.world)
  do
    for c, v in ipairs(worldrow)
    do
      love.graphics.setColor(v, v, v, 1)  -- important to reset
      love.graphics.rectangle("fill", c-1, r-1, 1, 1)
    end
  end
  love.graphics.setColor(1,1,1,1) -- important reset
  --love.graphics.setCanvas()
  love.graphics.setCanvas(M.golcanvas1)
  if M.withshader then love.graphics.setShader(M.golshader) end
  love.graphics.draw(M.golcanvas)
  if M.withshader then love.graphics.setShader() end
  love.graphics.setCanvas()
  if M.withshader
  then -- update world with this trick
    data = M.golcanvas1:newImageData()
    data:mapPixel(M.worldlocationfrompixel)
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

M.turn = function()
end

M.worldlocationfrompixel = function(x, y, r, g, b, a)
  M.world[y+1][x+1] = math.floor(r)
  return r, g, b, a --do nothing
end

return M
