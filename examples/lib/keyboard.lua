local x, y, scale = 0, 0, 1

local function update(dt)
  if love.keyboard.isDown("down") then
    y = y - dt * 200
  elseif love.keyboard.isDown("up") then
    y = y + dt * 200
  end

  if love.keyboard.isDown("right") then
    x = x - dt * 200
  elseif love.keyboard.isDown("left") then
    x = x + dt * 200
  end

  if love.keyboard.isDown("-") then
    scale = scale - 0.01
  elseif love.keyboard.isDown("=") then
    scale = scale + 0.01
  end

  return x, y, scale
end

local function status()
  return x, y, scale
end

return {
  update = update,
  status = status,
}
