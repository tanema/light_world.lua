--[[
The MIT License (MIT)

Copyright (c) 2014 Marcus Ihde, Tim Anema

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
local _PACKAGE = string.gsub(...,"%.","/") or ""
if string.len(_PACKAGE) > 0 then _PACKAGE = _PACKAGE .. "/" end
local class = require(_PACKAGE..'class')
local Light = require(_PACKAGE..'light')
local Body = require(_PACKAGE..'body')
local util = require(_PACKAGE..'util')
local PostShader = require(_PACKAGE..'postshader')

local light_world = class()

light_world.blurv              = love.graphics.newShader(_PACKAGE.."shaders/blurv.glsl")
light_world.blurh              = love.graphics.newShader(_PACKAGE.."shaders/blurh.glsl")
light_world.refractionShader   = love.graphics.newShader(_PACKAGE.."shaders/refraction.glsl")
light_world.reflectionShader   = love.graphics.newShader(_PACKAGE.."shaders/reflection.glsl")

function light_world:init(options)
	self.lights = {}
	self.body = {}
  self.post_shader = PostShader()

  self.l, self.t, self.s    =  0, 0, 1 
	self.ambient              = {0, 0, 0}
	self.refractionStrength   = 8.0
	self.reflectionStrength   = 16.0
	self.reflectionVisibility = 1.0
	self.shadowBlur           = 0.0
	self.glowBlur             = 1.0
	self.glowTimer            = 0.0
	self.glowDown             = false

  self.disableGlow          = false
  self.disableMaterial      = false
  self.disableReflection    = true
  self.disableRefraction    = true

  options = options or {}
  for k, v in pairs(options) do self[k] = v end

  self:refreshScreenSize()
end

function light_world:refreshScreenSize(w, h)
  w, h = w or love.window.getWidth(), h or love.window.getHeight()

  self.w, self.h        = w, h
	self.render_buffer    = love.graphics.newCanvas(w, h)
	self.normal           = love.graphics.newCanvas(w, h)
	self.normal2          = love.graphics.newCanvas(w, h)
	self.normalMap        = love.graphics.newCanvas(w, h)
	self.shadowMap        = love.graphics.newCanvas(w, h)
	self.glowMap          = love.graphics.newCanvas(w, h)
	self.glowMap2         = love.graphics.newCanvas(w, h)
	self.refractionMap    = love.graphics.newCanvas(w, h)
	self.refractionMap2   = love.graphics.newCanvas(w, h)
	self.reflectionMap    = love.graphics.newCanvas(w, h)
	self.reflectionMap2   = love.graphics.newCanvas(w, h)

  self.blurv:send("screen",            {w, h})
  self.blurh:send("screen",            {w, h})
  self.refractionShader:send("screen", {w, h})
  self.reflectionShader:send("screen", {w, h})

  for i = 1, #self.lights do
    self.lights[i]:refresh(w, h)
  end

  self.post_shader:refreshScreenSize(w, h)
end

function light_world:update(dt)
  for i = 1, #self.body do
    if self.body[i]:isInRange(-self.l,-self.t,self.w,self.h,self.s) and 
      self.body[i].type == 'animation' then
      self.body[i]:update(dt)
    end
  end
end

function light_world:draw(cb)
  util.drawto(self.render_buffer, self.l, self.t, self.s, function()
    cb(                     self.l,self.t,self.w,self.h,self.s)
		_ = self.disableMaterial   or self:drawMaterial(      self.l,self.t,self.w,self.h,self.s)
    self:drawNormalShading( self.l,self.t,self.w,self.h,self.s)
    _ = self.disableGlow       or self:drawGlow(          self.l,self.t,self.w,self.h,self.s)
    _ = self.disableRefraction or self:drawRefraction(    self.l,self.t,self.w,self.h,self.s)
    _ = self.disableReflection or self:drawReflection(    self.l,self.t,self.w,self.h,self.s)
  end)
  self.post_shader:drawWith(self.render_buffer, self.l, self.t, self.s)
end
 
function light_world:drawBlur(blendmode, blur, canvas, canvas2, l, t, w, h, s)
  if blur <= 0 then
    return
  end
  canvas2:clear()
  self.blurv:send("steps", blur)
  self.blurh:send("steps", blur)
  util.drawCanvasToCanvas(canvas, canvas2, {shader = self.blurv, blendmode = blendmode})
  util.drawCanvasToCanvas(canvas2, canvas, {shader = self.blurh, blendmode = blendmode})
end

-- draw normal shading
function light_world:drawNormalShading(l,t,w,h,s)
  -- create normal map
  self.normalMap:clear()
  util.drawto(self.normalMap, l, t, s, function()
    for i = 1, #self.body do
      if self.body[i]:isInRange(-l,-t,w,h,s) then
        self.body[i]:drawNormal()
      end
    end
  end)

  self.normal2:clear()
  for i = 1, #self.lights do
    if self.lights[i]:inRange(l,t,w,h,s) then
      -- create shadow map for this light
      self.shadowMap:clear()
      util.drawto(self.shadowMap, l, t, s, function()
        for k = 1, #self.body do
          if self.body[k]:isInLightRange(self.lights[i]) and self.body[k]:isInRange(-l,-t,w,h,s) then
            self.body[k]:drawShadow(self.lights[i])
          end
        end
      end)
      -- draw scene for this light using normals and shadowmap
      self.lights[i]:drawNormalShading(l,t,w,h,s, self.normalMap, self.shadowMap, self.normal2)
    end
  end

  -- add in ambient color
  self.normal:clear(255, 255, 255)
  util.drawCanvasToCanvas(self.normal2, self.normal, {blendmode = "alpha"})
  util.drawto(self.normal, l, t, s, function()
    love.graphics.setBlendMode("additive")
    love.graphics.setColor({self.ambient[1], self.ambient[2], self.ambient[3]})
    love.graphics.rectangle("fill", -l/s, -t/s, w/s,h/s)
  end)

  light_world:drawBlur("alpha", self.shadowBlur, self.normal, self.normal2, l, t, w, h, s)
  util.drawCanvasToCanvas(self.normal, self.render_buffer, {blendmode = "multiplicative"})
end

-- draw material
function light_world:drawMaterial(l,t,w,h,s)
  for i = 1, #self.body do
    if self.body[i]:isInRange(-l,-t,w,h,s) then
      self.body[i]:drawMaterial()
    end
  end
end

-- draw glow
function light_world:drawGlow(l,t,w,h,s)
  if self.glowDown then
    self.glowTimer = math.max(0.0, self.glowTimer - love.timer.getDelta())
  else
    self.glowTimer = math.min(self.glowTimer + love.timer.getDelta(), 1.0)
  end

  if self.glowTimer == 1.0 or self.glowTimer == 0.0 then
    self.glowDown = not self.glowDown
  end

  local has_glow = false
  -- create glow map
  self.glowMap:clear(0, 0, 0)
  util.drawto(self.glowMap, l, t, s, function()
    for i = 1, #self.body do
      if self.body[i]:isInRange(-l,-t,w,h,s) and self.body[i].glowStrength > 0.0 then
        has_glow = true
        self.body[i]:drawGlow()
      end
    end
  end)

  if has_glow then
    light_world:drawBlur("alpha", self.glowBlur, self.glowMap, self.glowMap2, l, t, w, h, s)
    util.drawCanvasToCanvas(self.glowMap, self.render_buffer, {blendmode = "additive"})
  end
end
-- draw refraction
function light_world:drawRefraction(l,t,w,h,s)
  -- create refraction map
  self.refractionMap:clear()
  util.drawto(self.refractionMap, l, t, s, function()
    for i = 1, #self.body do
      if self.body[i]:isInRange(-l,-t,w,h,s) then
        self.body[i]:drawRefraction()
      end
    end
  end)

  util.drawCanvasToCanvas(self.render_buffer, self.refractionMap2)
  self.refractionShader:send("backBuffer", self.refractionMap2)
  self.refractionShader:send("refractionStrength", self.refractionStrength)
  util.drawCanvasToCanvas(self.refractionMap, self.render_buffer, {shader = self.refractionShader})
end

-- draw reflection
function light_world:drawReflection(l,t,w,h,s)
  -- create reflection map
  self.reflectionMap:clear(0, 0, 0)
  util.drawto(self.reflectionMap, l, t, s, function()
    for i = 1, #self.body do
      if self.body[i]:isInRange(-l,-t,w,h,s) then
        self.body[i]:drawReflection()
      end
    end
  end)

  util.drawCanvasToCanvas(self.render_buffer, self.reflectionMap2)
  self.reflectionShader:send("backBuffer", self.reflectionMap2)
  self.reflectionShader:send("reflectionStrength", self.reflectionStrength)
  self.reflectionShader:send("reflectionVisibility", self.reflectionVisibility)
  util.drawCanvasToCanvas(self.reflectionMap, self.render_buffer, {shader = self.reflectionShader})
end

-- new light
function light_world:newLight(x, y, red, green, blue, range)
  self.lights[#self.lights + 1] = Light(x, y, red, green, blue, range)
  return self.lights[#self.lights]
end

function light_world:clear()
  light_world:clearLights()
  light_world:clearBodies()
end

function light_world:setTranslation(l, t, s) 
  self.l, self.t, self.s = l or self.l, t or self.t, s or self.s
end

function light_world:setScale(s) self.s = s end
function light_world:clearLights() self.lights = {} end
function light_world:clearBodies() self.body = {} end
function light_world:setAmbientColor(red, green, blue) self.ambient = {red, green, blue} end
function light_world:setShadowBlur(blur) self.shadowBlur = blur end
function light_world:setGlowStrength(strength) self.glowBlur = strength end
function light_world:setRefractionStrength(strength) self.refractionStrength = strength end
function light_world:setReflectionStrength(strength) self.reflectionStrength = strength end
function light_world:setReflectionVisibility(visibility) self.reflectionVisibility = visibility end
function light_world:getBodyCount() return #self.body end
function light_world:getBody(n) return self.body[n] end
function light_world:getLightCount() return #self.lights end
function light_world:getLight(n) return self.lights[n] end
function light_world:newRectangle(...) return self:newBody("rectangle", ...) end
function light_world:newAnimationGrid(...) return self:newBody("animation", ...) end
function light_world:newCircle(...) return self:newBody("circle", ...) end
function light_world:newPolygon(...) return self:newBody("polygon", ...) end
function light_world:newImage(...) return self:newBody("image", ...) end

function light_world:newRefraction(...) 
  self.disableRefraction = false
  return self:newBody("refraction", ...) 
end
function light_world:newReflection(normal, ...) 
  self.disableReflection = false
  return self:newBody("reflection", ...) 
end

-- new body
function light_world:newBody(type, ...)
  local id = #self.body + 1
  self.body[id] = Body(id, type, ...)
  return self.body[#self.body]
end

function light_world:remove(to_kill)
  if to_kill:is_a(Body) then
    for i = 1, #self.body do
      if self.body[i] == to_kill then
        table.remove(self.body, i)
        return true
      end
    end
  elseif to_kill:is_a(Light) then
    for i = 1, #self.lights do
      if self.lights[i] == to_kill then
        table.remove(self.lights, i)
        return true
      end
    end
  end

  -- failed to find it
  return false
end

return light_world
