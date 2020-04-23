local M = {}

M.round = function(x) -- banker's rounding
  local r = math.floor(x + 0.5)
  if r == x + 0.5 and 0 < r % 2 then r = math.ceil(x - 0.5) end
  return r
end

M.shallowcopy = function(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = orig_value
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

return M
