local M = {}

M.tilew = 4
M.worldcols = 160
M.worldrows = 90

M.screen_width = M.tilew * M.worldcols
M.screen_height = M.tilew * M.worldrows

M.refresh_rate = 60
M.max_update_frames = 10
M.loop_relax = 0.005

function love.conf(t)
  t.console = true
  -- The window title (string)
  t.window.title = "LD46"
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
