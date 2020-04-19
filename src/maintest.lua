function love.draw()
end

function love.resize(w, h)
end

function love.update(frames)
  print('Memory actually used (in kB): ' .. collectgarbage('count'))
end
