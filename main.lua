require "postshader"
require "light"

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
	phyBody = {}
	phyShape = {}
	phyFixture = {}
end

function love.load()
    love.graphics.setBackgroundColor(0, 0, 0)
	love.graphics.setDefaultFilter("nearest", "nearest")

	-- load image font
	font = love.graphics.newImageFont("gfx/font.png", " abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.,!?-+/():;%&`'*#=[]\"")
	love.graphics.setFont(font)

	-- set background
	quadScreen = love.graphics.newQuad(0, 0, love.window.getWidth() + 32, love.window.getHeight() + 24, 32, 24)
	imgFloor = love.graphics.newImage("gfx/floor.png")
	imgFloor:setWrap("repeat", "repeat")

	-- load image examples
	circle = love.graphics.newImage("gfx/circle.png")
	circle_normal = love.graphics.newImage("gfx/circle_normal.png")
	cone = love.graphics.newImage("gfx/cone.png")
	cone_large = love.graphics.newImage("gfx/cone_large.png")
	cone_large_normal = love.graphics.newImage("gfx/cone_large_normal.png")
	cone_normal = love.graphics.newImage("gfx/cone_normal.png")
	chest = love.graphics.newImage("gfx/chest.png")
	chest_normal = love.graphics.newImage("gfx/chest_normal.png")
	machine = love.graphics.newImage("gfx/machine.png")
	machine_normal = love.graphics.newImage("gfx/machine_normal.png")
	machine_glow = love.graphics.newImage("gfx/machine_glow.png")
	machine2 = love.graphics.newImage("gfx/machine2.png")
	machine2_normal = love.graphics.newImage("gfx/machine2_normal.png")
	machine2_glow = love.graphics.newImage("gfx/machine2_glow.png")
	blopp = love.graphics.newImage("gfx/blopp.png")
	tile = love.graphics.newImage("gfx/tile.png")
	tile_normal = love.graphics.newImage("gfx/tile_normal.png")
	tile_glow = love.graphics.newImage("gfx/tile_glow.png")
	refraction_normal = love.graphics.newImage("gfx/refraction_normal.png")
	water = love.graphics.newImage("gfx/water.png")
	led = love.graphics.newImage("gfx/led.png")
	led2 = love.graphics.newImage("gfx/led2.png")
	led3 = love.graphics.newImage("gfx/led3.png")
	led_normal = love.graphics.newImage("gfx/led_normal.png")
	led_glow = love.graphics.newImage("gfx/led_glow.png")
	led_glow2 = love.graphics.newImage("gfx/led_glow2.png")
	led_glow3 = love.graphics.newImage("gfx/led_glow3.png")
	ape = love.graphics.newImage("gfx/ape.png")
	ape_normal = love.graphics.newImage("gfx/ape_normal.png")
	ape_glow = love.graphics.newImage("gfx/ape_glow.png")

	-- materials
	material = {}

	local files = love.filesystem.getDirectoryItems("gfx/sphere")
	for i, file in ipairs(files) do
		material[i] = love.graphics.newImage("gfx/sphere/" .. file)
	end

	-- light world
	lightRange = 400
	lightSmooth = 1.0
	lightWorld = love.light.newWorld()
	lightWorld.setAmbientColor(15, 15, 31)
	lightWorld.setRefractionStrength(16.0)
	lightWorld.setReflectionVisibility(0.75)
	mouseLight = lightWorld.newLight(0, 0, 255, 191, 127, lightRange)
	mouseLight.setGlowStrength(0.3)
	mouseLight.setSmooth(lightSmooth)
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
	bloomOn = 0.25
	textureOn = true
	normalOn = false
	glowBlur = 1.0

	offsetX = 0.0
	offsetY = 0.0
	offsetOldX = 0.0
	offsetOldY = 0.0
	offsetChanged = false

	tileX = 0
	tileY = 0
end

