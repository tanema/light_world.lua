local Camera = require "examples/vendor/hump/camera"
local simple = require "examples.simple"
local keyboard = require "examples.lib.keyboard"

local function load()
  cam = Camera(love.graphics.getWidth()/2, love.graphics.getHeight()/2)
  simple.load()
end

local function update(dt)
  local x, y, scale = keyboard.update(dt)
  simple.update(dt, x, y, scale)
  cam:lookAt(x, y)
  cam:zoom(scale)
end

local function draw()
  cam:attach()
  simple.draw()
  cam:detach()
end

return {
  load = load,
  update = update,
  draw = draw,
}
