local LightWorld = require "lib"
local lightWorld, lightMouse
local image, image_normal, glow, circleTest, rectangleTest, imageTest, objectTest
local scanLight, floatLight
local lightDirection = 0.0

local box_locations = {
  {200, 200},
  {600, 200},
  {600, 400},
  {200, 400},
}

local function load()
  image = love.graphics.newImage("examples/img/simple/machine.png")
  normal = love.graphics.newImage("examples/img/simple/machine_normal.png")
  glow = love.graphics.newImage("examples/img/simple/machine_glow.png")
  -- create light world
  lightWorld = LightWorld({ambient = {0.21,0.21,0.21}})
  -- create light
  lightMouse = lightWorld:newLight(0, 0, 1, 0.49, 1, 300)
  lightMouse:setGlowStrength(0.3)

  scanLight = lightWorld:newLight(400, 550, 1, 1, 0.24, 400)
  scanLight:setAngle(0.7)
  scanLight:setDirection(3.4)

  floatLight = lightWorld:newLight(100, 100, 0.49, 1, 1, 200)
  floatLight:setGlowStrength(0.3)

  -- create shadow bodys
  for i, v in ipairs(box_locations) do
    imageTest = lightWorld:newImage(image, v[1], v[2])
    imageTest:setNormalMap(normal)
    imageTest:setGlowMap(glow)
  end
end

local function update(dt, x, y, scale)
  floatLight:setPosition(math.sin(-1*lightDirection)*200+400, 100)
  scanLight:setDirection(math.sin(lightDirection)+4.8)
  lightDirection = lightDirection + dt

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
