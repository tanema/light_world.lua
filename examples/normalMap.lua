-- Example: Normal map Example
local LightWorld = require "lib"
local image, image_normal
local lightWorld, lightMouse, imageBody, font
local rotation = 0

local function load()
	-- load images
	image = love.graphics.newImage("examples/img/normalMap/rock.png")
	image_normal = love.graphics.newImage("examples/img/normalMap/normal.png")
	-- load font
	font = love.graphics.newImageFont("examples/img/complex/font.png", " abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.,!?-+/():;%&`'*#=[]\"")
	love.graphics.setFont(font)
	-- create light world
	lightWorld = LightWorld({ambient = {0.21,0.21,0.21}})
	-- create light
	lightMouse = lightWorld:newLight(0, 0, 160, 160, 160, 300)
	lightMouse.normalInvert = true
	-- create shadow bodys
	local w, h = love.graphics.getWidth(), love.graphics.getHeight()
	imageBody = lightWorld:newImage(image, w/2, h/2)
	imageBody:setNormalMap(image_normal)
end

local function update(dt)
	love.window.setTitle("Light vs. Shadow Engine (FPS:" .. love.timer.getFPS() .. ")")
	lightWorld:update(dt)
	lightMouse:setPosition(love.mouse.getX(), love.mouse.getY())
	
	-- Handle arrow key rotation
	if love.keyboard.isDown("left") then
		rotation = rotation - 2 * dt
	end
	if love.keyboard.isDown("right") then
		rotation = rotation + 2 * dt
	end
	imageBody:setRotation(rotation)
end

local function draw()
	love.graphics.clear(0.21,0.21,0.21)
	lightWorld:draw(function(l, t, w, h, s)
		love.graphics.setColor(1, 1, 1)
		love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
		love.graphics.draw(image, w/2, h/2, rotation, 1, 1, image:getWidth()/2, image:getHeight()/2)
	end)
	love.graphics.setBlendMode("alpha")
	love.graphics.setColor(0, 0.5, 1)
	love.graphics.print("Arrow Keys: Rotate Object", 4, love.graphics.getHeight() - 20 * 1)
end

return {
	load = load,
	update = update,
	draw = draw,
}
