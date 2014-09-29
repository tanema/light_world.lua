local _PACKAGE = (...):match("^(.+)[%./][^%./]+") or ""
local class = require(_PACKAGE.."/class")
local stencils = require(_PACKAGE..'/stencils')
local vector = require(_PACKAGE..'/vector')

local light = class()

light.shader             = love.graphics.newShader(_PACKAGE.."/shaders/poly_shadow.glsl")
light.normalShader       = love.graphics.newShader(_PACKAGE.."/shaders/normal.glsl")
light.normalInvertShader = love.graphics.newShader(_PACKAGE.."/shaders/normal_invert.glsl")

function light:init(world, x, y, r, g, b, range)
  self.world = world
	self.direction = 0
	self.angle = math.pi * 2.0
	self.range = 0
	self.shadow = love.graphics.newCanvas()
	self.shine = love.graphics.newCanvas()
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

function light:updateShadow()
  love.graphics.setShader(self.shader)
  if self.x + self.range > self.world.translate_x and self.x - self.range < love.graphics.getWidth() + self.world.translate_x
    and self.y + self.range > self.world.translate_y and self.y - self.range < love.graphics.getHeight() + self.world.translate_y
  then
    local lightposrange = {self.x, love.graphics.getHeight() - self.y, self.range}
    self.shader:send("lightPosition", {self.x - self.world.translate_x, love.graphics.getHeight() - (self.y - self.world.translate_y), self.z})
    self.shader:send("lightRange", self.range)
    self.shader:send("lightColor", {self.red / 255.0, self.green / 255.0, self.blue / 255.0})
    self.shader:send("lightSmooth", self.smooth)
    self.shader:send("lightGlow", {1.0 - self.glowSize, self.glowStrength})
    self.shader:send("lightAngle", math.pi - self.angle / 2.0)
    self.shader:send("lightDirection", self.direction)

    love.graphics.setCanvas(self.shadow)
    love.graphics.clear()

    -- calculate shadows
    local shadow_geometry = self:calculateShadows()

    -- draw shadow
    love.graphics.setInvertedStencil(stencils.shadow(shadow_geometry, self.world.body))
    love.graphics.setBlendMode("additive")
    -- FIND THIS TOOOO
    love.graphics.rectangle("fill", self.world.translate_x, self.world.translate_y, love.graphics.getWidth(), love.graphics.getHeight())

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

    for k = 1, #self.world.body do
      self.world.body[k]:drawShadow(self)
    end

    love.graphics.setShader(self.shader)

    -- draw shine
    love.graphics.setCanvas(self.shine)
    self.shine:clear(255, 255, 255)
    love.graphics.setBlendMode("alpha")
    love.graphics.setStencil(stencils.poly(self.world.body))
    -- WHOA THIS MAY BE THE ISSUE HERE FIND THIS!
    love.graphics.rectangle("fill", self.world.translate_x, self.world.translate_y, love.graphics.getWidth(), love.graphics.getHeight())

    self.visible = true
  else
    self.visible = false
  end
  love.graphics.setShader()
end

function light:drawShadow()
  if self.visible then
    love.graphics.draw(self.shadow, self.world.translate_x, self.world.translate_y)
  end
end

function light:drawShine()
  if self.visible then
    love.graphics.draw(self.shine, self.world.translate_x, self.world.translate_y)
  end
end

