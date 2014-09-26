local stencils = {}

function stencils.shadow(geometry, bodies)
  return function()
    for i = 1,#geometry do
      if geometry[i].alpha == 1.0 then
        love.graphics.polygon("fill", unpack(geometry[i]))
      end
    end
    for i = 1, #bodies do
      if not bodies[i].castsNoShadow then
        if bodies[i].shadowType == "circle" then
          love.graphics.circle("fill", bodies[i].x - bodies[i].ox, bodies[i].y - bodies[i].oy, bodies[i].radius)
        elseif bodies[i].shadowType == "rectangle" then
          love.graphics.rectangle("fill", bodies[i].x - bodies[i].ox, bodies[i].y - bodies[i].oy, bodies[i].width, bodies[i].height)
        elseif bodies[i].shadowType == "polygon" then
          love.graphics.polygon("fill", unpack(bodies[i].data))
        elseif bodies[i].shadowType == "image" then
        --love.graphics.rectangle("fill", bodies[i].x - bodies[i].ox, bodies[i].y - bodies[i].oy, bodies[i].width, bodies[i].height)
        end
      end
    end
  end
end

function stencils.poly(bodies)
  return function()
    for i = 1, #bodies do
      if bodies[i].shine and (bodies[i].glowStrength == 0.0 or (bodies[i].type == "image" and not bodies[i].normal)) then
        if bodies[i].shadowType == "circle" then
          love.graphics.circle("fill", bodies[i].x - bodies[i].ox, bodies[i].y - bodies[i].oy, bodies[i].radius)
        elseif bodies[i].shadowType == "rectangle" then
          love.graphics.rectangle("fill", bodies[i].x - bodies[i].ox, bodies[i].y - bodies[i].oy, bodies[i].width, bodies[i].height)
        elseif bodies[i].shadowType == "polygon" then
          love.graphics.polygon("fill", unpack(bodies[i].data))
        elseif bodies[i].shadowType == "image" then
        --love.graphics.rectangle("fill", bodies[i].x - bodies[i].ox, bodies[i].y - bodies[i].oy, bodies[i].width, bodies[i].height)
        end
      end
    end
  end
end

return stencils
