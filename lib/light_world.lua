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
local stencils = require(_PACKAGE..'/stencils')
local vector = require(_PACKAGE..'/vector')
local Light = require(_PACKAGE..'/light')
local Body = require(_PACKAGE..'/body')

local light_world = class(function(o)
  o.translate_x = 0
  o.translate_y = 0
  o.translate_x_old = 0
  o.translate_y_old = 0
  o.direction = 0

  o.last_buffer = nil

	o.lights = {}
	o.ambient = {0, 0, 0}
	o.body = {}
	o.refraction = {}
	o.shadow = love.graphics.newCanvas()
	o.shadow2 = love.graphics.newCanvas()
	o.shine = love.graphics.newCanvas()
	o.shine2 = love.graphics.newCanvas()
	o.normalMap = love.graphics.newCanvas()
	o.glowMap = love.graphics.newCanvas()
	o.glowMap2 = love.graphics.newCanvas()
	o.refractionMap = love.graphics.newCanvas()
	o.refractionMap2 = love.graphics.newCanvas()
	o.reflectionMap = love.graphics.newCanvas()
	o.reflectionMap2 = love.graphics.newCanvas()
	o.normalInvert = false
	o.glowBlur = 1.0
	o.glowTimer = 0.0
	o.glowDown = false
	o.refractionStrength = 8.0

	o.pixelShadow = love.graphics.newCanvas()
	o.pixelShadow2 = love.graphics.newCanvas()

  o.blurv = love.graphics.newShader("shader/blurv.glsl")
  o.blurh = love.graphics.newShader("shader/blurh.glsl")
  o.blurv:send("screen", {love.window.getWidth(), love.window.getHeight()})
  o.blurh:send("screen", {love.window.getWidth(), love.window.getHeight()})

	o.shader = love.graphics.newShader("shader/poly_shadow.glsl")
	o.glowShader = love.graphics.newShader("shader/glow.glsl")
	o.normalShader = love.graphics.newShader("shader/normal.glsl")
	o.normalInvertShader = love.graphics.newShader("shader/normal_invert.glsl")
	o.materialShader = love.graphics.newShader("shader/material.glsl")
	o.refractionShader = love.graphics.newShader("shader/refraction.glsl")
	o.refractionShader:send("screen", {love.window.getWidth(), love.window.getHeight()})
	o.reflectionShader = love.graphics.newShader("shader/reflection.glsl")
	o.reflectionShader:send("screen", {love.window.getWidth(), love.window.getHeight()})

	o.reflectionStrength = 16.0
	o.reflectionVisibility = 1.0
	o.changed = true
	o.blur = 2.0
	o.optionShadows = true
	o.optionPixelShadows = true
	o.optionGlow = true
	o.optionRefraction = true
	o.optionReflection = true
	o.isShadows = false
	o.isLight = false
	o.isPixelShadows = false
	o.isGlow = false
	o.isRefraction = false
	o.isReflection = false
end)

