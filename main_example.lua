require "light"

function love.load()
	-- create light world
	lightWorld = love.light.newWorld()
	lightWorld.setAmbientColor(15, 15, 31)

	-- create light
	lightMouse = lightWorld.newLight(0, 0, 255, 127, 63, 300)
	lightMouse.setGlowStrength(0.3)

	-- create shadow bodys
	circleTest = lightWorld.newCircle(256, 256, 32)
	rectangleTest = lightWorld.newRectangle(512, 512, 64, 64)
end

function love.update(dt)
	love.window.setTitle("Light vs. Shadow Engine (FPS:" .. love.timer.getFPS() .. ")")
	lightMouse.setPosition(love.mouse.getX(), love.mouse.getY())
end

function love.draw()
	-- update lightmap (doesn't need deltatime)
	lightWorld.update()

	-- draw background
	love.graphics.setColor(255, 255, 255)
	love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

	-- draw lightmap shadows
	lightWorld.drawShadow()

	-- draw scene objects
	love.graphics.setColor(63, 255, 127)
	love.graphics.circle("fill", circleTest.getX(), circleTest.getY(), circleTest.getRadius())
	love.graphics.polygon("fill", rectangleTest.getPoints())

	-- draw lightmap shine
	lightWorld.drawShine()
end