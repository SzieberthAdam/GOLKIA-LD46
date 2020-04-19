local conf = require 'conf'

M = {}

M.init = function()
  M.world = {}
  M.card = {}
  M.set_random_world()
  M.set_random_card()
  M.relaxframes = conf.turnframes

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

  local logo_image = love.graphics.newImage("graphics/status.png")
  love.graphics.draw(logo_image, 2, 2)
  love.graphics.setCanvas()

  M.canvas = love.graphics.newCanvas(
    conf.screen_width, conf.screen_height
  )

  M.cardcanvast = {}
  for n = 1, conf.ncards, 1
  do
    M.cardcanvast[n] = love.graphics.newCanvas(
      conf.cardcols, conf.cardrows,
      {format = "r8"}
    )
  end

  M.world_canvas0 = love.graphics.newCanvas(
    conf.worldcols, conf.worldrows,
    {format = "r8"}
  )

  M.world_canvas = love.graphics.newCanvas(
    conf.worldcols, conf.worldrows,
    {format = "r8"}
  )

  love.graphics.setCanvas(M.world_canvas)
  for r, worldrow in ipairs(M.world)
  do
    for c, v in ipairs(worldrow)
    do
      love.graphics.setColor(v, v, v, 1)
      love.graphics.rectangle("fill", c-1, r-1, 1, 1)
    end
  end
  love.graphics.setCanvas()
 -- M.update_world_canvas()

  local golshader_pixelcode = [[

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
  M.golshader = love.graphics.newShader(golshader_pixelcode)

  local r8backshader_pixelcode = [[
    extern vec4 black;
    extern vec4 white;

    vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
    {
      vec4 newcolor;
      vec4 texcolor = Texel(tex, texture_coords);
      if (0<texcolor.r) {
        newcolor = white;
      } else {
        newcolor = black;
      }
      return newcolor;
    }
  ]]
  M.r8backshader = love.graphics.newShader(r8backshader_pixelcode)
  M.r8backshader:sendColor("black",
    {conf.black[1],conf.black[2],conf.black[3], 1.0}
  )
  M.r8backshader:sendColor("white",
    {conf.white[1],conf.white[2],conf.white[3], 1.0}
  )

end

M.draw = function()
  love.graphics.setCanvas(M.canvas)
  love.graphics.clear(0, 0, 0, 0)
  love.graphics.draw(M.background_canvas)
  love.graphics.setShader(M.r8backshader)
  love.graphics.draw(M.world_canvas, 70, 2, 0, conf.tilew, conf.tilew)
  love.graphics.setShader()
  love.graphics.draw(M.cardcanvast[1], 3, 92, 0, conf.tilew, conf.tilew)
  love.graphics.draw(M.cardcanvast[1], 3, 159, 0, conf.tilew, conf.tilew)
  love.graphics.draw(M.cardcanvast[1], 3, 226, 0, conf.tilew, conf.tilew)
  love.graphics.draw(M.cardcanvast[1], 3, 293, 0, conf.tilew, conf.tilew)
  love.graphics.setCanvas()
end

M.update = function(frames) -- TODO! number of frames times
  M.relaxframes = M.relaxframes - 1
  if M.relaxframes == 0
  then
    M.relaxframes = conf.turnframes
    M.update_world_canvas()
  end
end

M.update_card_canvas = function(n)
  if n == nil then
    for m = 1, conf.ncards, 1
    do M.update_card_canvas(m)
    end
    return
  end
  love.graphics.setCanvas(M.cardcanvast[n])
  love.graphics.clear(0, 0, 0, 0)
  for r, row in ipairs(M.card[n])
  do
    for c, v in ipairs(row)
    do
      love.graphics.setColor(v, v, v, 1)  -- important to reset
      love.graphics.rectangle("fill", c-1, r-1, 1, 1)
    end
  end
  love.graphics.setColor(1,1,1,1) -- important reset
  love.graphics.setCanvas()
end

M.update_world_canvas = function()
  -- clone canvas
  love.graphics.setCanvas(M.world_canvas0)
  love.graphics.setColor(1,1,1,1)
  love.graphics.draw(M.world_canvas, 0, 0)
  love.graphics.setCanvas()

  love.graphics.setCanvas(M.world_canvas)
  love.graphics.setColor(1,1,1,1)
  --love.graphics.clear(0, 0, 0, 0)
  love.graphics.setShader(M.golshader)
  love.graphics.draw(M.world_canvas0)
  love.graphics.setShader()
  love.graphics.setCanvas()
end

M.set_random_card = function(n)
  if n == nil then
    for m = 1, conf.ncards, 1
    do M.set_random_card(m)
    end
    return
  end
  M.card[n] = {}
  for r = 1, conf.cardrows, 1
  do
    M.card[n][r] = {}
    for c = 1, conf.worldcols, 1
    do
      M.card[n][r][c] = love.math.random(0, 1)
    end
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

return M
