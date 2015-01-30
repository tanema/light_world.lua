local _PACKAGE    = (...):match("^(.+)[%./][^%./]+") or ""
local normal_map  = require(_PACKAGE..'/normal_map')
local util        = require(_PACKAGE..'/util')
local anim8       = require(_PACKAGE..'/anim8')
local vector      = require(_PACKAGE..'/vector')

local body        = {}
body.__index = body

body.glowShader     = love.graphics.newShader(_PACKAGE.."/shaders/glow.glsl")
body.materialShader = love.graphics.newShader(_PACKAGE.."/shaders/material.glsl")

local function new(id, type, ...)
	local args = {...}
  local obj = setmetatable({}, body)
	obj.id = id
	obj.type = type
	obj.shine = true
	obj.red = 1.0
	obj.green = 1.0
	obj.blue = 1.0
	obj.alpha = 1.0
	obj.glowRed = 255
	obj.glowGreen = 255
	obj.glowBlue = 255
	obj.glowStrength = 0.0
	obj.tileX = 0
	obj.tileY = 0
  obj.zheight = 1

  obj.rotation = 0
  obj.scalex = 1
  obj.scaley = 1
 
  obj.castsNoShadow = false
  obj.visible = true
  obj.is_on_screen = true

	if obj.type == "circle" then
		obj.x = args[1] or 0
		obj.y = args[2] or 0

    circle_canvas = love.graphics.newCanvas(args[3]*2, args[3]*2)
    util.drawto(circle_canvas, 0, 0, 1, function()
      love.graphics.circle('fill', args[3], args[3], args[3]) 
    end)
    obj.img = love.graphics.newImage(circle_canvas:getImageData()) 
    obj.imgWidth = obj.img:getWidth()
    obj.imgHeight = obj.img:getHeight()
    obj.ix = obj.imgWidth * 0.5
    obj.iy = obj.imgHeight * 0.5
    obj:generateNormalMapFlat("top")

    obj:setShadowType('circle', args[3], args[4], args[5])
	elseif obj.type == "rectangle" then
		local x = args[1] or 0
		local y = args[2] or 0
    local width = args[3] or 64
    local height = args[4] or 64
    local ox = args[5] or width * 0.5
    local oy = args[6] or height * 0.5

    obj:setPoints(
      x - ox, y - oy,
      x - ox + width, y - oy,
      x - ox + width, y - oy + height,
      x - ox,  y - oy + height
    )
	elseif obj.type == "polygon" then
    obj:setPoints(...)
	elseif obj.type == "image" then
		obj.img = args[1]
		obj.x = args[2] or 0
		obj.y = args[3] or 0
		if obj.img then
			obj.imgWidth = obj.img:getWidth()
			obj.imgHeight = obj.img:getHeight()
			obj.ix = obj.imgWidth * 0.5
			obj.iy = obj.imgHeight * 0.5
		end
    obj:generateNormalMapFlat("top")
    obj:setShadowType('rectangle', args[4] or obj.imgWidth, args[5] or obj.imgHeight, args[6], args[7])
		obj.reflective = true
  elseif obj.type == "animation" then
		obj.img = args[1]
		obj.x = args[2] or 0
		obj.y = args[3] or 0
    obj.animations = {}
    obj.castsNoShadow = true
    obj:generateNormalMapFlat("top")
		obj.reflective = true
	elseif obj.type == "refraction" then
    obj.x = args[2] or 0
    obj.y = args[3] or 0
    obj:setNormalMap(args[1], args[4], args[5])
    obj.width = args[4] or obj.normalWidth
    obj.height = args[5] or obj.normalHeight
    obj.ox = obj.width * 0.5
    obj.oy = obj.height * 0.5
    obj.refraction = true
  elseif obj.type == "reflection" then
    obj.x = args[2] or 0
    obj.y = args[3] or 0
    obj:setNormalMap(args[1], args[4], args[5])
    obj.width = args[4] or obj.normalWidth
    obj.height = args[5] or obj.normalHeight
    obj.ox = obj.width * 0.5
    obj.oy = obj.height * 0.5
    obj.reflection = true
	end

  obj:commit_changes()

  return obj
end

