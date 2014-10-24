local stencils = {}

function stencils.shadow(geometry, bodies)
  return function()
    --cast shadows
    for i = 1,#geometry do
      if geometry[i].alpha == 1.0 then
        love.graphics.polygon("fill", unpack(geometry[i]))
      end
    end
    -- underneath shadows
    for i = 1, #bodies do
      if not bodies[i].castsNoShadow then
        bodies[i]:stencil()
      end
    end
  end
end

function stencils.shine(bodies)
  return function()
    for i = 1, #bodies do
      if bodies[i].shine and 
        (bodies[i].glowStrength == 0.0 or 
        (bodies[i].type == "image" and not bodies[i].normal)) 
      then
        bodies[i]:stencil()
      end
    end
  end
end

return stencils
