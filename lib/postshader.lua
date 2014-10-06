--[[
The MIT License (MIT)

Copyright (c) 2014 Marcus Ihde

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]
local _PACKAGE = (...):match("^(.+)[%./][^%./]+") or ""
local class = require(_PACKAGE..'/class')

local post_shader = class()
post_shader.blurv                 = love.graphics.newShader(_PACKAGE.."/shaders/blurv.glsl")
post_shader.blurh                 = love.graphics.newShader(_PACKAGE.."/shaders/blurh.glsl")
post_shader.contrast              = love.graphics.newShader(_PACKAGE.."/shaders/contrast.glsl")
post_shader.chromatic_aberration  = love.graphics.newShader(_PACKAGE.."/shaders/chromatic_aberration.glsl")
post_shader.four_color            = love.graphics.newShader(_PACKAGE.."/shaders/four_colors.glsl")
post_shader.monochrome            = love.graphics.newShader(_PACKAGE.."/shaders/monochrome.glsl")
post_shader.scanlines             = love.graphics.newShader(_PACKAGE.."/shaders/scanlines.glsl")
post_shader.tilt_shift            = love.graphics.newShader(_PACKAGE.."/shaders/tilt_shift.glsl")

function post_shader:init()
  self:refreshScreenSize()
  self.effects = {}
end

function post_shader:refreshScreenSize()
  self.render_buffer = love.graphics.newCanvas()
  self.back_buffer = love.graphics.newCanvas()

  post_shader.blurv:send("screen", {love.window.getWidth(), love.window.getHeight()})
  post_shader.blurh:send("screen", {love.window.getWidth(), love.window.getHeight()})
  post_shader.scanlines:send("screen", {love.window.getWidth(), love.window.getHeight()})
end

function post_shader:addEffect(shaderName, ...)
  self.effects[shaderName] = {...}
end

function post_shader:removeEffect(shaderName)
  self.effects[shaderName] = nil
end

function post_shader:toggleEffect(shaderName, ...)
  if self.effects[shaderName] ~= nil then
    self:removeEffect(shaderName)
  else
    self:addEffect(shaderName, ...)
  end
end

function post_shader:drawWith(canvas)
  for shader, args in pairs(self.effects) do 
    if shader == "bloom" then
      self:drawBloom(canvas, args)
    elseif shader == "blur" then
      self:drawBlur(canvas, args)
    elseif shader == "chromatic" then
      self:drawChromatic(canvas, args)
    elseif shader == "4colors" then
      self:draw4Color(canvas, args)
    elseif shader == "monochrome" then
      self:drawMonochome(canvas, args)
    elseif shader == "scanlines" then
      self:drawScanlines(canvas, args)
    elseif shader == "tiltshift" then
      self:drawTiltshift(canvas, args)
    end
  end

  love.graphics.setBackgroundColor(0, 0, 0)
  love.graphics.setBlendMode("alpha")
  love.graphics.setCanvas()
  love.graphics.setShader()
  love.graphics.setColor(255, 255, 255)
  love.graphics.draw(canvas)
end

function post_shader:drawBloom(canvas, args)
  love.graphics.setCanvas(self.back_buffer)
  love.graphics.setBlendMode("alpha")

  post_shader.blurv:send("steps", args[1] or 2.0)
  post_shader.blurh:send("steps", args[1] or 2.0)

  love.graphics.setShader(post_shader.blurv)
  love.graphics.draw(canvas)

  love.graphics.setShader(post_shader.blurh)
  love.graphics.draw(self.back_buffer)

  love.graphics.setShader(post_shader.contrast)
  love.graphics.draw(self.back_buffer)

  love.graphics.setCanvas(canvas)
  love.graphics.setShader()
  love.graphics.setColor(255, 255, 255)
  love.graphics.draw(canvas)
  love.graphics.setBlendMode("additive")
  love.graphics.setColor(255, 255, 255, (args[2] or 0.25) * 255)
  love.graphics.draw(self.back_buffer)
  love.graphics.setBlendMode("alpha")
end

function post_shader:drawBlur(canvas, args)
  love.graphics.setCanvas(self.back_buffer)
  love.graphics.setBlendMode("alpha")

  post_shader.blurv:send("steps", args[1] or 2.0)
  post_shader.blurh:send("steps", args[2] or 2.0)

  love.graphics.setShader(post_shader.blurv)
  love.graphics.draw(canvas)

  love.graphics.setShader(post_shader.blurh)
  love.graphics.draw(self.back_buffer)

  love.graphics.setBlendMode("alpha")
  love.graphics.setCanvas(canvas)
  love.graphics.setShader()
  love.graphics.setColor(255, 255, 255)
  love.graphics.draw(self.back_buffer)
end

function post_shader:drawChromatic(canvas, args)
  love.graphics.setCanvas(self.back_buffer)
  love.graphics.setBlendMode("alpha")

  post_shader.chromatic_aberration:send("redStrength", {args[1] or 0.0, args[2] or 0.0})
  post_shader.chromatic_aberration:send("greenStrength", {args[3] or 0.0, args[4] or 0.0})
  post_shader.chromatic_aberration:send("blueStrength", {args[5] or 0.0, args[6] or 0.0})
  love.graphics.setCanvas(self.back_buffer)
  love.graphics.setShader(post_shader.chromatic_aberration)
  love.graphics.draw(canvas)

  love.graphics.setBlendMode("alpha")
  love.graphics.setCanvas(canvas)
  love.graphics.setShader()
  love.graphics.setColor(255, 255, 255)
  love.graphics.draw(self.back_buffer)
end

function post_shader:draw4Color(canvas, args)
  love.graphics.setCanvas(self.back_buffer)
  love.graphics.setBlendMode("alpha")
  
  local palette = {{unpack(args[1])}, {unpack(args[2])}, {unpack(args[3])}, {unpack(args[4])}}
  for i = 1, 4 do
    for k = 1, 3 do
      palette[i][k] = args[i][k] / 255.0
    end
  end

  self.four_color:send("palette", palette[1], palette[2], palette[3], palette[4])
  love.graphics.setShader(self.four_color)
  love.graphics.draw(canvas)

  love.graphics.setBlendMode("alpha")
  love.graphics.setCanvas(canvas)
  love.graphics.setShader()
  love.graphics.setColor(255, 255, 255)
  love.graphics.draw(self.back_buffer)
end

function post_shader:drawMonochome(canvas, args)
  love.graphics.setCanvas(self.back_buffer)
  love.graphics.setBlendMode("alpha")

  local tint = {args[1], args[2], args[3]}
  for i = 1, 3 do
    if tint[i] then
      tint[i] = tint[i] / 255.0
    end
  end

  post_shader.monochrome:send("tint", {tint[1] or 1.0, tint[2] or 1.0, tint[3] or 1.0})
  post_shader.monochrome:send("fudge", args[4] or 0.1)
  post_shader.monochrome:send("time", args[5] or love.timer.getTime())
  love.graphics.setShader(post_shader.monochrome)
  love.graphics.draw(canvas)

  love.graphics.setBlendMode("alpha")
  love.graphics.setCanvas(canvas)
  love.graphics.setShader()
  love.graphics.setColor(255, 255, 255)
  love.graphics.draw(self.back_buffer)
end

function post_shader:drawScanlines(canvas, args)
  love.graphics.setCanvas(self.back_buffer)
  love.graphics.setBlendMode("alpha")

  post_shader.scanlines:send("strength", args[1] or 2.0)
  post_shader.scanlines:send("time", args[2] or love.timer.getTime())
  love.graphics.setShader(post_shader.scanlines)
  love.graphics.draw(canvas)

  love.graphics.setBlendMode("alpha")
  love.graphics.setCanvas(canvas)
  love.graphics.setShader()
  love.graphics.setColor(255, 255, 255)
  love.graphics.draw(self.back_buffer)
end

function post_shader:drawTiltshift(canvas, args)
  love.graphics.setCanvas(self.back_buffer)
  love.graphics.setBlendMode("alpha")

  post_shader.tilt_shift:send("imgBuffer", canvas)
  love.graphics.setShader(post_shader.tilt_shift)
  love.graphics.draw(self.back_buffer)

  love.graphics.setBlendMode("alpha")
  love.graphics.setCanvas(canvas)
  love.graphics.setShader()
  love.graphics.setColor(255, 255, 255)
  love.graphics.draw(self.back_buffer)
end

return post_shader
