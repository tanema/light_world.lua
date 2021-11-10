local List = {}

function List:new(x, y, w, h)
  o = {
    x = x, y = y, w = w, h = h,
    items = {},
  }
  setmetatable(o, self)
  self.__index = self
  return o
end

function List:add(item, file, cb)
  local x, y = self.x+2, self.y+((self.h+1)*(#self.items-1)+1)
  local w, h = self.w-3, self.h
  table.insert(self.items, {item = item, file = file, cb = cb, x = x, y = y, w = w, h = h, hover = false})
end

function List:update(dt)
  local mx, my = love.mouse.getPosition()
  for i, item in ipairs(self.items) do
    item.hover = mx >= item.x and mx <= (item.x+item.w) and my >= item.y and my <= (item.y+item.h)
  end
end

function List:mousepressed(mx, my, b)
  for i, item in ipairs(self.items) do
    if item.hover then return item.cb() end
  end
end

function List:draw()
  love.graphics.setFont(self.font)
  love.graphics.setColor(0.18, 0.61, 1)
  for i, item in ipairs(self.items) do
    love.graphics.setColor(0, 0, 0, item.hover and 0.49 or 0.24)
    love.graphics.rectangle("fill", item.x+1, item.y+1, item.w-3, item.h)
    love.graphics.setColor(1, 1, 1, item.hover and 1 or 0.49)
    love.graphics.print(item.item, item.x+10, item.y+6)
  end
end

return List