local shadowLength = 100000
function light:calculateShadows()
	local shadowGeometry = {}
  local body = self.world.body

	for i = 1, #body do
    local current
		if body[i].shadowType == "rectangle" or body[i].shadowType == "polygon" then
      current = self:calculatePolyShadow(body[i])
		elseif body[i].shadowType == "circle" then
      current = self:calculateCircleShadow(body[i])
		end
    if current ~= nil then
      shadowGeometry[#shadowGeometry + 1] = current
    end
	end

	return shadowGeometry
end

function light:calculatePolyShadow(poly)
  if poly.castsNoShadow then
    return nil
  end

  local curPolygon = poly.data
  local edgeFacingTo = {}
  for k = 1, #curPolygon, 2 do
    local indexOfNextVertex = (k + 2) % #curPolygon
    local normal = {-curPolygon[indexOfNextVertex+1] + curPolygon[k + 1], curPolygon[indexOfNextVertex] - curPolygon[k]}
    local selfToPoint = {curPolygon[k] - self.x, curPolygon[k + 1] - self.y}

    normal = vector.normalize(normal)
    selfToPoint = vector.normalize(selfToPoint)

    local dotProduct = vector.dot(normal, selfToPoint)
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

      local selfVecFrontBack = vector.normalize({curPolygon[nextIndex*2-1] - self.x, curPolygon[nextIndex*2] - self.y})
      curShadowGeometry[3] = curShadowGeometry[1] + selfVecFrontBack[1] * shadowLength
      curShadowGeometry[4] = curShadowGeometry[2] + selfVecFrontBack[2] * shadowLength

    elseif not edgeFacingTo[k] and edgeFacingTo[nextIndex] then
      curShadowGeometry[7] = curPolygon[nextIndex*2-1]
      curShadowGeometry[8] = curPolygon[nextIndex*2]

      local selfVecBackFront = vector.normalize({curPolygon[nextIndex*2-1] - self.x, curPolygon[nextIndex*2] - self.y})
      curShadowGeometry[5] = curShadowGeometry[7] + selfVecBackFront[1] * shadowLength
      curShadowGeometry[6] = curShadowGeometry[8] + selfVecBackFront[2] * shadowLength
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
    curShadowGeometry.alpha = poly.alpha
    curShadowGeometry.red = poly.red
    curShadowGeometry.green = poly.green
    curShadowGeometry.blue = poly.blue
    return curShadowGeometry
  else
    return nil
  end
end

function light:calculateCircleShadow(circle)
  if circle.castsNoShadow then
    return nil
  end
  local length = math.sqrt(math.pow(self.x - (circle.x - circle.ox), 2) + math.pow(self.y - (circle.y - circle.oy), 2))
  if length >= circle.radius and length <= self.range then
    local curShadowGeometry = {}
    local angle = math.atan2(self.x - (circle.x - circle.ox), (circle.y - circle.oy) - self.y) + math.pi / 2
    local x2 = ((circle.x - circle.ox) + math.sin(angle) * circle.radius)
    local y2 = ((circle.y - circle.oy) - math.cos(angle) * circle.radius)
    local x3 = ((circle.x - circle.ox) - math.sin(angle) * circle.radius)
    local y3 = ((circle.y - circle.oy) + math.cos(angle) * circle.radius)

    curShadowGeometry[1] = x2
    curShadowGeometry[2] = y2
    curShadowGeometry[3] = x3
    curShadowGeometry[4] = y3

    curShadowGeometry[5] = x3 - (self.x - x3) * shadowLength
    curShadowGeometry[6] = y3 - (self.y - y3) * shadowLength
    curShadowGeometry[7] = x2 - (self.x - x2) * shadowLength
    curShadowGeometry[8] = y2 - (self.y - y2) * shadowLength
    curShadowGeometry.alpha = circle.alpha
    curShadowGeometry.red = circle.red
    curShadowGeometry.green = circle.green
    curShadowGeometry.blue = circle.blue
    return curShadowGeometry
  else
    return nil
  end
end

function light:drawPixelShadow()
  if self.visible then
    if self.normalInvert then
      self.normalInvertShader:send('screenResolution', {love.graphics.getWidth(), love.graphics.getHeight()})
      self.normalInvertShader:send('lightColor', {self.red / 255.0, self.green / 255.0, self.blue / 255.0})
      self.normalInvertShader:send('lightPosition',{self.x, love.graphics.getHeight() - self.y, self.z / 255.0})
      self.normalInvertShader:send('lightRange',{self.range})
      self.normalInvertShader:send("lightSmooth", self.smooth)
      self.normalInvertShader:send("lightAngle", math.pi - self.angle / 2.0)
      self.normalInvertShader:send("lightDirection", self.direction)
      love.graphics.setShader(self.normalInvertShader)
    else
      self.normalShader:send('screenResolution', {love.graphics.getWidth(), love.graphics.getHeight()})
      self.normalShader:send('lightColor', {self.red / 255.0, self.green / 255.0, self.blue / 255.0})
      self.normalShader:send('lightPosition',{self.x, love.graphics.getHeight() - self.y, self.z / 255.0})
      self.normalShader:send('lightRange',{self.range})
      self.normalShader:send("lightSmooth", self.smooth)
      self.normalShader:send("lightAngle", math.pi - self.angle / 2.0)
      self.normalShader:send("lightDirection", self.direction)
      love.graphics.setShader(self.normalShader)
    end
    love.graphics.draw(self.world.normalMap, self.world.translate_x, self.world.translate_y)
  end
end

return light
