local LightWorld = require "lib"
local sti = require 'examples.vendor.sti'
local lightWorld, map, image_normal, lightMouse

local function load()
	-- create light world
  lightWorld = LightWorld({ambient = {0.49, 0.49, 0.49}})
	map = sti.new("examples/img/sti/map.lua")
	image_normal = love.graphics.newImage("examples/img/sti/border_NRM.png")
	-- create light
  lightMouse = lightWorld:newLight(0, 0, 1, 0.49, 0.24, 300)
	lightMouse:setGlowStrength(0.3)
	-- create light blocking bodies for sections of the map
  -- create walls
	lightWorld:newRectangle(400, 32, 800, 64):setNormalMap(image_normal, 800, 64)
	lightWorld:newRectangle(32, 272, 64, 416):setNormalMap(image_normal, 64, 416)
	lightWorld:newRectangle(400, 464, 800, 32):setNormalMap(image_normal, 800, 32)
	lightWorld:newRectangle(784, 272, 32, 416):setNormalMap(image_normal, 32, 416)
  -- create blocks
	lightWorld:newRectangle(224, 256, 128, 124):setNormalMap(image_normal, 128, 124)
	lightWorld:newRectangle(592, 224, 224, 64):setNormalMap(image_normal, 224, 64)
end

local function update(dt)
	love.window.setTitle("Light vs. Shadow Engine (FPS:" .. love.timer.getFPS() .. ")")
  map:update(dt)
  lightWorld:update(dt)
	lightMouse:setPosition(love.mouse.getX(), love.mouse.getY())
end

local function draw()
	love.graphics.setBackgroundColor(1, 1, 1)
	lightWorld:draw(function()
		map:draw()
	end)
end

return {
	load = load,
	mousepressed = mousepressed,
	update = update,
	draw = draw,
}
