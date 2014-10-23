local _PACKAGE = (...):match("^(.+)[%./][^%./]+") or ""
local class = require(_PACKAGE.."/class")
local normal_map = require(_PACKAGE..'/normal_map')
local vector = require(_PACKAGE..'/vector')
local shadowLength = 100000

local body = class()

body.glowShader     = love.graphics.newShader(_PACKAGE.."/shaders/glow.glsl")
body.materialShader = love.graphics.newShader(_PACKAGE.."/shaders/material.glsl")

function body:init(id, type, ...)
	local args = {...}
	self.id = id
	self.type = type
	self.shine = true
	self.red = 0
	self.green = 0
	self.blue = 0
	self.alpha = 1.0
	self.glowRed = 255
	self.glowGreen = 255
	self.glowBlue = 255
	self.glowStrength = 0.0
	self.tileX = 0
	self.tileY = 0

	if self.type == "circle" then
		self.x = args[1] or 0
		self.y = args[2] or 0
    self:setShadowType('circle', args[3], args[4], args[5])
	elseif self.type == "rectangle" then
		self.x = args[1] or 0
		self.y = args[2] or 0
    self:setShadowType('rectangle', args[3], args[4])
	elseif self.type == "polygon" then
    self:setShadowType('polygon', ...)
	elseif self.type == "image" then
		self.img = args[1]
		self.x = args[2] or 0
		self.y = args[3] or 0
		if self.img then
			self.imgWidth = self.img:getWidth()
			self.imgHeight = self.img:getHeight()
			self.ix = self.imgWidth * 0.5
			self.iy = self.imgHeight * 0.5
		end
    self:setShadowType('rectangle', args[4] or self.imgWidth, args[5] or self.imgHeight, args[6], args[7])
		self.reflective = true
	elseif self.type == "refraction" then
    self:initNormal(...)
		self.refraction = true
	elseif self.type == "reflection" then
    self:initNormal(...)
		self.reflection = true
	end
end

function body:initNormal(...)
	local args = {...}
  self.normal = args[1]
  self.x = args[2] or 0
  self.y = args[3] or 0
  if self.normal then
    self.normalWidth = self.normal:getWidth()
    self.normalHeight = self.normal:getHeight()
    self.width = args[4] or self.normalWidth
    self.height = args[5] or self.normalHeight
    self.nx = self.normalWidth * 0.5
    self.ny = self.normalHeight * 0.5
    self.normal:setWrap("repeat", "repeat")
    self.normalVert = {
      {0.0, 0.0, 0.0, 0.0},
      {self.width, 0.0, 1.0, 0.0},
      {self.width, self.height, 1.0, 1.0},
      {0.0, self.height, 0.0, 1.0}
    }
    self.normalMesh = love.graphics.newMesh(self.normalVert, self.normal, "fan")
  else
    self.width = args[4] or 64
    self.height = args[5] or 64
  end
  self.ox = self.width * 0.5
  self.oy = self.height * 0.5
end

-- refresh
function body:refresh()
  if self.x and self.y and self.width and self.height and self.ox and self.oy then
    self.data = {
      self.x - self.ox,
      self.y - self.oy,
      self.x - self.ox + self.width,
      self.y - self.oy,
      self.x - self.ox + self.width,
      self.y - self.oy + self.height,
      self.x - self.ox,
      self.y - self.oy + self.height
    }
  end
end

-- set position
function body:setPosition(x, y)
  if x ~= self.x or y ~= self.y then
    self.x = x
    self.y = y
    self:refresh()
  end
end

-- set x position
function body:setX(x)
  if x ~= self.x then
    self.x = x
    self:refresh()
  end
end

-- set y position
function body:setY(y)
  if y ~= self.y then
    self.y = y
    self:refresh()
  end
end

-- get x position
function body:getX()
  return self.x
end

-- get y position
function body:getY(y)
  return self.y
end

-- get width
function body:getWidth()
  return self.width
end

-- get height
function body:getHeight()
  return self.height
end

-- get image width
function body:getImageWidth()
  return self.imgWidth
end

-- get image height
function body:getImageHeight()
  return self.imgHeight
end

-- set dimension
function body:setDimension(width, height)
  self.width = width
  self.height = height
  self:refresh()
end

-- set offset
function body:setOffset(ox, oy)
  if ox ~= self.ox or oy ~= self.oy then
    self.ox = ox
    self.oy = oy
    self:refresh()
  end
end

-- set offset
function body:setImageOffset(ix, iy)
  if ix ~= self.ix or iy ~= self.iy then
    self.ix = ix
    self.iy = iy
    self:refresh()
  end
