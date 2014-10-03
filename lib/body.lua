local _PACKAGE = (...):match("^(.+)[%./][^%./]+") or ""
local class = require(_PACKAGE.."/class")
local height_map_conv = require(_PACKAGE..'/height_map_conv')

local body = class()

body.glowShader     = love.graphics.newShader(_PACKAGE.."/shaders/glow.glsl")
body.materialShader = love.graphics.newShader(_PACKAGE.."/shaders/material.glsl")

function body:init(id, type, ...)
	local args = {...}
	self.id = id
	self.type = type
	self.normal = nil
	self.material = nil
	self.glow = nil

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
		self.radius = args[3] or 16
		self.ox = args[4] or 0
		self.oy = args[5] or 0
		self.shadowType = "circle"
	elseif self.type == "rectangle" then
		self.x = args[1] or 0
		self.y = args[2] or 0
		self.width = args[3] or 64
		self.height = args[4] or 64
		self.ox = self.width * 0.5
		self.oy = self.height * 0.5
		self.shadowType = "rectangle"
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
	elseif self.type == "polygon" then
		self.shadowType = "polygon"
		self.data = args or {0, 0, 0, 0, 0, 0}
	elseif self.type == "image" then
		self.img = args[1]
		self.x = args[2] or 0
		self.y = args[3] or 0
		if self.img then
			self.imgWidth = self.img:getWidth()
			self.imgHeight = self.img:getHeight()
			self.width = args[4] or self.imgWidth
			self.height = args[5] or self.imgHeight
			self.ix = self.imgWidth * 0.5
			self.iy = self.imgHeight * 0.5
			self.vert = {
				{ 0.0, 0.0, 0.0, 0.0 },
				{ self.width, 0.0, 1.0, 0.0 },
				{ self.width, self.height, 1.0, 1.0 },
				{ 0.0, self.height, 0.0, 1.0 },
			}
			self.msh = love.graphics.newMesh(self.vert, self.img, "fan")
		else
			self.width = args[4] or 64
			self.height = args[5] or 64
		end
		self.ox = args[6] or self.width * 0.5
		self.oy = args[7] or self.height * 0.5
		self.shadowType = "rectangle"
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
		self.reflective = true
	elseif self.type == "refraction" then
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
		self.refraction = true
	elseif self.type == "reflection" then
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
		self.reflection = true
	end
end

-- refresh
function body:refresh()
  if self.data then
    self.data[1] = self.x - self.ox
    self.data[2] = self.y - self.oy
    self.data[3] = self.x - self.ox + self.width
    self.data[4] = self.y - self.oy
    self.data[5] = self.x - self.ox + self.width
    self.data[6] = self.y - self.oy + self.height
    self.data[7] = self.x - self.ox
    self.data[8] = self.y - self.oy + self.height
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
    if self.shadowType == "rectangle" then
      self:refresh()
    end
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
  self:setNormalMap(height_map_conv.toNormalMap(heightMap, strength))
end

-- generate flat normal map
function body:generateNormalMapFlat(mode)
  local imgData = self.img:getData()
  local imgNormalData = love.image.newImageData(self.imgWidth, self.imgHeight)
  local color

  if mode == "top" then
    color = {127, 127, 255}
  elseif mode == "front" then
    color = {127, 0, 127}
  elseif mode == "back" then
    color = {127, 255, 127}
  elseif mode == "left" then
    color = {31, 0, 223}
  elseif mode == "right" then
    color = {223, 0, 127}
  end

  for i = 0, self.imgHeight - 1 do
    for k = 0, self.imgWidth - 1 do
      local r, g, b, a = imgData:getPixel(k, i)
      if a > 0 then
        imgNormalData:setPixel(k, i, color[1], color[2], color[3], 255)
      end
    end
  end

  self:setNormalMap(love.graphics.newImage(imgNormalData))
end

