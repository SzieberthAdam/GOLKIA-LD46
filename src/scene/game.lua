local conf = require 'conf'
local state = require 'state'

M = {}

M.init = function()
  M.running = false
  M.world = {}
  M.worldzoom = 1
  M.worldzoomrc = nil
  M.worldzoomxy = nil

  M.relaxframes = conf.turnframes

  M.input=nil
  M.inputworldrc=nil
  M.inputworldbutton=nil

  M.background_canvas = love.graphics.newCanvas(
    conf.screen_width, conf.screen_height
  )
  love.graphics.setCanvas(M.background_canvas)
  love.graphics.clear(conf.black[1],conf.black[2],conf.black[3], 1)
  love.graphics.setColor(conf.green[1],conf.green[2],conf.green[3], 1)
  love.graphics.rectangle("fill", 1, 1, 638, 358)
  love.graphics.setColor(1,1,1,1) -- important reset!

  local logo_image = love.graphics.newImage("graphics/status.png")
  love.graphics.draw(logo_image, 0, 0)
  love.graphics.setCanvas()

  M.canvas = love.graphics.newCanvas(
    conf.screen_width, conf.screen_height
  )

  M.world_canvas0 = love.graphics.newCanvas(
    conf.worldcols, conf.worldrows,
    {format = "r8"} -- for efficiency
  )

  M.world_canvas = love.graphics.newCanvas(
    conf.worldcols, conf.worldrows,
    {format = "r8"}
  )

  M.restart()



  -- derived from:
  -- https://github.com/skeeto/webgl-game-of-life/blob/master/glsl/gol.frag
  local golshader_pixelcode = [[
    int state(Image tex, vec2 texture_coords, vec2 offset) {
      float x = texture_coords[0] * love_ScreenSize.x;
      float y = texture_coords[1] * love_ScreenSize.y;
      x += offset[0];
      y += offset[1];
      if (love_ScreenSize.x < x) {
        return 0;
      }
      else if (x < 0) {
        return 0;
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
  if M.worldzoom==1
  then
    love.graphics.draw(M.world_canvas, 70, 2, 0, conf.tilew, conf.tilew)
  else

    local quad = love.graphics.newQuad(
      M.worldzoomrc.c-M.worldzoomrc.c/conf.worldcols/M.worldzoom,
      M.worldzoomrc.r-M.worldzoomrc.r/conf.worldrows/M.worldzoom,
      math.floor(conf.worldcols/M.worldzoom),
      math.floor(conf.worldrows/M.worldzoom),
      conf.worldcols, conf.worldrows
    )
    love.graphics.draw(M.world_canvas, quad, 70, 2, 0, conf.tilew*M.worldzoom, conf.tilew*M.worldzoom)
  end
  love.graphics.setShader()
  love.graphics.setCanvas()
end

M.update = function(frames) -- TODO! number of frames times
  if not M.running then return end
  M.relaxframes = M.relaxframes - 1
  if M.relaxframes == 0
  then
    M.relaxframes = conf.turnframes
    M.update_world_canvas()
  end
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

M.set_random_world = function()
  for r = 1, conf.worldrows, 1
  do
    M.world[r] = {}
    for c = 1, conf.worldcols, 1
    do
      M.world[r][c] = love.math.random(0, 1)
    end
  end
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
end

M.restart = function()
  M.set_random_world()
  M.update_world_canvas()
end





-----------------------------------  EVENTS  -----------------------------------

function M.keypressed(key, isrepeat)
  if key == "n" then
    M.running=false
    M.restart()
  elseif key == "space" then
    M.running = not M.running
  end
end

function M.mousemoved(x, y, dx, dy, istouch)
  if M.input ~= "draw" then return end
  local worldrc = M.realxytoworldrc(x,y)
  if not worldrc then return end
  local button = M.inputworldbutton
  love.graphics.setCanvas(M.world_canvas)
  if button==1--left
  then love.graphics.setColor(1,1,1,1)
  elseif button==2--right
  then love.graphics.setColor(0,0,0,1)
  end
  love.graphics.points(worldrc.c,worldrc.r)
  love.graphics.setColor(1,1,1,1)
  love.graphics.setCanvas()
end

function M.mousepressed(x, y, button, istouch, presses)
  local worldrc = M.realxytoworldrc(x,y)
  if not worldrc then return end
  M.input="draw"
  M.inputworldrc=worldrc
  M.inputworldbutton=button
  love.graphics.setCanvas(M.world_canvas)
  if button==1--left
  then love.graphics.setColor(1,1,1,1)
  elseif button==2--right
  then love.graphics.setColor(0,0,0,1)
  end
  love.graphics.points(worldrc.c, worldrc.r)
  love.graphics.setColor(1,1,1,1)
  love.graphics.setCanvas()
 end

 function M.mousereleased(x, y, button, istouch, presses)
  M.input=nil
  M.inputworldrc=nil
  M.inputworldbutton=nil
 end

 function M.wheelmoved(x, y)
  --local worldrc = M.mouseworldrc()
  --if not worldrc then return end
  --print("w "..tostring(worldrc.c).." "..tostring(worldrc.r))
  --M.worldzoomrc=worldrc
  --M.worldzoom = math.max(1,math.min(conf.maxworldzoom, M.worldzoom+x+y))
  --print("z "..M.worldzoom)
  --M.worldzoomxy=M.mouseworldxy()
end




-----------------------------------  HELPER  -----------------------------------

function realxytogamexy(x, y)
  x = math.floor(x / state.scale) - state.background_offset[1]
  y = math.floor(y / state.scale) - state.background_offset[2]
  if x < 0 or conf.screen_width < x then return end
  if y < 0 or conf.screen_height < y then return end
  return {x=x,y=y}
end

function gamexytoworldxy(x, y)
  if (70<=x and x<=637 and 2<=y and y<=357)
  then
    return {x=x-69,y=y-1}
  end
end

function gamexytoworldrc(x, y)
  if (70<=x and x<=637 and 2<=y and y<=357)
  then
    local c = math.ceil((x-69)/conf.tilew/M.worldzoom)
    local r = math.ceil((y-1)/conf.tilew/M.worldzoom)
    if conf.worldrows<r or conf.worldcols<c then return end
    return {r=r,c=c}
  end
end

M.realxytoworldrc = function(x, y)
  xp, yp = love.mouse.getPosition( )
  local gamexy = realxytogamexy(x, y)
  if not gamexy then return end
  return gamexytoworldrc(gamexy.x, gamexy.y)
end

M.mouseworldrc = function()
  xp, yp = love.mouse.getPosition()
 -- print("r "..xp.." "..yp)
  local gamexy = realxytogamexy(xp, yp)
  if not gamexy then return end
  --print("g "..tostring(gamexy.x).." "..tostring(gamexy.y))
  return gamexytoworldrc(gamexy.x, gamexy.y)
end

M.mouseworldxy = function()
  xp, yp = love.mouse.getPosition()
  local gamexy = realxytogamexy(xp, yp)
  if not gamexy then return end
  local worldxy = gamexytoworldxy(gamexy.x, gamexy.y)
  if not worldxy then return end
  --print("wx "..tostring(worldxy.x).." "..tostring(worldxy.y))
  return worldxy
end




return M
