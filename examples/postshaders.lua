-- Example: Only Postshader Example
local PostShader = require "lib/postshader"

function love.load()
  testShader = 0
  x = 0
  y = 0
  scale = 1
  colorAberration = 0.0
	-- load images
	image = love.graphics.newImage("gfx/machine2.png")
	quadScreen = love.graphics.newQuad(0, 0, love.window.getWidth() + 32, love.window.getHeight() + 24, 32, 24)
	imgFloor = love.graphics.newImage("gfx/floor.png")
	imgFloor:setWrap("repeat", "repeat")

  post_shader = PostShader()
  render_buffer = love.graphics.newCanvas(love.window.getWidth(), love.window.getHeight())
end

function love.keypressed(k)
  if k == "1" then
    post_shader:toggleEffect("four_colors", {15, 56, 15}, {48, 98, 48}, {139, 172, 15}, {155, 188, 15})
  elseif k == "2" then
    post_shader:toggleEffect("monochrome")
  elseif k == "3" then
    post_shader:toggleEffect("scanlines")
  elseif k == "4" then
    post_shader:toggleEffect("tilt_shift", 4.0)
  elseif k == "5" then
		post_shader:toggleEffect("bloom", 2.0, 0.25)
  elseif k == "6" then
		post_shader:toggleEffect("blur", 2.0, 2.0)
  elseif k == "7" then
		post_shader:toggleEffect("black_and_white")
  elseif k == "8" then
		post_shader:toggleEffect("curvature")
  elseif k == "9" then
		post_shader:toggleEffect("edges")
  elseif k == "0" then
		post_shader:toggleEffect("hdr_tv")
  elseif k == "q" then
		post_shader:toggleEffect("phosphor")
  elseif k == "w" then
		post_shader:toggleEffect("phosphorish")
  elseif k == "e" then
		post_shader:toggleEffect("pip")
  elseif k == "r" then
		post_shader:toggleEffect("pixellate")
  elseif k == "t" then
		post_shader:toggleEffect("radialblur")
  elseif k == "y" then
		post_shader:toggleEffect("waterpaint")
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

	if love.keyboard.isDown("-") then
		scale = scale - 0.01
	elseif love.keyboard.isDown("=") then
		scale = scale + 0.01
	end
                                                                       
	colorAberration = math.max(0.0, colorAberration - dt * 10.0)
	if colorAberration > 0.0 then
		post_shader:addEffect("blur", 2.0, 2.0)
		post_shader:addEffect("chromatic_aberration")
  else
		post_shader:removeEffect("blur")
		post_shader:removeEffect("chromatic_aberration")
	end

	lightMouse:setPosition(love.mouse.getX()/scale, love.mouse.getY()/scale)
end

function love.draw()
  local w, h = love.graphics.getWidth(), love.graphics.getHeight()
  render_buffer:clear()
  love.graphics.push()
    love.graphics.setCanvas(render_buffer)
    love.graphics.translate(x, y)
    love.graphics.scale(scale)

    love.graphics.setColor(255, 255, 255)
		love.graphics.draw(imgFloor, quadScreen, 0,0)

    love.graphics.setColor(63, 255, 127)
    love.graphics.circle("fill", 256, 256, 16)
    love.graphics.rectangle("fill", 512, 512, 64, 64)
    love.graphics.setColor(255, 255, 255)
    love.graphics.draw(image, 64 - image:getWidth() * 0.5, 64 - image:getHeight() * 0.5)
  love.graphics.pop()

  love.graphics.setCanvas()
  post_shader:drawWith(render_buffer)

  love.graphics.setBlendMode("alpha")
  love.graphics.setColor(0, 0, 0, 191)
  love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), 24)
  love.graphics.setColor(0, 255, 0)
  love.graphics.print("To toggle postshaders, use 0-9 and q->y, to scale use - and =, and to translate use arrows")
end
