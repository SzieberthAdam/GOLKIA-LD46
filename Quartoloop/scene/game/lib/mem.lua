local M = {}

local random = math.random


function M.new()

  local width = (display.actualContentWidth / 8) - 6
  local height = width


  local mem = {}

  for r = 1, 4, 1
  do
    mem[r] = {}
    for c = 1, 4, 1
    do
      mem[r][c] = random(4)-1
    end
  end

  local board = display.newGroup()
  board.anchorChildren = true
  board.status = "init"

  function board:newSquare(r,c)
    if board.space == nil then
      board.space = {}
    end
    local spaces = board.space
    -- function that draws an empty square
    local nextSpace = #spaces+1
    spaces[nextSpace] = display.newRoundedRect(self, c*width + c, r*height + r, width-2, height-2, width * 0.10)
    spaces[nextSpace].alpha = 0.25
    --spaces[nextSpace]:translate(-width * 0.5, -height * 0.5)
  end

  for r, row in ipairs(mem) do
    for c, value in ipairs(row) do
      board:newSquare(r,c)
    end
  end

  function board:newPiece(r,c)
    if not board.removeSelf then return false end
    if board.piece == nil then
      board.piece = {}
    end
    local pieces = board.piece
    -- function that builds a new game piece
    local nextPiece = #pieces+1

    --pieces[nextPiece] = display.newCircle(self, c*width + c, r*height + r, width * 0.45)
    pieces[nextPiece] = display.newText({parent=self,text=tostring(mem[r][c]),x=c*width + c,y=r*height + r,width=width-2,height=height-2,font=native.systemFontBold,fontSize=60,align="center"})

    -- make a local copy
    local currentPiece = pieces[nextPiece]
    currentPiece.id = nextPiece
    currentPiece.r,currentPiece.c = r,c
  end

  function board:replunish()
    if not board.removeSelf then return false end
    for r, row in ipairs(mem) do
      for c, value in ipairs(row) do
        --if not board:getPiece(r,c) then board:newPiece(r,c) end
        board:newPiece(r,c)
      end
    end
  end
  board:replunish()

  M.mem=mem

  return board
end

function M.shift()
  local cl = table.clone(M.mem[1])
  for i,v in pairs(cl)
  do
    M.mem[1][bit32.band(i+1,4)]=v
  end
end

timer.performWithDelay( 1000, manageTime, 0 )

return M
