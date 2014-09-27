local _PACKAGE = (...):match("^(.+)[%./][^%./]+") or ""
local class = require(_PACKAGE.."/class")
local stencils = require(_PACKAGE..'/stencils')
local vector = require(_PACKAGE..'/vector')

local light = class()

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
  if self.x + self.range > self.world.translate_x and self.x - self.range < love.graphics.getWidth() + self.world.translate_x
    and self.y + self.range > self.world.translate_y and self.y - self.range < love.graphics.getHeight() + self.world.translate_y
  then
    local lightposrange = {self.x, love.graphics.getHeight() - self.y, self.range}
    local light = self
    self.world.direction = self.world.direction + 0.002
    self.world.shader:send("lightPosition", {self.x - self.world.translate_x, love.graphics.getHeight() - (self.y - self.world.translate_y), self.z})
    self.world.shader:send("lightRange", self.range)
    self.world.shader:send("lightColor", {self.red / 255.0, self.green / 255.0, self.blue / 255.0})
    self.world.shader:send("lightSmooth", self.smooth)
    self.world.shader:send("lightGlow", {1.0 - self.glowSize, self.glowStrength})
    self.world.shader:send("lightAngle", math.pi - self.angle / 2.0)
    self.world.shader:send("lightDirection", self.direction)

    love.graphics.setCanvas(self.shadow)
    love.graphics.clear()

    -- calculate shadows
    local shadow_geometry = self.calculateShadows(light, self.world.body)

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

    love.graphics.setShader(self.world.shader)

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

function light.calculateShadows(light, body)
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

function light:drawPixelShadow()
  if self.visible then
    if self.normalInvert then
      self.world.normalInvertShader:send('screenResolution', {love.graphics.getWidth(), love.graphics.getHeight()})
      self.world.normalInvertShader:send('lightColor', {self.red / 255.0, self.green / 255.0, self.blue / 255.0})
      self.world.normalInvertShader:send('lightPosition',{self.x, love.graphics.getHeight() - self.y, self.z / 255.0})
      self.world.normalInvertShader:send('lightRange',{self.range})
      self.world.normalInvertShader:send("lightSmooth", self.smooth)
      self.world.normalInvertShader:send("lightAngle", math.pi - self.angle / 2.0)
      self.world.normalInvertShader:send("lightDirection", self.direction)
      love.graphics.setShader(self.world.normalInvertShader)
    else
      self.world.normalShader:send('screenResolution', {love.graphics.getWidth(), love.graphics.getHeight()})
      self.world.normalShader:send('lightColor', {self.red / 255.0, self.green / 255.0, self.blue / 255.0})
      self.world.normalShader:send('lightPosition',{self.x, love.graphics.getHeight() - self.y, self.z / 255.0})
      self.world.normalShader:send('lightRange',{self.range})
      self.world.normalShader:send("lightSmooth", self.smooth)
      self.world.normalShader:send("lightAngle", math.pi - self.angle / 2.0)
      self.world.normalShader:send("lightDirection", self.direction)
      love.graphics.setShader(self.world.normalShader)
    end
    love.graphics.draw(self.world.normalMap, self.world.translate_x, self.world.translate_y)
  end
end

return light
