local PostShader = require "lib/postshader"
local colorAberration = 0
local post_shader, render_buffer
local img

local function load()
  post_shader = PostShader()
  render_buffer = love.graphics.newCanvas(love.graphics.getWidth(), love.graphics.getHeight())
  img = love.graphics.newImage("examples/gfx/kingscard.jpeg")
end

local function keypressed(k)
  if k == "1" then
    post_shader:toggleEffect("four_colors", {0.05, 0.21, 0.05}, {0.18, 0.38, 0.18}, {0.54, 0.67, 0.05}, {0.60, 0.73, 0.05})
  elseif k == "2" then
    post_shader:toggleEffect("monochrome")
  elseif k == "3" then
    post_shader:toggleEffect("scanlines")
  elseif k == "4" then
    post_shader:toggleEffect("tilt_shift", 4.0)
  elseif k == "5" then
    post_shader:toggleEffect("bloom", 2.0, 0.25)
  elseif k == "6" then
    post_shader:toggleEffect("blur", 10.0, 10.0)
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
    colorAberration = 3.0
    post_shader:addEffect("blur", 2.0, 2.0)
    post_shader:addEffect("chromatic_aberration")
  end
end

local function update(dt)
  love.window.setTitle("Light vs. Shadow Engine (FPS:" .. love.timer.getFPS() .. ")")
  colorAberration = math.max(0.0, colorAberration - dt * 10.0)
  if colorAberration <= 0.0 then
    post_shader:removeEffect("blur")
    post_shader:removeEffect("chromatic_aberration")
  end
end

local function draw()
  local w, h = love.graphics.getWidth(), love.graphics.getHeight()
  love.graphics.setCanvas(render_buffer)
  love.graphics.clear()
  love.graphics.setColor(1, 1, 1)
  love.graphics.draw(img, 250, 100, 0, 0.5)
  love.graphics.setCanvas()
  post_shader:drawWith(render_buffer)
  love.graphics.setBlendMode("alpha")
  love.graphics.setColor(0, 0, 0, 0.74)
  love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), 24)
  love.graphics.setColor(0, 1, 0)
  love.graphics.print("To toggle postshaders, use 0-9 and q->y, c for chromatic aberration")
end

return {
  load = load,
  update = update,
  draw = draw,
  keypressed = keypressed,
}
