local vector = {}
vector.__index = vector

local function new(x, y)
  if type(x) == "table" then
    return setmetatable({
      x = x[1],
      y = y[1]
    }, vector)
  else
    return setmetatable({
      x = x or 0,
      y = y or 0
    }, vector)
  end
end

function vector.__add(a, b)
  return new(a.x + b.x, a.y + b.y)
end

function vector.__sub(a, b)
  return new(a.x - b.x, a.y - b.y)
end

function vector.__mul(a, b)
  if type(b) == "number" then
    return new(a.x * b, a.y * b)
  else
    return a.x * b.x + a.y * b.y
  end
end

function vector.__div(a, b)
  return new(a.x / b, a.y / b)
end

function vector.__eq(a, b)
  return a.x == b.x and a.y == b.y
end

function vector:dist(b)
  return math.sqrt(math.pow(b.x - self.x, 2) + math.pow(b.y-self.y, 2))
end

return setmetatable({new = new}, {__call = function(_, ...) return new(...) end})
