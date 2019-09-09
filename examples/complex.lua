-- Example: Complex Example
local LightWorld = require "lib"
local ProFi = require 'examples.vendor.ProFi'

function initScene()
	-- physic world
	physicWorld = love.physics.newWorld(0, 9.81 * 64, true)
	wall1 = {}
	wall1.body = love.physics.newBody(physicWorld, 400, 605, "static")
	wall1.shape = love.physics.newRectangleShape(0, 0, 800, 10)
	wall1.fixture = love.physics.newFixture(wall1.body, wall1.shape)

	wall2 = {}
	wall2.body = love.physics.newBody(physicWorld, -5, 300, "static")
	wall2.shape = love.physics.newRectangleShape(0, 0, 10, 600)
	wall2.fixture = love.physics.newFixture(wall2.body, wall2.shape)

	wall3 = {}
	wall3.body = love.physics.newBody(physicWorld, 805, 300, "static")
	wall3.shape = love.physics.newRectangleShape(0, 0, 10, 600)
	wall3.fixture = love.physics.newFixture(wall3.body, wall3.shape)

	wall4 = {}
	wall4.body = love.physics.newBody(physicWorld, 400, -5, "static")
	wall4.shape = love.physics.newRectangleShape(0, 0, 800, 10)
	wall4.fixture = love.physics.newFixture(wall4.body, wall4.shape)

	phyCnt = 0
	phyLight = {}
end

function love.load()
  ProFi:start()

  love.graphics.setBackgroundColor(0, 0, 0)
	love.graphics.setDefaultFilter("nearest", "nearest")

	-- load image font
	font = love.graphics.newImageFont("examples/gfx/font.png", " abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.,!?-+/():;%&`'*#=[]\"")
	love.graphics.setFont(font)

	-- set background
	quadScreen = love.graphics.newQuad(0, 0, love.graphics.getWidth() + 32, love.graphics.getHeight() + 24, 32, 24)
	imgFloor = love.graphics.newImage("examples/gfx/floor.png")
	imgFloor:setWrap("repeat", "repeat")

	-- load image examples
	circle = love.graphics.newImage("examples/gfx/circle.png")
	circle_normal = love.graphics.newImage("examples/gfx/circle_normal.png")
	cone = love.graphics.newImage("examples/gfx/cone.png")
	cone_large = love.graphics.newImage("examples/gfx/cone_large.png")
	cone_large_normal = love.graphics.newImage("examples/gfx/cone_large_normal.png")
	cone_normal = love.graphics.newImage("examples/gfx/cone_normal.png")
	chest = love.graphics.newImage("examples/gfx/chest.png")
	chest_normal = love.graphics.newImage("examples/gfx/chest_normal.png")
	machine = love.graphics.newImage("examples/gfx/machine.png")
	machine_normal = love.graphics.newImage("examples/gfx/machine_normal.png")
	machine_glow = love.graphics.newImage("examples/gfx/machine_glow.png")
	machine2 = love.graphics.newImage("examples/gfx/machine2.png")
	machine2_normal = love.graphics.newImage("examples/gfx/machine2_normal.png")
	machine2_glow = love.graphics.newImage("examples/gfx/machine2_glow.png")
	blopp = love.graphics.newImage("examples/gfx/blopp.png")
	tile = love.graphics.newImage("examples/gfx/tile.png")
	tile_normal = love.graphics.newImage("examples/gfx/tile_normal.png")
	tile_glow = love.graphics.newImage("examples/gfx/tile_glow.png")
	refraction_normal = love.graphics.newImage("examples/gfx/refraction_normal.png")
	water = love.graphics.newImage("examples/gfx/water.png")
	led = love.graphics.newImage("examples/gfx/led.png")
	led2 = love.graphics.newImage("examples/gfx/led2.png")
	led3 = love.graphics.newImage("examples/gfx/led3.png")
	led_normal = love.graphics.newImage("examples/gfx/led_normal.png")
	led_glow = love.graphics.newImage("examples/gfx/led_glow.png")
	led_glow2 = love.graphics.newImage("examples/gfx/led_glow2.png")
	led_glow3 = love.graphics.newImage("examples/gfx/led_glow3.png")
	ape = love.graphics.newImage("examples/gfx/ape.png")
	ape_normal = love.graphics.newImage("examples/gfx/ape_normal.png")
	ape_glow = love.graphics.newImage("examples/gfx/ape_glow.png")
	imgLight = love.graphics.newImage("examples/gfx/light.png")

	-- materials
	material = {}

	local files = love.filesystem.getDirectoryItems("examples/gfx/sphere")
	for i, file in ipairs(files) do
		material[i] = love.graphics.newImage("examples/gfx/sphere/" .. file)
	end

	-- light world
	lightRange = 400
	lightSmooth = 1.0

	lightWorld = LightWorld({
    ambient = {15,15,15},
    refractionStrength = 16.0,
    reflectionVisibility = 0.75,
    shadowBlur = 2.0
  })

	mouseLight = lightWorld:newLight(0, 0, 1, 191/ 255, 0.5, lightRange)
	mouseLight:setGlowStrength(0.3)
	mouseLight:setSmooth(lightSmooth)
	mouseLight.z = 63
	lightDirection = 0.0
	colorAberration = 0.0

	-- init physic world
	initScene()

	helpOn = false
	physicOn = false
	lightOn = true
	gravityOn = 1
	shadowBlur = 2.0
	bloomOn = 0.0
	textureOn = true
	normalOn = false
	glowBlur = 1.0
	effectOn = 0.0

	offsetX = 0.0
	offsetY = 0.0
  scale = 1.0
	offsetOldX = 0.0
	offsetOldY = 0.0
	offsetChanged = false

	tileX = 0
	tileY = 0
