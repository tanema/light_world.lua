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
local Light = require(_PACKAGE..'light')
local Body = require(_PACKAGE..'body')
local util = require(_PACKAGE..'util')
local PostShader = require(_PACKAGE..'postshader')

local light_world = {}
light_world.__index = light_world

light_world.image_mask       = util.loadShader(_PACKAGE.."/shaders/image_mask.glsl")
light_world.shadowShader     = util.loadShader(_PACKAGE.."/shaders/shadow.glsl")
light_world.refractionShader = util.loadShader(_PACKAGE.."/shaders/refraction.glsl")
light_world.reflectionShader = util.loadShader(_PACKAGE.."/shaders/reflection.glsl")

local function new(options)
  local obj = {}
	obj.lights = {}
	obj.bodies = {}
  obj.post_shader = PostShader()

  obj.l, obj.t, obj.s      =  0, 0, 1
	obj.ambient              = {0, 0, 0}
	obj.refractionStrength   = 8.0
	obj.reflectionStrength   = 16.0
	obj.reflectionVisibility = 1.0
	obj.shadowBlur           = 2.0
	obj.glowBlur             = 1.0
	obj.glowTimer            = 0.0
	obj.glowDown             = false

  obj.disableGlow          = false
  obj.disableMaterial      = false
  obj.disableReflection    = true
  obj.disableRefraction    = true

  options = options or {}
  for k, v in pairs(options) do obj[k] = v end
  for i, v in ipairs(obj.ambient) do if v > 1 then obj.ambient[i] = v / 255 end end

  local world = setmetatable(obj, light_world)
  world:refreshScreenSize()

  return world
end

function light_world:refreshScreenSize(w, h)
  w, h = w or love.graphics.getWidth(), h or love.graphics.getHeight()

  self.w, self.h        = w, h
	self.render_buffer    = love.graphics.newCanvas(w, h)
	self.shadow_buffer    = love.graphics.newCanvas(w, h)
	self.normalMap        = love.graphics.newCanvas(w, h)
	self.shadowMap        = love.graphics.newCanvas(w, h)
	self.glowMap          = love.graphics.newCanvas(w, h)
	self.refractionMap    = love.graphics.newCanvas(w, h)
	self.reflectionMap    = love.graphics.newCanvas(w, h)

  self.post_shader:refreshScreenSize(w, h)
end

function light_world:update(dt)
  for i = 1, #self.bodies do
    self.bodies[i].is_on_screen = self.bodies[i]:inRange(-self.l,-self.t,self.w,self.h,self.s)
    if self.bodies[i]:isVisible() then
      self.bodies[i]:update(dt)
    end
  end
  for i = 1, #self.lights do
    self.lights[i].is_on_screen = self.lights[i]:inRange(self.l,self.t,self.w,self.h,self.s)
  end
end

function light_world:draw(cb)
  util.drawto(self.render_buffer, self.l, self.t, self.s, false, function()
    cb(self.l,self.t,self.w,self.h,self.s)
		_ = self.disableMaterial   or self:drawMaterial(      self.l,self.t,self.w,self.h,self.s)
    self:drawShadows( self.l,self.t,self.w,self.h,self.s)
    _ = self.disableGlow       or self:drawGlow(          self.l,self.t,self.w,self.h,self.s)
    _ = self.disableRefraction or self:drawRefraction(    self.l,self.t,self.w,self.h,self.s)
    _ = self.disableReflection or self:drawReflection(    self.l,self.t,self.w,self.h,self.s)
  end)
  self.post_shader:drawWith(self.render_buffer, self.l, self.t, self.s)
end

