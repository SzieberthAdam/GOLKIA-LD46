var_dump = require 'lib/var_dump'  -- for debugging

local helper = require 'helper'

local conf = require 'conf'
local state = require 'state'

local M = {}

M.init = function()
  M.running = false
  M.world = {}

  M.vp = {x=70, y=2, c=0, r=0, zoom=1} -- viewport
  M.prevvp = nil -- previous viewport

  M.relaxframes = conf.turnframes

  M.input=nil
  M.inputworldcr=nil
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

  M.prev_world_canvas = love.graphics.newCanvas(
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
      // if (love_ScreenSize.x < x) {
      //   x -= love_ScreenSize.x;
      // }
      // else if (x < 0) {
      //   x += love_ScreenSize.x;
      // }
      // // map is circular vertically too yet; TODO //
      // if (love_ScreenSize.y < y) {
      //   y -= love_ScreenSize.y;
      // }
      // else if (y < 0) {
      //   y += love_ScreenSize.y;
      // }
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
  love.graphics.setScissor(70, 2, 568, 356)
  love.graphics.setShader(M.r8backshader)
  love.graphics.draw(M.world_canvas, M.vp.x, M.vp.y, 0,
    conf.tilew*M.vp.zoom, conf.tilew*M.vp.zoom)
  love.graphics.setShader()
  love.graphics.setScissor( x, y, width, height )
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
  -- copy world_canvas -> prev_world_canvas
  love.graphics.setCanvas(M.prev_world_canvas)
  love.graphics.setColor(1,1,1,1)
  love.graphics.draw(M.world_canvas, 0, 0)
  love.graphics.setCanvas()

  -- apply the shader (GOL step) on prev_world_canvas and draw it to world_canvas
  love.graphics.setCanvas(M.world_canvas)
  love.graphics.setColor(1,1,1,1)
  love.graphics.setShader(M.golshader)
  love.graphics.draw(M.prev_world_canvas)
  love.graphics.setShader()
  love.graphics.setCanvas()

  -- prev_world_canvas has the previous GOL state
  -- world_canvas has the current GOL state
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
  local t = M.mousepos(x, y)
  if not t.c then return end
  local button = M.inputworldbutton
  love.graphics.setCanvas(M.world_canvas)
  if button==1--left
  then love.graphics.setColor(1,1,1,1)
  elseif button==2--right
  then love.graphics.setColor(0,0,0,1)
  else
    return
  end
  love.graphics.points(t.c,t.r)
  love.graphics.setColor(1,1,1,1)
  love.graphics.setCanvas()
end

function M.mousepressed(x, y, button, istouch, presses)
  local t = M.mousepos(x, y)
  if not t.c then return end
  M.input="draw"
  M.inputworldcr={t.c, t.r}
  M.inputworldbutton=button
  love.graphics.setCanvas(M.world_canvas)
  if button==1--left
  then love.graphics.setColor(1,1,1,1)
  elseif button==2--right
  then love.graphics.setColor(0,0,0,1)
  else
    return
  end
  love.graphics.points(t.c, t.r)
  love.graphics.setColor(1,1,1,1)
  love.graphics.setCanvas()
 end

 function M.mousereleased(x, y, button, istouch, presses)
  M.input=nil
  M.inputworldcr=nil
  M.inputworldbutton=nil
 end

 function M.wheelmoved(x, y)
  local t = M.mousepos()
  print("========= BEGIN wheelmoved =========")
  print(
    "screenxy=["..tostring(t.x)..","..tostring(t.y).."]"
    .." gamexy=["..tostring(t.xg)..","..tostring(t.yg).."]"
  )
  print(
    "vppos=["..tostring(t.vpx)..","..tostring(t.vpy).."]"
    .." worldpos={"..tostring(t.c)..","..tostring(t.r).."}"
  )
  if t.c then
    M.prevvp = helper.shallowcopy(M.vp) -- copy vp to prevvp
    M.vp.zoom = math.max(1,math.min(conf.maxvpzoom, M.prevvp.zoom+x+y))
    M.vp.x=1+t.xg-t.c*M.vp.zoom
    M.vp.y=1+t.yg-t.r*M.vp.zoom

    print(
      "zoom="..M.vp.zoom
      .." vp=["..tostring(M.vp.x)..","..tostring(M.vp.y).."]"
    )
  end
  print("========= END wheelmoved =========")
end




-----------------------------------  HELPER  -----------------------------------

function realxytogamexy(x, y)
  if not x or not y then return end
  x = math.floor(x / state.scale) - state.background_offset[1]
  y = math.floor(y / state.scale) - state.background_offset[2]
  if x < 0 or conf.screen_width < x then return end
  if y < 0 or conf.screen_height < y then return end
  return unpack({x, y})
end

function gamexytovpxy(x, y)
  if not x or not y then return end
  if (70<=x and x<=637 and 2<=y and y<=357)
  then return unpack({x-69,y-1})
  end
end

function vpxytoworldcr(x, y)
  if not x or not y then return end
  local c = M.vp.c + x / conf.tilew
  local r = M.vp.r + y / conf.tilew
  if conf.worldrows < r or conf.worldcols < c then return end
  return unpack({c, r})
end

M.realxytoworldcr = function(x, y)
  if not x or not y then return end
  return vpxytoworldcr(gamexytovpxy(realxytogamexy(x, y)))
end

M.mousepos = function(x, y)
  local r={}
  if not x or not y
  then
    local mposx, mposy = love.mouse.getPosition()
    x = x or mposx
    y = y or mposy
  end
  r.xg, r.yg = realxytogamexy(x, y)
  if r.xg
  then
    r.vpx, r.vpy = gamexytovpxy(r.xg, r.yg)
    r.c, r.r = vpxytoworldcr(r.vpx, r.vpy)
  end
  return r
end


return M