-- update
function light_world:update()
  self.last_buffer = love.graphics.getCanvas()

  if self.translate_x ~= self.translate_x_old or self.translate_y ~= self.translate_y_old then
    self.translate_x_old = self.translate_x
    self.translate_y_old = self.translate_y
    self.changed = true
  end

  love.graphics.setColor(255, 255, 255)
  love.graphics.setBlendMode("alpha")

  if self.optionShadows and (self.isShadows or self.isLight) then
    love.graphics.setShader(self.shader)

    local lightsOnScreen = 0
    for i = 1, #self.lights do
      if self.lights[i].changed or self.changed then
        if self.lights[i].x + self.lights[i].range > self.translate_x and self.lights[i].x - self.lights[i].range < love.graphics.getWidth() + self.translate_x
          and self.lights[i].y + self.lights[i].range > self.translate_y and self.lights[i].y - self.lights[i].range < love.graphics.getHeight() + self.translate_y
        then
          local lightposrange = {self.lights[i].x, love.graphics.getHeight() - self.lights[i].y, self.lights[i].range}
          local light = self.lights[i]
          self.direction = self.direction + 0.002
          self.shader:send("lightPosition", {self.lights[i].x - self.translate_x, love.graphics.getHeight() - (self.lights[i].y - self.translate_y), self.lights[i].z})
          self.shader:send("lightRange", self.lights[i].range)
          self.shader:send("lightColor", {self.lights[i].red / 255.0, self.lights[i].green / 255.0, self.lights[i].blue / 255.0})
          self.shader:send("lightSmooth", self.lights[i].smooth)
          self.shader:send("lightGlow", {1.0 - self.lights[i].glowSize, self.lights[i].glowStrength})
          self.shader:send("lightAngle", math.pi - self.lights[i].angle / 2.0)
          self.shader:send("lightDirection", self.lights[i].direction)

          love.graphics.setCanvas(self.lights[i].shadow)
          love.graphics.clear()

          -- calculate shadows
          local shadow_geometry = calculateShadows(light, self.body)

          -- draw shadow
          love.graphics.setInvertedStencil(stencils.shadow(shadow_geometry, self.body))
          love.graphics.setBlendMode("additive")
          love.graphics.rectangle("fill", self.translate_x, self.translate_y, love.graphics.getWidth(), love.graphics.getHeight())

          -- draw color shadows
          love.graphics.setBlendMode("multiplicative")
          love.graphics.setShader()
          for k = 1,#shadow_geometry do
            if shadow_geometry[k].alpha < 1.0 then
              love.graphics.setColor(
                shadow_geometry[k].red * (1.0 - shadow_geometry[k].alpha),
                shadow_geometry[k].green * (1.0 - shadow_geometry[k].alpha),
                shadow_geometry[k].blue * (1.0 - shadow_geometry[k].alpha)
              )
              love.graphics.polygon("fill", unpack(shadow_geometry[k]))
            end
          end

          for k = 1, #self.body do
            if self.body[k].alpha < 1.0 then
              love.graphics.setBlendMode("multiplicative")
              love.graphics.setColor(self.body[k].red, self.body[k].green, self.body[k].blue)
              if self.body[k].shadowType == "circle" then
                love.graphics.circle("fill", self.body[k].x - self.body[k].ox, self.body[k].y - self.body[k].oy, self.body[k].radius)
              elseif self.body[k].shadowType == "rectangle" then
                love.graphics.rectangle("fill", self.body[k].x - self.body[k].ox, self.body[k].y - self.body[k].oy, self.body[k].width, self.body[k].height)
              elseif self.body[k].shadowType == "polygon" then
                love.graphics.polygon("fill", unpack(self.body[k].data))
              end
            end

            if self.body[k].shadowType == "image" and self.body[k].img then
              love.graphics.setBlendMode("alpha")
              local length = 1.0
              local shadowRotation = math.atan2((self.body[k].x) - self.lights[i].x, (self.body[k].y + self.body[k].oy) - self.lights[i].y)
              --local alpha = math.abs(math.cos(shadowRotation))

              self.body[k].shadowVert = {
                {math.sin(shadowRotation) * self.body[k].imgHeight * length, (length * math.cos(shadowRotation) + 1.0) * self.body[k].imgHeight + (math.cos(shadowRotation) + 1.0) * self.body[k].shadowY, 0, 0, self.body[k].red, self.body[k].green, self.body[k].blue, self.body[k].alpha * self.body[k].fadeStrength * 255},
                {self.body[k].imgWidth + math.sin(shadowRotation) * self.body[k].imgHeight * length, (length * math.cos(shadowRotation) + 1.0) * self.body[k].imgHeight + (math.cos(shadowRotation) + 1.0) * self.body[k].shadowY, 1, 0, self.body[k].red, self.body[k].green, self.body[k].blue, self.body[k].alpha * self.body[k].fadeStrength * 255},
                {self.body[k].imgWidth, self.body[k].imgHeight + (math.cos(shadowRotation) + 1.0) * self.body[k].shadowY, 1, 1, self.body[k].red, self.body[k].green, self.body[k].blue, self.body[k].alpha * 255},
                {0, self.body[k].imgHeight + (math.cos(shadowRotation) + 1.0) * self.body[k].shadowY, 0, 1, self.body[k].red, self.body[k].green, self.body[k].blue, self.body[k].alpha * 255}
              }

              self.body[k].shadowMesh:setVertices(self.body[k].shadowVert)
              love.graphics.draw(self.body[k].shadowMesh, self.body[k].x - self.body[k].ox + self.translate_x, self.body[k].y - self.body[k].oy + self.translate_y)
            end
          end

          love.graphics.setShader(self.shader)

          -- draw shine
          love.graphics.setCanvas(self.lights[i].shine)
          self.lights[i].shine:clear(255, 255, 255)
          love.graphics.setBlendMode("alpha")
          love.graphics.setStencil(stencils.poly(self.body))
          love.graphics.rectangle("fill", self.translate_x, self.translate_y, love.graphics.getWidth(), love.graphics.getHeight())

          lightsOnScreen = lightsOnScreen + 1

          self.lights[i].visible = true
        else
          self.lights[i].visible = false
        end

        self.lights[i].changed = self.changed
      end
    end

    -- update shadow
    love.graphics.setShader()
    love.graphics.setCanvas(self.shadow)
    love.graphics.setStencil()
    love.graphics.setColor(unpack(self.ambient))
    love.graphics.setBlendMode("alpha")
    love.graphics.rectangle("fill", self.translate_x, self.translate_y, love.graphics.getWidth(), love.graphics.getHeight())
    love.graphics.setColor(255, 255, 255)
    love.graphics.setBlendMode("additive")
    for i = 1, #self.lights do
      if self.lights[i].visible then
        love.graphics.draw(self.lights[i].shadow, self.translate_x, self.translate_y)
      end
    end
    self.isShadowBlur = false

    -- update shine
    love.graphics.setCanvas(self.shine)
    love.graphics.setColor(unpack(self.ambient))
    love.graphics.setBlendMode("alpha")
    love.graphics.rectangle("fill", self.translate_x, self.translate_y, love.graphics.getWidth(), love.graphics.getHeight())
    love.graphics.setColor(255, 255, 255)
    love.graphics.setBlendMode("additive")
    for i = 1, #self.lights do
      if self.lights[i].visible then
        love.graphics.draw(self.lights[i].shine, self.translate_x, self.translate_y)
      end
    end
  end

  if self.optionPixelShadows and self.isPixelShadows then
    -- update pixel shadow
    love.graphics.setBlendMode("alpha")

    -- create normal map
    self.normalMap:clear()
    love.graphics.setShader()
    love.graphics.setCanvas(self.normalMap)
    for i = 1, #self.body do
      if self.body[i].type == "image" and self.body[i].normalMesh then
        love.graphics.setColor(255, 255, 255)
        love.graphics.draw(self.body[i].normalMesh, self.body[i].x - self.body[i].nx + self.translate_x, self.body[i].y - self.body[i].ny + self.translate_y)
      end
    end
    love.graphics.setColor(255, 255, 255)
    love.graphics.setBlendMode("alpha")

    self.pixelShadow2:clear()
    love.graphics.setCanvas(self.pixelShadow2)
    love.graphics.setBlendMode("additive")
    love.graphics.setShader(self.shader2)

    for i = 1, #self.lights do
      if self.lights[i].visible then
        if self.normalInvert then
          self.normalInvertShader:send('screenResolution', {love.graphics.getWidth(), love.graphics.getHeight()})
          self.normalInvertShader:send('lightColor', {self.lights[i].red / 255.0, self.lights[i].green / 255.0, self.lights[i].blue / 255.0})
          self.normalInvertShader:send('lightPosition',{self.lights[i].x, love.graphics.getHeight() - self.lights[i].y, self.lights[i].z / 255.0})
          self.normalInvertShader:send('lightRange',{self.lights[i].range})
          self.normalInvertShader:send("lightSmooth", self.lights[i].smooth)
          self.normalInvertShader:send("lightAngle", math.pi - self.lights[i].angle / 2.0)
          self.normalInvertShader:send("lightDirection", self.lights[i].direction)
          love.graphics.setShader(self.normalInvertShader)
        else
          self.normalShader:send('screenResolution', {love.graphics.getWidth(), love.graphics.getHeight()})
          self.normalShader:send('lightColor', {self.lights[i].red / 255.0, self.lights[i].green / 255.0, self.lights[i].blue / 255.0})
          self.normalShader:send('lightPosition',{self.lights[i].x, love.graphics.getHeight() - self.lights[i].y, self.lights[i].z / 255.0})
          self.normalShader:send('lightRange',{self.lights[i].range})
          self.normalShader:send("lightSmooth", self.lights[i].smooth)
          self.normalShader:send("lightAngle", math.pi - self.lights[i].angle / 2.0)
          self.normalShader:send("lightDirection", self.lights[i].direction)
          love.graphics.setShader(self.normalShader)
        end
        love.graphics.draw(self.normalMap, self.translate_x, self.translate_y)
      end
    end

    love.graphics.setShader()
    self.pixelShadow:clear(255, 255, 255)
    love.graphics.setCanvas(self.pixelShadow)
    love.graphics.setBlendMode("alpha")
    love.graphics.draw(self.pixelShadow2, self.translate_x, self.translate_y)
    love.graphics.setBlendMode("additive")
    love.graphics.setColor({self.ambient[1], self.ambient[2], self.ambient[3]})
    love.graphics.rectangle("fill", self.translate_x, self.translate_y, love.graphics.getWidth(), love.graphics.getHeight())
    love.graphics.setBlendMode("alpha")
  end

  if self.optionGlow and self.isGlow then
    -- create glow map
    self.glowMap:clear(0, 0, 0)
    love.graphics.setCanvas(self.glowMap)

    if self.glowDown then
      self.glowTimer = math.max(0.0, self.glowTimer - love.timer.getDelta())
      if self.glowTimer == 0.0 then
        self.glowDown = not self.glowDown
      end
    else
      self.glowTimer = math.min(self.glowTimer + love.timer.getDelta(), 1.0)
      if self.glowTimer == 1.0 then
        self.glowDown = not self.glowDown
      end
    end

    for i = 1, #self.body do
      if self.body[i].glowStrength > 0.0 then
        love.graphics.setColor(self.body[i].glowRed * self.body[i].glowStrength, self.body[i].glowGreen * self.body[i].glowStrength, self.body[i].glowBlue * self.body[i].glowStrength)
      else
        love.graphics.setColor(0, 0, 0)
      end

      if self.body[i].type == "circle" then
        love.graphics.circle("fill", self.body[i].x, self.body[i].y, self.body[i].radius)
      elseif self.body[i].type == "rectangle" then
        love.graphics.rectangle("fill", self.body[i].x, self.body[i].y, self.body[i].width, self.body[i].height)
      elseif self.body[i].type == "polygon" then
        love.graphics.polygon("fill", unpack(self.body[i].data))
      elseif self.body[i].type == "image" and self.body[i].img then
        if self.body[i].glowStrength > 0.0 and self.body[i].glow then
          love.graphics.setShader(self.glowShader)
          self.glowShader:send("glowImage", self.body[i].glow)
          self.glowShader:send("glowTime", love.timer.getTime() * 0.5)
          love.graphics.setColor(255, 255, 255)
        else
          love.graphics.setShader()
          love.graphics.setColor(0, 0, 0)
        end
        love.graphics.draw(self.body[i].img, self.body[i].x - self.body[i].ix + self.translate_x, self.body[i].y - self.body[i].iy + self.translate_y)
      end
    end
  end

  if self.optionRefraction and self.isRefraction then
    love.graphics.setShader()

    -- create refraction map
    self.refractionMap:clear()
    love.graphics.setCanvas(self.refractionMap)
    for i = 1, #self.body do
      if self.body[i].refraction and self.body[i].normal then
        love.graphics.setColor(255, 255, 255)
        if self.body[i].tileX == 0.0 and self.body[i].tileY == 0.0 then
          love.graphics.draw(normal, self.body[i].x - self.body[i].nx + self.translate_x, self.body[i].y - self.body[i].ny + self.translate_y)
        else
          self.body[i].normalMesh:setVertices(self.body[i].normalVert)
          love.graphics.draw(self.body[i].normalMesh, self.body[i].x - self.body[i].nx + self.translate_x, self.body[i].y - self.body[i].ny + self.translate_y)
        end
      end
    end

    love.graphics.setColor(0, 0, 0)
    for i = 1, #self.body do
      if not self.body[i].refractive then
        if self.body[i].type == "circle" then
          love.graphics.circle("fill", self.body[i].x, self.body[i].y, self.body[i].radius)
        elseif self.body[i].type == "rectangle" then
          love.graphics.rectangle("fill", self.body[i].x, self.body[i].y, self.body[i].width, self.body[i].height)
        elseif self.body[i].type == "polygon" then
          love.graphics.polygon("fill", unpack(self.body[i].data))
        elseif self.body[i].type == "image" and self.body[i].img then
          love.graphics.draw(self.body[i].img, self.body[i].x - self.body[i].ix + self.translate_x, self.body[i].y - self.body[i].iy + self.translate_y)
        end
      end
    end
  end

  if self.optionReflection and self.isReflection then
    -- create reflection map
    if self.changed then
      self.reflectionMap:clear(0, 0, 0)
      love.graphics.setCanvas(self.reflectionMap)
      for i = 1, #self.body do
        if self.body[i].reflection and self.body[i].normal then
          love.graphics.setColor(255, 0, 0)
          self.body[i].normalMesh:setVertices(self.body[i].normalVert)
          love.graphics.draw(self.body[i].normalMesh, self.body[i].x - self.body[i].nx + self.translate_x, self.body[i].y - self.body[i].ny + self.translate_y)
        end
      end
      for i = 1, #self.body do
        if self.body[i].reflective and self.body[i].img then
          love.graphics.setColor(0, 255, 0)
          love.graphics.draw(self.body[i].img, self.body[i].x - self.body[i].ix + self.translate_x, self.body[i].y - self.body[i].iy + self.translate_y)
        elseif not self.body[i].reflection and self.body[i].img then
          love.graphics.setColor(0, 0, 0)
          love.graphics.draw(self.body[i].img, self.body[i].x - self.body[i].ix + self.translate_x, self.body[i].y - self.body[i].iy + self.translate_y)
        end
      end
    end
  end

  love.graphics.setShader()
  love.graphics.setBlendMode("alpha")
  love.graphics.setStencil()
  love.graphics.setCanvas(self.last_buffer)

  self.changed = false
