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
	circle = love.graphics.newImage "gfx/circle.png"
	circle_normal = love.graphics.newImage "gfx/circle_normal.png"
	cone = love.graphics.newImage "gfx/cone.png"
	cone_normal = love.graphics.newImage "gfx/cone_normal.png"
	chest = love.graphics.newImage "gfx/chest.png"
	chest_normal = love.graphics.newImage "gfx/chest_normal.png"
	machine = love.graphics.newImage "gfx/machine.png"
	machine_normal = love.graphics.newImage "gfx/machine_normal.png"
	machine_glow = love.graphics.newImage "gfx/machine_glow.png"
	machine2 = love.graphics.newImage "gfx/machine2.png"
	machine2_normal = love.graphics.newImage "gfx/machine2_normal.png"
	machine2_glow = love.graphics.newImage "gfx/machine2_glow.png"

	-- light world
	lightRange = 300
	lightSmooth = 1.0
	lightWorld = love.light.newWorld()
	lightWorld.setAmbientColor(15, 15, 31)
	mouseLight = lightWorld.newLight(0, 0, 255, 127, 63, lightRange)
	mouseLight.setGlowStrength(0.3)
	mouseLight.setSmooth(lightSmooth)

	-- init physic world
	initScene()

	helpOn = false
	physicOn = false
	lightOn = true
	gravityOn = 1
	shadowBlur = 2.0
	bloomOn = true
	textureOn = true

	offsetX = 0.0
	offsetY = 0.0
	offsetOldX = 0.0
	offsetOldY = 0.0
	offsetChanged = false
end

