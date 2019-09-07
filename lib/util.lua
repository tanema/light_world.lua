local util = {}
--TODO: the whole stencil/canvas system should be reviewed since it has been changed in a naive way

function util.process(canvas, options)
  --TODO: now you cannot draw a canvas to itself
  temp = love.graphics.newCanvas()
  util.drawCanvasToCanvas(canvas, temp, options)
  util.drawCanvasToCanvas(temp, canvas, options)
end

function util.drawCanvasToCanvas(canvas, other_canvas, options)
  options = options or {}

  util.drawto(other_canvas, 0, 0, 1, options['stencil'] or options['istencil'] and true or false, function()
    if options["blendmode"] == 'multiply' then
      love.graphics.setBlendMode(options["blendmode"], 'premultiplied')
    elseif options["blendmode"] then
      love.graphics.setBlendMode(options["blendmode"])
    end
    if options["shader"] then
      love.graphics.setShader(options["shader"])
    end
    if options["stencil"] then
      love.graphics.stencil(options["stencil"])
      love.graphics.setStencilTest("greater",0)
    end
    if options["istencil"] then
      love.graphics.stencil(options["istencil"])
      love.graphics.setStencilTest("equal", 0)
    end
    if options["color"] then
      love.graphics.setColor(unpack(options["color"]))
    else
      love.graphics.setColor(1,1,1)
    end
    if love.graphics.getCanvas() ~= canvas then
      love.graphics.draw(canvas,0,0)
    end
    if options["blendmode"] then
      love.graphics.setBlendMode("alpha")
    end
    if options["shader"] then
      love.graphics.setShader()
    end
    if options["stencil"] or options["istencil"] then
      --love.graphics.setInvertedStencil()
      love.graphics.setStencilTest()
    end
  end)
end

function util.drawto(canvas, x, y, scale, stencil, cb)
  local last_buffer = love.graphics.getCanvas()
  love.graphics.push()
    love.graphics.origin()
      love.graphics.setCanvas({ canvas, stencil = stencil })
      love.graphics.translate(x, y)
      love.graphics.scale(scale)
      cb()
    love.graphics.setCanvas(last_buffer)
  love.graphics.pop()
end

function util.loadShader(name)
  local shader = ""
  local externInit = {}
  for line in love.filesystem.lines(name) do

    if line:sub(1,6) == "extern" then
      local type, name = line:match("extern (%w+) (%w+)")
      local value = line:match("=(.*);")
      if value then
        externInit[name] = {type=type, val=value}
        line = line:match("extern %w+ %w+")..";"
      end
    end
    shader = shader.."\n"..line
  end

  local effect = love.graphics.newShader(shader)
  for k, v in pairs(externInit) do
    if v.type == "bool" then
      effect:send(k, v.val)
    elseif v.type == "int" or v.type == "uint" then
      effect:sendInt(k, tonumber(v.val))
    elseif v.type == "float" or v.type == "double" or v.type == "number" then
      effect:send(k, tonumber(v.val))
    elseif v.type:sub(1,3) == "vec" then
      v.val = v.val:gsub(" ", ""):sub(6):sub(1, -2)
      local next = v.val:gmatch("([^,]+)")
      local values = {}
      for n in next do
        table.insert(values, tonumber(n))
      end
      effect:send(k, values)
    end
  end
  return effect
end


return util