function love.update(dt)
	love.window.setTitle("Light vs. Shadow Engine (FPS:" .. love.timer.getFPS() .. ")")
	mouseLight.setPosition(love.mouse.getX(), love.mouse.getY())
	mx = love.mouse.getX()
	my = love.mouse.getY()
	lightDirection = lightDirection + dt
	colorAberration = math.max(0.0, colorAberration - dt * 10.0)

	if love.keyboard.isDown("w") then
		for i = 1, phyCnt do
			if phyBody[i] then
				phyBody[i]:applyForce(0, -2000)
			end
		end
	elseif love.keyboard.isDown("s") then
		for i = 1, phyCnt do
			if phyBody[i] then
				phyBody[i]:applyForce(0, 2000)
			end
		end
	end

	if love.keyboard.isDown("a") then
		for i = 1, phyCnt do
			if phyBody[i] then
				phyBody[i]:applyForce(-2000, 0)
			end
		end
	elseif love.keyboard.isDown("d") then
		for i = 1, phyCnt do
			if phyBody[i] then
				phyBody[i]:applyForce(2000, 0)
			end
		end
	end

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

	if offsetX ~= offsetOldX or offsetY ~= offsetOldY then
		offsetChanged = true
		for i = 2, lightWorld.getLightCount() do
			lightWorld.setLightPosition(i, lightWorld.getLightX(i) + (offsetX - offsetOldX), lightWorld.getLightY(i) + (offsetY - offsetOldY))
		end
	else
		offsetChanged = false
	end

    for i = 1, lightWorld.getLightCount() do
		lightWorld.setLightDirection(i, lightDirection)
    end

	tileX = tileX + dt * 32.0
	tileY = tileY + dt * 8.0

    for i = 1, phyCnt do
		if phyBody[i] and (phyBody[i]:isAwake() or offsetChanged) then
			if offsetChanged then
				phyBody[i]:setX(phyBody[i]:getX() + (offsetX - offsetOldX))
				phyBody[i]:setY(phyBody[i]:getY() + (offsetY - offsetOldY))
			end
			if phyLight[i].getType() == "polygon" then
				phyLight[i].setPoints(phyBody[i]:getWorldPoints(phyShape[i]:getPoints()))
			elseif phyLight[i].getType() == "circle" then
				phyLight[i].setPosition(phyBody[i]:getX(), phyBody[i]:getY())
			elseif phyLight[i].getType() == "image" then
				phyLight[i].setPosition(phyBody[i]:getX(), phyBody[i]:getY())
			elseif phyLight[i].getType() == "refraction" then
				--phyLight[i].setPosition(phyBody[i]:getX(), phyBody[i]:getY())
			end
		end
		if phyLight[i].getType() == "refraction" then
			--if math.mod(i, 2) == 0  then
				phyLight[i].setNormalTileOffset(tileX, tileY)
			--end
			if offsetChanged then
				phyLight[i].setPosition(phyLight[i].getX() + (offsetX - offsetOldX), phyLight[i].getY() + (offsetY - offsetOldY))
			end
		end
    end

	if physicOn then
		physicWorld:update(dt)
	end

	offsetOldX = offsetX
	offsetOldY = offsetY
end

