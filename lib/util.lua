local util = {}
--TODO: the whole stencil/canvas system should be reviewed since it has been changed in a naive way

function util.process(canvas, options)
  --TODO: now you cannot draw a canvas to itself  
  util.drawCanvasToCanvas(canvas, canvas, options)
end

function util.drawCanvasToCanvas(canvas, other_canvas, options)
  options = options or {}

  util.drawto(other_canvas, 0, 0, 1, function()
    if options["blendmode"] then
      love.graphics.setBlendMode(options["blendmode"])
    end
    if options["shader"] then
      love.graphics.setShader(options["shader"])
    end
    if options["stencil"] then
      love.graphics.stencil(options["stencil"])
    end
    if options["istencil"] then
      love.graphics.stencil(options["istencil"])
      --TODO: invert map
    end
    if options["color"] then
      love.graphics.setColor(unpack(options["color"]))
    else
      love.graphics.setColor(255,255,255)
    end
    --TODO: not really sure if this is right
    love.graphics.setCanvas()
    love.graphics.draw(canvas,0,0)
    love.graphics.setCanvas(canvas)
    if options["blendmode"] then
      love.graphics.setBlendMode("alpha")
    end
    if options["shader"] then
      love.graphics.setShader()
    end
    if options["stencil"] then
      --TODO: check if commenting this is really ok
      --love.graphics.stencil()
    end
    if options["istencil"] then
      --TODO: check if commenting this is really ok
      --love.graphics.setInvertedStencil()
    end
  end)
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
