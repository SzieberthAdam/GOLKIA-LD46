local M = {}

M.tilew = 1
M.worldcols = math.floor(568 / M.tilew)
M.worldrows = math.floor(356 / M.tilew)

M.cardrows = math.floor(64 / M.tilew)
M.cardcols = math.floor(64 / M.tilew)
M.ncards = 3
M.cardpos = {{3,119},{3,186},{3,253}}

M.screen_width = 640
M.screen_height = 360

M.refresh_rate = 60
M.max_update_frames = 10
M.loop_relax = 0.005

M.turnframes = 5

M.black = {0.13333333333333333, 0.13725490196078433, 0.13725490196078433}
M.white = {0.9411764705882353, 0.9647058823529412, 0.9411764705882353}
M.green = {0.26666666666666666, 0.6666666666666666, 0.6}


function love.conf(t)
  t.console = true
  -- The window title (string)
  t.window.title = "GOLKIA LD46"
  -- Filepath to an image to use as the window's icon (string)
  t.window.icon = nil
  -- The window width (number)
  t.window.width = M.screen_width
  -- Enable fullscreen (boolean)
  t.window.fullscreen = false
  -- The window height (number)       -- Remove all border visuals from the window (boolean)
  t.window.height = M.screen_height
  -- Let the window be user-resizable (boolean)
  t.window.resizable = true
  -- Minimum window width if the window is resizable (number)
  t.window.minwidth = M.screen_width
  -- Minimum window height if the window is resizable (number)
  t.window.minheight = M.screen_height
end


return M
