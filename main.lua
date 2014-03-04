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

	myPoly1 = lightWorld.newPolygon(wall1.body:getWorldPoints(wall1.shape:getPoints()))
	myPoly2 = lightWorld.newPolygon(wall2.body:getWorldPoints(wall2.shape:getPoints()))
	myPoly3 = lightWorld.newPolygon(wall3.body:getWorldPoints(wall3.shape:getPoints()))
	myPoly4 = lightWorld.newPolygon(wall4.body:getWorldPoints(wall4.shape:getPoints()))

	phyCnt = 0
	phyLight = {}
	phyBody = {}
	phyShape = {}
	phyFixture = {}
end

function love.load()
    love.graphics.setBackgroundColor(0, 0, 0)
	quadScreen = love.graphics.newQuad(0, 0, love.window.getWidth(), love.window.getHeight(), 32, 32)
	imgFloor = love.graphics.newImage("floor.png")
	imgFloor:setWrap("repeat", "repeat")

	-- light world
	lightRange = 400
	lightSmooth = 1.0
	lightWorld = love.light.newWorld()
	lightWorld.setAmbientColor(15, 15, 15)
	mouseLight = lightWorld.newLight(0, 0, 255, 127, 63, lightRange)
	mouseLight.setGlowStrength(0.3)

	-- init physic world
	initScene()

	helpOn = true
	physicOn = true
	lightOn = true
	gravityOn = 1
	shadowBlurOn = true
	bloomOn = true
	textureOn = true
end

function love.update(dt)
	love.window.setTitle("FPS:" .. love.timer.getFPS())
	mouseLight.setPosition(love.mouse.getX(), love.mouse.getY())

    for i = 1, phyCnt do
		if phyBody[i]:isAwake() then
			if phyShape[i]:getType() == "polygon" then
				phyLight[i].setPoints(phyBody[i]:getWorldPoints(phyShape[i]:getPoints()))
			else
				phyLight[i].setPosition(phyBody[i]:getX(), phyBody[i]:getY())
			end
		end
    end

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

	if physicOn then
		physicWorld:update(dt)
	end

	-- update lightmap
	if lightOn then
		lightWorld.update(dt)
	end
end

function love.draw()
	-- set shader buffer
	if bloomOn then
		love.postshader.setBuffer("render")
	end

	love.graphics.setBlendMode("alpha")
	love.graphics.setColor(255, 255, 255)
	if textureOn then
		love.graphics.draw(imgFloor, quadScreen)
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
		else
			love.graphics.circle("fill", phyLight[i].getX(), phyLight[i].getY(), phyLight[i].getRadius())
		end
	end

	-- draw lightmap shine
	if lightOn then
		lightWorld.drawShine()
	end

	-- draw help
	if helpOn then
		love.graphics.setColor(0, 0, 0, 191)
		love.graphics.rectangle("fill", 8, 8, 210, 16 * 15)
		love.graphics.setColor(255, 255, 255)
		love.graphics.print("WASD: Move objects", 16, 16)
		love.graphics.print("F1: Help on/off", 16, 32)
		love.graphics.print("F2: Physic on/off", 16, 48)
		love.graphics.print("F3: Light on/off", 16, 64)
		love.graphics.print("F4: Clear objects", 16, 80)
		love.graphics.print("F5: Clear lights", 16, 96)
		love.graphics.print("F6: Gravity on/off", 16, 112)
		love.graphics.print("F7: Shadowblur on/off", 16, 128)
		love.graphics.print("F8: Bloom on/off", 16, 144)
		love.graphics.print("F9: Texture on/off", 16, 160)
		love.graphics.print("M.left: Add cube", 16, 176)
		love.graphics.print("M.middle: Add light", 16, 192)
		love.graphics.print("M.right: Add circle", 16, 208)
		love.graphics.print("M.scroll: Change smooth", 16, 224)
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
		lightSmooth = lightSmooth * 1.1
		mouseLight.setSmooth(lightSmooth)
	elseif c == "wd" then
		lightSmooth = lightSmooth / 1.1
		mouseLight.setSmooth(lightSmooth)
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
		physicWorld:destroy()
		lightWorld.clearObjects()
		initScene()
	elseif k == "f5" then
		lightWorld.clearLights()
		mouseLight = lightWorld.newLight(0, 0, 127, 63, 0, lightRange)
		mouseLight.setGlowStrength(0.3)
	elseif k == "f6" then
		gravityOn = 1 - gravityOn
		physicWorld:setGravity(0, gravityOn * 9.81 * 64)
	elseif k == "f7" then
		shadowBlurOn = not shadowBlurOn
		lightWorld.setBlur(shadowBlurOn)
	elseif k == "f8" then
		bloomOn = not bloomOn
	elseif k == "f9" then
		textureOn = not textureOn
	end
end