end

function light_world:refreshScreenSize()
  self.shadow = love.graphics.newCanvas()
  self.shadow2 = love.graphics.newCanvas()
  self.shine = love.graphics.newCanvas()
  self.shine2 = love.graphics.newCanvas()
  self.normalMap = love.graphics.newCanvas()
  self.glowMap = love.graphics.newCanvas()
  self.glowMap2 = love.graphics.newCanvas()
  self.refractionMap = love.graphics.newCanvas()
  self.refractionMap2 = love.graphics.newCanvas()
  self.reflectionMap = love.graphics.newCanvas()
  self.reflectionMap2 = love.graphics.newCanvas()
  self.pixelShadow = love.graphics.newCanvas()
  self.pixelShadow2 = love.graphics.newCanvas()
end
-- draw shadow
function light_world:drawShadow()
  if self.optionShadows and (self.isShadows or self.isLight) then
    love.graphics.setColor(255, 255, 255)
    if self.blur then
      self.last_buffer = love.graphics.getCanvas()
      self.blurv:send("steps", self.blur)
      self.blurh:send("steps", self.blur)
      love.graphics.setBlendMode("alpha")
      love.graphics.setCanvas(self.shadow2)
      love.graphics.setShader(self.blurv)
      love.graphics.draw(self.shadow, self.translate_x, self.translate_y)
      love.graphics.setCanvas(self.shadow)
      love.graphics.setShader(self.blurh)
      love.graphics.draw(self.shadow2, self.translate_x, self.translate_y)
      love.graphics.setCanvas(self.last_buffer)
      love.graphics.setBlendMode("multiplicative")
      love.graphics.setShader()
      love.graphics.draw(self.shadow, self.translate_x, self.translate_y)
      love.graphics.setBlendMode("alpha")
    else
      love.graphics.setBlendMode("multiplicative")
      love.graphics.setShader()
      love.graphics.draw(self.shadow, self.translate_x, self.translate_y)
      love.graphics.setBlendMode("alpha")
    end
  end
