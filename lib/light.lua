local _PACKAGE = (...):match("^(.+)[%./][^%./]+") or ""
local class = require(_PACKAGE.."/class")
local stencils = require(_PACKAGE..'/stencils')
local util = require(_PACKAGE..'/util')

local light = class()

light.shineShader  = love.graphics.newShader(_PACKAGE.."/shaders/shine.glsl")
light.normalShader = love.graphics.newShader(_PACKAGE.."/shaders/normal.glsl")
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

	self.shadow = love.graphics.newCanvas(w, h)
	self.shine  = love.graphics.newCanvas(w, h)
  self.normalShader:send('screenResolution', {w, h})
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

  return (lx + rs) > 0 and 
         (lx - rs) < w/s and 
         (ly + rs) > 0 and 
         (ly - rs) < h/s
end

function light:drawShadow(l,t,w,h,s,bodies, canvas)
  if self.visible and self:inRange(l,t,w,h,s) then
    -- calculate shadows
    local shadow_geometry = {}
    for i = 1, #bodies do
      local current = bodies[i]:calculateShadow(self)
      if current ~= nil then
        shadow_geometry[#shadow_geometry + 1] = current
      end
    end

    -- draw shadow
    self.shadow:clear()
    util.drawto(self.shadow, l, t, s, function()
 
      self.shineShader:send("lightPosition", {(self.x + l/s) * s, (h/s - (self.y + t/s)) * s, (self.z * 10)/255.0})
      self.shineShader:send("lightRange", self.range*s)
      self.shineShader:send("lightColor", {self.red / 255.0, self.green / 255.0, self.blue / 255.0})
      self.shineShader:send("lightSmooth", self.smooth)
      self.shineShader:send("lightGlow", {1.0 - self.glowSize, self.glowStrength})
      self.shineShader:send("lightAngle", math.pi - self.angle / 2.0)
      self.shineShader:send("lightDirection", self.direction)
      love.graphics.setShader(self.shineShader)
      love.graphics.setInvertedStencil(stencils.shadow(shadow_geometry, bodies))
      love.graphics.setBlendMode("additive")
      love.graphics.rectangle("fill", -l/s,-t/s,w/s,h/s)

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
          if shadow_geometry[k].circle then
            love.graphics.arc("fill", unpack(shadow_geometry[k].circle))
          end
        end
      end

      for k = 1, #bodies do
        bodies[k]:drawShadow(self,l,t,w,h,s)
      end
    end)

    love.graphics.setStencil()
    love.graphics.setShader()
    util.drawCanvasToCanvas(self.shadow, canvas, {blendmode = "additive"})
  end
end

function light:drawShine(l,t,w,h,s,bodies,canvas)
  if self.visible and self:inRange(l,t,w,h,s) then
    --update shine
    self.shine:clear(255, 255, 255)
    util.drawto(self.shine, l, t, s, function()
      love.graphics.setShader(self.shineShader)
      love.graphics.setBlendMode("alpha")
      love.graphics.setStencil(stencils.shine(bodies))
      love.graphics.rectangle("fill", -l/s,-t/s,w/s,h/s)
    end)
    love.graphics.setStencil()
    love.graphics.setShader()
    util.drawCanvasToCanvas(self.shine, canvas, {blendmode = "additive"})
  end
end

function light:drawNormalShading(l,t,w,h,s, normalMap, canvas)
  if self.visible and self:inRange(l,t,w,h,s) then
    self.shadowShader:send('lightColor', {self.red / 255.0, self.green / 255.0, self.blue / 255.0})
    self.shadowShader:send("lightPosition", {(self.x + l/s) * s, (h/s - (self.y + t/s)) * s, (self.z * 10) / 255.0})
    self.shadowShader:send('lightRange',{self.range})
    self.shadowShader:send("lightSmooth", self.smooth)
    self.shadowShader:send("lightGlow", {1.0 - self.glowSize, self.glowStrength})
    self.shadowShader:send("lightAngle", math.pi - self.angle / 2.0)
    self.shadowShader:send("lightDirection", self.direction)
    self.shadowShader:send("invert_normal", self.normalInvert == true)
    util.drawCanvasToCanvas(normalMap, canvas, {shader = self.shadowShader})
  end
end

function light:setVisible(visible)
  self.visible = visible
end

return light