-- refresh
function body:refresh()
  if self.shadowType == 'polygon' and self:has_changed() then
    local dx, dy, dr, dsx, dsy = self:changes()
    if self:position_changed() then
      for i = 1, #self.data, 2 do
        self.data[i], self.data[i+1] = self.data[i] + dx, self.data[i+1] + dy
      end
    end
    if self:rotation_changed() then
      local center = vector(self.x, self.y)
      for i = 1, #self.data, 2 do
        self.data[i], self.data[i+1] = vector(self.data[i], self.data[i+1]):rotateAround(center, dr):unpack()
      end
    end
    if self:scale_changed() then
      for i = 1, #self.data, 2 do
        self.data[i] = self.x + (self.data[i] - self.x) + ((self.data[i] - self.x) * dsx)
        self.data[i+1] = self.y + (self.data[i+1] - self.y) + ((self.data[i+1] - self.y) * dsy)
      end
    end
    self:commit_changes()
  end
end

function body:has_changed()
  return self:position_changed() or self:rotation_changed() or self:scale_changed()
end

function body:position_changed()
  return self.old_x ~= self.x or 
         self.old_y ~= self.y
end

function body:rotation_changed()
  return self.old_rotation ~= self.rotation
end

function body:scale_changed()
  return self.old_scalex ~= self.scalex or
         self.old_scaley ~= self.scaley
end

function body:changes()
  return self.x - self.old_x, 
         self.y - self.old_y,
         self.rotation - self.old_rotation,
         self.scalex - self.old_scalex,
         self.scaley - self.old_scaley
end

function body:commit_changes()
  self.old_x, self.old_y = self.x, self.y
  self.old_rotation = self.rotation
  self.old_scalex, self.old_scaley = self.scalex, self.scaley
end

function body:newGrid(frameWidth, frameHeight, imageWidth, imageHeight, left, top, border)
  return anim8.newGrid(
    frameWidth, frameHeight, 
    imageWidth or self.img:getWidth(), imageHeight or self.img:getHeight(), 
    left, top, border
  )
end
-- frameWidth, frameHeight, imageWidth, imageHeight, left, top, border 
function body:addAnimation(name, frames, durations, onLoop)
  self.animations[name] = anim8.newAnimation(frames, durations, onLoop)

  if not self.current_animation_name then
    self:setAnimation(name)
  end
end

function body:setAnimation(name)
  self.current_animation_name = name
  self.animation = self.animations[self.current_animation_name]

  local frame = self.animation.frames[self.animation.position]
  _,_,self.width, self.height = frame:getViewport()
end

function body:gotoFrame(frame) self.animation:gotoFrame(frame) end
function body:pause() self.animation:pause() end
function body:resume() self.animation:resume() end
function body:flipH() self.animation:flipH() end
function body:flipV() self.animation:flipV() end
function body:pauseAtEnd() self.animation:pauseAtEnd() end
function body:pauseAtStart() self.animation:pauseAtStart() end

function body:update(dt)
  self:refresh()
  if self.type == "animation" and self.animation then
    local frame = self.animation.frames[self.animation.position]
    _,_,self.width, self.height = frame:getViewport()
    self.imgWidth, self.imgHeight = self.width, self.height
    self.normalWidth, self.normalHeight = self.width, self.height 
    self.ix, self.iy = self.imgWidth * 0.5,self.imgHeight * 0.5
    self.nx, self.ny = self.ix, self.iy
    self.animation:update(dt)
  end
end

function body:rotate(angle)
  self:setRotation(self.rotation + angle)
end

function body:setRotation(angle)
  self.rotation = angle
end

function body:scale(sx, sy)
  self.scalex = self.scalex + sx
  self.scaley = self.scaley + (sy or sx)
end

function body:setScale(sx, sy)
  self.scalex = sx
  self.scaley = sy or sx
end

-- set position
function body:setPosition(x, y)
  if x ~= self.x or y ~= self.y then
    self.x = x
    self.y = y
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

