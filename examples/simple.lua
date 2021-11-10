local LightWorld = require "lib"
local lightWorld, lightMouse
local image, image_normal, glow, circleTest, rectangleTest, imageTest, objectTest

local box_locations = {
  {200, 200},
  {600, 200},
  {600, 400},
  {200, 400},
}

local function load()
  image = love.graphics.newImage("examples/gfx/machine.png")
  normal = love.graphics.newImage("examples/gfx/machine_normal.png")
  glow = love.graphics.newImage("examples/gfx/machine_glow.png")
  -- create light world
  lightWorld = LightWorld({ambient = {0.21,0.21,0.21}})
  -- create light
  lightMouse = lightWorld:newLight(0, 0, 255, 127, 63, 300)
  lightMouse:setGlowStrength(0.3)
  -- create shadow bodys
  for i, v in ipairs(box_locations) do
    imageTest = lightWorld:newImage(image, v[1], v[2])
    imageTest:setNormalMap(normal)
    imageTest:setGlowMap(glow)
  end
end

local function update(dt, x, y, scale)
  love.window.setTitle("Light vs. Shadow Engine (FPS:" .. love.timer.getFPS() .. ")")
  x, y, scale = x or 0, y or 0, scale or 1
  lightMouse:setPosition((love.mouse.getX() - x)/scale, (love.mouse.getY() - y)/scale)
  lightWorld:update(dt)
  lightWorld:setTranslation(x, y, scale)
end

local function draw()
  lightWorld:draw(function()
    love.graphics.clear(1, 1, 1)
    love.graphics.setColor(1, 1, 1)
    for i, v in ipairs(box_locations) do
      love.graphics.draw(image, v[1] - image:getWidth() * 0.5, v[2] - image:getHeight() * 0.5)
    end
  end)
end

return {
  load = load,
  update = update,
  draw = draw,
}
