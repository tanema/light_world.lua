require "postshader"
require "light"

function love.load()
	-- load images
	image = love.graphics.newImage("gfx/machine2.png")
	image_normal = love.graphics.newImage("gfx/cone_normal.png")
	normal = love.graphics.newImage("gfx/refraction_normal.png")
	glow = love.graphics.newImage("gfx/machine2_glow.png")

	-- create light world
	lightWorld = love.light.newWorld()
	lightWorld.setAmbientColor(15, 15, 31)
	lightWorld.setRefractionStrength(32.0)

	-- create light
	lightMouse = lightWorld.newLight(0, 0, 255, 127, 63, 300)
	lightMouse.setGlowStrength(0.3)
	--lightMouse.setSmooth(0.01)

	-- create shadow bodys
	circleTest = lightWorld.newCircle(256, 256, 16)
	rectangleTest = lightWorld.newRectangle(512, 512, 64, 64)
	imageTest = lightWorld.newImage(image, 64, 64, 24, 6)
	imageTest.setNormalMap(image_normal)
	imageTest.setGlowMap(glow)
	imageTest.setOffset(12, -10)

	-- create body object
	objectTest = lightWorld.newBody("refraction", normal, 64, 64, 128, 128)
	--objectTest.setShine(false)
	--objectTest.setShadowType("rectangle")
	--objectTest.setShadowDimension(64, 64)
	objectTest.setReflection(true)

	-- set background
	quadScreen = love.graphics.newQuad(0, 0, love.window.getWidth(), love.window.getHeight(), 32, 24)
	imgFloor = love.graphics.newImage("gfx/floor.png")
	imgFloor:setWrap("repeat", "repeat")
end

function love.update(dt)
	love.window.setTitle("Light vs. Shadow Engine (FPS:" .. love.timer.getFPS() .. ")")
	lightMouse.setPosition(love.mouse.getX(), love.mouse.getY())
end

function love.draw()
	-- update lightmap (doesn't need deltatime)
	lightWorld.update()

	love.postshader.setBuffer("render")
	
	-- draw background
	love.graphics.setColor(255, 255, 255)
	love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
	--love.graphics.draw(imgFloor, quadScreen, 0, 0)

	-- draw lightmap shadows
	lightWorld.drawShadow()

	-- draw scene objects
	love.graphics.setColor(63, 255, 127)
	love.graphics.circle("fill", circleTest.getX(), circleTest.getY(), circleTest.getRadius())
	love.graphics.polygon("fill", rectangleTest.getPoints())
	love.graphics.setColor(255, 255, 255)
	love.graphics.draw(image, 64 - image:getWidth() * 0.5, 64 - image:getHeight() * 0.5)

	--love.graphics.rectangle("fill", 128 - 32, 128 - 32, 64, 64)

	-- draw lightmap shine
	lightWorld.drawShine()

	-- draw pixel shadow
	lightWorld.drawPixelShadow()

	-- draw glow
	lightWorld.drawGlow()

	-- draw refraction
	lightWorld.drawRefraction()

	-- draw reflection
	lightWorld.drawReflection()

	love.postshader.draw()
end