function love.draw()
	-- update lightmap (don't need deltatime)
	if lightOn then
		lightWorld.update()
	end

	-- set shader buffer
	if bloomOn then
		love.postshader.setBuffer("render")
	end

	love.graphics.setBlendMode("alpha")
	if normalOn then
		love.graphics.setColor(127, 127, 255)
		love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
	else
		love.graphics.setColor(255, 255, 255)
		if textureOn then
			love.graphics.draw(imgFloor, quadScreen, offsetX % 32 - 32, offsetY % 24 - 24)
		else
			love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
		end
	end

	for i = 1, phyCnt do
		if phyLight[i].getType() == "refraction" then
			if not normalOn then
				--if math.mod(i, 2) == 0  then
					love.graphics.setBlendMode("alpha")
					love.graphics.setColor(255, 255, 255, 191)
					love.graphics.draw(water, phyLight[i].x - phyLight[i].ox, phyLight[i].y - phyLight[i].oy)
				--else
					--love.graphics.setBlendMode("multiplicative")
					--math.randomseed(i)
					--love.graphics.setColor(math.random(0, 255), math.random(0, 255), math.random(0, 255))
					--love.graphics.rectangle("fill", phyLight[i].x - phyLight[i].ox, phyLight[i].y - phyLight[i].oy, 128, 128)
				--end
			end
		end
	end

	-- draw lightmap shadows
	if lightOn and not normalOn then
		lightWorld.drawShadow()
	end

	for i = 1, phyCnt do
		math.randomseed(i)
		love.graphics.setColor(math.random(0, 255), math.random(0, 255), math.random(0, 255))
		if phyLight[i].getType() == "polygon" then
			love.graphics.polygon("fill", phyLight[i].getPoints())
		elseif phyLight[i].getType() == "circle" then
			love.graphics.circle("fill", phyLight[i].getX(), phyLight[i].getY(), phyLight[i].getRadius())
		end
	end

	-- draw lightmap shine
	if lightOn and not normalOn then
		lightWorld.drawShine()
	end

	love.graphics.setBlendMode("alpha")
	for i = 1, phyCnt do
		if phyLight[i].getType() == "image" and not phyLight[i].material then
			if not normalOn then
				math.randomseed(i)
				love.graphics.setColor(math.random(127, 255), math.random(127, 255), math.random(127, 255))
				love.graphics.draw(phyLight[i].img, phyLight[i].x - phyLight[i].ix, phyLight[i].y - phyLight[i].iy)
			elseif phyLight[i].normal then
				love.graphics.setColor(255, 255, 255)
				love.graphics.draw(phyLight[i].normal, phyLight[i].x - phyLight[i].nx, phyLight[i].y - phyLight[i].ny)
			end
		end
	end

	lightWorld.drawMaterial()
	
	-- draw pixel shadow
	if lightOn and not normalOn then
		lightWorld.drawPixelShadow()
	end

	-- draw glow
	if lightOn and not normalOn then
		lightWorld.drawGlow()
	end

	-- draw reflection
	lightWorld.drawReflection()

	-- draw refraction
	lightWorld.drawRefraction()

	-- draw help
	if helpOn then
		love.graphics.setBlendMode("alpha")
		love.graphics.setColor(0, 0, 0, 191)
		love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), 44)
		love.graphics.rectangle("fill", 0, love.graphics.getHeight() - 68, 240, 68)
		love.graphics.rectangle("fill", love.graphics.getWidth() - 244, love.graphics.getHeight() - 84, 244, 84)
		love.graphics.setColor(0, 255, 0)
		love.graphics.print("F1: Help (on)", 4 + 152 * 0, 4)
		if physicOn then
			love.graphics.setColor(0, 255, 0)
			love.graphics.print("F2: Physic (on)", 4 + 152 * 1, 4)
		else
			love.graphics.setColor(255, 0, 0)
			love.graphics.print("F2: Physic (off)", 4 + 152 * 1, 4)
		end
		if lightOn then
			love.graphics.setColor(0, 255, 0)
			love.graphics.print("F3: Light (on)", 4 + 152 * 2, 4)
		else
			love.graphics.setColor(255, 0, 0)
			love.graphics.print("F3: Light (off)", 4 + 152 * 2, 4)
		end
		if gravityOn == 1.0 then
			love.graphics.setColor(0, 255, 0)
			love.graphics.print("F4: Gravity (on)", 4 + 152 * 3, 4)
		else
			love.graphics.setColor(255, 0, 0)
			love.graphics.print("F4: Gravity (off)", 4 + 152 * 3, 4)
		end
		if shadowBlur >= 1.0 then
			love.graphics.setColor(0, 255, 0)
			love.graphics.print("F5: Shadowblur (" .. shadowBlur .. ")", 4 + 152 * 4, 4)
		else
			love.graphics.setColor(255, 0, 0)
			love.graphics.print("F5: Shadowblur (off)", 4 + 152 * 4, 4)
		end
		if bloomOn > 0.0 then
			love.graphics.setColor(0, 255, 0)
			love.graphics.print("F6: Bloom (" .. (bloomOn * 4) .. ")", 4 + 152 * 0, 4 + 20 * 1)
		else
			love.graphics.setColor(255, 0, 0)
			love.graphics.print("F6: Bloom (off)", 4 + 152 * 0, 4 + 20 * 1)
		end
		if textureOn then
			love.graphics.setColor(0, 255, 0)
			love.graphics.print("F7: Texture (on)", 4 + 152 * 1, 4 + 20 * 1)
		else
			love.graphics.setColor(255, 0, 0)
			love.graphics.print("F7: Texture (off)", 4 + 152 * 1, 4 + 20 * 1)
		end
		if normalOn then
			love.graphics.setColor(0, 255, 0)
			love.graphics.print("F8: Normal (on)", 4 + 152 * 2, 4 + 20 * 1)
		else
			love.graphics.setColor(255, 0, 0)
			love.graphics.print("F8: Normal (off)", 4 + 152 * 2, 4 + 20 * 1)
		end
		if glowBlur >= 1.0 then
			love.graphics.setColor(0, 255, 0)
			love.graphics.print("F9: Glow Blur (" .. glowBlur .. ")", 4 + 152 * 3, 4 + 20 * 1)
		else
			love.graphics.setColor(255, 0, 0)
			love.graphics.print("F9: Glow Blur (off)", 4 + 152 * 3, 4 + 20 * 1)
		end
		love.graphics.setColor(255, 0, 255)
		love.graphics.print("F11: Clear obj.", 4 + 152 * 4, 4 + 20 * 2)
		love.graphics.print("F12: Clear lights", 4 + 152 * 4, 4 + 20 * 3)
		love.graphics.setColor(0, 127, 255)
		love.graphics.print("WASD Keys: Move objects", 4, love.graphics.getHeight() - 20 * 3)
		love.graphics.print("Arrow Keys: Move map", 4, love.graphics.getHeight() - 20 * 2)
		love.graphics.print("0-9 Keys: Add object", 4, love.graphics.getHeight() - 20 * 1)
		love.graphics.setColor(255, 127, 0)
		love.graphics.print("M.left: Add cube", love.graphics.getWidth() - 240, love.graphics.getHeight() - 20 * 4)
		love.graphics.print("M.middle: Add light", love.graphics.getWidth() - 240, love.graphics.getHeight() - 20 * 3)
		love.graphics.print("M.right: Add circle", love.graphics.getWidth() - 240, love.graphics.getHeight() - 20 * 2)
		love.graphics.print("M.scroll: Change smooth", love.graphics.getWidth() - 240, love.graphics.getHeight() - 20 * 1)
		love.graphics.setColor(255, 127, 0)
	else
		love.graphics.setColor(255, 255, 255, 191)
		love.graphics.print("F1: Help", 4, 4)
	end

	-- draw shader
	if colorAberration > 0.0 then
		-- vert / horz blur
		love.postshader.addEffect("blur", 2.0, 2.0)
		love.postshader.addEffect("chromatic", math.sin(lightDirection * 10.0) * colorAberration, math.cos(lightDirection * 10.0) * colorAberration, math.cos(lightDirection * 10.0) * colorAberration, math.sin(lightDirection * 10.0) * -colorAberration, math.sin(lightDirection * 10.0) * colorAberration, math.cos(lightDirection * 10.0) * -colorAberration)
	end

	if bloomOn > 0.0 then
		-- blur, strength
		love.postshader.addEffect("bloom", 2.0, bloomOn)
	end

	love.postshader.draw()