end

-- set offset
function body:setNormalOffset(nx, ny)
  if nx ~= self.nx or ny ~= self.ny then
    self.nx = nx
    self.ny = ny
    self:refresh()
  end
end

-- set glow color
function body:setGlowColor(red, green, blue)
  self.glowRed = red
  self.glowGreen = green
  self.glowBlue = blue
end

-- set glow alpha
function body:setGlowStrength(strength)
  self.glowStrength = strength
end

-- get radius
function body:getRadius()
  return self.radius
end

-- set radius
function body:setRadius(radius)
  if radius ~= self.radius then
    self.radius = radius
  end
end

-- set polygon data
function body:setPoints(...)
  self.data = {...}
end

-- get polygon data
function body:getPoints()
  return unpack(self.data)
end

-- set shadow on/off
function body:setShadow(b)
  self.castsNoShadow = not b
end

-- set shine on/off
function body:setShine(b)
  self.shine = b
end

-- set glass color
function body:setColor(red, green, blue)
  self.red = red
  self.green = green
  self.blue = blue
end

-- set glass alpha
function body:setAlpha(alpha)
  self.alpha = alpha
end

-- set reflection on/off
function body:setReflection(reflection)
  self.reflection = reflection
end

-- set refraction on/off
function body:setRefraction(refraction)
  self.refraction = refraction
end

-- set reflective on other objects on/off
function body:setReflective(reflective)
  self.reflective = reflective
end

-- set refractive on other objects on/off
function body:setRefractive(refractive)
  self.refractive = refractive
end

-- set image
function body:setImage(img)
  if img then
    self.img = img
    self.imgWidth = self.img:getWidth()
    self.imgHeight = self.img:getHeight()
    self.ix = self.imgWidth * 0.5
    self.iy = self.imgHeight * 0.5
  end
end

-- set normal
function body:setNormalMap(normal, width, height, nx, ny)
  if normal then
    self.normal = normal
    self.normal:setWrap("repeat", "repeat")
    self.normalWidth = width or self.normal:getWidth()
    self.normalHeight = height or self.normal:getHeight()
    self.nx = nx or self.normalWidth * 0.5
    self.ny = ny or self.normalHeight * 0.5
    self.normalVert = {
      {0.0, 0.0, 0.0, 0.0},
      {self.normalWidth, 0.0, self.normalWidth / self.normal:getWidth(), 0.0},
      {self.normalWidth, self.normalHeight, self.normalWidth / self.normal:getWidth(), self.normalHeight / self.normal:getHeight()},
      {0.0, self.normalHeight, 0.0, self.normalHeight / self.normal:getHeight()}
    }
    self.normalMesh = love.graphics.newMesh(self.normalVert, self.normal, "fan")
  else
    self.normalMesh = nil
  end
end

-- set height map
function body:setHeightMap(heightMap, strength)
  self:setNormalMap(normal_map.fromHeightMap(heightMap, strength))
end

-- generate flat normal map
function body:generateNormalMapFlat(mode)
  self:setNormalMap(normal_map.generateFlat(self.img, mode))
end

-- generate faded normal map
function body:generateNormalMapGradient(horizontalGradient, verticalGradient)
  self:setNormalMap(normal_map.generateGradient(self.img, horizontalGradient, verticalGradient))
end

-- generate normal map
function body:generateNormalMap(strength)
  self:setNormalMap(normal_map.fromHeightMap(self.img, strength))
end

-- set material
function body:setMaterial(material)
  if material then
    self.material = material
  end
end

-- set normal
function body:setGlowMap(glow)
  self.glow = glow
  self.glowStrength = 1.0
end

-- set tile offset
function body:setNormalTileOffset(tx, ty)
  self.tileX = tx / self.normalWidth
  self.tileY = ty / self.normalHeight
  self.normalVert = {
    {0.0, 0.0, self.tileX, self.tileY},
    {self.normalWidth, 0.0, self.tileX + 1.0, self.tileY},
    {self.normalWidth, self.normalHeight, self.tileX + 1.0, self.tileY + 1.0},
    {0.0, self.normalHeight, self.tileX, self.tileY + 1.0}
  }
end

-- get type
function body:getType()
  return self.type
end

