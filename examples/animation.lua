local LightWorld = require "lib"
local x, y, z, scale = 20, -55, 1, 3.5

local function load()
  -- load images
  image = love.graphics.newImage("examples/gfx/scott_pilgrim.png")
  image_normal = love.graphics.newImage("examples/gfx/scott_pilgrim_NRM.png")
  -- create light world
  lightWorld = LightWorld({ambient = {0.49, 0.49, 0.49}})
  -- create light
  lightMouse = lightWorld:newLight(0, 0, 1, 0.49, 0.24, 300)
  -- create shadow bodys
  animation = lightWorld:newAnimationGrid(image, 100, 100)
  animation:setNormalMap(image_normal)
  grid = animation:newGrid(108, 140)
  animation:addAnimation('run right', grid('1-8', 1), 0.1)
  animation:addAnimation('run left', grid('8-1', 2), 0.1)
end

local function update(dt)
  love.window.setTitle("Light vs. Shadow Engine (FPS:" .. love.timer.getFPS() .. ")")
  if love.keyboard.isDown("a") then
    animation:setAnimation('run left')
  elseif love.keyboard.isDown("d") then
    animation:setAnimation('run right')
  end
  lightWorld:update(dt)
  lightMouse:setPosition((love.mouse.getX() - x)/scale, (love.mouse.getY() - y)/scale, z)
end

local function draw()
  lightWorld:setTranslation(x, y, scale)
  love.graphics.push()
    love.graphics.translate(x, y)
    love.graphics.scale(scale)
    lightWorld:draw(function()
      love.graphics.setColor(255, 255, 255)
      love.graphics.rectangle("fill", -x/scale, -y/scale, love.graphics.getWidth()/scale, love.graphics.getHeight()/scale)
      animation:drawAnimation()
    end)
  love.graphics.pop()
end

return {
  load = load,
  update = update,
  draw = draw,
  mousepressed = mousepressed,
}
