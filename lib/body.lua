local _PACKAGE = (...):match("^(.+)[%./][^%./]+") or ""
local class = require(_PACKAGE.."/class")

local body = class(function(o, world, id, type, ...)
	local args = {...}
	o.id = id
	o.type = type
	o.normal = nil
	o.material = nil
	o.glow = nil
  o.world = world
	if o.type == "circle" then
		o.x = args[1] or 0
		o.y = args[2] or 0
		o.radius = args[3] or 16
		o.ox = args[4] or 0
		o.oy = args[5] or 0
		o.shadowType = "circle"
		o.reflection = false
		o.reflective = false
		o.refraction = false
		o.refractive = false
		world.isShadows = true
	elseif o.type == "rectangle" then
		o.x = args[1] or 0
		o.y = args[2] or 0
		o.width = args[3] or 64
		o.height = args[4] or 64
		o.ox = o.width * 0.5
		o.oy = o.height * 0.5
		o.shadowType = "rectangle"
		o.data = {
			o.x - o.ox,
			o.y - o.oy,
			o.x - o.ox + o.width,
			o.y - o.oy,
			o.x - o.ox + o.width,
			o.y - o.oy + o.height,
			o.x - o.ox,
			o.y - o.oy + o.height
		}
		o.reflection = false
		o.reflective = false
		o.refraction = false
		o.refractive = false
		world.isShadows = true
	elseif o.type == "polygon" then
		o.shadowType = "polygon"
		o.data = args or {0, 0, 0, 0, 0, 0}
		o.reflection = false
		o.reflective = false
		o.refraction = false
		o.refractive = false
		world.isShadows = true
	elseif o.type == "image" then
		o.img = args[1]
		o.x = args[2] or 0
		o.y = args[3] or 0
		if o.img then
			o.imgWidth = o.img:getWidth()
			o.imgHeight = o.img:getHeight()
			o.width = args[4] or o.imgWidth
			o.height = args[5] or o.imgHeight
			o.ix = o.imgWidth * 0.5
			o.iy = o.imgHeight * 0.5
			o.vert = {
				{ 0.0, 0.0, 0.0, 0.0 },
				{ o.width, 0.0, 1.0, 0.0 },
				{ o.width, o.height, 1.0, 1.0 },
				{ 0.0, o.height, 0.0, 1.0 },
			}
			o.msh = love.graphics.newMesh(o.vert, o.img, "fan")
		else
			o.width = args[4] or 64
			o.height = args[5] or 64
		end
		o.ox = args[6] or o.width * 0.5
		o.oy = args[7] or o.height * 0.5
		o.shadowType = "rectangle"
		o.data = {
			o.x - o.ox,
			o.y - o.oy,
			o.x - o.ox + o.width,
			o.y - o.oy,
			o.x - o.ox + o.width,
			o.y - o.oy + o.height,
			o.x - o.ox,
			o.y - o.oy + o.height
		}
		o.reflection = false
		o.reflective = true
		o.refraction = false
		o.refractive = false
		world.isShadows = true
	elseif o.type == "refraction" then
		o.normal = args[1]
		o.x = args[2] or 0
		o.y = args[3] or 0
		if o.normal then
			o.normalWidth = o.normal:getWidth()
			o.normalHeight = o.normal:getHeight()
			o.width = args[4] or o.normalWidth
			o.height = args[5] or o.normalHeight
			o.nx = o.normalWidth * 0.5
			o.ny = o.normalHeight * 0.5
			o.normal:setWrap("repeat", "repeat")
			o.normalVert = {
				{0.0, 0.0, 0.0, 0.0},
				{o.width, 0.0, 1.0, 0.0},
				{o.width, o.height, 1.0, 1.0},
				{0.0, o.height, 0.0, 1.0}
			}
			o.normalMesh = love.graphics.newMesh(o.normalVert, o.normal, "fan")
		else
			o.width = args[4] or 64
			o.height = args[5] or 64
		end
		o.ox = o.width * 0.5
		o.oy = o.height * 0.5
		o.reflection = false
		o.reflective = false
		o.refraction = true
		o.refractive = false
		world.isRefraction = true
	elseif o.type == "reflection" then
		o.normal = args[1]
		o.x = args[2] or 0
		o.y = args[3] or 0
		if o.normal then
			o.normalWidth = o.normal:getWidth()
			o.normalHeight = o.normal:getHeight()
			o.width = args[4] or o.normalWidth
			o.height = args[5] or o.normalHeight
			o.nx = o.normalWidth * 0.5
			o.ny = o.normalHeight * 0.5
			o.normal:setWrap("repeat", "repeat")
			o.normalVert = {
				{0.0, 0.0, 0.0, 0.0},
				{o.width, 0.0, 1.0, 0.0},
				{o.width, o.height, 1.0, 1.0},
				{0.0, o.height, 0.0, 1.0}
			}
			o.normalMesh = love.graphics.newMesh(o.normalVert, o.normal, "fan")
		else
			o.width = args[4] or 64
			o.height = args[5] or 64
		end
		o.ox = o.width * 0.5
		o.oy = o.height * 0.5
		o.reflection = true
		o.reflective = false
		o.refraction = false
		o.refractive = false
		world.isReflection = true
	end
	o.shine = true
	o.red = 0
	o.green = 0
	o.blue = 0
	o.alpha = 1.0
	o.glowRed = 255
	o.glowGreen = 255
	o.glowBlue = 255
	o.glowStrength = 0.0
	o.tileX = 0
	o.tileY = 0
end)

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
    self.world.changed = true
  end
