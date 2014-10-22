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
local util = require(_PACKAGE..'/util')

local post_shader = class()
post_shader.blurv                 = love.graphics.newShader(_PACKAGE.."/shaders/blurv.glsl")
post_shader.blurh                 = love.graphics.newShader(_PACKAGE.."/shaders/blurh.glsl")
post_shader.contrast              = love.graphics.newShader(_PACKAGE.."/shaders/postshaders/contrast.glsl")
post_shader.chromatic_aberration  = love.graphics.newShader(_PACKAGE.."/shaders/postshaders/chromatic_aberration.glsl")
post_shader.four_color            = love.graphics.newShader(_PACKAGE.."/shaders/postshaders/four_colors.glsl")
post_shader.monochrome            = love.graphics.newShader(_PACKAGE.."/shaders/postshaders/monochrome.glsl")
post_shader.scanlines             = love.graphics.newShader(_PACKAGE.."/shaders/postshaders/scanlines.glsl")
post_shader.tilt_shift            = love.graphics.newShader(_PACKAGE.."/shaders/postshaders/tilt_shift.glsl")

function post_shader:init()
  self:refreshScreenSize()
  self.effects = {}
end

function post_shader:refreshScreenSize(w, h)
  w, h = w or love.window.getWidth(), h or love.window.getHeight()

  self.render_buffer = love.graphics.newCanvas(w, h)
  self.back_buffer   = love.graphics.newCanvas(w, h)

  post_shader.blurv:send("screen",     {w, h})
  post_shader.blurh:send("screen",     {w, h})
  post_shader.scanlines:send("screen", {w, h})

  self.w = w
  self.h = h
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
    elseif shader == "test" then
      self:drawTest(canvas, args)
    end
  end
  util.drawCanvasToCanvas(canvas)
end

function post_shader:drawBloom(canvas, args)
  post_shader.blurv:send("steps", args[1] or 2.0)
  post_shader.blurh:send("steps", args[1] or 2.0)
  util.drawCanvasToCanvas(canvas, self.back_buffer, {shader = post_shader.blurv})
  util.drawCanvasToCanvas(self.back_buffer, self.back_buffer, {shader = post_shader.blurh})
  util.drawCanvasToCanvas(self.back_buffer, self.back_buffer, {shader = post_shader.contrast})
  util.drawCanvasToCanvas(canvas, canvas, {shader = post_shader.contrast})
  util.drawCanvasToCanvas(self.back_buffer, canvas, {blendmode = "additive", color = {255, 255, 255, (args[2] or 0.25) * 255}})
end

function post_shader:drawBlur(canvas, args)
  post_shader.blurv:send("steps", args[1] or 2.0)
  post_shader.blurh:send("steps", args[2] or 2.0)
  util.drawCanvasToCanvas(canvas, self.back_buffer, {shader = post_shader.blurv})
  util.drawCanvasToCanvas(self.back_buffer, self.back_buffer, {shader = post_shader.blurh})
  util.drawCanvasToCanvas(self.back_buffer, canvas)
end

function post_shader:drawChromatic(canvas, args)
  post_shader.chromatic_aberration:send("redStrength", {args[1] or 0.0, args[2] or 0.0})
  post_shader.chromatic_aberration:send("greenStrength", {args[3] or 0.0, args[4] or 0.0})
  post_shader.chromatic_aberration:send("blueStrength", {args[5] or 0.0, args[6] or 0.0})
  util.drawCanvasToCanvas(canvas, self.back_buffer, {shader = post_shader.chromatic_aberration})
  util.drawCanvasToCanvas(self.back_buffer, canvas)
end

function post_shader:draw4Color(canvas, args)
  local palette = {{unpack(args[1])}, {unpack(args[2])}, {unpack(args[3])}, {unpack(args[4])}}
  for i = 1, 4 do
    for k = 1, 3 do
      palette[i][k] = args[i][k] / 255.0
    end
  end
  self.four_color:send("palette", palette[1], palette[2], palette[3], palette[4])
  util.drawCanvasToCanvas(canvas, self.back_buffer, {shader = post_shader.four_color})
  util.drawCanvasToCanvas(self.back_buffer, canvas)
end

function post_shader:drawMonochome(canvas, args)
  local tint = {args[1], args[2], args[3]}
  for i = 1, 3 do
    if tint[i] then
      tint[i] = tint[i] / 255.0
    end
  end
  post_shader.monochrome:send("tint", {tint[1] or 1.0, tint[2] or 1.0, tint[3] or 1.0})
  post_shader.monochrome:send("fudge", args[4] or 0.1)
  post_shader.monochrome:send("time", args[5] or love.timer.getTime())
  util.drawCanvasToCanvas(canvas, self.back_buffer, {shader = post_shader.monochrome})
  util.drawCanvasToCanvas(self.back_buffer, canvas)
end

function post_shader:drawScanlines(canvas, args)
  post_shader.scanlines:send("strength", args[1] or 2.0)
  post_shader.scanlines:send("time", args[2] or love.timer.getTime())
  util.drawCanvasToCanvas(canvas, self.back_buffer, {shader = post_shader.scanlines})
  util.drawCanvasToCanvas(self.back_buffer, canvas)
end

function post_shader:drawTiltshift(canvas, args)
  post_shader.tilt_shift:send("imgBuffer", canvas)
  util.drawCanvasToCanvas(canvas, self.back_buffer, {shader = post_shader.tilt_shift})
  util.drawCanvasToCanvas(self.back_buffer, canvas)
end

local files = love.filesystem.getDirectoryItems(_PACKAGE.."/shaders/postshaders/test")
local testShaders = {}
	
for i,v in ipairs(files) do
  local name = _PACKAGE.."/shaders/postshaders/test".."/"..v
  if love.filesystem.isFile(name) then
    local str = love.filesystem.read(name)
    local effect = love.graphics.newShader(name)
    local defs = {}
    for vtype, extern in str:gmatch("extern (%w+) (%w+)") do
      defs[extern] = true
    end
    testShaders[#testShaders+1] = {effect, defs, name}
  end
end

function post_shader:drawTest(canvas, args)
  local w, h = love.graphics.getWidth(), love.graphics.getHeight()
  local scale = 1
  local defaults = {
    textureSize = {w, h},
    inputSize = {w, h},
    outputSize = {w, h},
    time = love.timer.getTime()
  }

  local effect = testShaders[args[1]]
  for def in pairs(effect[2]) do
    if defaults[def] then
      effect[1]:send(def, defaults[def])
    end
  end

  util.drawCanvasToCanvas(canvas, self.back_buffer, {shader = effect[1]})
  util.drawCanvasToCanvas(self.back_buffer, canvas)
end

return post_shader
