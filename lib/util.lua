local util = {}

function util.drawCanvasToCanvas(canvas, other_canvas, options)
  options = options or {}

  local last_buffer = love.graphics.getCanvas()
  love.graphics.push()
    love.graphics.origin()
    love.graphics.setCanvas(other_canvas)
      if options["blendmode"] then
        love.graphics.setBlendMode(options["blendmode"])
      end
      if options["shader"] then
        love.graphics.setShader(options["shader"])
      end
      if options["color"] then
        love.graphics.setColor(unpack(options["color"]))
      end
      love.graphics.setColor(255,255,255)
      love.graphics.draw(canvas,0,0)
    love.graphics.setCanvas(last_buffer)
    if options["blendmode"] then
      love.graphics.setBlendMode("alpha")
    end
    if options["shader"] then
      love.graphics.setShader()
    end
  love.graphics.pop()
end

function util.drawto(canvas, x, y, scale, cb)
  local last_buffer = love.graphics.getCanvas()
  love.graphics.push()
    love.graphics.origin()
    love.graphics.setCanvas(canvas)
      love.graphics.translate(x, y)
      love.graphics.scale(scale)
      cb()
    love.graphics.setCanvas(last_buffer)
  love.graphics.pop()
end

return util
