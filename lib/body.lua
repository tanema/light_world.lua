local _PACKAGE = (...):match("^(.+)[%./][^%./]+") or ""
local class = require(_PACKAGE.."/class")
local normal_map = require(_PACKAGE..'/normal_map')
local util = require(_PACKAGE..'/util')
local vec2 = require(_PACKAGE..'/vec2')
local body = class()

body.glowShader     = love.graphics.newShader(_PACKAGE.."/shaders/glow.glsl")
body.materialShader = love.graphics.newShader(_PACKAGE.."/shaders/material.glsl")

function body:init(id, type, ...)
	local args = {...}
	self.id = id
	self.type = type
	self.shine = true
	self.red = 1.0
	self.green = 1.0
	self.blue = 1.0
	self.alpha = 1.0
	self.glowRed = 255
	self.glowGreen = 255
	self.glowBlue = 255
	self.glowStrength = 0.0
	self.tileX = 0
	self.tileY = 0
  self.zheight = 1
 
  self.castsNoShadow = false
  self.visible = true

	if self.type == "circle" then
		self.x = args[1] or 0
		self.y = args[2] or 0

    circle_canvas = love.graphics.newCanvas(args[3]*2, args[3]*2)
    util.drawto(circle_canvas, 0, 0, 1, function()
      love.graphics.circle('fill', args[3], args[3], args[3]) 
    end)
    self.img = love.graphics.newImage(circle_canvas:getImageData()) 
    self.imgWidth = self.img:getWidth()
    self.imgHeight = self.img:getHeight()
    self.ix = self.imgWidth * 0.5
    self.iy = self.imgHeight * 0.5
    self:generateNormalMapFlat("top")

    self:setShadowType('circle', args[3], args[4], args[5])
	elseif self.type == "rectangle" then
		self.x = args[1] or 0
		self.y = args[2] or 0

    rectangle_canvas = love.graphics.newCanvas(args[3], args[4])
    util.drawto(rectangle_canvas, 0, 0, 1, function()
      love.graphics.rectangle('fill', 0, 0, args[3], args[4]) 
    end)
    self.img = love.graphics.newImage(rectangle_canvas:getImageData()) 
    self.imgWidth = self.img:getWidth()
    self.imgHeight = self.img:getHeight()
    self.ix = self.imgWidth * 0.5
    self.iy = self.imgHeight * 0.5
    self:generateNormalMapFlat("top")

    self:setShadowType('rectangle', args[3], args[4])
	elseif self.type == "polygon" then
    self:setPoints(...)
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
    self:generateNormalMapFlat("top")
    self:setShadowType('rectangle', args[4] or self.imgWidth, args[5] or self.imgHeight, args[6], args[7])
		self.reflective = true
	elseif self.type == "refraction" then
    self:initNormal(...)
		self.refraction = true
	elseif self.type == "reflection" then
    self:initNormal(...)
		self.reflection = true
	end
  self.old_x, self.old_y = self.x, self.y
end

--use for refraction and reflection because they are both just a normal map
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
  if self.shadowType == "rectangle" then
    self.data = {
      self.x - self.ox, self.y - self.oy,
      self.x - self.ox + self.width, self.y - self.oy,
      self.x - self.ox + self.width, self.y - self.oy + self.height,
      self.x - self.ox, self.y - self.oy + self.height
    }
  elseif self.shadowType == 'polygon' and (self.old_x ~= self.x or self.old_y ~= self.y) then
    local dx, dy = self.x - self.old_x, self.y - self.old_y
    for i = 1, #self.data, 2 do
      self.data[i], self.data[i+1] = self.data[i] + dx, self.data[i+1] + dy
    end
    self.old_x, self.old_y = self.x, self.y
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

-- move position
function body:move(x, y)
  if x then
    self.x = self.x + x
  end
  if y then
    self.y = self.y + y
  end
  self:refresh()
end

-- get x position
function body:getPosition()
  return self.x, self.y
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
  end
end

-- set offset
function body:setNormalOffset(nx, ny)
  if nx ~= self.nx or ny ~= self.ny then
    self.nx = nx
    self.ny = ny
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