end
-- draw shine
function light_world:drawShine()
  if self.optionShadows and self.isShadows then
    love.graphics.setColor(255, 255, 255)
    if self.blur and false then
      self.last_buffer = love.graphics.getCanvas()
      self.blurv:send("steps", self.blur)
      self.blurh:send("steps", self.blur)
      love.graphics.setBlendMode("alpha")
      love.graphics.setCanvas(self.shine2)
      love.graphics.setShader(self.blurv)
      love.graphics.draw(self.shine, self.translate_x, self.translate_y)
      love.graphics.setCanvas(self.shine)
      love.graphics.setShader(self.blurh)
      love.graphics.draw(self.shine2, self.translate_x, self.translate_y)
      love.graphics.setCanvas(self.last_buffer)
      love.graphics.setBlendMode("multiplicative")
      love.graphics.setShader()
      love.graphics.draw(self.shine, self.translate_x, self.translate_y)
      love.graphics.setBlendMode("alpha")
    else
      love.graphics.setBlendMode("multiplicative")
      love.graphics.setShader()
      love.graphics.draw(self.shine, self.translate_x, self.translate_y)
      love.graphics.setBlendMode("alpha")
    end
  end
end
-- draw pixel shadow
function light_world:drawPixelShadow()
  if self.optionPixelShadows and self.isPixelShadows then
    love.graphics.setColor(255, 255, 255)
    love.graphics.setBlendMode("multiplicative")
    love.graphics.setShader()
    love.graphics.draw(self.pixelShadow, self.translate_x, self.translate_y)
    love.graphics.setBlendMode("alpha")
  end