-- get type
function body:setShadowType(type, ...)
  self.shadowType = type
  local args = {...}
  if self.shadowType == "circle" then
    self.radius = args[1] or 16
    self.ox = args[2] or 0
    self.oy = args[3] or 0
  elseif self.shadowType == "rectangle" then
    self.width = args[1] or 64
    self.height = args[2] or 64
    self.ox = args[3] or self.width * 0.5
    self.oy = args[4] or self.height * 0.5
    self:refresh()
  elseif self.shadowType == "polygon" then
    self.data = args or {0, 0, 0, 0, 0, 0}
  elseif self.shadowType == "image" then
    if self.img then
      self.width = self.imgWidth
      self.height = self.imgHeight
      self.shadowVert = {
        {0.0, 0.0, 0.0, 0.0},
        {self.width, 0.0, 1.0, 0.0},
        {self.width, self.height, 1.0, 1.0},
        {0.0, self.height, 0.0, 1.0}
      }
      if not self.shadowMesh then
        self.shadowMesh = love.graphics.newMesh(self.shadowVert, self.img, "fan")
        self.shadowMesh:setVertexColors(true)
      end
    else
      self.width = 64
      self.height = 64
    end
    self.shadowX = args[1] or 0
    self.shadowY = args[2] or 0
    self.fadeStrength = args[3] or 0.0
  end
end

function body:shadowStencil()
  if self.shadowType == "circle" then
    love.graphics.circle("fill", self.x - self.ox, self.y - self.oy, self.radius)
  elseif self.shadowType == "rectangle" then
    love.graphics.rectangle("fill", self.x - self.ox, self.y - self.oy, self.width, self.height)
  elseif self.shadowType == "polygon" then
    love.graphics.polygon("fill", unpack(self.data))
  elseif self.shadowType == "image" then
  --love.graphics.rectangle("fill", self.x - self.ox, self.y - self.oy, self.width, self.height)
  end
end

function body:drawShadow(light)
  if self.alpha < 1.0 then
    love.graphics.setBlendMode("multiplicative")
    love.graphics.setColor(self.red, self.green, self.blue)
    if self.shadowType == "circle" then
      love.graphics.circle("fill", self.x - self.ox, self.y - self.oy, self.radius)
    elseif self.shadowType == "rectangle" then
      love.graphics.rectangle("fill", self.x - self.ox, self.y - self.oy, self.width, self.height)
    elseif self.shadowType == "polygon" then
      love.graphics.polygon("fill", unpack(self.data))
    end
  end

  if self.shadowType == "image" and self.img then
    love.graphics.setBlendMode("alpha")
    local length = 1.0
    local shadowRotation = math.atan2((self.x) - light.x, (self.y + self.oy) - light.y)

    self.shadowVert = {
      {
        math.sin(shadowRotation) * self.imgHeight * length, 
        (length * math.cos(shadowRotation) + 1.0) * self.imgHeight + (math.cos(shadowRotation) + 1.0) * self.shadowY, 
        0, 0, 
        self.red, 
        self.green, 
        self.blue, 
        self.alpha * self.fadeStrength * 255
      },
      {
        self.imgWidth + math.sin(shadowRotation) * self.imgHeight * length, 
        (length * math.cos(shadowRotation) + 1.0) * self.imgHeight + (math.cos(shadowRotation) + 1.0) * self.shadowY, 
        1, 0, 
        self.red, 
        self.green, 
        self.blue, 
        self.alpha * self.fadeStrength * 255
      },
      {
        self.imgWidth, 
        self.imgHeight + (math.cos(shadowRotation) + 1.0) * self.shadowY, 
        1, 1, 
        self.red, 
        self.green, 
        self.blue, 
        self.alpha * 255
      },
      {
        0, 
        self.imgHeight + (math.cos(shadowRotation) + 1.0) * self.shadowY, 
        0, 1, 
        self.red, 
        self.green, 
        self.blue, 
        self.alpha * 255
      }
    }

    self.shadowMesh:setVertices(self.shadowVert)
    love.graphics.draw(self.shadowMesh, self.x - self.ox, self.y - self.oy, 0, s, s)
  end
end

function body:drawPixelShadow()
  if self.type == "image" and self.normalMesh then
    love.graphics.setColor(255, 255, 255)
    love.graphics.draw(self.normalMesh, self.x - self.nx, self.y - self.ny)
  end
end

