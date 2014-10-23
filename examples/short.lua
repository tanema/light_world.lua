-- Example: Short Example
local LightWorld = require "lib/light_world"

function love.load()
  testShader = 0
  x = 0
  y = 0
  scale = 1
	-- load images
	image = love.graphics.newImage("gfx/machine2.png")
	image_normal = love.graphics.newImage("gfx/cone_normal.png")
	normal = love.graphics.newImage("gfx/refraction_normal.png")
	glow = love.graphics.newImage("gfx/machine2_glow.png")

	-- create light world
	lightWorld = LightWorld({
    drawBackground = drawBackground,
    drawForground = drawForground,
    ambient = {15,15,15},
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

function love.keypressed(k)
  if k == "1" then
    lightWorld.post_shader:toggleEffect("4colors", {15, 56, 15}, {48, 98, 48}, {139, 172, 15}, {155, 188, 15})
  elseif k == "2" then
    lightWorld.post_shader:toggleEffect("monochrome")
  elseif k == "3" then
    lightWorld.post_shader:toggleEffect("scanlines")
  elseif k == "4" then
    lightWorld.post_shader:toggleEffect("tiltshift", 4.0)
  elseif k == "5" then
		lightWorld.post_shader:toggleEffect("bloom", 2.0, 0.25)
  elseif k == "6" then
		lightWorld.post_shader:toggleEffect("blur", 2.0, 2.0)
		--lightWorld.post_shader:addEffect("chromatic", math.sin(lightDirection * 10.0) * colorAberration, math.cos(lightDirection * 10.0) * colorAberration, math.cos(lightDirection * 10.0) * colorAberration, math.sin(lightDirection * 10.0) * -colorAberration, math.sin(lightDirection * 10.0) * colorAberration, math.cos(lightDirection * 10.0) * -colorAberration)
  elseif k == "7" then
    testShader = testShader + 1
		lightWorld.post_shader:addEffect("test", testShader)
  end
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
  love.graphics.setColor(63, 255, 127)
  love.graphics.circle("fill", circleTest:getX(), circleTest:getY(), circleTest:getRadius())
  love.graphics.polygon("fill", rectangleTest:getPoints())
  love.graphics.setColor(255, 255, 255)
  love.graphics.draw(image, 64 - image:getWidth() * 0.5, 64 - image:getHeight() * 0.5)
end

