local List = require('examples.lib.list')
local LightWorld = require('lib')
local examples = {
  ["Animation Example"] = "animation.lua",
  ["Complex Example"] = "complex.lua",
  ["Gamera Example"] = "gamera.lua",
  ["Hump Example"] = "hump.lua",
  ["Normal Map Example"] = "normalMap.lua",
  ["Only Postshader Example"] = "postshaders.lua",
  ["Simple Example"] = "simple.lua",
  ["STI Example"] = "simple_tiled_impl.lua",
}
local list, smallfont, bigfont, bigball, lightWorld, lightMouse

local function start(file)
  local state = love.filesystem.load("examples/" .. file)()
  love.update = state.update
  love.draw = state.draw
  love.keyreleased = state.keyrelease
  love.mousepressed = state.mousepressed
  love.mousereleased = state.mousereleased
  love.wheelmoved = state.wheelmoved
  love.keypressed = function(k)
    if k == "escape"then
      if file ~= "examples_list.lua" then start("examples_list.lua") else love.event.quit() end
    end
    if state.keypressed ~= nil then state.keypressed(k) end
  end
  state.load()
end

local function load()
  list = List:new(50, 100, 400, 23)
  smallfont = love.graphics.newFont(12)
  bigfont = love.graphics.newFont(24)
  list.font = smallfont
  bigball = love.graphics.newImage("examples/gfx/love-big-ball.png")
  local n = 0
  for c, v in pairs(examples) do
    n = n + 1
    local title = string.format("%04d", n) .. " " .. c .. " (" .. v .. ")"
    list:add(title, v, function() start(v) end)
  end
  love.window.setTitle("LOVE Example Browser")
  lightWorld = LightWorld({ambient = {0.49, 0.49, 0.49}})
  lightMouse = lightWorld:newLight(20, 20, 1, 0.49, 0.24, 500)
  lightWorld.post_shader:toggleEffect("scanlines")
  lightMouse:setSmooth(2)
  lightWorld:newCircle(620, 200, bigball:getWidth()*0.5)
end

local function update(dt)
  list:update(dt)
  lightMouse:setPosition(love.mouse.getX(), love.mouse.getY())
  lightWorld:update(dt)
end

local function draw()
  lightWorld:draw(function()
    love.graphics.setBackgroundColor(0, 0, 0)
    love.graphics.setColor(0.18, 0.61, 1)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(bigfont)
    love.graphics.print("Examples:", 50, 30)
    love.graphics.setFont(smallfont)
    love.graphics.print("Browse and click on the example you \nwant to run. To return the the example \nselection screen, press escape.", 500, 80)
    list:draw()
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(bigball, 620, 200, love.timer.getTime()/5, 1, 1, bigball:getWidth() * 0.5, bigball:getHeight() * 0.5)
  end)
end

return {
  start = start,
  draw = draw,
  update = update,
  load = load,
  mousepressed = function(x, y, b) list:mousepressed(x, y, b) end,
}