function love.update(dt)
	love.window.setTitle("Light vs. Shadow Engine (FPS:" .. love.timer.getFPS() .. ")")
	mouseLight.setPosition(love.mouse.getX(), love.mouse.getY())
	mx = love.mouse.getX()
	my = love.mouse.getY()

	if love.keyboard.isDown("w") then
		for i = 1, phyCnt do
			phyBody[i]:applyForce(0, -2000)
		end
	elseif love.keyboard.isDown("s") then
		for i = 1, phyCnt do
			phyBody[i]:applyForce(0, 2000)
		end
	end

	if love.keyboard.isDown("a") then
		for i = 1, phyCnt do
			phyBody[i]:applyForce(-2000, 0)
		end
	elseif love.keyboard.isDown("d") then
		for i = 1, phyCnt do
			phyBody[i]:applyForce(2000, 0)
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

    for i = 1, phyCnt do
		if phyBody[i]:isAwake() or offsetChanged then
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
	love.graphics.setColor(255, 255, 255)
	if textureOn then
		love.graphics.draw(imgFloor, quadScreen, offsetX % 32 - 32, offsetY % 24 - 24)
	else
		love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
	end
	-- draw lightmap shadows
	if lightOn then
		lightWorld.drawShadow()
	end

	for i = 1, phyCnt do
		love.graphics.setColor(math.sin(i) * 255, math.cos(i) * 255, math.tan(i) * 255)
		if phyLight[i].getType() == "polygon" then
			love.graphics.polygon("fill", phyLight[i].getPoints())
		elseif phyLight[i].getType() == "circle" then
			love.graphics.circle("fill", phyLight[i].getX(), phyLight[i].getY(), phyLight[i].getRadius())
		end
	end

	-- draw lightmap shine
	if lightOn then
		lightWorld.drawShine()
	end

	for i = 1, phyCnt do
		if phyLight[i].getType() == "image" then
			love.graphics.setColor(223 + math.sin(i) * 31, 223 + math.cos(i) * 31, 223 + math.tan(i) * 31)
			love.graphics.draw(phyLight[i].img, phyLight[i].x - phyLight[i].ox2, phyLight[i].y - phyLight[i].oy2)
		end
	end

	-- draw pixel shadow
	if lightOn then
		lightWorld.drawPixelShadow()
	end

	-- draw glow
	if lightOn then
		lightWorld.drawGlow()
	end

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
		if bloomOn then
			love.graphics.setColor(0, 255, 0)
			love.graphics.print("F6: Bloom on", 4 + 152 * 0, 4 + 20 * 1)
		else
			love.graphics.setColor(255, 0, 0)
			love.graphics.print("F6: Bloom off", 4 + 152 * 0, 4 + 20 * 1)
		end
		if textureOn then
			love.graphics.setColor(0, 255, 0)
			love.graphics.print("F7: Texture on", 4 + 152 * 1, 4 + 20 * 1)
		else
			love.graphics.setColor(255, 0, 0)
			love.graphics.print("F7: Texture off", 4 + 152 * 1, 4 + 20 * 1)
		end
		love.graphics.setColor(255, 0, 255)
		love.graphics.print("F11: Clear obj.", 4 + 152 * 3, 4 + 20 * 1)
		love.graphics.print("F12: Clear lights", 4 + 152 * 4, 4 + 20 * 1)
		love.graphics.setColor(0, 127, 255)
		love.graphics.print("WASD Keys: Move objects", 4, love.graphics.getHeight() - 20 * 3)
		love.graphics.print("Arrow Keys: Move map", 4, love.graphics.getHeight() - 20 * 2)
		love.graphics.print("1-5 Keys: Add image", 4, love.graphics.getHeight() - 20 * 1)
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
	if bloomOn then
		love.postshader.draw("bloom")
	end
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
	elseif k == "f6" then
		bloomOn = not bloomOn
	elseif k == "f7" then
		textureOn = not textureOn
	elseif k == "f11" then
		physicWorld:destroy()
		lightWorld.clearObjects()
		initScene()
	elseif k == "f12" then
		lightWorld.clearLights()
		mouseLight = lightWorld.newLight(0, 0, 255, 127, 63, lightRange)
		mouseLight.setGlowStrength(0.3)
		mouseLight.setSmooth(lightSmooth)
	elseif k == "1" then
		-- add image
		phyCnt = phyCnt + 1
		phyLight[phyCnt] = lightWorld.newImage(circle, mx, my)
		phyLight[phyCnt].setNormalMap(circle_normal)
		phyBody[phyCnt] = love.physics.newBody(physicWorld, mx, my, "dynamic")
		phyShape[phyCnt] = love.physics.newRectangleShape(0, 0, 32, 32)
		phyFixture[phyCnt] = love.physics.newFixture(phyBody[phyCnt], phyShape[phyCnt])
		phyFixture[phyCnt]:setRestitution(0.5)
	elseif k == "2" then
		-- add image
		phyCnt = phyCnt + 1
		phyLight[phyCnt] = lightWorld.newImage(cone, mx, my, 24, 12, 12, 28)
		phyLight[phyCnt].setNormalMap(cone_normal)
		phyBody[phyCnt] = love.physics.newBody(physicWorld, mx, my, "dynamic")
		phyShape[phyCnt] = love.physics.newRectangleShape(0, 0, 24, 32)
		phyFixture[phyCnt] = love.physics.newFixture(phyBody[phyCnt], phyShape[phyCnt])
		phyFixture[phyCnt]:setRestitution(0.5)
	elseif k == "3" then
		-- add image
		phyCnt = phyCnt + 1
		phyLight[phyCnt] = lightWorld.newImage(chest, mx, my, 32, 24, 16, 36)
		phyLight[phyCnt].setNormalMap(chest_normal)
		phyBody[phyCnt] = love.physics.newBody(physicWorld, mx, my, "dynamic")
		phyShape[phyCnt] = love.physics.newRectangleShape(0, 0, 32, 24)
		phyFixture[phyCnt] = love.physics.newFixture(phyBody[phyCnt], phyShape[phyCnt])
		phyFixture[phyCnt]:setRestitution(0.5)
	elseif k == "4" then
		-- add image
		phyCnt = phyCnt + 1
		phyLight[phyCnt] = lightWorld.newImage(machine, mx, my, 32, 24, 16, 36)
		phyLight[phyCnt].setNormalMap(machine_normal)
		phyLight[phyCnt].setGlowMap(machine_glow)
		phyBody[phyCnt] = love.physics.newBody(physicWorld, mx, my, "dynamic")
		phyShape[phyCnt] = love.physics.newRectangleShape(0, 0, 32, 24)
		phyFixture[phyCnt] = love.physics.newFixture(phyBody[phyCnt], phyShape[phyCnt])
		phyFixture[phyCnt]:setRestitution(0.5)
	elseif k == "5" then
		-- add image
		phyCnt = phyCnt + 1
		phyLight[phyCnt] = lightWorld.newImage(machine2, mx, my, 24, 12, 12, 28)
		phyLight[phyCnt].setNormalMap(machine2_normal)
		phyLight[phyCnt].setGlowMap(machine2_glow)
		phyBody[phyCnt] = love.physics.newBody(physicWorld, mx, my, "dynamic")
		phyShape[phyCnt] = love.physics.newRectangleShape(0, 0, 24, 32)
		phyFixture[phyCnt] = love.physics.newFixture(phyBody[phyCnt], phyShape[phyCnt])
		phyFixture[phyCnt]:setRestitution(0.5)
	end
end