-- Example: STI Example
local LightWorld = require "lib"
local sti = require 'examples.vendor.sti'

function love.load()
  x = 0
  y = 0
  z = 1
  scale = 1

	-- create light world
	lightWorld = LightWorld({
    ambient = {55,55,55},
  })

	map = sti.new("examples/gfx/map")
	image_normal = love.graphics.newImage("examples/gfx/border_NRM.png")

	-- create light
	lightMouse = lightWorld:newLight(0, 0, 255, 127, 63, 300)
	lightMouse:setGlowStrength(0.3)

  -- walls
	lightWorld:newRectangle(400, 32, 800, 64):setNormalMap(image_normal, 800, 64)
	lightWorld:newRectangle(32, 272, 64, 416):setNormalMap(image_normal, 64, 416) 
	lightWorld:newRectangle(400, 464, 800, 32):setNormalMap(image_normal, 800, 32) 
	lightWorld:newRectangle(784, 272, 32, 416):setNormalMap(image_normal, 32, 416) 

  --blocks
	lightWorld:newRectangle(224, 256, 128, 124):setNormalMap(image_normal, 128, 124) 
	lightWorld:newRectangle(592, 224, 224, 64):setNormalMap(image_normal, 224, 64) 
end

function love.update(dt)
	love.window.setTitle("Light vs. Shadow Engine (FPS:" .. love.timer.getFPS() .. ")")

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

  map:update(dt)
	lightMouse:setPosition((love.mouse.getX() - x)/scale, (love.mouse.getY() - y)/scale, z)
end

function love.mousepressed(x, y, c)
	if c == "wu" then
    z = z + 1
	elseif c == "wd" then
    z = z - 1
	end
end

function love.draw()
  lightWorld:setTranslation(x, y, scale)
  love.graphics.push()
    love.graphics.translate(x, y)
    love.graphics.scale(scale)
    lightWorld:draw(function()
      love.graphics.setColor(255, 255, 255)
      love.graphics.rectangle("fill", -x/scale, -y/scale, love.graphics.getWidth()/scale, love.graphics.getHeight()/scale)
      map:draw()
    end)
  love.graphics.pop()

end