function body:setVisible(visible)
  self.visible = visible
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
  local points = {...}
  self.x, self.y, self.width, self.height = points[1], points[2], 0, 0
  for i = 1, #points, 2 do
    local px, py = points[i], points[i+1]
    if px < self.x then self.x = px end
    if py < self.y then self.y = py end
    if px > self.width then self.width = px end
    if py > self.height then self.height = py end
  end
  self.width = self.width - self.x
  self.height = self.height - self.y
  for i = 1, #points, 2 do
    points[i], points[i+1] = points[i] - self.x, points[i+1] - self.y
  end

  poly_canvas = love.graphics.newCanvas(self.width, self.height)
  util.drawto(poly_canvas, 0, 0, 1, function()
    love.graphics.polygon('fill', points) 
  end)
  self.img = love.graphics.newImage(poly_canvas:getImageData()) 
  self.imgWidth = self.img:getWidth()
  self.imgHeight = self.img:getHeight()
  self.ix = self.imgWidth * 0.5
  self.iy = self.imgHeight * 0.5
  self:generateNormalMapFlat("top")
  --wrapping with polygon normals causes edges to show 
  --also we do not need wrapping for this default normal map
  self.normal:setWrap("clamp", "clamp")
  self.nx, self.ny = 0, 0

  self:setShadowType('polygon', ...)
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

function body:isInLightRange(light, l, t, w, h, s)
  local distance
  if self.type == 'circle' then
    return light.range > math.sqrt(math.pow(light.x - self.x, 2) + math.pow(light.y - self.y, 2)) 
  else
    local cx, cy = self.x + (self.width * 0.5), self.y + (self.height * 0.5)
    distance = math.sqrt(math.pow(light.x - cx, 2) + math.pow(light.y - cy, 2)) 
    return distance <= light.range + (self.width > self.height and self.width or self.height)
  end
end

function body:isInRange(l, t, w, h, s)
  local bx, by, bw, bh 
  if self.type == 'circle' then
    bx, by, bw, bh = (self.x + l/s) * s, (self.y + t/s) * s, self.radius/s, self.radius/s
  else
    bx, by, bw, bh = (self.x + l/s) * s, (self.y + t/s) * s, self.width/s, self.height/s
  end
  return self.visible and (bx + bw) > 0 and (bx - bw) < w/s and (by + bh) > 0 and (by - bh) < h/s
end

function body:drawNormal()
  if not self.refraction and not self.reflection and self.normalMesh then
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
      love.graphics.draw(self.normal, self.x - self.nx, self.y - self.ny)
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

function body:drawShadow(light)
  if self.castsNoShadow or (self.zheight - light.z) > 0 then
    return
  end

  love.graphics.setColor(self.red, self.green, self.blue, self.alpha)
  if self.shadowType == "rectangle" or self.shadowType == "polygon" then
    self:drawPolyShadow(light)
  elseif self.shadowType == "circle" then
    self:drawCircleShadow(light)
  elseif self.shadowType == "image" and self.img then
    self:drawImageShadow(light)
  end
end

