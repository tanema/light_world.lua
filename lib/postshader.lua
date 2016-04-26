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
local util = require(_PACKAGE..'/util')

local post_shader = {}
post_shader.__index = post_shader

local files = love.filesystem.getDirectoryItems(_PACKAGE.."/shaders/postshaders")
local shaders = {}
	
for i,v in ipairs(files) do
  local name = _PACKAGE.."/shaders/postshaders".."/"..v
  if love.filesystem.isFile(name) then
    local str = love.filesystem.read(name)
    local effect = love.graphics.newShader(name)
    local defs = {}
    for vtype, extern in str:gmatch("extern (%w+) (%w+)") do
      defs[extern] = true
    end
    local shaderName = name:match(".-([^\\|/]-[^%.]+)$"):gsub("%.glsl", "")
    shaders[shaderName] = {effect, defs}
  end
end

local function new()
  local obj = {effects = {}}
  local class = setmetatable(obj, post_shader)
  class:refreshScreenSize()
  return class
end

function post_shader:refreshScreenSize(w, h)
  w, h = w or love.graphics.getWidth(), h or love.graphics.getHeight()
  self.back_buffer   = love.graphics.newCanvas(w, h)
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
    elseif shader == "tilt_shift" then
      self:drawTiltShift(canvas, args)
    else 
      self:drawShader(shader, canvas, args)
    end
  end
  util.drawCanvasToCanvas(canvas)
end

function post_shader:drawBloom(canvas, args)
  shaders['blurv'][1]:send("steps", args[1] or 2.0)
  shaders['blurh'][1]:send("steps", args[1] or 2.0)
  util.drawCanvasToCanvas(canvas, self.back_buffer, {shader = shaders['blurv'][1]})
  util.process(self.back_buffer, {shader = shaders['blurh'][1]})
  util.process(self.back_buffer, {shader = shaders['contrast'][1]})
  util.process(canvas, {shader = shaders['contrast'][1]})
  util.drawCanvasToCanvas(self.back_buffer, canvas, {blendmode = "add", color = {255, 255, 255, (args[2] or 0.25) * 255}})
end

function post_shader:drawBlur(canvas, args)
  shaders['blurv'][1]:send("steps", args[1] or 0.0)
  shaders['blurh'][1]:send("steps", args[2] or args[1] or 0.0)
  util.process(canvas, {shader = shaders['blurv'][1], blendmode = "alpha"})
  util.process(canvas, {shader = shaders['blurh'][1], blendmode = "alpha"})
end

function post_shader:drawTiltShift(canvas, args)
  shaders['blurv'][1]:send("steps", args[1] or 2.0)
  shaders['blurh'][1]:send("steps", args[2] or 2.0)
  util.drawCanvasToCanvas(canvas, self.back_buffer, {shader = shaders['blurv'][1]})
  util.process(self.back_buffer, {shader = shaders['blurh'][1]})
  shaders['tilt_shift'][1]:send("imgBuffer", canvas)
  util.drawCanvasToCanvas(self.back_buffer, canvas, {shader = shaders['tilt_shift'][1]})
end

function post_shader:drawShader(shaderName, canvas, args)
  local current_arg = 1

  local effect = shaders[shaderName]
  if effect == nil then
    print("no shader called "..shaderName)
    return
  end
  for def in pairs(effect[2]) do
    if def == "time" then
      effect[1]:send("time", love.timer.getTime())
    elseif def == "palette" then
      effect[1]:send("palette", unpack(process_palette({
        args[current_arg], 
        args[current_arg + 1], 
        args[current_arg + 2], 
        args[current_arg + 3]
      })))
      current_arg = current_arg + 4
    elseif def == "tint" then
      effect[1]:send("tint", {process_tint(args[1], args[2], args[3])})
      current_arg = current_arg + 3
    elseif def == "imgBuffer" then
      effect[1]:send("imgBuffer", canvas)
    else
      local value = args[current_arg]
      if value ~= nil then
        effect[1]:send(def, value)
      end
      current_arg = current_arg + 1
    end
  end

  util.drawCanvasToCanvas(canvas, self.back_buffer, {shader = effect[1]})
  util.drawCanvasToCanvas(self.back_buffer, canvas)
end

function process_tint(r, g, b)
  return (r and r/255.0 or 1.0), (g and g/255.0 or 1.0), (b and b/255.0 or 1.0)
end

function process_palette(palette)
  for i = 1, #palette do
    palette[i] = {process_tint(unpack(palette[i]))}
  end
  return palette
end

return setmetatable({new = new}, {__call = function(_, ...) return new(...) end})