-- generate faded normal map
function body:generateNormalMapGradient(horizontalGradient, verticalGradient)
  local imgData = self.img:getData()
  local imgNormalData = love.image.newImageData(self.imgWidth, self.imgHeight)
  local dx = 255.0 / self.imgWidth
  local dy = 255.0 / self.imgHeight
  local nx
  local ny
  local nz

  for i = 0, self.imgWidth - 1 do
    for k = 0, self.imgHeight - 1 do
      local r, g, b, a = imgData:getPixel(i, k)
      if a > 0 then
        if horizontalGradient == "gradient" then
          nx = i * dx
        elseif horizontalGradient == "inverse" then
          nx = 255 - i * dx
        else
          nx = 127
        end

        if verticalGradient == "gradient" then
          ny = 127 - k * dy * 0.5
          nz = 255 - k * dy * 0.5
        elseif verticalGradient == "inverse" then
          ny = 127 + k * dy * 0.5
          nz = 127 - k * dy * 0.25
        else
          ny = 255
          nz = 127
        end

        imgNormalData:setPixel(i, k, nx, ny, nz, 255)
      end
    end
  end

  self:setNormalMap(love.graphics.newImage(imgNormalData))
end

-- generate normal map
function body:generateNormalMap(strength)
  self:setNormalMap(height_map_conv.toNormalMap(self.img, strength))
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

function body:drawShadow(light, l,t,w,h)
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
      {math.sin(shadowRotation) * self.imgHeight * length, (length * math.cos(shadowRotation) + 1.0) * self.imgHeight + (math.cos(shadowRotation) + 1.0) * self.shadowY, 0, 0, self.red, self.green, self.blue, self.alpha * self.fadeStrength * 255},
      {self.imgWidth + math.sin(shadowRotation) * self.imgHeight * length, (length * math.cos(shadowRotation) + 1.0) * self.imgHeight + (math.cos(shadowRotation) + 1.0) * self.shadowY, 1, 0, self.red, self.green, self.blue, self.alpha * self.fadeStrength * 255},
      {self.imgWidth, self.imgHeight + (math.cos(shadowRotation) + 1.0) * self.shadowY, 1, 1, self.red, self.green, self.blue, self.alpha * 255},
      {0, self.imgHeight + (math.cos(shadowRotation) + 1.0) * self.shadowY, 0, 1, self.red, self.green, self.blue, self.alpha * 255}
    }

    self.shadowMesh:setVertices(self.shadowVert)
    love.graphics.draw(self.shadowMesh, self.x - self.ox + l, self.y - self.oy + t)
  end
end

function body:drawPixelShadow(l,t,w,h)
  if self.type == "image" and self.normalMesh then
    love.graphics.setColor(255, 255, 255)
    love.graphics.draw(self.normalMesh, self.x - self.nx, self.y - self.ny)
  end
end

function body:drawGlow(l,t,w,h)
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

function body:drawRefraction(l,t,w,h)
  if self.refraction and self.normal then
    love.graphics.setColor(255, 255, 255)
    if self.tileX == 0.0 and self.tileY == 0.0 then
      love.graphics.draw(normal, self.x - self.nx + l, self.y - self.ny + t)
    else
      self.normalMesh:setVertices(self.normalVert)
      love.graphics.draw(self.normalMesh, self.x - self.nx + l, self.y - self.ny + t)
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
      love.graphics.draw(self.img, self.x - self.ix + l, self.y - self.iy + t)
    end
  end
end

function body:drawReflection(l,t,w,h)
  if self.reflection and self.normal then
    love.graphics.setColor(255, 0, 0)
    self.normalMesh:setVertices(self.normalVert)
    love.graphics.draw(self.normalMesh, self.x - self.nx + l, self.y - self.ny + t)
  end
  if self.reflective and self.img then
    love.graphics.setColor(0, 255, 0)
    love.graphics.draw(self.img, self.x - self.ix + l, self.y - self.iy + t)
  elseif not self.reflection and self.img then
    love.graphics.setColor(0, 0, 0)
    love.graphics.draw(self.img, self.x - self.ix + l, self.y - self.iy + t)
  end
end

function body:drawMaterial(l,t,w,h)
  if self.material and self.normal then
    love.graphics.setShader(self.materialShader)
    love.graphics.setColor(255, 255, 255)
    self.materialShader:send("material", self.material)
    love.graphics.draw(self.normal, self.x - self.nx + l, self.y - self.ny + t)
    love.graphics.setShader()
  end
end

return body
