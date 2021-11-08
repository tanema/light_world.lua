-- Example: Short Example
local LightWorld = require "lib"

function love.load()
  testShader = 0
  x = 0
  y = 0
  z = 1
  scale = 1
  colorAberration = 0.0
	-- load images
	image = love.graphics.newImage("examples/gfx/machine2.png")
	image_normal = love.graphics.newImage("examples/gfx/cone_normal.png")
	normal = love.graphics.newImage("examples/gfx/refraction_normal.png")
	glow = love.graphics.newImage("examples/gfx/machine2_glow.png")

	-- create light world
	lightWorld = LightWorld({
    ambient = {55,55,55},
    refractionStrength = 32.0,
    reflectionVisibility = 0.75,
    shadowBlur = 0.0
  })

	-- create light
	lightMouse = lightWorld:newLight(0, 0, 255, 127, 63, 300)
	lightMouse:setGlowStrength(0.3)

	-- create shadow bodys
	circleTest = lightWorld:newCircle(256, 256, 16)
	rectangleTest = lightWorld:newRectangle(512, 512, 64, 64)
  local px, py, pw, ph = 100, 200, 20, 50
	polygonTest = lightWorld:newPolygon(
    px, py,
    px+pw, py,
    px+pw, py+ph,
    px-50, py+ph)

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
    lightWorld.post_shader:toggleEffect("four_colors", {15, 56, 15}, {48, 98, 48}, {139, 172, 15}, {155, 188, 15})
  elseif k == "2" then
    lightWorld.post_shader:toggleEffect("monochrome")
  elseif k == "3" then
    lightWorld.post_shader:toggleEffect("scanlines")
  elseif k == "4" then
    lightWorld.post_shader:toggleEffect("tilt_shift", 4.0)
  elseif k == "5" then
		lightWorld.post_shader:toggleEffect("bloom", 2.0, 0.25)
  elseif k == "6" then
		lightWorld.post_shader:toggleEffect("blur", 2.0, 2.0)
  elseif k == "7" then
		lightWorld.post_shader:toggleEffect("black_and_white")
  elseif k == "8" then
		lightWorld.post_shader:toggleEffect("curvature")
  elseif k == "9" then
		lightWorld.post_shader:toggleEffect("edges")
  elseif k == "0" then
		lightWorld.post_shader:toggleEffect("hdr_tv")
  elseif k == "q" then
		lightWorld.post_shader:toggleEffect("phosphor")
  elseif k == "w" then
		lightWorld.post_shader:toggleEffect("phosphorish")
  elseif k == "e" then
		lightWorld.post_shader:toggleEffect("pip")
  elseif k == "r" then
		lightWorld.post_shader:toggleEffect("pixellate")
  elseif k == "t" then
		lightWorld.post_shader:toggleEffect("radialblur")
  elseif k == "y" then
		lightWorld.post_shader:toggleEffect("waterpaint")
	elseif k == "c" then
		if colorAberration == 0.0 then
			colorAberration = 3.0
		end
  end
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


	if love.keyboard.isDown("k") then
    polygonTest:move(0, -(dt * 200))
	elseif love.keyboard.isDown("j") then
    polygonTest:move(0, (dt * 200))
  end
	if love.keyboard.isDown("h") then
    polygonTest:move(-(dt * 200), 0)
	elseif love.keyboard.isDown("l") then
    polygonTest:move((dt * 200), 0)
  end

	if love.keyboard.isDown("f") then
    polygonTest:scale(0.005)
	elseif love.keyboard.isDown("a") then
    polygonTest:scale(-0.005)
  end
	if love.keyboard.isDown("s") then
    polygonTest:rotate(0.05)
	elseif love.keyboard.isDown("d") then
    polygonTest:rotate(-0.05)
  end

	if love.keyboard.isDown("-") then
		scale = scale - 0.01
	elseif love.keyboard.isDown("=") then
		scale = scale + 0.01
	end

	colorAberration = math.max(0.0, colorAberration - dt * 10.0)
	if colorAberration > 0.0 then
		lightWorld.post_shader:addEffect("blur", 2.0, 2.0)
		lightWorld.post_shader:addEffect("chromatic_aberration")
  else
		lightWorld.post_shader:removeEffect("blur")
		lightWorld.post_shader:removeEffect("chromatic_aberration")
	end

  lightWorld:update(dt)
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
      love.graphics.setColor(63, 255, 127)
      local cx, cy = circleTest:getPosition()
      love.graphics.circle("fill", cx, cy, circleTest:getRadius())
      love.graphics.polygon("fill", rectangleTest:getPoints())
      love.graphics.polygon("fill", polygonTest:getPoints())
      love.graphics.setColor(255, 255, 255)
      love.graphics.draw(image, 64 - image:getWidth() * 0.5, 64 - image:getHeight() * 0.5)
    end)
  love.graphics.pop()

  love.graphics.setBlendMode("alpha")
  love.graphics.setColor(0, 0, 0, 191)
  love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), 24)
  love.graphics.setColor(0, 255, 0)
  love.graphics.print("To toggle postshaders, use 0-9 and q->y, to scale use - and =, and to translate use arrows")
  love.graphics.print("light z: " .. lightMouse.z, 0, 50)
end
