local gamera = require "examples/vendor/gamera"
local LightWorld = require "lib"
local objects = {}
local obj = require "examples.lib.object"
local keyboard = require "examples.lib.keyboard"
local cam, font, quadScreen, imgFloor, imgLight
local lightRange = 300
local lightDirection = 0.0
local colorAberration = 0.0
local lightWorld, mouseLight

local function load()
	math.randomseed(love.timer.getTime())
  cam = gamera.new(0, 0, love.graphics.getWidth(), love.graphics.getHeight())
  love.graphics.setBackgroundColor(0, 0, 0)
	love.graphics.setDefaultFilter("nearest", "nearest")
	font = love.graphics.newImageFont("examples/img/complex/font.png", " abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.,!?-+/():;%&`'*#=[]\"")
	love.graphics.setFont(font)
	quadScreen = love.graphics.newQuad(0, 0, love.graphics.getWidth() + 32, love.graphics.getHeight() + 24, 32, 24)
	imgFloor = love.graphics.newImage("examples/img/complex/floor.png")
	imgFloor:setWrap("repeat", "repeat")
	imgLight = love.graphics.newImage("examples/img/complex/light.png")
	lightWorld = LightWorld({ambient = {15,15,15}, refractionStrength = 16.0, reflectionVisibility = 0.75, shadowBlur = 2.0})
	mouseLight = lightWorld:newLight(0, 0, 1, 191/ 255, 0.5, lightRange)
	mouseLight:setGlowStrength(0.3)
	mouseLight.z = 63
end

local function update(dt)
	love.window.setTitle("Light vs. Shadow Engine (FPS:" .. love.timer.getFPS() .. ")")
  local x, y, scale = keyboard.update(dt)
  cam:setScale(scale)
  cam:setPosition(x, y)
  local mx, my = cam:toScreen(love.mouse.getX(),love.mouse.getY())
  lightWorld:setTranslation(offsetX,offsetY, scale)
	lightDirection = lightDirection + dt
	mouseLight:setPosition(mx, my, 1 + (math.sin(lightDirection)+1.0))
  for i, o in ipairs(objects) do o:update(dt) end
	colorAberration = math.max(0.0, colorAberration - dt * 10.0)
	if colorAberration > 0.0 then
		lightWorld.post_shader:addEffect("blur", 2.0, 2.0)
		lightWorld.post_shader:addEffect("chromatic_aberration",
      {math.sin(lightDirection * 10.0) * colorAberration, math.cos(lightDirection * 10.0) * colorAberration},
      {math.cos(lightDirection * 10.0) * colorAberration, math.sin(lightDirection * 10.0) * -colorAberration},
      {math.sin(lightDirection * 10.0) * colorAberration, math.cos(lightDirection * 10.0) * -colorAberration})
  else
		lightWorld.post_shader:removeEffect("blur")
		lightWorld.post_shader:removeEffect("chromatic_aberration")
	end
  lightWorld:update(dt)
end

local function draw()
  cam:draw(function(l,t,w,h)
		lightWorld:draw(function(l, t, w, h, s)
			love.graphics.setBlendMode("alpha")
			love.graphics.setColor(1, 1, 1)
			love.graphics.draw(imgFloor, quadScreen, 0,0)
			for i, ob in ipairs(objects) do ob:draw() end
		end)
		local mx, my = cam:toScreen(love.mouse.getX(),love.mouse.getY())
		love.graphics.draw(imgLight, mx - 5, (my - 5) - (16.0 + (math.sin(lightDirection) + 1.0) * 64.0))
	end)
	love.graphics.setBlendMode("alpha")
	love.graphics.setColor(0, 0.5, 1)
	love.graphics.print("c: chromatic abberation", 4, love.graphics.getHeight() - 20 * 6)
	love.graphics.print("F1-F9: Shaders", 4, love.graphics.getHeight() - 20 * 5)
	love.graphics.print("F10: Clear Bodies", 4, love.graphics.getHeight() - 20 * 4)
	love.graphics.print("F11: Clear Lights", 4, love.graphics.getHeight() - 20 * 3)
	love.graphics.print("Arrow Keys: Move map", 4, love.graphics.getHeight() - 20 * 2)
	love.graphics.print("0-9 Keys: Add object", 4, love.graphics.getHeight() - 20 * 1)
	love.graphics.setColor(1, 0.5, 0)
	love.graphics.print("M.left: Add cube", love.graphics.getWidth()    - 180, love.graphics.getHeight() - 20 * 3)
	love.graphics.print("M.middle: Add light", love.graphics.getWidth() - 180, love.graphics.getHeight() - 20 * 2)
	love.graphics.print("M.right: Add circle", love.graphics.getWidth() - 180, love.graphics.getHeight() - 20 * 1)