end
-- set x position
function body:setX(x)
  if x ~= self.x then
    self.x = x
    self:refresh()
    self.world.changed = true
  end
end
-- set y position
function body:setY(y)
  if y ~= self.y then
    self.y = y
    self:refresh()
    self.world.changed = true
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
  self.world.changed = true
end
-- set offset
function body:setOffset(ox, oy)
  if ox ~= self.ox or oy ~= self.oy then
    self.ox = ox
    self.oy = oy
    if self.shadowType == "rectangle" then
      self:refresh()
    end
    self.world.changed = true
  end
end
-- set offset
function body:setImageOffset(ix, iy)
  if ix ~= self.ix or iy ~= self.iy then
    self.ix = ix
    self.iy = iy
    self:refresh()
    self.world.changed = true
  end
end
-- set offset
function body:setNormalOffset(nx, ny)
  if nx ~= self.nx or ny ~= self.ny then
    self.nx = nx
    self.ny = ny
    self:refresh()
    self.world.changed = true
  end
end
-- set glow color
function body:setGlowColor(red, green, blue)
  self.glowRed = red
  self.glowGreen = green
  self.glowBlue = blue
  self.world.changed = true
end
-- set glow alpha
function body:setGlowStrength(strength)
  self.glowStrength = strength
  self.world.changed = true
end
-- get radius
function body:getRadius()
  return self.radius
end
-- set radius
function body:setRadius(radius)
  if radius ~= self.radius then
    self.radius = radius
    self.world.changed = true
  end
end
-- set polygon data
function body:setPoints(...)
  self.data = {...}
  self.world.changed = true
end
-- get polygon data
function body:getPoints()
  return unpack(self.data)
end
-- set shadow on/off
function body:setShadowType(type)
  self.shadowType = type
  self.world.changed = true
end
-- set shadow on/off
function body:setShadow(b)
  self.castsNoShadow = not b
  self.world.changed = true
end
-- set shine on/off
function body:setShine(b)
  self.shine = b
  self.world.changed = true
end
-- set glass color
function body:setColor(red, green, blue)
  self.red = red
  self.green = green
  self.blue = blue
  self.world.changed = true
end
-- set glass alpha
function body:setAlpha(alpha)
  self.alpha = alpha
  self.world.changed = true
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

    self.world.isPixelShadows = true
  else
    self.normalMesh = nil
  end
end
-- set height map
function body:setHeightMap(heightMap, strength)
  self:setNormalMap(HeightMapToNormalMap(heightMap, strength))
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
  self:setNormalMap(HeightMapToNormalMap(self.img, strength))
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

  self.world.isGlow = true
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
  self.world.changed = true
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

return body