-- draw normal shading
function light_world:drawShadows(l,t,w,h,s)
  love.graphics.setCanvas( self.normalMap )
  love.graphics.clear()
  love.graphics.setCanvas()
  util.drawto(self.normalMap, l, t, s, false, function()
    for i = 1, #self.bodies do
      if self.bodies[i]:isVisible() then
        self.bodies[i]:drawNormal()
      end
    end
  end)

  self.shadowShader:send('normalMap', self.normalMap)
  self.shadowShader:send("invert_normal", self.normalInvert == true)

  love.graphics.setCanvas( self.shadow_buffer )
  love.graphics.clear()
  love.graphics.setCanvas()
  for i = 1, #self.lights do
    local light = self.lights[i]
    if light:isVisible() then
      -- create shadow map for this light
      love.graphics.setCanvas( self.shadowMap )
      love.graphics.clear()
      love.graphics.setCanvas()

      util.drawto(self.shadowMap, l, t, s, true, function()
        --I dont know if it uses both or just calls both
        love.graphics.stencil(function()
          local angle = light.direction - (light.angle / 2.0)
          love.graphics.arc("fill", light.x, light.y, light.range, angle, angle + light.angle)
        end)
        love.graphics.setStencilTest("greater",0)
        love.graphics.stencil(function()
          love.graphics.setShader(self.image_mask)
          for k = 1, #self.bodies do
            if self.bodies[k]:inLightRange(light) and self.bodies[k]:isVisible() then
              self.bodies[k]:drawStencil()
            end
          end
          love.graphics.setShader()
        end)
        love.graphics.setStencilTest("equal", 0)
        for k = 1, #self.bodies do
          if self.bodies[k]:inLightRange(light) and self.bodies[k]:isVisible() then
            self.bodies[k]:drawShadow(light)
          end
        end
      end)

      -- draw scene for this light using normals and shadowmap
      self.shadowShader:send('lightColor', {light.red, light.green, light.blue})
      self.shadowShader:send("lightPosition", {(light.x + l/s) * s, (light.y + t/s) * s, (light.z * 10) / 255})
      self.shadowShader:send('lightRange',light.range * s)
      self.shadowShader:send("lightSmooth", light.smooth)
      self.shadowShader:send("lightGlow", {1.0 - light.glowSize, light.glowStrength})
      util.drawCanvasToCanvas(self.shadowMap, self.shadow_buffer, {
        blendmode = 'add',
        shader = self.shadowShader,
        stencil = function()
          local angle = light.direction - (light.angle / 2.0)
          love.graphics.arc(
            "fill", (light.x + l/s) * s, (light.y + t/s) * s, light.range, angle, angle + light.angle
          )
        end
      })
    end
  end

  -- add in ambient color
  util.drawto(self.shadow_buffer, l, t, s, false, function()
    love.graphics.setBlendMode("add")
    love.graphics.setColor({self.ambient[1], self.ambient[2], self.ambient[3]})
    love.graphics.rectangle("fill", -l/s, -t/s, w/s,h/s)
  end)

  self.post_shader:drawBlur(self.shadow_buffer, {self.shadowBlur})
  util.drawCanvasToCanvas(self.shadow_buffer, self.render_buffer, {blendmode = "multiply"})
  love.graphics.setStencilTest()
end

-- draw material
function light_world:drawMaterial(l,t,w,h,s)
  for i = 1, #self.bodies do
    if self.bodies[i]:isVisible() then
      self.bodies[i]:drawMaterial()
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
  love.graphics.setCanvas( self.glowMap )
  love.graphics.clear()
  love.graphics.setCanvas()
  util.drawto(self.glowMap, l, t, s, false, function()
    for i = 1, #self.bodies do
      if self.bodies[i]:isVisible() and self.bodies[i].glowStrength > 0.0 then
        has_glow = true
        self.bodies[i]:drawGlow()
      end
    end
  end)

  if has_glow then
    self.post_shader:drawBlur(self.glowMap, {self.glowBlur})
    util.drawCanvasToCanvas(self.glowMap, self.render_buffer, {blendmode = "add"})
  end
end
-- draw refraction
function light_world:drawRefraction(l,t,w,h,s)
  -- create refraction map
  love.graphics.setCanvas( self.refractionMap )
  love.graphics.clear()
  love.graphics.setCanvas()
  util.drawto(self.refractionMap, l, t, s, false, function()
    for i = 1, #self.bodies do
      if self.bodies[i]:isVisible() then
        self.bodies[i]:drawRefraction()
      end
    end
  end)

  self.refractionShader:send("backBuffer", self.render_buffer)
  self.refractionShader:send("refractionStrength", self.refractionStrength)
  util.drawCanvasToCanvas(self.refractionMap, self.render_buffer, {shader = self.refractionShader})
end

-- draw reflection
function light_world:drawReflection(l,t,w,h,s)
  -- create reflection map
  love.graphics.setCanvas( self.reflectionMap )
  love.graphics.clear()
  love.graphics.setCanvas()
  util.drawto(self.reflectionMap, l, t, s, false, function()
    for i = 1, #self.bodies do
      if self.bodies[i]:isVisible() then
        self.bodies[i]:drawReflection()
      end
    end
  end)

  self.reflectionShader:send("backBuffer", self.render_buffer)
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
function light_world:clearBodies() self.bodies = {} end
function light_world:setAmbientColor(red, green, blue)
  self.ambient = {red, green, blue}
  for i, v in ipairs(self.ambient) do if v > 1 then self.ambient[i] = v / 255 end end
end
function light_world:setShadowBlur(blur) self.shadowBlur = blur end
function light_world:setGlowStrength(strength) self.glowBlur = strength end
function light_world:setRefractionStrength(strength) self.refractionStrength = strength end
function light_world:setReflectionStrength(strength) self.reflectionStrength = strength end
function light_world:setReflectionVisibility(visibility) self.reflectionVisibility = visibility end
function light_world:getBodyCount() return #self.bodies end
function light_world:getBody(n) return self.bodies[n] end
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
  local id = #self.bodies + 1
  self.bodies[id] = Body(id, type, ...)
  return self.bodies[#self.bodies]
end

function light_world:is_body(target)
  return target.type ~= nil
end

function light_world:is_light(target)
  return target.angle ~= nil
end

function light_world:remove(to_kill)
  if self:is_body(to_kill) then
    for i = 1, #self.bodies do
      if self.bodies[i] == to_kill then
        table.remove(self.bodies, i)
        return true
      end
    end
  elseif self:is_light(to_kill) then
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

return setmetatable({new = new}, {__call = function(_, ...) return new(...) end})
