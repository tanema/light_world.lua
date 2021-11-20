-- Example: Normal map Example
local LightWorld = require "lib"
local image, image_normal
local lightWorld, lightMouse

local function load()
	-- load images
	image = love.graphics.newImage("examples/img/normalMap/rock.png")
	image_normal = love.graphics.newImage("examples/img/normalMap/normal.png")
	-- create light world
	lightWorld = LightWorld({ambient = {0.21,0.21,0.21}})
	-- create light
	lightMouse = lightWorld:newLight(0, 0, 160, 160, 160, 300)
  lightMouse.normalInvert = true
	-- create shadow bodys
  local w, h = love.graphics.getWidth(), love.graphics.getHeight()
	lightWorld:newImage(image, w/2, h/2):setNormalMap(image_normal)
end

local function update(dt)
	love.window.setTitle("Light vs. Shadow Engine (FPS:" .. love.timer.getFPS() .. ")")
  lightWorld:update(dt)
	lightMouse:setPosition(love.mouse.getX(), love.mouse.getY())
end

local function draw()
	love.graphics.clear(0.21,0.21,0.21)
	lightWorld:draw(function(l, t, w, h, s)
		love.graphics.setColor(1, 1, 1)
		love.graphics.draw(image, w/2-(image:getWidth()/2), h/2-(image:getHeight()/2))
	end)
end

return {
	load = load,
	update = update,
	draw = draw,
}