end
-- draw material
function light_world:drawMaterial()
  love.graphics.setShader(self.materialShader)
  for i = 1, #self.body do
    if self.body[i].material and self.body[i].normal then
      love.graphics.setColor(255, 255, 255)
      self.materialShader:send("material", self.body[i].material)
      love.graphics.draw(self.body[i].normal, self.body[i].x - self.body[i].nx + self.translate_x, self.body[i].y - self.body[i].ny + self.translate_y)
    end
  end
  love.graphics.setShader()
end
-- draw glow
function light_world:drawGlow()
  if self.optionGlow and self.isGlow then
    love.graphics.setColor(255, 255, 255)
    if self.glowBlur == 0.0 then
      love.graphics.setBlendMode("additive")
      love.graphics.setShader()
      love.graphics.draw(self.glowMap, self.translate_x, self.translate_y)
      love.graphics.setBlendMode("alpha")
    else
      self.blurv:send("steps", self.glowBlur)
      self.blurh:send("steps", self.glowBlur)
      self.last_buffer = love.graphics.getCanvas()
      love.graphics.setBlendMode("additive")
      self.glowMap2:clear()
      love.graphics.setCanvas(self.glowMap2)
      love.graphics.setShader(self.blurv)
      love.graphics.draw(self.glowMap, self.translate_x, self.translate_y)
      love.graphics.setCanvas(self.glowMap)
      love.graphics.setShader(self.blurh)
      love.graphics.draw(self.glowMap2, self.translate_x, self.translate_y)
      love.graphics.setCanvas(self.last_buffer)
      love.graphics.setShader()
      love.graphics.draw(self.glowMap, self.translate_x, self.translate_y)
      love.graphics.setBlendMode("alpha")
    end
  end