end

function love.update(dt)
	love.window.setTitle("Light vs. Shadow Engine (FPS:" .. love.timer.getFPS() .. ")")

  mx, my = (love.mouse.getX() - offsetX)/scale, (love.mouse.getY() - offsetY)/scale

	mouseLight:setPosition(mx, my, 1 + (math.sin(lightDirection) + 1.0))

	lightDirection = lightDirection + dt
	colorAberration = math.max(0.0, colorAberration - dt * 10.0)

	if love.keyboard.isDown("up") then
		offsetY = offsetY + dt * 200
	elseif love.keyboard.isDown("down") then
		offsetY = offsetY - dt * 200
	end

	if love.keyboard.isDown("left") then
		offsetX = offsetX + dt * 200
	elseif love.keyboard.isDown("right") then
		offsetX = offsetX - dt * 200
	end

	if love.keyboard.isDown("-") then
		scale = scale - 0.01
	elseif love.keyboard.isDown("=") then
		scale = scale + 0.01
	end

  for i = 1, lightWorld:getLightCount() do
		lightWorld:getLight(i):setDirection(lightDirection)
  end

	tileX = tileX + dt * 32.0
	tileY = tileY + dt * 8.0
  for i = 1, phyCnt do
		if phyLight[i]:getType() == "refraction" then
			phyLight[i]:setNormalTileOffset(tileX, tileY)
		end
  end

	-- draw shader
	if colorAberration > 0.0 then
		-- vert / horz blur
		lightWorld.post_shader:addEffect("blur", 2.0, 2.0)
		lightWorld.post_shader:addEffect("chromatic_aberration",
      {math.sin(lightDirection * 10.0) * colorAberration, math.cos(lightDirection * 10.0) * colorAberration},
      {math.cos(lightDirection * 10.0) * colorAberration, math.sin(lightDirection * 10.0) * -colorAberration},
      {math.sin(lightDirection * 10.0) * colorAberration, math.cos(lightDirection * 10.0) * -colorAberration})
  else
		lightWorld.post_shader:removeEffect("blur")
		lightWorld.post_shader:removeEffect("chromatic_aberration")
	end

	if bloomOn > 0.0 then
		-- blur, strength
		lightWorld.post_shader:addEffect("bloom", 2.0, bloomOn)
  else
		lightWorld.post_shader:removeEffect("bloom")
	end
  lightWorld:update(dt)
end

