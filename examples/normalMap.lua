-- Example: Normal map Example
local LightWorld = require "lib/light_world"

function love.load()
  x = 0
  y = 0
  scale = 1
	-- load images
	image = love.graphics.newImage("gfx/crossColor.jpg")
	image_normal = love.graphics.newImage("gfx/crossnrm.jpg")

	-- create light world
	lightWorld = LightWorld({
    drawBackground = drawBackground,
    drawForground = drawForground,
    ambient = {55,55,55},
    refractionStrength = 32.0,
    reflectionVisibility = 0.75,
  })

	-- create light
	lightMouse = lightWorld:newLight(0, 0, 160, 160, 160, 300)
	lightMouse:setGlowStrength(0.3)

	-- create shadow bodys
  local w, h = love.graphics.getWidth(), love.graphics.getHeight()
	imageTest = lightWorld:newImage(image, w/2, h/2)
	imageTest:setNormalMap(image_normal)
end

function love.update(dt)
	love.window.setTitle("Light vs. Shadow Engine (FPS:" .. love.timer.getFPS() .. ")")

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

	lightMouse:setPosition(love.mouse.getX()/scale, love.mouse.getY()/scale)
end

function love.draw()
  love.graphics.push()
    love.graphics.translate(x, y)
    love.graphics.scale(scale)
    lightWorld:draw(x,y,scale)
  love.graphics.pop()
end

function drawBackground(l,t,w,h)
  love.graphics.setColor(255, 255, 255)
  love.graphics.rectangle("fill", -l/scale, -t/scale, w/scale, h/scale)
end

function drawForground(l,t,w,h)
  love.graphics.setColor(255, 255, 255)
  local w, h = love.graphics.getWidth(), love.graphics.getHeight()
  love.graphics.draw(image, w/2-(image:getWidth()/2), h/2-(image:getHeight()/2))
end