end

function love.mousepressed(x, y, c)
	if c == "m" then
		-- add light
		local r = lightWorld.getLightCount() % 3
		local light

		if r == 0 then
			light = lightWorld.newLight(x, y, 31, 127, 63, lightRange)
		elseif r == 1 then
			light = lightWorld.newLight(x, y, 127, 63, 31, lightRange)
		else
			light = lightWorld.newLight(x, y, 31, 63, 127, lightRange)
		end
		light.setSmooth(lightSmooth)
		light.setGlowStrength(0.3)
	elseif c == "l" then
		-- add rectangle
		phyCnt = phyCnt + 1
		phyLight[phyCnt] = lightWorld.newPolygon()
		phyBody[phyCnt] = love.physics.newBody(physicWorld, x, y, "dynamic")
		phyShape[phyCnt] = love.physics.newRectangleShape(0, 0, math.random(32, 64), math.random(32, 64))
		phyFixture[phyCnt] = love.physics.newFixture(phyBody[phyCnt], phyShape[phyCnt])
		phyFixture[phyCnt]:setRestitution(0.5)
	elseif c == "r" then
		-- add circle
		cRadius = math.random(8, 32)
		phyCnt = phyCnt + 1
		phyLight[phyCnt] = lightWorld.newCircle(x, y, cRadius)
		phyBody[phyCnt] = love.physics.newBody(physicWorld, x, y, "dynamic")
		phyShape[phyCnt] = love.physics.newCircleShape(0, 0, cRadius)
		phyFixture[phyCnt] = love.physics.newFixture(phyBody[phyCnt], phyShape[phyCnt])
		phyFixture[phyCnt]:setRestitution(0.5)
	elseif c == "wu" then
		if lightSmooth < 4.0 then
			lightSmooth = lightSmooth * 1.1
			mouseLight.setSmooth(lightSmooth)
		end
	elseif c == "wd" then
		if lightSmooth > 0.5 then
			lightSmooth = lightSmooth / 1.1
			mouseLight.setSmooth(lightSmooth)
		end
	end