function love.draw()
	-- set shader buffer
  lightWorld:setTranslation(offsetX,offsetY, scale)
  love.graphics.push()
    love.graphics.translate(offsetX, offsetY)
    love.graphics.scale(scale)
    lightWorld:draw(function(l, t, w, h, s)
      love.graphics.setBlendMode("alpha")
      if normalOn then
        love.graphics.setColor(0.5, 0.5, 1)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
      else
        love.graphics.setColor(1, 1, 1)
        if textureOn then
          love.graphics.draw(imgFloor, quadScreen, 0,0)
        else
          love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        end
      end

      for i = 1, phyCnt do
        if phyLight[i]:getType() == "refraction" then
          if not normalOn then
            love.graphics.setBlendMode("alpha")
            love.graphics.setColor(1, 1, 1, 191/255)
            love.graphics.draw(water, phyLight[i].x - phyLight[i].ox, phyLight[i].y - phyLight[i].oy)
          end
        end
      end

      love.graphics.setBlendMode("alpha")
      for i = 1, phyCnt do
        if phyLight[i]:getType() == "polygon" then
          math.randomseed(i)
          love.graphics.setColor(math.random(), math.random(), math.random())
          love.graphics.polygon("fill", phyLight[i]:getPoints())
        elseif phyLight[i]:getType() == "circle" then
          math.randomseed(i)
          love.graphics.setColor(math.random(), math.random(), math.random())
          local cx, cy = phyLight[i]:getPosition()
          love.graphics.circle("fill", cx, cy, phyLight[i]:getRadius())
        elseif phyLight[i]:getType() == "image" then
          if normalOn and phyLight[i].normal then
            love.graphics.setColor(1, 1, 1)
            love.graphics.draw(phyLight[i].normal, phyLight[i].x - phyLight[i].nx, phyLight[i].y - phyLight[i].ny)
          elseif not phyLight[i].material then
            math.randomseed(i)
            love.graphics.setColor(
              math.random(127, 255) / 255, math.random(127, 255)/ 255, math.random(127, 255) / 255
            )
            love.graphics.draw(phyLight[i].img, phyLight[i].x - phyLight[i].ix, phyLight[i].y - phyLight[i].iy)
          end
        end
      end
    end)
  love.graphics.pop()

	love.graphics.draw(imgLight, mx - 5, (my - 5) - (16.0 + (math.sin(lightDirection) + 1.0) * 64.0))

	-- draw help
	if helpOn then
		love.graphics.setBlendMode("alpha")
		love.graphics.setColor(0, 0, 0, 191)
		love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), 44)
		love.graphics.rectangle("fill", 0, love.graphics.getHeight() - 68, 240, 68)
		love.graphics.rectangle("fill", love.graphics.getWidth() - 244, love.graphics.getHeight() - 84, 244, 84)
		love.graphics.setColor(0, 1, 0)
		love.graphics.print("F1: Help (on)", 4 + 152 * 0, 4)
		if shadowBlur >= 1.0 then
			love.graphics.setColor(0, 1, 0)
			love.graphics.print("F5: Shadowblur (" .. shadowBlur .. ")", 4 + 152 * 4, 4)
		else
			love.graphics.setColor(1, 0, 0)
			love.graphics.print("F5: Shadowblur (off)", 4 + 152 * 4, 4)
		end
		if bloomOn > 0.0 then
			love.graphics.setColor(0, 1, 0)
			love.graphics.print("F6: Bloom (" .. (bloomOn * 4) .. ")", 4 + 152 * 0, 4 + 20 * 1)
		else
			love.graphics.setColor(1, 0, 0)
			love.graphics.print("F6: Bloom (off)", 4 + 152 * 0, 4 + 20 * 1)
		end
		if textureOn then
			love.graphics.setColor(0, 1, 0)
			love.graphics.print("F7: Texture (on)", 4 + 152 * 1, 4 + 20 * 1)
		else
			love.graphics.setColor(1, 0, 0)
			love.graphics.print("F7: Texture (off)", 4 + 152 * 1, 4 + 20 * 1)
		end
		if normalOn then
			love.graphics.setColor(0, 1, 0)
			love.graphics.print("F8: Normal (on)", 4 + 152 * 2, 4 + 20 * 1)
		else
			love.graphics.setColor(1, 0, 0)
			love.graphics.print("F8: Normal (off)", 4 + 152 * 2, 4 + 20 * 1)
		end
		if glowBlur >= 1.0 then
			love.graphics.setColor(0, 1, 0)
			love.graphics.print("F9: Glow Blur (" .. glowBlur .. ")", 4 + 152 * 3, 4 + 20 * 1)
		else
			love.graphics.setColor(1, 0, 0)
			love.graphics.print("F9: Glow Blur (off)", 4 + 152 * 3, 4 + 20 * 1)
		end
		if effectOn >= 1.0 then
			love.graphics.setColor(0, 1, 0)
			love.graphics.print("F10: Effects (" .. effectOn .. ")", 4 + 152 * 4, 4 + 20 * 1)
		else
			love.graphics.setColor(1, 0, 0)
			love.graphics.print("F10: Effects (off)", 4 + 152 * 4, 4 + 20 * 1)
		end
		love.graphics.setColor(1, 0, 1)
		love.graphics.print("F11: Clear obj.", 4 + 152 * 4, 4 + 20 * 2)
		love.graphics.print("F12: Clear lights", 4 + 152 * 4, 4 + 20 * 3)
		love.graphics.setColor(0, 0.5, 1)
		love.graphics.print("WASD Keys: Move objects", 4, love.graphics.getHeight() - 20 * 3)
		love.graphics.print("Arrow Keys: Move map", 4, love.graphics.getHeight() - 20 * 2)
		love.graphics.print("0-9 Keys: Add object", 4, love.graphics.getHeight() - 20 * 1)
		love.graphics.setColor(1, 0.5, 0)
		love.graphics.print("M.left: Add cube", love.graphics.getWidth() - 240, love.graphics.getHeight() - 20 * 4)
		love.graphics.print("M.middle: Add light", love.graphics.getWidth() - 240, love.graphics.getHeight() - 20 * 3)
		love.graphics.print("M.right: Add circle", love.graphics.getWidth() - 240, love.graphics.getHeight() - 20 * 2)
		love.graphics.print("M.scroll: Change smooth", love.graphics.getWidth() - 240, love.graphics.getHeight() - 20 * 1)
		love.graphics.setColor(1, 0.5, 0)
	else
		love.graphics.setColor(1, 1, 1, 191/255)
		love.graphics.print("F1: Help", 4, 4)
	end
