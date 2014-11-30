-- Example: normal map generation testing
local LightWorld = require "lib"
local util = require "lib/util"
local normal_map = require "lib/normal_map"

function love.load()
  z = 1
	lightWorld = LightWorld({
    drawBackground = drawBackground,
    drawForeground = drawForeground,
    ambient = {55,55,55},
    refractionStrength = 32.0,
    reflectionVisibility = 0.75,
  })

	-- create light
	lightMouse = lightWorld:newLight(0, 0, 255, 127, 63, 300)
	lightMouse:setGlowStrength(0.3)

  radius = 50
	circle_canvas = love.graphics.newCanvas(radius*2, radius*2)
  util.drawto(circle_canvas, 0, 0, 1, function()
    love.graphics.circle('fill', radius, radius, radius) 
  end)
  circle_image = love.graphics.newImage(circle_canvas:getImageData()) 

	local t = lightWorld:newCircle(150, 150, radius)
  t:setNormalMap(normal_map.generateFlat(circle_image, "top"))
end

function love.mousepressed(x, y, c)
	if c == "wu" then
    z = z + 1
	elseif c == "wd" then
    z = z - 1
	end
end

function love.update(dt)
	love.window.setTitle("Light vs. Shadow Engine (FPS:" .. love.timer.getFPS() .. ")")
	lightMouse:setPosition(love.mouse.getX(), love.mouse.getY(), z)
end

function love.draw()
  lightWorld:draw()
end

function drawBackground(l,t,w,h)
  love.graphics.setColor(255, 255, 255)
  love.graphics.rectangle("fill", l, t, w, h)
end

function drawForeground(l,t,w,h)
  love.graphics.setColor(0, 255, 0)
  love.graphics.circle('fill', 150,  150, 50)
end


