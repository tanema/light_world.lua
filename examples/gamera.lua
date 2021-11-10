local gamera = require "examples/vendor/gamera"
local simple = require "examples.simple"
local keyboard = require "examples.lib.keyboard"

local function load()
  cam = gamera.new(0, 0, love.graphics.getWidth(), love.graphics.getHeight())
  simple.load()
end

local function update(dt)
  local x, y, scale = keyboard.update(dt)
  simple.update(dt, x, y, scale)
  cam:setScale(scale)
  cam:setPosition(x, y)
end

local function draw()
  cam:draw(function(l,t,w,h)
    simple.draw()
  end)
end

return {
  load = load,
  update = update,
  draw = draw,
  keypressed = keypressed,
}
