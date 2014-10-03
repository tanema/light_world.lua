require 'lib/postshader'
-- Example: Short Example
local gamera     = require "vendor/gamera"
local LightWorld = require "lib/light_world"

function love.load()
  scale = 1
  camera = gamera.new(0,0,2000,2000)
	-- load images
	image = love.graphics.newImage("gfx/machine2.png")
	image_normal = love.graphics.newImage("gfx/cone_normal.png")
	normal = love.graphics.newImage("gfx/refraction_normal.png")
	glow = love.graphics.newImage("gfx/machine2_glow.png")

	-- create light world
	lightWorld = LightWorld({
    drawBackground = drawBackground,
    drawForground = drawForground
  })
	lightWorld:setAmbientColor(15, 15, 31)
	lightWorld:setRefractionStrength(32.0)

	-- create light
	lightMouse = lightWorld:newLight(0, 0, 255, 127, 63, 300)
	lightMouse:setGlowStrength(0.3)

	-- create shadow bodys
	circleTest = lightWorld:newCircle(256, 256, 16)
	rectangleTest = lightWorld:newRectangle(512, 512, 64, 64)

	imageTest = lightWorld:newImage(image, 64, 64, 24, 6)
	imageTest:setNormalMap(image_normal)
	imageTest:setGlowMap(glow)
	imageTest:setOffset(12, -10)

	-- create body object
	objectTest = lightWorld:newRefraction(normal, 64, 64, 128, 128)
	objectTest:setReflection(true)
end

function love.update(dt)
	love.window.setTitle("Light vs. Shadow Engine (FPS:" .. love.timer.getFPS() .. ")")

  local x, y = camera:getPosition()
	if love.keyboard.isDown("up") then
		y = y - dt * 200
	elseif love.keyboard.isDown("down") then
		y = y + dt * 200
	end

	if love.keyboard.isDown("left") then
		x = x - dt * 200
	elseif love.keyboard.isDown("right") then
		x = x + dt * 200
	end

	if love.keyboard.isDown("-") then
		scale = scale - 0.01
	elseif love.keyboard.isDown("=") then
		scale = scale + 0.01
	end

  camera:setPosition(x, y)
  camera:setScale(scale)
	lightMouse:setPosition(camera:toWorld(love.mouse.getX(), love.mouse.getY()))
end

function love.draw()
  camera:draw(function(l,t,w,h)
    lightWorld:draw(l,t,w,h,scale)
  end)
end

function drawBackground(l,t,w,h)
  love.graphics.setColor(255, 255, 255)
  love.graphics.rectangle("fill", 0, 0, 2000, 2000)
end

function drawForground(l,t,w,h)
  love.graphics.setColor(63, 255, 127)
  love.graphics.circle("fill", circleTest:getX(), circleTest:getY(), circleTest:getRadius())
  love.graphics.polygon("fill", rectangleTest:getPoints())
  love.graphics.setColor(255, 255, 255)
  love.graphics.draw(image, 64 - image:getWidth() * 0.5, 64 - image:getHeight() * 0.5)
end