--using shadow point calculations from this article
--http://web.cs.wpi.edu/~matt/courses/cs563/talks/shadow/shadow.html
function body:drawPolyShadow(light)
  local edgeFacingTo = {}
  for k = 1, #self.data, 2 do
    local indexOfNextVertex = (k + 2) % #self.data
    local normal = vec2(-self.data[indexOfNextVertex+1] + self.data[k + 1], self.data[indexOfNextVertex] - self.data[k]):normalize()
    local lightToPoint = vec2(self.data[k] - light.x, self.data[k + 1] - light.y):normalize()

    local dotProduct = normal:dot(lightToPoint)
    if dotProduct > 0 then 
      table.insert(edgeFacingTo, true)
    else 
      table.insert(edgeFacingTo, false) 
    end
  end

  local curShadowGeometry = {}
  local lxh = (light.x * self.zheight)
  local lyh = (light.y * self.zheight)
  local height_diff = (self.zheight - light.z) 
  if height_diff == 0 then -- prevent inf
    height_diff = -0.001
  end

  for k = 1, #edgeFacingTo do
    local nextIndex = (k + 1) % #edgeFacingTo
    if nextIndex == 0 then nextIndex = #edgeFacingTo end

    local x, y = self.data[nextIndex*2-1], self.data[nextIndex*2]
    local xs, ys = (lxh - (x * light.z))/height_diff, (lyh - (y * light.z))/height_diff

    if edgeFacingTo[k] and not edgeFacingTo[nextIndex] then
      curShadowGeometry[#curShadowGeometry+1] = x
      curShadowGeometry[#curShadowGeometry+1] = y
      curShadowGeometry[#curShadowGeometry+1] = xs
      curShadowGeometry[#curShadowGeometry+1] = ys
    elseif not edgeFacingTo[k] and not edgeFacingTo[nextIndex] then
      curShadowGeometry[#curShadowGeometry+1] = xs
      curShadowGeometry[#curShadowGeometry+1] = ys
    elseif not edgeFacingTo[k] and edgeFacingTo[nextIndex] then
      curShadowGeometry[#curShadowGeometry+1] = xs
      curShadowGeometry[#curShadowGeometry+1] = ys
      curShadowGeometry[#curShadowGeometry+1] = x
      curShadowGeometry[#curShadowGeometry+1] = y
    end
  end
  if #curShadowGeometry >= 6 then
    love.graphics.polygon("fill", unpack(curShadowGeometry))
  end
end

--using shadow point calculations from this article
--http://web.cs.wpi.edu/~matt/courses/cs563/talks/shadow/shadow.html
function body:drawCircleShadow(light)
  local curShadowGeometry = {}
  local angle = math.atan2(light.x - (self.x - self.ox), (self.y - self.oy) - light.y) + math.pi / 2
  local x2 = ((self.x - self.ox) + math.sin(angle) * self.radius)
  local y2 = ((self.y - self.oy) - math.cos(angle) * self.radius)
  local x3 = ((self.x - self.ox) - math.sin(angle) * self.radius)
  local y3 = ((self.y - self.oy) + math.cos(angle) * self.radius)

  local lxh = (light.x * self.zheight)
  local lyh = (light.y * self.zheight)
  local height_diff = (self.zheight - light.z) 
  if height_diff == 0 then -- prevent inf
    height_diff = -0.001
  end
  
  local x4 = (lxh - (x3 * light.z))/height_diff 
  local y4 = (lyh - (y3 * light.z))/height_diff 
  local x5 = (lxh - (x2 * light.z))/height_diff  
  local y5 = (lyh - (y2 * light.z))/height_diff  

  local radius = math.sqrt(math.pow(x5 - x4, 2) + math.pow(y5-y4, 2)) / 2
  local cx, cy = (x4 + x5)/2, (y4 + y5)/2
  local distance1 = math.sqrt(math.pow(light.x - self.x, 2) + math.pow(light.y - self.y, 2))
  local distance2 = math.sqrt(math.pow(light.x - cx, 2) + math.pow(light.y - cy, 2)) 

  if distance1 >= self.radius then
    love.graphics.polygon("fill", x2, y2, x3, y3, x4, y4, x5, y5)
  end

  if distance1 <= self.radius then
    love.graphics.circle("fill", cx, cy, radius)
  elseif distance2 < light.range then -- dont draw circle if way off screen
    local angle1 = math.atan2(y4 - cy, x4 - cx)
    local angle2 = math.atan2(y5 - cy, x5 - cx)
    if angle1 > angle2 then
      love.graphics.arc("fill", cx, cy, radius, angle1, angle2)
    else
      love.graphics.arc("fill", cx, cy, radius, angle1 - math.pi, angle2 - math.pi)
    end
  end
end

function body:drawImageShadow(light)
  local height_diff = (light.z - self.zheight) 
  if height_diff <= 0.1 then -- prevent shadows from leaving thier person like peter pan.
    height_diff = 0.1
  end

  local length = 1.0 / height_diff
  local shadowRotation = math.atan2((self.x) - light.x, (self.y + self.oy) - light.y)
  local shadowStartY = self.imgHeight + (math.cos(shadowRotation) + 1.0) * self.shadowY
  local shadowX = math.sin(shadowRotation) * self.imgHeight * length
  local shadowY = (length * math.cos(shadowRotation) + 1.0) * shadowStartY

  self.shadowMesh:setVertices({
    {shadowX, shadowY, 0, 0, self.red, self.green, self.blue, self.alpha},
    {shadowX + self.imgWidth, shadowY, 1, 0, self.red, self.green, self.blue, self.alpha},
    {self.imgWidth, shadowStartY, 1, 1, self.red, self.green, self.blue, self.alpha},
    {0, shadowStartY, 0, 1, self.red, self.green, self.blue, self.alpha}
  })

  love.graphics.draw(self.shadowMesh, self.x - self.ox, self.y - self.oy, 0, s, s)
end

return body
