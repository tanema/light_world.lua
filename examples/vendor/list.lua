local List = {}

function inside(mx, my, x, y, w, h)
  return mx >= x and mx <= (x+w) and my >= y and my <= (y+h)
end

function List:new()
  o = {}
  setmetatable(o, self)
  self.__index = self

  o.items = {}
  o.files = {}

  o.x = 50
  o.y = 70

  o.width = 400
  o.height = 500

  o.item_height = 23
  o.sum_item_height = 0

  o.bar_size = 20
  o.bar_pos = 0
  o.bar_max_pos = 0
  o.bar_width = 15
  o.bar_lock = nil

  return o
end

function List:add(item, file)
  table.insert(self.items, item)
  table.insert(self.files, file)
  self.items.n = #self.items
  self.bar_pos = 0
  local num_items = (self.height/self.item_height)
  local ratio = num_items/self.items.n
  self.bar_size = self.height * ratio
  self.bar_max_pos = self.height - self.bar_size - 3
  self.sum_item_height = (self.item_height+1) * self.items.n + 2
end

function List:hasBar()
  return self.sum_item_height > self.height
end

function List:getBarRatio()
  return self.bar_pos/self.bar_max_pos
end

function List:getOffset()
  local ratio = self.bar_pos/self.bar_max_pos
  return math.floor((self.sum_item_height-self.height)*ratio + 0.5)
end

function List:update(dt)
  if self.bar_lock then
    local dy = math.floor(love.mouse.getY()-self.bar_lock.y+0.5)
    self.bar_pos = self.bar_pos + dy

    if self.bar_pos < 0 then
      self.bar_pos = 0
    elseif self.bar_pos > self.bar_max_pos then
     self.bar_pos = self.bar_max_pos
    end

    self.bar_lock.y = love.mouse.getY()
  end
end

function List:mousepressed(mx, my, b)
  if self:hasBar() then
    if b == 1 then
      local x, y, w, h = self:getBarRect()
      if inside(mx, my, x, y, w, h) then
        self.bar_lock = { x = mx, y = my }
      end
    end

    local per_pixel = (self.sum_item_height-self.height)/self.bar_max_pos
    local bar_pixel_dt = math.floor(((self.item_height)*3)/per_pixel + 0.5)

    if b == "wd" then
      self.bar_pos = self.bar_pos + bar_pixel_dt
      if self.bar_pos > self.bar_max_pos then
        self.bar_pos = self.bar_max_pos
      end
    elseif b == "wu" then
      self.bar_pos = self.bar_pos - bar_pixel_dt
      if self.bar_pos < 0 then
        self.bar_pos = 0
      end
    end
  end

  if b == 1 and inside(mx, my, self.x+2, self.y+1, self.width-3, self.height-3) then
    local tx, ty = mx-self.x, my + self:getOffset() - self.y
    local index = math.floor((ty/self.sum_item_height)*self.items.n)
    local i = self.items[index+1]
    local f = self.files[index+1]
    if f then
      exf.start(i, f)
    end
  end
end

function List:mousereleased(x, y, b)
  if self:hasBar() then
    if b == 1 then
      self.bar_lock = nil
    end
  end
end

function List:getBarRect()
  return self.x+self.width+2, self.y+1+self.bar_pos,
         self.bar_width-3, self.bar_size
end

function List:getItemRect(i)
  return self.x+2, self.y+((self.item_height+1)*(i-1)+1)-self:getOffset(),
         self.width-3, self.item_height
end

function List:draw()
  love.graphics.setLineWidth(2)
  love.graphics.setLineStyle("rough")
  love.graphics.setFont(self.font)

  love.graphics.setColor(48/255, 156/255, 225 / 255)

  local mx, my = love.mouse.getPosition()

  -- Get interval to display.
  local start_i = math.floor( self:getOffset()/(self.item_height+1) ) + 1
  local end_i = start_i+math.floor( self.height/(self.item_height+1) ) + 1

  if end_i > self.items.n then
    end_i = self.items.n
  end

  love.graphics.setScissor(self.x, self.y, self.width, self.height)

  -- Items.
  for i = start_i,end_i do
    local x, y, w, h = self:getItemRect(i)
    local hover = inside(mx, my, x, y, w, h)

    if hover then
      love.graphics.setColor(0, 0, 0, 127/255)
    else
      love.graphics.setColor(0, 0, 0, 63/255)
    end

    love.graphics.rectangle("fill", x+1, y+i+1, w-3, h)

    if hover then
      love.graphics.setColor(1, 1, 1, 1)
    else
      love.graphics.setColor(1, 1, 1, 127/255)
    end

    local e_id = string.sub(self.items[i], 1, 5)
    local e_rest = string.sub(self.items[i], 5)

    love.graphics.print(e_id, x+10, y+i+6)  --Updated y placement -- Used to change position of Example IDs
    love.graphics.print(e_rest, x+50, y+i+6) --Updated y placement -- Used to change position of Example Titles
  end

  love.graphics.setScissor()

  -- Bar.
  if self:hasBar() then
    local x, y, w, h = self:getBarRect()
    local hover = inside(mx, my, x, y, w, h)

    if hover or self.bar_lock then
      love.graphics.setColor(0, 0, 0, 127/255)
    else
      love.graphics.setColor(0, 0, 0, 63/255)
    end
    love.graphics.rectangle("fill", x, y, w, h)
  end

  -- Border.
  love.graphics.setColor(0, 0, 0, 63/255)
  love.graphics.rectangle("line", self.x+self.width, self.y, self.bar_width, self.height)
  love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
end

return List