-- set offset
function body:setOffset(ox, oy)
  if ox ~= self.ox or oy ~= self.oy then
    self.ox = ox
    self.oy = oy
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
  -- normalize width and height
  self.width = self.width - self.x
  self.height = self.height - self.y
  for i = 1, #points, 2 do
    points[i], points[i+1] = points[i] - self.x, points[i+1] - self.y
  end
  self.x = self.x + (self.width * 0.5)
  self.y = self.y + (self.height * 0.5)

  local poly_canvas = love.graphics.newCanvas(self.width, self.height)
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
    self.shadowType = "polygon"
    self.width = args[1] or 64
    self.height = args[2] or 64
    self.ox = args[3] or self.width * 0.5
    self.oy = args[4] or self.height * 0.5

    self.data = {
      self.x - self.ox,  self.y - self.oy,
      self.x - self.ox + self.width, self.y - self.oy,
      self.x - self.ox + self.width, self.y - self.oy + self.height,
      self.x - self.ox,  self.y - self.oy + self.height
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

function body:isVisible()
  return self.visible and self.is_on_screen
end

function body:inLightRange(light)
  local l, t, w = light.x - light.range, light.y - light.range, light.range*2 
  return self:inRange(l,t,w,w,1)
end

function body:inRange(l, t, w, h, s)
  local radius
  if self.type == 'circle' then
    radius = self.radius
  else
    radius = (self.width > self.height and self.width or self.height)
  end
    
  local bx, by, bw, bh = self.x - radius, self.y - radius, radius * 2, radius * 2

  return self.visible and (bx+bw) > (l/s) and bx < (l+w)/s and (by+bh) > (t/s) and by < (t+h)/s
end

function body:drawAnimation()
  self.animation:draw(self.img, self.x, self.y, self.rotation, self.scalex, self.scaley, self.ix, self.iy)
end

function body:drawNormal()
  if not self.refraction and not self.reflection and self.normalMesh then
    love.graphics.setColor(255, 255, 255)
    if self.type == 'animation' then
      self.animation:draw(self.normal, self.x, self.y, self.rotation, self.scalex, self.scaley, self.nx, self.ny)
    else
      love.graphics.draw(self.normalMesh, self.x, self.y, self.rotation, self.scalex, self.scaley, self.nx, self.ny)
    end
  end
end

function body:drawGlow()
  love.graphics.setColor(self.glowRed * self.glowStrength, self.glowGreen * self.glowStrength, self.glowBlue * self.glowStrength)

  if self.type == "circle" then
    love.graphics.circle("fill", self.x, self.y, self.radius)
  elseif self.type == "polygon" then
    love.graphics.polygon("fill", unpack(self.data))
  elseif (self.type == "image" or self.type == "animation") and self.img then
    if self.glow then
      love.graphics.setShader(self.glowShader)
      self.glowShader:send("glowImage", self.glow)
      self.glowShader:send("glowTime", love.timer.getTime() * 0.5)
      love.graphics.setColor(255, 255, 255)
    else
      love.graphics.setColor(0, 0, 0)
    end

    if self.type == "animation" then
      self.animation:draw(self.img, self.x, self.y, self.rotation, self.scalex, self.scaley, self.ix, self.iy)
    else
      love.graphics.draw(self.img, self.x, self.y, self.rotation, self.scalex, self.scaley, self.ix, self.iy)
    end

    love.graphics.setShader()
  end
end

function body:drawRefraction()
  if self.refraction and self.normal then
    love.graphics.setColor(255, 255, 255)
    if self.tileX == 0.0 and self.tileY == 0.0 then
      love.graphics.draw(self.normal, self.x, self.y, self.rotation, self.scalex, self.scaley, self.nx, self.ny)
    else
      self.normalMesh:setVertices(self.normalVert)
      love.graphics.draw(self.normalMesh, self.x, self.y, self.rotation, self.scalex, self.scaley, self.nx, self.ny)
    end
  end

  love.graphics.setColor(0, 0, 0)

  if not self.refractive then
    if self.type == "circle" then
      love.graphics.circle("fill", self.x, self.y, self.radius)
    elseif self.type == "polygon" then
      love.graphics.polygon("fill", unpack(self.data))
    elseif self.type == "image" and self.img then
      love.graphics.draw(self.img, self.x, self.y, self.rotation, self.scalex, self.scaley, self.ix, self.iy)
    elseif self.type == 'animation' then
      self.animation:draw(self.img, self.x, self.y, self.rotation, self.scalex, self.scaley, self.ix, self.iy)
    end
  end
end

function body:drawReflection()
  if self.reflection and self.normal then
    love.graphics.setColor(255, 0, 0)
    self.normalMesh:setVertices(self.normalVert)
    love.graphics.draw(self.normalMesh, self.x, self.y, self.rotation, self.scalex, self.scaley, self.nx, self.ny)
  end
  if self.reflective and self.img then
    love.graphics.setColor(0, 255, 0)
    if self.type == 'animation' then
      self.animation:draw(self.img, self.x, self.y, self.rotation, self.scalex, self.scaley, self.ix, self.iy)
    else
      love.graphics.draw(self.img, self.x, self.y, self.rotation, self.scalex, self.scaley, self.ix, self.iy)
    end
  elseif not self.reflection and self.img then
    love.graphics.setColor(0, 0, 0)
    if self.type == 'animation' then
      self.animation:draw(self.img, self.x, self.y, self.rotation, self.scalex, self.scaley, self.ix, self.iy)
    else
      love.graphics.draw(self.img, self.x, self.y, self.rotation, self.scalex, self.scaley, self.ix, self.iy)
    end
  end
end

function body:drawMaterial()
  if self.material and self.normal then
    love.graphics.setShader(self.materialShader)
    love.graphics.setColor(255, 255, 255)
    self.materialShader:send("material", self.material)
    if self.type == 'animation' then
      self.animation:draw(self.normal, self.x, self.y, self.rotation, self.scalex, self.scaley, self.nx, self.ny)
    else
      love.graphics.draw(self.normal, self.x, self.y, self.rotation, self.scalex, self.scaley, self.nx, self.ny)
    end
    love.graphics.setShader()
  end
end

function body:drawStencil()
  if not self.refraction and not self.reflection and not self.castsNoShadow then
    love.graphics.draw(self.img, self.x, self.y, self.rotation, self.scalex, self.scaley, self.ix, self.iy)
  end
end

function body:drawShadow(light)
  if self.castsNoShadow or (self.zheight - light.z) > 0 then
    return
  end
   
  love.graphics.setColor(self.red, self.green, self.blue, self.alpha)
  if self.shadowType == "polygon" then
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
  local lightPosition = vector(light.x, light.y)
  local lh = lightPosition * self.zheight

  local height_diff = (self.zheight - light.z) 
  if height_diff == 0 then -- prevent inf
    height_diff = -0.001
  end

  for i = 1, #self.data, 2 do
    local vertex = vector(self.data[i], self.data[i + 1])
    local nextVertex = vector(self.data[(i + 2) % 8], self.data[(i + 2) % 8 + 1])
    local startToEnd = nextVertex - vertex
    if vector(startToEnd.y, -startToEnd.x) * (vertex - lightPosition) > 0 then
      local point1 = (lh - (vertex * light.z))/height_diff
      local point2 = (lh - (nextVertex * light.z))/height_diff
      love.graphics.polygon("fill", 
        vertex.x, vertex.y, point1.x, point1.y, 
        point2.x, point2.y, nextVertex.x, nextVertex.y)
    end
  end
end

--using shadow point calculations from this article
--http://web.cs.wpi.edu/~matt/courses/cs563/talks/shadow/shadow.html
function body:drawCircleShadow(light)
  local selfPos = vector(self.x - self.ox, self.y - self.oy)
  local lightPosition = vector(light.x, light.y)
  local lh = lightPosition * self.zheight
  local height_diff = (self.zheight - light.z) 
  if height_diff == 0 then -- prevent inf
    height_diff = -0.001
  end

  local angle = math.atan2(light.x - selfPos.x, selfPos.y - light.y) + math.pi / 2
  local point1 = vector(selfPos.x + math.sin(angle) * self.radius,
                        selfPos.y - math.cos(angle) * self.radius)
  local point2 = vector(selfPos.x - math.sin(angle) * self.radius,
                        selfPos.y + math.cos(angle) * self.radius)
  local point3 = (lh - (point1 * light.z))/height_diff
  local point4 = (lh - (point2 * light.z))/height_diff
  
  local radius = point3:dist(point4)/2
  local circleCenter = (point3 + point4)/2

  if lightPosition:dist(selfPos) <= self.radius then
    love.graphics.circle("fill", circleCenter.x, circleCenter.y, radius)
  else
    love.graphics.polygon("fill", point1.x, point1.y, 
                                  point2.x, point2.y, 
                                  point4.x, point4.y,
                                  point3.x, point3.y)
    if lightPosition:dist(circleCenter) < light.range then -- dont draw circle if way off screen
      local angle1 = math.atan2(point3.y - circleCenter.y, point3.x - circleCenter.x)
      local angle2 = math.atan2(point4.y - circleCenter.y, point4.x - circleCenter.x)
      if angle1 < angle2 then
        love.graphics.arc("fill", circleCenter.x, circleCenter.y, radius, angle1, angle2)
      else
        love.graphics.arc("fill", circleCenter.x, circleCenter.y, radius, angle1 - math.pi, angle2 - math.pi)
      end
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

  love.graphics.draw(self.shadowMesh, self.x, self.y, self.rotation, self.scalex, self.scaley, self.ox, self.oy)
end

return setmetatable({new = new}, {__call = function(_, ...) return new(...) end})