function body:drawGlow()
  if self.glowStrength > 0.0 then
    love.graphics.setColor(self.glowRed * self.glowStrength, self.glowGreen * self.glowStrength, self.glowBlue * self.glowStrength)
  else
    love.graphics.setColor(0, 0, 0)
  end

  if self.type == "circle" then
    love.graphics.circle("fill", self.x, self.y, self.radius)
  elseif self.type == "rectangle" then
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
  elseif self.type == "polygon" then
    love.graphics.polygon("fill", unpack(self.data))
  elseif self.type == "image" and self.img then
    if self.glowStrength > 0.0 and self.glow then
      love.graphics.setShader(self.glowShader)
      self.glowShader:send("glowImage", self.glow)
      self.glowShader:send("glowTime", love.timer.getTime() * 0.5)
      love.graphics.setColor(255, 255, 255)
    else
      love.graphics.setShader()
      love.graphics.setColor(0, 0, 0)
    end
    love.graphics.draw(self.img, self.x - self.ix, self.y - self.iy)
  end

  love.graphics.setShader()
end

function body:drawRefraction()
  if self.refraction and self.normal then
    love.graphics.setColor(255, 255, 255)
    if self.tileX == 0.0 and self.tileY == 0.0 then
      love.graphics.draw(normal, self.x - self.nx, self.y - self.ny)
    else
      self.normalMesh:setVertices(self.normalVert)
      love.graphics.draw(self.normalMesh, self.x - self.nx, self.y - self.ny)
    end
  end

  love.graphics.setColor(0, 0, 0)

  if not self.refractive then
    if self.type == "circle" then
      love.graphics.circle("fill", self.x, self.y, self.radius)
    elseif self.type == "rectangle" then
      love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
    elseif self.type == "polygon" then
      love.graphics.polygon("fill", unpack(self.data))
    elseif self.type == "image" and self.img then
      love.graphics.draw(self.img, self.x - self.ix, self.y - self.iy)
    end
  end
end

function body:drawReflection()
  if self.reflection and self.normal then
    love.graphics.setColor(255, 0, 0)
    self.normalMesh:setVertices(self.normalVert)
    love.graphics.draw(self.normalMesh, self.x - self.nx, self.y - self.ny)
  end
  if self.reflective and self.img then
    love.graphics.setColor(0, 255, 0)
    love.graphics.draw(self.img, self.x - self.ix, self.y - self.iy)
  elseif not self.reflection and self.img then
    love.graphics.setColor(0, 0, 0)
    love.graphics.draw(self.img, self.x - self.ix, self.y - self.iy)
  end
end

function body:drawMaterial()
  if self.material and self.normal then
    love.graphics.setShader(self.materialShader)
    love.graphics.setColor(255, 255, 255)
    self.materialShader:send("material", self.material)
    love.graphics.draw(self.normal, self.x - self.nx, self.y - self.ny)
    love.graphics.setShader()
  end
end

function body:calculateShadow(light)
  if self.shadowType == "rectangle" or self.shadowType == "polygon" then
    return self:calculatePolyShadow(light)
  elseif self.shadowType == "circle" then
    return self:calculateCircleShadow(light)
  end
end

function body:calculatePolyShadow(light)
  if self.castsNoShadow then
    return nil
  end

  local curPolygon = self.data
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
    curShadowGeometry.alpha = self.alpha
    curShadowGeometry.red = self.red
    curShadowGeometry.green = self.green
    curShadowGeometry.blue = self.blue
    return curShadowGeometry
  else
    return nil
  end
end

function body:calculateCircleShadow(light)
  if self.castsNoShadow then
    return nil
  end
  local length = math.sqrt(math.pow(light.x - (self.x - self.ox), 2) + math.pow(light.y - (self.y - self.oy), 2))
  if length >= self.radius and length <= light.range then
    local curShadowGeometry = {}
    local angle = math.atan2(light.x - (self.x - self.ox), (self.y - self.oy) - light.y) + math.pi / 2
    local x2 = ((self.x - self.ox) + math.sin(angle) * self.radius)
    local y2 = ((self.y - self.oy) - math.cos(angle) * self.radius)
    local x3 = ((self.x - self.ox) - math.sin(angle) * self.radius)
    local y3 = ((self.y - self.oy) + math.cos(angle) * self.radius)

    curShadowGeometry[1] = x2
    curShadowGeometry[2] = y2
    curShadowGeometry[3] = x3
    curShadowGeometry[4] = y3

    curShadowGeometry[5] = x3 - (light.x - x3) * shadowLength
    curShadowGeometry[6] = y3 - (light.y - y3) * shadowLength
    curShadowGeometry[7] = x2 - (light.x - x2) * shadowLength
    curShadowGeometry[8] = y2 - (light.y - y2) * shadowLength
    curShadowGeometry.alpha = self.alpha
    curShadowGeometry.red = self.red
    curShadowGeometry.green = self.green
    curShadowGeometry.blue = self.blue
    return curShadowGeometry
  else
    return nil
  end
end

return body