end

function love.mousepressed(x, y, c)
	if c == "m" then
		-- add light
		local r = lightWorld:getLightCount() % 3
		local light

		if r == 0 then
			light = lightWorld:newLight(x, y, 31/ 255, 0.5, 63/ 255, lightRange)
		elseif r == 1 then
			light = lightWorld:newLight(x, y, 0.5, 63/255, 31/255, lightRange)
		else
			light = lightWorld:newLight(x, y, 31/255, 63/255, 127/255, lightRange)
		end
		light:setSmooth(lightSmooth)
		light:setGlowStrength(0.3)
	elseif c == "l" then
		-- add rectangle
		math.randomseed(love.timer.getTime())
		phyCnt = phyCnt + 1
    local w, h = math.random(32, 64), math.random(32, 64)
		phyLight[phyCnt] = lightWorld:newPolygon(
     x, y,
     x+w, y,
     x+w, y+h,
     x, y+h
    )
	elseif c == "r" then
		-- add circle
		math.randomseed(love.timer.getTime())
		cRadius = math.random(8, 32)
		phyCnt = phyCnt + 1
		phyLight[phyCnt] = lightWorld:newCircle(x, y, cRadius)
	elseif c == "wu" then
		if lightSmooth < 4.0 then
			lightSmooth = lightSmooth * 1.1
			mouseLight:setSmooth(lightSmooth)
		end
	elseif c == "wd" then
		if lightSmooth > 0.5 then
			lightSmooth = lightSmooth / 1.1
			mouseLight:setSmooth(lightSmooth)
		end
	end
end