end
-- draw refraction
function light_world:drawRefraction()
  if self.optionRefraction and self.isRefraction then
    self.last_buffer = love.graphics.getCanvas()
    if self.last_buffer then
      love.graphics.setColor(255, 255, 255)
      love.graphics.setBlendMode("alpha")
      love.graphics.setCanvas(self.refractionMap2)
      love.graphics.draw(self.last_buffer, self.translate_x, self.translate_y)
      love.graphics.setCanvas(self.last_buffer)
      self.refractionShader:send("backBuffer", self.refractionMap2)
      self.refractionShader:send("refractionStrength", self.refractionStrength)
      love.graphics.setShader(self.refractionShader)
      love.graphics.draw(self.refractionMap, self.translate_x, self.translate_y)
      love.graphics.setShader()
    end
  end
end
-- draw reflection
function light_world:drawReflection()
  if self.optionReflection and self.isReflection then
    self.last_buffer = love.graphics.getCanvas()
    if self.last_buffer then
      love.graphics.setColor(255, 255, 255)
      love.graphics.setBlendMode("alpha")
      love.graphics.setCanvas(self.reflectionMap2)
      love.graphics.draw(self.last_buffer, self.translate_x, self.translate_y)
      love.graphics.setCanvas(self.last_buffer)
      self.reflectionShader:send("backBuffer", self.reflectionMap2)
      self.reflectionShader:send("reflectionStrength", self.reflectionStrength)
      self.reflectionShader:send("reflectionVisibility", self.reflectionVisibility)
      love.graphics.setShader(self.reflectionShader)
      love.graphics.draw(self.reflectionMap, self.translate_x, self.translate_y)
      love.graphics.setShader()
    end
  end
