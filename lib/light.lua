local _PACKAGE = (...):match("^(.+)[%./][^%./]+") or ""
local class = require(_PACKAGE.."/class")
local stencils = require(_PACKAGE..'/stencils')
local util = require(_PACKAGE..'/util')

local light = class()

light.shader             = love.graphics.newShader(_PACKAGE.."/shaders/poly_shadow.glsl")
light.normalShader       = love.graphics.newShader(_PACKAGE.."/shaders/normal.glsl")
light.normalInvertShader = love.graphics.newShader(_PACKAGE.."/shaders/normal_invert.glsl")

function light:init(x, y, r, g, b, range)
	self.direction = 0
	self.angle = math.pi * 2.0
	self.range = 0
	self.x = x or 0
	self.y = y or 0
	self.z = 15
	self.red = r or 255
	self.green = g or 255
	self.blue = b or 255
	self.range = range or 300
	self.smooth = 1.0
	self.glowSize = 0.1
	self.glowStrength = 0.0
	self.visible = true
  self:refresh()
end

function light:refresh(w, h)
  w, h = w or love.window.getWidth(), h or love.window.getHeight()

	self.shadow = love.graphics.newCanvas(w, h)
	self.shine  = love.graphics.newCanvas(w, h)
end

-- set position
function light:setPosition(x, y, z)
  if x ~= self.x or y ~= self.y or (z and z ~= self.z) then
    self.x = x
    self.y = y
    if z then
      self.z = z
    end
  end
end

-- get x
function light:getX()
  return self.x
end

-- get y
function light:getY()
  return self.y
end

-- set x
function light:setX(x)
  if x ~= self.x then
    self.x = x
  end
end

-- set y
function light:setY(y)
  if y ~= self.y then
    self.y = y
  end
end

-- set color
function light:setColor(red, green, blue)
  self.red = red
  self.green = green
  self.blue = blue
end

-- set range
function light:setRange(range)
  if range ~= self.range then
    self.range = range
  end
end

-- set direction
function light:setDirection(direction)
  if direction ~= self.direction then
    if direction > math.pi * 2 then
      self.direction = math.mod(direction, math.pi * 2)
    elseif direction < 0.0 then
      self.direction = math.pi * 2 - math.mod(math.abs(direction), math.pi * 2)
    else
      self.direction = direction
    end
  end
end

-- set angle
function light:setAngle(angle)
  if angle ~= self.angle then
    if angle > math.pi then
      self.angle = math.mod(angle, math.pi)
    elseif angle < 0.0 then
      self.angle = math.pi - math.mod(math.abs(angle), math.pi)
    else
      self.angle = angle
    end
  end
end

-- set glow size
function light:setSmooth(smooth)
  self.smooth = smooth
end

-- set glow size
function light:setGlowSize(size)
  self.glowSize = size
end

-- set glow strength
function light:setGlowStrength(strength)
  self.glowStrength = strength
end

function light:inRange(l,t,w,h)
  return self.x + self.range > l     and 
         self.x - self.range < (l+w) and 
         self.y + self.range > t     and 
         self.y - self.range < (t+h)
end

function light:drawShadow(l,t,w,h,s,bodies, canvas)
  if self.visible and self:inRange(l,t,w,h) then
    -- calculate shadows
    local shadow_geometry = {}
    for i = 1, #bodies do
      local current = bodies[i]:calculateShadow(self)
      if current ~= nil then
        shadow_geometry[#shadow_geometry + 1] = current
      end
    end

    self.shadow:clear()
    self.shader:send("lightPosition", {self.x - l, h - (self.y - t), self.z})
    self.shader:send("lightRange", self.range)
    self.shader:send("lightColor", {self.red / 255.0, self.green / 255.0, self.blue / 255.0})
    self.shader:send("lightSmooth", self.smooth)
    self.shader:send("lightGlow", {1.0 - self.glowSize, self.glowStrength})
    self.shader:send("lightAngle", math.pi - self.angle / 2.0)
    self.shader:send("lightDirection", self.direction)

    -- draw shadow
    util.drawto(self.shadow, l, t, s, function()
      love.graphics.setShader(self.shader)
      love.graphics.setInvertedStencil(stencils.shadow(shadow_geometry, bodies))
      love.graphics.setBlendMode("additive")
      love.graphics.rectangle("fill", -l,-t,w,h)

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

      for k = 1, #bodies do
        bodies[k]:drawShadow(self,l,t,w,h,s)
      end
    end)

    -- update shine
    util.drawto(self.shine, l, t, s, function()
      love.graphics.setShader(self.shader)
      self.shine:clear(255, 255, 255)
      love.graphics.setBlendMode("alpha")
      love.graphics.setStencil(stencils.colorShadow(bodies))
      love.graphics.rectangle("fill", -l,-t,w,h)
    end)

    love.graphics.setStencil()
    love.graphics.setShader()

    util.drawCanvasToCanvas(self.shadow, canvas, {blendmode = "additive"})
  end
end

function light:drawShine(canvas)
  if self.visible then
    util.drawCanvasToCanvas(self.shine, canvas)
  end
end

function light:drawPixelShadow(l,t,w,h, normalMap, canvas)
  if self.visible then
    if self.normalInvert then
      self.normalInvertShader:send('screenResolution', {w, h})
      self.normalInvertShader:send('lightColor', {self.red / 255.0, self.green / 255.0, self.blue / 255.0})
      self.normalInvertShader:send('lightPosition',{self.x, lh - self.y, self.z / 255.0})
      self.normalInvertShader:send('lightRange',{self.range})
      self.normalInvertShader:send("lightSmooth", self.smooth)
      self.normalInvertShader:send("lightAngle", math.pi - self.angle / 2.0)
      self.normalInvertShader:send("lightDirection", self.direction)
      util.drawCanvasToCanvas(normalMap, canvas, {shader = self.normalInvertShader})
    else
      self.normalShader:send('screenResolution', {w, h})
      self.normalShader:send('lightColor', {self.red / 255.0, self.green / 255.0, self.blue / 255.0})
      self.normalShader:send('lightPosition',{self.x, h - self.y, self.z / 255.0})
      self.normalShader:send('lightRange',{self.range})
      self.normalShader:send("lightSmooth", self.smooth)
      self.normalShader:send("lightAngle", math.pi - self.angle / 2.0)
      self.normalShader:send("lightDirection", self.direction)
      util.drawCanvasToCanvas(normalMap, canvas, {shader = self.normalShader})
    end
  end
end

return light