function love.keypressed(k, u)
	-- debug options
	if k == "f1" then
		helpOn = not helpOn
	elseif k == "f5" then
		shadowBlur = math.max(1, shadowBlur * 2.0)
		if shadowBlur > 8.0 then
			shadowBlur = 0.0
		end
		lightWorld:setShadowBlur(shadowBlur)
	elseif k == "f6" or k == "b" then
		bloomOn = math.max(0.25, bloomOn * 2.0)
		if bloomOn > 1.0 then
			bloomOn = 0.0
		end
	elseif k == "f7" then
		textureOn = not textureOn
	elseif k == "f8" then
		normalOn = not normalOn
	elseif k == "f9" then
		glowBlur = glowBlur + 1.0
		if glowBlur > 8.0 then
			glowBlur = 0.0
		end
		lightWorld:setGlowStrength(glowBlur)
	elseif k == "f10" then
		effectOn = effectOn + 1.0
		if effectOn > 4.0 then
			effectOn = 0.0
		end

    if effectOn == 1.0 then
      lightWorld.post_shader:addEffect("four_colors", {15, 56, 15}, {48, 98, 48}, {139, 172, 15}, {155, 188, 15})
      --lightWorld.post_shader:addEffect("4colors", {108, 108, 78}, {142, 139, 87}, {195, 196, 165}, {227, 230, 201})
    else
      lightWorld.post_shader:removeEffect("four_colors")
    end

    if effectOn == 2.0 then
      lightWorld.post_shader:addEffect("monochrome")
    else
      lightWorld.post_shader:removeEffect("monochrome")
    end

    if effectOn == 3.0 then
      lightWorld.post_shader:addEffect("scanlines")
    else
      lightWorld.post_shader:removeEffect("scanlines")
    end

    if effectOn == 4.0 then
      lightWorld.post_shader:addEffect("tilt_shift", 4.0)
    else
      lightWorld.post_shader:removeEffect("tilt_shift")
    end

	elseif k == "f11" then
		physicWorld:destroy()
		lightWorld:clearBodies()
		initScene()
	elseif k == "f12" then
		lightWorld:clearLights()
		mouseLight = lightWorld:newLight(0, 0, 1, 191/255, 0.5, lightRange)
		mouseLight:setGlowStrength(0.3)
		mouseLight:setSmooth(lightSmooth)
	elseif k == "1" then
		-- add image
		phyCnt = phyCnt + 1
		phyLight[phyCnt] = lightWorld:newImage(circle, mx, my)
		phyLight[phyCnt]:setNormalMap(circle_normal)
		phyLight[phyCnt]:setShadowType("circle", 16)
	elseif k == "2" then
		local r = lightWorld:getBodyCount() % 2
		if r == 0 then
			-- add image
			phyCnt = phyCnt + 1
			phyLight[phyCnt] = lightWorld:newImage(cone, mx, my, 24, 12, 12, 16)
			phyLight[phyCnt]:setNormalMap(cone_normal)
			phyLight[phyCnt]:setShadowType("circle", 12)
		elseif r == 1 then
			-- add image
			phyCnt = phyCnt + 1
			phyLight[phyCnt] = lightWorld:newImage(chest, mx, my, 32, 24, 16, 0)
			phyLight[phyCnt]:setNormalMap(chest_normal)
		end
	elseif k == "3" then
		-- add image
		local r = lightWorld:getBodyCount() % #material
		phyCnt = phyCnt + 1
		phyLight[phyCnt] = lightWorld:newImage(ape, mx, my, 160, 128, 80, 64)
		phyLight[phyCnt]:setNormalMap(ape_normal)
		if r == 3 then
			phyLight[phyCnt]:setGlowMap(ape_glow)
		end
		phyLight[phyCnt]:setMaterial(material[r + 1])
		phyLight[phyCnt]:setShadowType("image", 0, -16, 0.0)
	elseif k == "4" then
		-- add glow image
		local r = lightWorld:getBodyCount() % 5
		if r == 0 then
			phyCnt = phyCnt + 1
			phyLight[phyCnt] = lightWorld:newImage(machine, mx, my, 32, 24, 16, 0)
			phyLight[phyCnt]:setNormalMap(machine_normal)
			phyLight[phyCnt]:setGlowMap(machine_glow)
		elseif r == 1 then
			phyCnt = phyCnt + 1
			phyLight[phyCnt] = lightWorld:newImage(machine2, mx, my, 24, 12, 12, -4)
			phyLight[phyCnt]:setNormalMap(machine2_normal)
			phyLight[phyCnt]:setGlowMap(machine2_glow)
		elseif r == 2 then
			phyCnt = phyCnt + 1
			phyLight[phyCnt] = lightWorld:newImage(led, mx, my, 32, 6, 16, -8)
			phyLight[phyCnt]:setNormalMap(led_normal)
			phyLight[phyCnt]:setGlowMap(led_glow)
		elseif r == 3 then
			phyCnt = phyCnt + 1
			phyLight[phyCnt] = lightWorld:newImage(led2, mx, my, 32, 6, 16, -8)
			phyLight[phyCnt]:setNormalMap(led_normal)
			phyLight[phyCnt]:setGlowMap(led_glow2)
		elseif r == 4 then
			phyCnt = phyCnt + 1
			phyLight[phyCnt] = lightWorld:newImage(led3, mx, my, 32, 6, 16, -8)
			phyLight[phyCnt]:setNormalMap(led_normal)
			phyLight[phyCnt]:setGlowMap(led_glow3)
		end
	elseif k == "5" then
		-- add image
		phyCnt = phyCnt + 1
		phyLight[phyCnt] = lightWorld:newImage(cone_large, mx, my, 24, 128, 12, 64)
		phyLight[phyCnt]:setNormalMap(cone_large_normal)
		phyLight[phyCnt]:setShadowType("image", 0, -6, 0.0)
	elseif k == "6" then
		-- add image
		phyCnt = phyCnt + 1
		phyLight[phyCnt] = lightWorld:newImage(blopp, mx, my, 42, 16, 21, 0)
		phyLight[phyCnt]:generateNormalMapGradient("gradient", "gradient")
		phyLight[phyCnt]:setAlpha(0.5)
	elseif k == "7" then
		-- add image
		phyCnt = phyCnt + 1
		phyLight[phyCnt] = lightWorld:newImage(tile, mx, my)
		phyLight[phyCnt]:setHeightMap(tile_normal, 2.0)
		phyLight[phyCnt]:setGlowMap(tile_glow)
		phyLight[phyCnt]:setShadow(false)
		phyLight[phyCnt].reflective = false
	elseif k == "8" then
		-- add rectangle
		phyCnt = phyCnt + 1
    local w, h = math.random(32, 64), math.random(32, 64)
		phyLight[phyCnt] = lightWorld:newPolygon(
      mx, my,
      mx+w, my,
      mx+w, my+h,
      mx, my+h
    )
		phyLight[phyCnt]:setAlpha(0.5)
		phyLight[phyCnt]:setGlowStrength(1.0)
		math.randomseed(phyCnt)
		phyLight[phyCnt]:setGlowColor(math.random(), math.random(), math.random())
		math.randomseed(phyCnt)
		phyLight[phyCnt]:setColor(math.random(), math.random(), math.random())
	elseif k == "9" then
		-- add circle
		math.randomseed(love.timer.getTime())
		cRadius = math.random(8, 32)
		phyCnt = phyCnt + 1
		phyLight[phyCnt] = lightWorld:newCircle(mx, my, cRadius)
		phyLight[phyCnt]:setAlpha(0.5)
		phyLight[phyCnt]:setGlowStrength(1.0)
		math.randomseed(phyCnt)
		phyLight[phyCnt]:setGlowColor(math.random(), math.random(), math.random())
		math.randomseed(phyCnt)
		phyLight[phyCnt]:setColor(math.random(), math.random(), math.random())
	elseif k == "0" then
		phyCnt = phyCnt + 1
		phyLight[phyCnt] = lightWorld:newRefraction(refraction_normal, mx, my)
		phyLight[phyCnt]:setReflection(true)
  elseif k == "k" then
		-- add light
		local r = lightWorld:getLightCount() % 3
		local light

		if r == 0 then
			light = lightWorld:newLight(mx, my, 31/255, 127 / 255, 63 / 255, lightRange)
		elseif r == 1 then
			light = lightWorld:newLight(mx, my, 127 / 255, 63 / 255, 31 / 255, lightRange)
		else
			light = lightWorld:newLight(mx, my, 31 / 255, 63 / 255, 127 / 255, lightRange)
		end
		light:setSmooth(lightSmooth)
		light:setGlowStrength(0.3)
	elseif k == "l" then
		-- add light
		local r = lightWorld:getLightCount() % 3
		local light

		if r == 0 then
			light = lightWorld:newLight(mx, my, 31/255, 127/255, 63/255, lightRange)
		elseif r == 1 then
			light = lightWorld:newLight(mx, my, 127/255, 63/255, 31/255, lightRange)
		else
			light = lightWorld:newLight(mx, my, 31, 63, 127, lightRange)
		end
		light:setSmooth(lightSmooth)
		light:setGlowStrength(0.3)
		math.randomseed(love.timer.getTime())
		light:setAngle(math.random(1, 5) * 0.1 * math.pi)
	elseif k == "c" then
		if colorAberration == 0.0 then
			colorAberration = 3.0
		end
	end
end