end
-- new light
function light_world:newLight(x, y, red, green, blue, range)
  self.lights[#self.lights + 1] = Light(o, x, y, red, green, blue, range)
  self.isLight = true
  return self.lights[#self.lights]
end
-- clear lights
function light_world:clearLights()
  self.lights = {}
  self.isLight = false
  self.changed = true
end
-- clear objects
function light_world:clearBodys()
  self.body = {}
  self.changed = true
  self.isShadows = false
  self.isPixelShadows = false
  self.isGlow = false
  self.isRefraction = false
  self.isReflection = false
end
-- set offset
function light_world:setTranslation(translateX, translateY)
  self.translate_x = translateX
  self.translate_y = translateY
end
-- set ambient color
function light_world:setAmbientColor(red, green, blue)
  self.ambient = {red, green, blue}
end
-- set ambient red
function light_world:setAmbientRed(red)
  self.ambient[1] = red
end
-- set ambient green
function light_world:setAmbientGreen(green)
  self.ambient[2] = green
end
-- set ambient blue
function light_world:setAmbientBlue(blue)
  self.ambient[3] = blue
end
-- set normal invert
function light_world:setNormalInvert(invert)
  self.normalInvert = invert
end
-- set blur
function light_world:setBlur(blur)
  self.blur = blur
  self.changed = true
end
-- set blur
function light_world:setShadowBlur(blur)
  self.blur = blur
  self.changed = true
end
-- set buffer
function light_world:setBuffer(buffer)
  if buffer == "render" then
    love.graphics.setCanvas(self.last_buffer)
  else
    self.last_buffer = love.graphics.getCanvas()
  end

  if buffer == "glow" then
    love.graphics.setCanvas(self.glowMap)
  end
end
-- set glow blur
function light_world:setGlowStrength(strength)
  self.glowBlur = strength
  self.changed = true
end
-- set refraction blur
function light_world:setRefractionStrength(strength)
  self.refractionStrength = strength
end
-- set reflection strength
function light_world:setReflectionStrength(strength)
  self.reflectionStrength = strength
end
-- set reflection visibility
function light_world:setReflectionVisibility(visibility)
  self.reflectionVisibility = visibility
end
-- new rectangle
function light_world:newRectangle(x, y, w, h)
  return self:newBody("rectangle", x, y, width, height)
end
-- new circle
function light_world:newCircle(x, y, r)
  return self:newBody("circle", x, y, radius)
end
-- new polygon
function light_world:newPolygon(...)
  return self:newBody("polygon", ...)
end
-- new image
function light_world:newImage(img, x, y, width, height, ox, oy)
  return self:newBody("image", img, x, y, width, height, ox, oy)
end
-- new refraction
function light_world:newRefraction(normal, x, y, width, height)
  return self:newBody("refraction", normal, x, y, width, height)
end
-- new refraction from height map
function light_world:newRefractionHeightMap(heightMap, x, y, strength)
  local normal = HeightMapToNormalMap(heightMap, strength)
  return self.newRefraction(p, normal, x, y)
end
-- new reflection
function light_world:newReflection(normal, x, y, width, height)
  return self:newBody("reflection", normal, x, y, width, height)
end
-- new reflection from height map
function light_world:newReflectionHeightMap(heightMap, x, y, strength)
  local normal = HeightMapToNormalMap(heightMap, strength)
  return self.newReflection(p, normal, x, y)
end
-- new body
function light_world:newBody(type, ...)
  local id = #self.body + 1
  self.body[id] = Body(self, id, type, ...)
  self.changed = true
  return self.body[#self.body]
end
-- set polygon data
function light_world:setPoints(n, ...)
  self.body[n].data = {...}
end
-- get polygon count
function light_world:getBodyCount()
  return #self.body
end
-- get polygon
function light_world:getPoints(n)
  if self.body[n].data then
    return unpack(self.body[n].data)
  end
end
-- set light position
function light_world:setLightPosition(n, x, y, z)
  self.lights[n]:setPosition(x, y, z)
end
-- set light x
function light_world:setLightX(n, x)
  self.lights[n]:setX(x)
end
-- set light y
function light_world:setLightY(n, y)
  self.lights[n]:setY(y)
end
-- set light angle
function light_world:setLightAngle(n, angle)
  self.lights[n]:setAngle(angle)
end
-- set light direction
function light_world:setLightDirection(n, direction)
  self.lights[n]:setDirection(direction)
end
-- get light count
function light_world:getLightCount()
  return #self.lights
end
-- get light x position
function light_world:getLightX(n)
  return self.lights[n].x
end
-- get light y position
function light_world:getLightY(n)
  return self.lights[n].y
end
-- get type
function light_world:getType()
  return "world"
end

function calculateShadows(light, body)
	local shadowGeometry = {}
	local shadowLength = 100000

	for i = 1, #body do
		if body[i].shadowType == "rectangle" or body[i].shadowType == "polygon" then
			curPolygon = body[i].data
			if not body[i].castsNoShadow then
				local edgeFacingTo = {}
				for k = 1, #curPolygon, 2 do
					local indexOfNextVertex = (k + 2) % #curPolygon
					local normal = {-curPolygon[indexOfNextVertex+1] + curPolygon[k + 1], curPolygon[indexOfNextVertex] - curPolygon[k]}
					local lightToPoint = {curPolygon[k] - light.x, curPolygon[k + 1] - light.y}

					normal = vector.normalize(normal)
					lightToPoint = vector.normalize(lightToPoint)

					local dotProduct = vector.dot(normal, lightToPoint)
					if dotProduct > 0 then table.insert(edgeFacingTo, true)
					else table.insert(edgeFacingTo, false) end
				end

				local curShadowGeometry = {}
				for k = 1, #edgeFacingTo do
					local nextIndex = (k + 1) % #edgeFacingTo
					if nextIndex == 0 then nextIndex = #edgeFacingTo end
					if edgeFacingTo[k] and not edgeFacingTo[nextIndex] then
						curShadowGeometry[1] = curPolygon[nextIndex*2-1]
						curShadowGeometry[2] = curPolygon[nextIndex*2]

						local lightVecFrontBack = vector.normalize({curPolygon[nextIndex*2-1] - light.x, curPolygon[nextIndex*2] - light.y})
						curShadowGeometry[3] = curShadowGeometry[1] + lightVecFrontBack[1] * shadowLength
						curShadowGeometry[4] = curShadowGeometry[2] + lightVecFrontBack[2] * shadowLength

					elseif not edgeFacingTo[k] and edgeFacingTo[nextIndex] then
						curShadowGeometry[7] = curPolygon[nextIndex*2-1]
						curShadowGeometry[8] = curPolygon[nextIndex*2]

						local lightVecBackFront = vector.normalize({curPolygon[nextIndex*2-1] - light.x, curPolygon[nextIndex*2] - light.y})
						curShadowGeometry[5] = curShadowGeometry[7] + lightVecBackFront[1] * shadowLength
						curShadowGeometry[6] = curShadowGeometry[8] + lightVecBackFront[2] * shadowLength
					end
				end
				if  curShadowGeometry[1]
					and curShadowGeometry[2]
					and curShadowGeometry[3]
					and curShadowGeometry[4]
					and curShadowGeometry[5]
					and curShadowGeometry[6]
					and curShadowGeometry[7]
					and curShadowGeometry[8]
				then
					curShadowGeometry.alpha = body[i].alpha
					curShadowGeometry.red = body[i].red
					curShadowGeometry.green = body[i].green
					curShadowGeometry.blue = body[i].blue
					shadowGeometry[#shadowGeometry + 1] = curShadowGeometry
				end
			end
		elseif body[i].shadowType == "circle" then
			if not body[i].castsNoShadow then
				local length = math.sqrt(math.pow(light.x - (body[i].x - body[i].ox), 2) + math.pow(light.y - (body[i].y - body[i].oy), 2))
				if length >= body[i].radius and length <= light.range then
					local curShadowGeometry = {}
					local angle = math.atan2(light.x - (body[i].x - body[i].ox), (body[i].y - body[i].oy) - light.y) + math.pi / 2
					local x2 = ((body[i].x - body[i].ox) + math.sin(angle) * body[i].radius)
					local y2 = ((body[i].y - body[i].oy) - math.cos(angle) * body[i].radius)
					local x3 = ((body[i].x - body[i].ox) - math.sin(angle) * body[i].radius)
					local y3 = ((body[i].y - body[i].oy) + math.cos(angle) * body[i].radius)

					curShadowGeometry[1] = x2
					curShadowGeometry[2] = y2
					curShadowGeometry[3] = x3
					curShadowGeometry[4] = y3

					curShadowGeometry[5] = x3 - (light.x - x3) * shadowLength
					curShadowGeometry[6] = y3 - (light.y - y3) * shadowLength
					curShadowGeometry[7] = x2 - (light.x - x2) * shadowLength
					curShadowGeometry[8] = y2 - (light.y - y2) * shadowLength
					curShadowGeometry.alpha = body[i].alpha
					curShadowGeometry.red = body[i].red
					curShadowGeometry.green = body[i].green
					curShadowGeometry.blue = body[i].blue
					shadowGeometry[#shadowGeometry + 1] = curShadowGeometry
				end
			end
		end
	end

	return shadowGeometry
end

function HeightMapToNormalMap(heightMap, strength)
	local imgData = heightMap:getData()
	local imgData2 = love.image.newImageData(heightMap:getWidth(), heightMap:getHeight())
	local red, green, blue, alpha
	local x, y
	local matrix = {}
	matrix[1] = {}
	matrix[2] = {}
	matrix[3] = {}
	strength = strength or 1.0

	for i = 0, heightMap:getHeight() - 1 do
		for k = 0, heightMap:getWidth() - 1 do
			for l = 1, 3 do
				for m = 1, 3 do
					if k + (l - 1) < 1 then
						x = heightMap:getWidth() - 1
					elseif k + (l - 1) > heightMap:getWidth() - 1 then
						x = 1
					else
						x = k + l - 1
					end

					if i + (m - 1) < 1 then
						y = heightMap:getHeight() - 1
					elseif i + (m - 1) > heightMap:getHeight() - 1 then
						y = 1
					else
						y = i + m - 1
					end

					local red, green, blue, alpha = imgData:getPixel(x, y)
					matrix[l][m] = red
				end
			end

			red = (255 + ((matrix[1][2] - matrix[2][2]) + (matrix[2][2] - matrix[3][2])) * strength) / 2.0
			green = (255 + ((matrix[2][2] - matrix[1][1]) + (matrix[2][3] - matrix[2][2])) * strength) / 2.0
			blue = 192

			imgData2:setPixel(k, i, red, green, blue)
		end
	end

	return love.graphics.newImage(imgData2)
end

return light_world
