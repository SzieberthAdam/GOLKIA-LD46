var_dump = require 'lib/var_dump'  -- for debugging

vector = require 'lib/vector'
-- make vectors roundable
local _v = vector(4.5, 5.5)
local _vector = getmetatable(_v)
local function isvector(t)
  return getmetatable(t) == _vector
end
function _vector:floor()
  self.x = math.floor(self.x)
  self.y = math.floor(self.y)
  return self
end
function _vector:ceil()
  self.x = math.ceil(self.x)
  self.y = math.ceil(self.y)
  return self
end
function _vector:round()
  self.x = helper.round(self.x)
  self.y = helper.round(self.y)
  return self
end
function _vector.__lt(a,b)
  assert(isvector(a) and isvector(b),
    "eq: wrong argument types (expected <vector> and <vector>)"
  )
  return a.x<b.x and a.y<b.y
end
function _vector.__le(a,b)
  assert(isvector(a) and isvector(b),
    "eq: wrong argument types (expected <vector> and <vector>)"
  )
  return a.x<=b.x and a.y<=b.y
end


local helper = require 'helper'

local conf = require 'conf'
local state = require 'state'

local M = {}

M.init = function()
  M.running = false
  M.world = {}

  local vp = {}
  vp.gamepos = vector(conf.vpgameposx, conf.vpgameposy)
  vp.pos = vector(0,0)
  vp.zoomlevel = 1

  function vp:getvppos(pos, frame)
    if not frame or frame == "game"
    then
      local lrgamepos = self.gamepos + vector(conf.worldwidth, conf.worldheight)
      if self.gamepos <= pos and pos < lrgamepos
      then
        return pos - self.gamepos + vector(1,1)
      end
    elseif frame == "vp"
    then return pos
    elseif frame == "world"
    then return (
      pos * self.zoomlevel
      + self:getbaseanchorvec(pos, frame) * (self.zoomlevel - 1)
    )
    end
  end

  function vp:getgamepos(pos, frame)
    if not frame or frame == "vp"
    then
      return self.gamepos - vector(1,1) + pos
    elseif frame == "game"
    then return pos
    elseif frame == "world"
    then
      return self.gamepos + self.pos + self.zoomlevel * pos
    end
  end

  function vp:settlepos(pos)
    pos = pos or self.pos
    if pos.x < conf.worldwidth / 2
    then pos.x = math.floor(pos.x)
    else pos.x = math.ceil(pos.x)
    end
    if pos.y < conf.worldheight / 2
    then pos.y = math.floor(pos.y)
    else pos.y = math.ceil(pos.y)
    end
    return pos
  end

  function vp:getworldpos(pos, frame)
    if not frame or frame == "game"
    then
      pos = self:getvppos(pos, frame)
      if not pos then return end
      return ((pos - self.pos) / self.zoomlevel):ceil()
    elseif frame == "vp"
    then
      return ((pos - self.pos) / self.zoomlevel):ceil()
    elseif frame == "world"
    then return pos
    end
  end

  function vp:getbaseanchorvec(pos, frame)
    local wpos = self:getworldpos(pos, frame)
    r = vector(0,0)
    if wpos.x < conf.worldwidth / 2
    then r.x = -1
    end
    if wpos.y < conf.worldheight / 2
    then r.y = -1
    end
    return r
  end

  function vp:getanchorvec(pos, frame)
    if self.zoomlevel == 1 then return self:getbaseanchorvec(pos, frame) end
    local wpos = self:getworldpos(pos, frame)
    return pos - self.pos - wpos * self.zoomlevel
  end

  function vp:clamp() -- enforce to fill vp area with world
    local adjvec = vector(0, 0)
    if self.zoomlevel == 1 then
      adjvec = adjvec - self.pos
    else
      if 0 < self.pos.x then adjvec.x = -self.pos.x end
      if 0 < self.pos.y then adjvec.y = -self.pos.y end
      local rightdiff = (self.zoomlevel - 1) * conf.worldwidth + self.pos.x
      if rightdiff < 0 then adjvec.x = -rightdiff end
      local bottomdiff = (self.zoomlevel - 1) * conf.worldheight + self.pos.y
      if bottomdiff < 0 then adjvec.y = -bottomdiff end
    end
    --print("adjvec="..tostring(adjvec))
    self.pos = self.pos + adjvec
  end

  M.vp = vp

  M.relaxframes = conf.turnframes

  M.input=nil
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
    conf.worldwidth, conf.worldheight,
    {format = "r8"} -- for efficiency
  )

  M.world_canvas = love.graphics.newCanvas(
    conf.worldwidth, conf.worldheight,
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
  love.graphics.draw(
    M.world_canvas,
    M.vp.gamepos.x + M.vp.pos.x,
    M.vp.gamepos.y + M.vp.pos.y,
    0,
    M.vp.zoomlevel,
    M.vp.zoomlevel
  )
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

  -- apply the shader (GOL step) on prev_world_canvas
  -- and draw it to world_canvas
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
  for r = 1, conf.worldheight, 1
  do
    M.world[r] = {}
    for c = 1, conf.worldwidth, 1
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
  --M.set_random_world()
  love.graphics.setCanvas(M.world_canvas)
  love.graphics.clear(0, 0, 0, 1)
  love.graphics.setColor(1,1,1,1)
  local image = love.graphics.newImage("graphics/jhc.png")
  love.graphics.draw(image, 0, 0)
  love.graphics.setCanvas(M.prev_world_canvas)
  love.graphics.clear(0, 0, 0, 1)
  love.graphics.setCanvas()
  --M.update_world_canvas()
end


function setposval(v)
  assert(v==0 or v==1, "setposval: expected 0 or 1 as value")
  love.graphics.setCanvas(M.world_canvas)
  love.graphics.setColor(v,v,v,1)
  love.graphics.points(pos.x,pos.y)
  love.graphics.setColor(1,1,1,1)
  love.graphics.setCanvas()
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
  local gamepos = realxytogamepos(x, y)
  pos = M.vp:getworldpos(gamepos)
  if not pos then return end
  local button = M.inputworldbutton
  if M.input == "draw" then
    if button==1 or button==2 then setposval(2-button) end
  elseif M.input == "pan" and button == 3 then
    M.vp.pos = M.vp.pos + vector(dx, dy) / state.scale
    M.vp:clamp()
  end
end

function M.mousepressed(x, y, button, istouch, presses)
  local gamepos = realxytogamepos(x, y)
  pos = M.vp:getworldpos(gamepos)
  if not pos then return end
  M.input="draw"
  M.inputworldbutton=button
  if button==1 or button==2
  then setposval(2-button)
  elseif button==3
  then
    M.input="pan"
    M.inputworldbutton=button
  end
 end

 function M.mousereleased(x, y, button, istouch, presses)
  M.input=nil
  M.inputworldbutton=nil
 end

 function M.wheelmoved(x, y)
  local mx, my = love.mouse.getPosition()
  local gamepos = realxytogamepos(mx, my)
  --print("------------------------------")
  --print("gamepos="..tostring(gamepos))
  local pos = M.vp:getvppos(gamepos)
  if not pos then return end
  --print("pos="..tostring(M.vp:getvppos(gamepos)))
  local wpos = M.vp:getworldpos(gamepos)
  --print("wpos="..tostring(M.vp:getworldpos(gamepos)))
  local oldzoomlevel = M.vp.zoomlevel
  local newzoomlevel = math.max(1 ,math.min(conf.maxvpzoomlevel,
    M.vp.zoomlevel + x + y
  ))
  --print("oldzoomlevel="..oldzoomlevel.." newzoomlevel="..newzoomlevel)
  --if newzoomlevel==1
  --then
  --  M.vp.zoomlevel = newzoomlevel
  --  M.vp.pos = vector(0, 0)
  --  return
  --end
  local anchorvec = M.vp:getanchorvec(pos, "vp")
  if 1 < oldzoomlevel then anchorvec = anchorvec / (oldzoomlevel-1) end
  --print("anchorvec="..tostring(anchorvec))
  local anchorvec = anchorvec * (newzoomlevel - 1)
  if anchorvec.x < 0
  then anchorvec.x = math.floor(anchorvec.x)
  else anchorvec.x = math.ceil(anchorvec.x)
  end
  if anchorvec.y < 0
  then anchorvec.y = math.floor(anchorvec.y)
  else anchorvec.y = math.ceil(anchorvec.y)
  end
  --print("anchorvec="..tostring(anchorvec))
  local newpos = wpos * newzoomlevel + anchorvec:ceil()
  --print("newpos="..tostring(newpos))
  local newvppos = pos - newpos  --normally it is nonpositive
  --print("newvppos="..tostring(newvppos))
  M.vp.zoomlevel = newzoomlevel
  M.vp.pos = newvppos
  M.vp:clamp()
end




-----------------------------------  HELPER  -----------------------------------

function realxytogamepos(x, y)
  if not x or not y then return end
  x = math.floor(x / state.scale) - state.background_offset[1]
  y = math.floor(y / state.scale) - state.background_offset[2]
  if x < 0 or conf.screen_width < x then return end
  if y < 0 or conf.screen_height < y then return end
  return vector(x, y)
end

return M
