local inspect = require 'examples.vendor.inspect'
local ImageObject, Rect, Circle, Refraction = {}, {}, {}, {}
ImageObject.__index = ImageObject
Rect.__index = Rect
Circle.__index = Circle
Refraction.__index = Refraction
local imageCache = {}

local function loadImg(path)
  if imageCache[path] == nil and love.filesystem.getInfo(path) ~= nil then
    imageCache[path] = love.graphics.newImage(path)
  end
  return imageCache[path]
end

local function loadMaterials(path)
  if imageCache[path] == nil and love.filesystem.getInfo(path) ~= nil then
    imageCache[path] = {}
    local files = love.filesystem.getDirectoryItems(path)
    for i, file in ipairs(files) do
      imageCache[path][i] = loadImg(path .."/" .. file)
    end
  end
  return imageCache[path]
end

function ImageObject:new(lightWorld, path, x, y, shadowType)
  o = {x = x, y = y, shadowType = shadowType}
  setmetatable(o, self)
  o.base = loadImg(path .. "/base.png")
  o.normal = loadImg(path .. "/normal.png")
  o.glow = loadImg(path .. "/glow.png")
  o.materials = loadMaterials(path .. "/materials")
  o.body = lightWorld:newImage(o.base, x, y)
  o.x, o.y = o.x - o.base:getWidth() * 0.5, o.y - o.base:getHeight() * 0.5
  if o.normal ~= nil then o.body:setNormalMap(o.normal) end
  if o.glow ~= nil then o.body:setGlowMap(o.glow) end
  if shadowType ~= nil then
    o.body:setShadowType(shadowType)
  end
  if o.materials ~= nil and #o.materials > 0 then
    o.body:setMaterial(o.materials[math.random(1, #o.materials-1)])
  end
  return o
end

function ImageObject:update(dt) end

function ImageObject:draw()
  love.graphics.setColor(1, 1, 1)
  love.graphics.draw(self.base, self.x, self.y)
end

function Rect:new(lightWorld, x, y, w, h)
  local w, h = math.random(32, 64), math.random(32, 64)
  local r, g, b = math.random(), math.random(), math.random()
  o = {x = x, y = y, w = w, h = h, r = r, g = g, b = b}
  setmetatable(o, self)
  o.body = lightWorld:newRectangle(x, y, w, h)
  o.x, o.y = o.x - o.w * 0.5, o.y - o.h * 0.5
  o.body:setGlowStrength(1.0)
  o.body:setGlowColor(math.random(), math.random(), math.random())
  o.body:setColor(r, g, b)
  return o
end

function Rect:update(dt) end

function Rect:draw()
  love.graphics.setColor(self.r, self.g, self.b)
  love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
end

function Circle:new(lightWorld, x, y, rad)
  local r, g, b = math.random(), math.random(), math.random()
  o = {x = x, y = y, rad = rad, r = r, g = g, b = b}
  setmetatable(o, self)
  o.body = lightWorld:newCircle(x, y, rad)
  o.body:setGlowStrength(1.0)
  o.body:setGlowColor(math.random(), math.random(), math.random())
  o.body:setColor(r, g, b)
  return o
end

function Circle:update(dt) end

function Circle:draw()
  love.graphics.setColor(self.r, self.g, self.b)
  love.graphics.circle("fill", self.x, self.y, self.rad)
end

function Refraction:new(lightWorld, path, x, y)
  o = {x = x, y = y, tx = 0, ty = 0}
  setmetatable(o, self)
  o.base = loadImg(path .. "/base.png")
  o.normal = loadImg(path .. "/normal.png")
  o.body = lightWorld:newRefraction(o.normal, x, y)
  o.x, o.y = o.x - o.base:getWidth() * 0.5, o.y - o.base:getHeight() * 0.5
  o.body:setReflection(true)
  return o
end

function Refraction:update(dt)
  self.tx = self.tx + dt * 32.0
  self.ty = self.ty + dt * 8.0
  self.body:setNormalTileOffset(self.tx, self.ty)
end

function Refraction:draw()
  love.graphics.setBlendMode("alpha")
  love.graphics.setColor(1, 1, 1, 0.74)
  love.graphics.draw(self.base, self.x, self.y)
end

return {
  ImageObject = ImageObject,
  Rect = Rect,
  Circle = Circle,
  Refraction = Refraction,
}
