--
-- EXF: Example Framework
--
-- This should make examples easier and more enjoyable to use.
-- All examples in one application! Yaay!
--
-- Updated by Dresenpai
require "lib/postshader"
local LightWorld = require "lib"
local ProFi = require 'examples.vendor.ProFi'
local List = require 'examples.vendor.list'

exf = {}
exf.current = nil
exf.available = {}

function love.load()
  exf.list = List:new()
  exf.smallfont = love.graphics.newFont(12)
  exf.bigfont = love.graphics.newFont(24)
  exf.list.font = exf.smallfont

  exf.bigball = love.graphics.newImage("examples/gfx/love-big-ball.png")

  -- Find available demos.
  local files =  love.filesystem.getDirectoryItems("examples")
  local n = 0

  for i, v in ipairs(files) do
    is_file = (love.filesystem.getInfo("examples/".. v ).type == "file")
    if is_file then
      n = n + 1
      table.insert(exf.available, v);
      local file = love.filesystem.newFile(v, love.file_read)
      file:open("r")
      local contents = love.filesystem.read("examples/" .. v, 100)
      local s, e, c = string.find(contents, "Example: ([%a%p ]-)[\r\n]")
      file:close(file)
      if not c then c = "Untitled" end
      local title = string.format("%04d", n) .. " " .. c .. " (" .. v .. ")"
      exf.list:add(title, v)
    end
  end

  exf.load()
end

function exf.empty() end
function exf.keypressed(k) end
function exf.keyreleased(k) end
function exf.mousepressed(x, y, b) exf.list:mousepressed(x, y, b) end
function exf.mousereleased(x, y, b) exf.list:mousereleased(x, y, b) end

function exf.load()
  ProFi:stop()
  ProFi:writeReport( 'light_world_profiling_report.txt' )

  load = nil
  love.update = exf.update
  love.draw = exf.draw
  love.keypressed = exf.keypressed
  love.keyreleased = exf.keyreleased
  love.mousepressed = exf.mousepressed
  love.mousereleased = exf.mousereleased

  love.mouse.setVisible(true)
  love.window.setTitle("LOVE Example Browser")

  lightWorld = LightWorld({ambient = {0.49, 0.49, 0.49}})
  lightMouse = lightWorld:newLight(20, 20, 1, 0.49, 0.24, 500)
  lightMouse:setSmooth(2)
  circleTest = lightWorld:newCircle(800 - 128, 600 - 128, exf.bigball:getWidth()*0.5)
end

function exf.update(dt)
  exf.list:update(dt)
  lightMouse:setPosition(love.mouse.getX(), love.mouse.getY())
  lightWorld:update(dt)
end

function exf.draw()
  lightWorld:draw(function()
    love.graphics.setBackgroundColor(0, 0, 0)

    love.graphics.setColor(0.18, 0.61, 1)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(exf.bigfont)
    love.graphics.print("Examples:", 50, 30)

    love.graphics.setFont(exf.smallfont)
    love.graphics.print("Browse and click on the example you \nwant to run. To return the the example \nselection screen, press escape.", 500, 80)

    exf.list:draw()

    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(exf.bigball, 800 - 128, 600 - 128, love.timer.getTime()/5, 1, 1, exf.bigball:getWidth() * 0.5, exf.bigball:getHeight() * 0.5)
  end)
end

function exf.start(item, file)
  love.load = exf.empty
  love.update = exf.empty
  love.draw = exf.empty
  love.keypressed = exf.empty
  love.keyreleased = exf.empty
  love.mousepressed = exf.empty
  love.mousereleased = exf.empty

  love.filesystem.load("examples/" .. file)()
  love.graphics.setBackgroundColor(0,0,0)
  love.graphics.setColor(1, 1, 1)
  love.graphics.setLineWidth(1)
  love.graphics.setLineStyle("smooth")
  love.graphics.setBlendMode("alpha")
  love.mouse.setVisible(true)

  local o_keypressed = love.keypressed
  love.keypressed = function(k)
    if k == "escape" then
      exf.load()
    end
    o_keypressed(k)
  end

  love.load()
end
