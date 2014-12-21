-- Example: Hump Example
local Camera = require "examples/vendor/hump/camera"
local LightWorld = require "lib"

function love.load()
  x = 0
  y = 0
  scale = 1
  cam = Camera(love.graphics.getWidth()/2, love.graphics.getHeight()/2)

	image = love.graphics.newImage("examples/gfx/machine2.png")
	image_normal = love.graphics.newImage("examples/gfx/cone_normal.png")
	normal = love.graphics.newImage("examples/gfx/refraction_normal.png")
	glow = love.graphics.newImage("examples/gfx/machine2_glow.png")

	-- create light world
	lightWorld = LightWorld({
    ambient = {55,55,55},
    refractionStrength = 32.0,
    reflectionVisibility = 0.75,
  })

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

	lightMouse:setPosition((love.mouse.getX() - x)/scale, (love.mouse.getY() - y)/scale)

  cam:lookAt(x, y)
  cam:zoom(scale)
  lightWorld:update(dt)
  lightWorld:setTranslation(x, y, scale)
end

function love.draw()
  cam:attach()
    lightWorld:draw(function()
      love.graphics.setColor(255, 255, 255)
      love.graphics.rectangle("fill", -x/scale, -y/scale, love.graphics.getWidth()/scale, love.graphics.getHeight()/scale)
      love.graphics.setColor(63, 255, 127)
      local cx, cy = circleTest:getPosition()
      love.graphics.circle("fill", cx, cy, circleTest:getRadius())
      love.graphics.polygon("fill", rectangleTest:getPoints())
      love.graphics.setColor(255, 255, 255)
      love.graphics.draw(image, 64 - image:getWidth() * 0.5, 64 - image:getHeight() * 0.5)
    end)
  cam:detach()
end
