local _PACKAGE = (...):match("^(.+)[%./][^%./]+") or ""
local class = require(_PACKAGE.."/class")
local stencils = require(_PACKAGE..'/stencils')
local util = require(_PACKAGE..'/util')

local light = class()

light.shadowShader = love.graphics.newShader(_PACKAGE.."/shaders/shadow.glsl")

function light:init(x, y, r, g, b, range)
	self.direction = 0
	self.angle = math.pi * 2.0
	self.range = 0
	self.x = x or 0
	self.y = y or 0
	self.z = 1
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
  self.shadowShader:send('screenResolution', {w, h})
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

-- move position
function light:move(x, y, z)
  if x then
    self.x = self.x + x
  end
  if y then
    self.y = self.y + y
  end
  if z then
    self.z = self.z + z
  end
end

-- get x
function light:getPosition()
  return self.x, self.y, self.z
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

function light:inRange(l,t,w,h,s)
  local lx, ly, rs = (self.x + l/s) * s, (self.y + t/s) * s, self.range * s
  return (lx + rs) > 0 and (lx - rs) < w/s and (ly + rs) > 0 and (ly - rs) < h/s
end

function light:drawNormalShading(l,t,w,h,s, normalMap, shadowMap, canvas)
  if self.visible and self:inRange(l,t,w,h,s) then
    self.shadowShader:send('shadowMap', shadowMap)
    self.shadowShader:send('lightColor', {self.red / 255.0, self.green / 255.0, self.blue / 255.0})
    self.shadowShader:send("lightPosition", {(self.x + l/s) * s, (h/s - (self.y + t/s)) * s, (self.z * 10) / 255.0})
    self.shadowShader:send('lightRange',{self.range})
    self.shadowShader:send("lightSmooth", self.smooth)
    self.shadowShader:send("lightGlow", {1.0 - self.glowSize, self.glowStrength})
    self.shadowShader:send("lightAngle", math.pi - self.angle / 2.0)
    self.shadowShader:send("lightDirection", self.direction)
    self.shadowShader:send("invert_normal", self.normalInvert == true)
    util.drawCanvasToCanvas(normalMap, canvas, {
      blendmode = 'additive',
      shader = self.shadowShader
    })
  end
end

function light:setVisible(visible)
  self.visible = visible
end

return light
