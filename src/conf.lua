local M = {}

M.debug = false

M.worldwidth = 568
M.worldheight = 356

M.vpgameposx = 70
M.vpgameposy = 2

M.screen_width = 640
M.screen_height = 360
M.screen_scale = 3

M.window_width = M.screen_scale*M.screen_width
M.window_height = M.screen_scale*M.screen_height

M.refresh_rate = 60
M.max_update_frames = 10
M.loop_relax = 0.005

M.turnframes = 5

M.maxvpzoomlevel = 16

M.brush_size = 1
M.max_brush_size = 56

M.brushx = 33.5
M.brushy = 304.5


M.black = {0.13333333333333333, 0.13725490196078433, 0.13725490196078433}
M.white = {0.9411764705882353, 0.9647058823529412, 0.9411764705882353}
M.green = {0.26666666666666666, 0.6666666666666666, 0.6}


function love.conf(t)
  t.console = M.debug
  -- The window title (string)
  t.window.title = "GOLKIA LD46"
  -- Filepath to an image to use as the window's icon (string)
  t.window.icon = nil
  -- The window width (number)
  t.window.width = M.window_width
  -- Enable fullscreen (boolean)
  t.window.fullscreen = false
  -- The window height (number)
  t.window.height = M.window_height
  -- Let the window be user-resizable (boolean)
  t.window.resizable = true
  -- Minimum window width if the window is resizable (number)
  t.window.minwidth = M.screen_width
  -- Minimum window height if the window is resizable (number)
  t.window.minheight = M.screen_height
end


return M
