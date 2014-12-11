-- Example: Animation Example
local LightWorld = require "lib"
local anim8 = require 'lib.anim8'

function love.load()
  x, y, z, scale = 0, 0, 1, 1
	-- load images
	image = love.graphics.newImage("examples/gfx/scott_pilgrim.png")
	image_normal = love.graphics.newImage("examples/gfx/scott_pilgrim_NRM.png")

	-- create light world
	lightWorld = LightWorld({
    ambient = {55,55,55},
    refractionStrength = 32.0,
    reflectionVisibility = 0.75,
  })

	-- create light
	lightMouse = lightWorld:newLight(0, 0, 255, 127, 63, 300)
	lightMouse:setGlowStrength(0.3)
  lightMouse.normalInvert = true

	-- create shadow bodys
	animation = lightWorld:newAnimationGrid(image, 100, 100)
  animation:setNormalMap(image_normal)
  grid = animation:newGrid(108, 140)
  animation:addAnimation('run right', grid('1-8', 1), 0.1)
  animation:addAnimation('run left', grid('8-1', 2), 0.1)

  local g = anim8.newGrid(108, 140, image:getWidth(), image:getHeight())
  animation2 = anim8.newAnimation(g('1-8', 1), 0.1)
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

	if love.keyboard.isDown("a") then
    animation:setAnimation('run left')
	elseif love.keyboard.isDown("d") then
    animation:setAnimation('run right')
	end

  animation2:update(dt)
  lightWorld:update(dt) --only needed for animation
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
      animation:drawAnimation()
 
      animation2:draw(image, 200, 30)
    end)
  love.graphics.pop()
end