end

local function mousepressed(x, y, c)
	if c == 3 then
		local light = lightWorld:newLight(x, y, math.random(), math.random(), math.random(), lightRange)
		light:setGlowStrength(0.3)
		if love.keyboard.isDown("rshift") or love.keyboard.isDown("lshift") then
			light:setAngle(math.random(1, 5) * 0.1 * math.pi)
			light:setDirection(math.random(1, 5) * 0.1 * math.pi)
		end
	elseif c == 1 then table.insert(objects, obj.Rect:new(lightWorld, x, y, math.random(32, 64), math.random(32, 64)))
	elseif c == 2 then table.insert(objects, obj.Circle:new(lightWorld, x, y, math.random(8, 32)))
	end
end

local function keypressed(k, u)
  local mx, my = cam:toScreen(love.mouse.getX(),love.mouse.getY())
  if k == "f1" then lightWorld.post_shader:toggleEffect("four_colors", {0.05, 0.21, 0.05}, {0.18, 0.38, 0.18}, {0.54, 0.67, 0.05}, {0.60, 0.73, 0.05})
  elseif k == "f2" then lightWorld.post_shader:toggleEffect("scanlines")
  elseif k == "f3" then lightWorld.post_shader:toggleEffect("bloom", 2.0, 0.25)
  elseif k == "f4" then lightWorld.post_shader:toggleEffect("black_and_white")
  elseif k == "f5" then lightWorld.post_shader:toggleEffect("curvature")
  elseif k == "f6" then lightWorld.post_shader:toggleEffect("edges")
  elseif k == "f7" then lightWorld.post_shader:toggleEffect("pip")
  elseif k == "f8" then lightWorld.post_shader:toggleEffect("pixellate")
  elseif k == "f9" then lightWorld.post_shader:toggleEffect("waterpaint")
	elseif k == "f10" then
		lightWorld:clearBodies()
		objects = {}
	elseif k == "f11" then
		lightWorld:clearLights()
		mouseLight = lightWorld:newLight(0, 0, 1, 191/255, 0.5, lightRange)
		mouseLight:setGlowStrength(0.3)
	elseif k == "1" then table.insert(objects, obj.ImageObject:new(lightWorld, "examples/img/complex/ape", mx, my, "image"))
	elseif k == "2" then table.insert(objects, obj.ImageObject:new(lightWorld, "examples/img/complex/chest", mx, my))
	elseif k == "3" then table.insert(objects, obj.ImageObject:new(lightWorld, "examples/img/complex/cone", mx, my, "circle"))
	elseif k == "4" then table.insert(objects, obj.ImageObject:new(lightWorld, "examples/img/complex/cube", mx, my))
	elseif k == "5" then table.insert(objects, obj.ImageObject:new(lightWorld, "examples/img/complex/cylinder", mx, my, "circle"))
	elseif k == "6" then table.insert(objects, obj.ImageObject:new(lightWorld, "examples/img/complex/screen1", mx, my))
	elseif k == "7" then table.insert(objects, obj.ImageObject:new(lightWorld, "examples/img/complex/screen2", mx, my))
	elseif k == "8" then table.insert(objects, obj.ImageObject:new(lightWorld, "examples/img/complex/screen3", mx, my))
	elseif k == "9" then table.insert(objects, obj.ImageObject:new(lightWorld, "examples/img/complex/tile", mx, my))
	elseif k == "0" then table.insert(objects, obj.Refraction:new(lightWorld, "examples/img/complex/water", mx, my))
	elseif k == "c" then colorAberration = 3.0
	end
end

return {
  load = load,
  update = update,
  draw = draw,
  keypressed = keypressed,
	mousepressed = mousepressed,
}