end

function love.keypressed(k, u)
	-- debug options
	if k == "f1" then
		helpOn = not helpOn
	elseif k == "f2" then
		physicOn = not physicOn
	elseif k == "f3" then
		lightOn = not lightOn
	elseif k == "f4" then
		gravityOn = 1 - gravityOn
		physicWorld:setGravity(0, gravityOn * 9.81 * 64)
	elseif k == "f5" then
		shadowBlur = math.max(1, shadowBlur * 2.0)
		if shadowBlur > 8.0 then
			shadowBlur = 0.0
		end
		lightWorld.setBlur(shadowBlur)
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
		lightWorld.setGlowStrength(glowBlur)
	elseif k == "f11" then
		physicWorld:destroy()
		lightWorld.clearBodys()
		initScene()
	elseif k == "f12" then
		lightWorld.clearLights()
		mouseLight = lightWorld.newLight(0, 0, 255, 191, 127, lightRange)
		mouseLight.setGlowStrength(0.3)
		mouseLight.setSmooth(lightSmooth)
	elseif k == "1" then
		-- add image
		phyCnt = phyCnt + 1
		phyLight[phyCnt] = lightWorld.newImage(circle, mx, my)
		phyLight[phyCnt].setNormalMap(circle_normal)
		phyLight[phyCnt].setShadowType("circle", 16)
		phyBody[phyCnt] = love.physics.newBody(physicWorld, mx, my, "dynamic")
		phyShape[phyCnt] = love.physics.newRectangleShape(0, 0, 32, 32)
		phyFixture[phyCnt] = love.physics.newFixture(phyBody[phyCnt], phyShape[phyCnt])
		phyFixture[phyCnt]:setRestitution(0.5)
	elseif k == "2" then
		local r = lightWorld.getBodyCount() % 2
		if r == 0 then
			-- add image
			phyCnt = phyCnt + 1
			phyLight[phyCnt] = lightWorld.newImage(cone, mx, my, 24, 12, 12, 16)
			phyLight[phyCnt].setNormalMap(cone_normal)
			phyLight[phyCnt].setShadowType("circle", 12, 0, -8)
			phyBody[phyCnt] = love.physics.newBody(physicWorld, mx, my, "dynamic")
			phyShape[phyCnt] = love.physics.newRectangleShape(0, 0, 24, 32)
			phyFixture[phyCnt] = love.physics.newFixture(phyBody[phyCnt], phyShape[phyCnt])
			phyFixture[phyCnt]:setRestitution(0.5)
		elseif r == 1 then
			-- add image
			phyCnt = phyCnt + 1
			phyLight[phyCnt] = lightWorld.newImage(chest, mx, my, 32, 24, 16, 0)
			phyLight[phyCnt].setNormalMap(chest_normal)
			phyBody[phyCnt] = love.physics.newBody(physicWorld, mx, my, "dynamic")
			phyShape[phyCnt] = love.physics.newRectangleShape(0, 0, 32, 24)
			phyFixture[phyCnt] = love.physics.newFixture(phyBody[phyCnt], phyShape[phyCnt])
			phyFixture[phyCnt]:setRestitution(0.5)
		end
	elseif k == "3" then
		-- add image
		local r = lightWorld.getBodyCount() % #material
		phyCnt = phyCnt + 1
		phyLight[phyCnt] = lightWorld.newImage(ape, mx, my, 160, 128, 80, 64)
		phyLight[phyCnt].setNormalMap(ape_normal)
		if r == 3 then
			phyLight[phyCnt].setGlowMap(ape_glow)
		end
		phyLight[phyCnt].setMaterial(material[r + 1])
		phyBody[phyCnt] = love.physics.newBody(physicWorld, mx, my, "dynamic")
		phyShape[phyCnt] = love.physics.newRectangleShape(0, 0, 32, 24)
		phyFixture[phyCnt] = love.physics.newFixture(phyBody[phyCnt], phyShape[phyCnt])
		phyFixture[phyCnt]:setRestitution(0.5)
		phyLight[phyCnt].setShadowType("image", 0, -16, 0.0)
	elseif k == "4" then
		-- add glow image
		local r = lightWorld.getBodyCount() % 5
		if r == 0 then
			phyCnt = phyCnt + 1
			phyLight[phyCnt] = lightWorld.newImage(machine, mx, my, 32, 24, 16, 0)
			phyLight[phyCnt].setNormalMap(machine_normal)
			phyLight[phyCnt].setGlowMap(machine_glow)
			phyBody[phyCnt] = love.physics.newBody(physicWorld, mx, my, "dynamic")
			phyShape[phyCnt] = love.physics.newRectangleShape(0, 0, 32, 24)
			phyFixture[phyCnt] = love.physics.newFixture(phyBody[phyCnt], phyShape[phyCnt])
			phyFixture[phyCnt]:setRestitution(0.5)
		elseif r == 1 then
			phyCnt = phyCnt + 1
			phyLight[phyCnt] = lightWorld.newImage(machine2, mx, my, 24, 12, 12, -4)
			phyLight[phyCnt].setNormalMap(machine2_normal)
			phyLight[phyCnt].setGlowMap(machine2_glow)
			phyBody[phyCnt] = love.physics.newBody(physicWorld, mx, my, "dynamic")
			phyShape[phyCnt] = love.physics.newRectangleShape(0, 0, 24, 32)
			phyFixture[phyCnt] = love.physics.newFixture(phyBody[phyCnt], phyShape[phyCnt])
			phyFixture[phyCnt]:setRestitution(0.5)
		elseif r == 2 then
			phyCnt = phyCnt + 1
			phyLight[phyCnt] = lightWorld.newImage(led, mx, my, 32, 6, 16, -8)
			phyLight[phyCnt].setNormalMap(led_normal)
			phyLight[phyCnt].setGlowMap(led_glow)
			phyBody[phyCnt] = love.physics.newBody(physicWorld, mx, my, "dynamic")
			phyShape[phyCnt] = love.physics.newRectangleShape(0, 0, 32, 6)
			phyFixture[phyCnt] = love.physics.newFixture(phyBody[phyCnt], phyShape[phyCnt])
			phyFixture[phyCnt]:setRestitution(0.5)
		elseif r == 3 then
			phyCnt = phyCnt + 1
			phyLight[phyCnt] = lightWorld.newImage(led2, mx, my, 32, 6, 16, -8)
			phyLight[phyCnt].setNormalMap(led_normal)
			phyLight[phyCnt].setGlowMap(led_glow2)
			phyBody[phyCnt] = love.physics.newBody(physicWorld, mx, my, "dynamic")
			phyShape[phyCnt] = love.physics.newRectangleShape(0, 0, 32, 6)
			phyFixture[phyCnt] = love.physics.newFixture(phyBody[phyCnt], phyShape[phyCnt])
			phyFixture[phyCnt]:setRestitution(0.5)
		elseif r == 4 then
			phyCnt = phyCnt + 1
			phyLight[phyCnt] = lightWorld.newImage(led3, mx, my, 32, 6, 16, -8)
			phyLight[phyCnt].setNormalMap(led_normal)
			phyLight[phyCnt].setGlowMap(led_glow3)
			phyBody[phyCnt] = love.physics.newBody(physicWorld, mx, my, "dynamic")
			phyShape[phyCnt] = love.physics.newRectangleShape(0, 0, 32, 6)
			phyFixture[phyCnt] = love.physics.newFixture(phyBody[phyCnt], phyShape[phyCnt])
			phyFixture[phyCnt]:setRestitution(0.5)
		end
	elseif k == "5" then
		-- add image
		phyCnt = phyCnt + 1
		phyLight[phyCnt] = lightWorld.newImage(cone_large, mx, my, 24, 128, 12, 64)
		phyLight[phyCnt].setNormalMap(cone_large_normal)
		phyLight[phyCnt].setShadowType("image", 0, -6, 0.0)
		phyBody[phyCnt] = love.physics.newBody(physicWorld, mx, my, "dynamic")
		phyShape[phyCnt] = love.physics.newRectangleShape(0, 0, 24, 32)
		phyFixture[phyCnt] = love.physics.newFixture(phyBody[phyCnt], phyShape[phyCnt])
		phyFixture[phyCnt]:setRestitution(0.5)
	elseif k == "6" then
		-- add image
		phyCnt = phyCnt + 1
		phyLight[phyCnt] = lightWorld.newImage(blopp, mx, my, 42, 16, 21, 0)
		phyLight[phyCnt].generateNormalMapGradient("gradient", "gradient")
		phyLight[phyCnt].setAlpha(0.5)
		phyBody[phyCnt] = love.physics.newBody(physicWorld, mx, my, "dynamic")
		phyShape[phyCnt] = love.physics.newRectangleShape(0, 0, 42, 29)
		phyFixture[phyCnt] = love.physics.newFixture(phyBody[phyCnt], phyShape[phyCnt])
		phyFixture[phyCnt]:setRestitution(0.5)
	elseif k == "7" then
		-- add image
		phyCnt = phyCnt + 1
		phyLight[phyCnt] = lightWorld.newImage(tile, mx, my)
		phyLight[phyCnt].setHeightMap(tile_normal, 2.0)
		phyLight[phyCnt].setGlowMap(tile_glow)
		phyLight[phyCnt].setShadow(false)
		phyLight[phyCnt].reflective = false
		phyBody[phyCnt] = love.physics.newBody(physicWorld, mx, my, "dynamic")
		phyShape[phyCnt] = love.physics.newRectangleShape(0, 0, 64, 64)
		phyFixture[phyCnt] = love.physics.newFixture(phyBody[phyCnt], phyShape[phyCnt])
		phyFixture[phyCnt]:setRestitution(0.5)
	elseif k == "8" then
		-- add rectangle
		phyCnt = phyCnt + 1
		phyLight[phyCnt] = lightWorld.newPolygon()
		phyLight[phyCnt].setAlpha(0.5)
		phyLight[phyCnt].setGlowStrength(1.0)
		phyBody[phyCnt] = love.physics.newBody(physicWorld, mx, my, "dynamic")
		math.randomseed(love.timer.getTime())
		phyShape[phyCnt] = love.physics.newRectangleShape(0, 0, math.random(32, 64), math.random(32, 64))
		phyFixture[phyCnt] = love.physics.newFixture(phyBody[phyCnt], phyShape[phyCnt])
		phyFixture[phyCnt]:setRestitution(0.5)
		math.randomseed(phyCnt)
		phyLight[phyCnt].setGlowColor(math.random(0, 255), math.random(0, 255), math.random(0, 255))
		math.randomseed(phyCnt)
		phyLight[phyCnt].setColor(math.random(0, 255), math.random(0, 255), math.random(0, 255))
	elseif k == "9" then
		-- add circle
		math.randomseed(love.timer.getTime())
		cRadius = math.random(8, 32)
		phyCnt = phyCnt + 1
		phyLight[phyCnt] = lightWorld.newCircle(mx, my, cRadius)
		phyLight[phyCnt].setAlpha(0.5)
		phyLight[phyCnt].setGlowStrength(1.0)
		math.randomseed(phyCnt)
		phyLight[phyCnt].setGlowColor(math.random(0, 255), math.random(0, 255), math.random(0, 255))
		math.randomseed(phyCnt)
		phyLight[phyCnt].setColor(math.random(0, 255), math.random(0, 255), math.random(0, 255))
		phyBody[phyCnt] = love.physics.newBody(physicWorld, mx, my, "dynamic")
		phyShape[phyCnt] = love.physics.newCircleShape(0, 0, cRadius)
		phyFixture[phyCnt] = love.physics.newFixture(phyBody[phyCnt], phyShape[phyCnt])
		phyFixture[phyCnt]:setRestitution(0.5)
	elseif k == "0" then
		phyCnt = phyCnt + 1
		phyLight[phyCnt] = lightWorld.newRefraction(refraction_normal, mx, my)
		phyLight[phyCnt].setReflection(true)
	elseif k == "l" then
		-- add light
		local r = lightWorld.getLightCount() % 3
		local light

		if r == 0 then
			light = lightWorld.newLight(mx, my, 31, 127, 63, lightRange)
		elseif r == 1 then
			light = lightWorld.newLight(mx, my, 127, 63, 31, lightRange)
		else
			light = lightWorld.newLight(mx, my, 31, 63, 127, lightRange)
		end
		light.setSmooth(lightSmooth)
		light.setGlowStrength(0.3)
		math.randomseed(love.timer.getTime())
		light.setAngle(math.random(1, 5) * 0.1 * math.pi)
	elseif k == "c" then
		if colorAberration == 0.0 then
			colorAberration = 3.0
		end
	end
end